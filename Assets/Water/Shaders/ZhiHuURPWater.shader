Shader "URP/URPUnlitShader" {
    Properties {
        _MainTex ("MainTex", 2D) = "White" { }
        _color ("color", Color) = (0.325, 0.807, 0.971, 0.725)
        [Normal]_NormalMap ("normalMap法线扰动", 2D) = "bump" { }
        _NormalIntensity ("NormalIntensity法线扰动强度", Range(0, 5)) = 1
        _NormalScale ("NormalScale法线缩放", Range(0, 5)) = 1
        _Offset ("Offset偏移", Range(-1, 1)) = 0
        
        _WaveXSpeed ("WaveXSpeed", Range(0, 1)) = 0.5
        _WaveYSpeed ("WaveYSpeed", Range(0, 1)) = 0.5
        _NormalRefract ("NormalRefract", Range(0, 1)) = 0.5
        
        _DepthGradientShallow ("Depth Gradient Shallow浅", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep ("Depth Gradient Deep深", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance ("Depth Maximum Distance距离", Float) = 1
        _Range ("Range", vector) = (0.13, 1.53, 0.37, 0.78)
        //边缘泡沫
        _WaveTex ("Gradient", 2D) = "white" { } //海水渐变
        _WaterSpeed ("WaterSpeed", float) = 0.74  //海水速度
        _WaveSpeed ("WaveSpeed", float) = -12.64 //海浪速度
        _WaveRange ("WaveRange", float) = 0.3
        _NoiseRange ("NoiseRange", float) = 6.43
        _WaveDelta ("WaveDelta", float) = 2.43

        _NoiseTex ("Noise海浪躁波", 2D) = "white" { }//海浪躁波
        _SurfaceNoiseCutoff ("Surface Noise Cutoff海浪躁波系数", Range(0, 1)) = 0.777
        _FoamDistance ("Foam Distance泡沫", Float) = 0.4
        [NoScaleOffset]_CubeMap ("Cubemap", CUBE) = "white" { }
        _CubemapMip ("CubemapMip", Range(0, 7)) = 0
        _Amount ("amount折射强度", float) = 100
        _FresnelPower ("Fresnel Power菲尼尔强度", Range(0.1, 50)) = 5
    }

    SubShader {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
        #define REQUIRE_DEPTH_TEXTURE //直接这样定义可以省去声明纹理的步骤(直接使用内部hlsl中的定义)

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float3 _NormalMap_ST;
        half4 _color;
        
        float1 _NormalIntensity;
        float1 _NormalScale;
        float1 _Offset;
        float1 _WaveYSpeed;
        float1 _WaveXSpeed;
        float1 _NormalRefract;

        half _WaterSpeed;
        half _WaveSpeed;
        half _WaveDelta;
        half _WaveRange;
        half _NoiseRange;
        float4 _DepthGradientShallow;
        float4 _DepthGradientDeep;
        float _DepthMaxDistance;
        float4 _Range;
        float4 _NoiseTex_ST;
        float _SurfaceNoiseCutoff;
        float _FoamDistance;
        float1 _CubemapMip;
        float _Amount;
        float4 _WaveTex_ST;
        float _FresnelPower;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_NoiseTex);
        SAMPLER(sampler_NoiseTex);
        //反射
        sampler2D _ReflectionTex;
        sampler2D _ReflectionBlockTex;
        
        TEXTURECUBE(_CubeMap);
        SAMPLER(sampler_CubeMap);
        SAMPLER(_CameraColorTexture);
        float4 _CameraColorTexture_TexelSize;//该向量是非本shader独有，不能放在常量缓冲区
        
        TEXTURE2D(_WaveTex);
        SAMPLER(sampler_WaveTex);

        struct vertexInput {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float2 uv : TEXCOORD;
        };

        struct vertexOutput {
            
            float4 positionHCS : SV_POSITION;
            float3 positionWS : TRXCOORD1;
            float3 normalWS : TRXCOORD2;
            float4 tangentWS : TANGENT;               //切线
            float2 uv : TEXCOORD0;
            float4 screenPosition : TEXCOORD3;
            float2 noiseUV : TEXCOORD4;
        };
        ENDHLSL

        pass {
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel

            vertexOutput Vertex(vertexInput v) {
                vertexOutput o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);     //计算不同空间（视图空间、世界空间、齐次裁剪空间）中的位置
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);    //计算世界空间中的法线和切线

                o.positionHCS = positionInputs.positionCS;             //裁剪空间顶点位置
                o.positionWS = positionInputs.positionWS;             //世界空间下顶点位置
                o.normalWS = normalInputs.normalWS;
                o.tangentWS = half4(normalInputs.tangentWS, v.tangentOS.w * GetOddNegativeScale());      //世界空间的切线
                
                o.screenPosition = ComputeScreenPos(o.positionHCS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);

                return o;
            }
            
            
            half4 Pixel(vertexOutput i) : SV_TARGET {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float3 worldPos = i.positionWS;
                Light mylight = GetMainLight();
                float3 lightDir = normalize(TransformObjectToWorldDir(mylight.direction));
                float3 vdirWS = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
                float3 hdir = normalize(lightDir + vdirWS); //光方向+视方向
                
                //uv偏移
                float4 offsetColor = (SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv
                + float2(_WaveXSpeed * _Time.x, 0))
                + SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, float2(i.uv.y, i.uv.x)
                + float2(_WaveYSpeed * _Time.x, 0))) / 2;
                half2 offset = UnpackNormal(offsetColor).xy * _NormalRefract; //法线偏移程度可控之后offset被用于这里
                
                //切线转世界
                half3 normalTS1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv * _NormalScale + offset));    //对法线纹理采样（切线）
                half3 normalTS2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv * _NormalScale - offset));    //对法线纹理采样（切线）
                half3 normalTS3 = normalize(normalTS1 + normalTS2);
                normalTS3.xy *= _NormalIntensity;
                normalTS3.z = sqrt(1 - saturate(dot(normalTS3.xy, normalTS3.xy)));
                half3 binormalWS = cross(i.normalWS, normalTS3.xyz) * i.tangentWS.w;                          //世界空间下的副切线
                float3 NormalWS = normalize(mul(normalTS3, half3x3(i.tangentWS.xyz, binormalWS, i.normalWS)));       //将切线空间中的法线转换到世界空间中

                //深度图
                
                float2 screenPos = i.screenPosition.xy / i.screenPosition .w;
                float depth = LinearEyeDepth(SampleSceneDepth(screenPos), _ZBufferParams);
                float depthDifference = depth - i.screenPosition.w;
                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);

                //return waterColor;
                
                //海浪泡沫
                float surfaceNoiseSample1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.noiseUV + offset).r;
                float surfaceNoiseSample2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.noiseUV - offset).r;
                float surfaceNoiseSample = surfaceNoiseSample1 + surfaceNoiseSample2;
                
                float foamDepthDifference01 = saturate(depthDifference / _FoamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;
                float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutoff * 2 ? 1 : 0;
                
                half4 haianxian = SAMPLE_TEXTURE2D(_WaveTex, sampler_WaveTex, float2(1 - min(_Range.z, depthDifference) / _Range.z + _WaveRange * sin(_Time.x * _WaveSpeed + surfaceNoiseSample.r * _NoiseRange), 1) + offset);
                haianxian.rgb *= (1 - (sin(_Time.x * _WaveSpeed + surfaceNoiseSample.r * _NoiseRange) + 1) / 2) * surfaceNoiseSample.r;
                half4 waveColor2 = SAMPLE_TEXTURE2D(_WaveTex, sampler_WaveTex, float2(1 - min(_Range.z, depthDifference) / _Range.z + _WaveRange * sin(_Time.x * _WaveSpeed + _WaveDelta + surfaceNoiseSample.r * _NoiseRange), 1) + offset);
                waveColor2.rgb *= (1 - (sin(_Time.x * _WaveSpeed + _WaveDelta + surfaceNoiseSample.r * _NoiseRange) + 1) / 2) * surfaceNoiseSample.r;
                half water_A = 1 - min(_Range.z, depthDifference) / _Range.z;
                half3 surfaceNoise1 = (haianxian.rgb + waveColor2.rgb) * water_A + surfaceNoise;
                //return half4(surfaceNoise1,1.0);
                
                //反射
                float3 vrDirWS = reflect(-vdirWS, NormalWS);       // 反射
                half3 SampleCubeMap = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, vrDirWS, _CubemapMip).rgb;// 采样Cubemap
                
                //折射
                float2 SS_texcoord = i.positionHCS.xy / _ScreenParams.xy;//获取屏幕UV
                float2 SS_bias = normalTS3.xy * _Amount * _CameraColorTexture_TexelSize;//如果取的是切线空间的法线则执行它计算偏移，但是切线空间的法线不随着模型的旋转而变换；
                half3 refract = tex2D(_CameraColorTexture, SS_texcoord + SS_bias).rgb;
                //菲尼尔
                half fresnel = pow((1 - (dot(NormalWS, vdirWS))), _FresnelPower);
                
                half3 ref = lerp(refract, SampleCubeMap, fresnel) + pow(fresnel, 100);
                half3 fcolor = (waterColor + surfaceNoise1 + ref);
                float Alpha = min(_Range.w, depth) / _Range.w; //透明度
                

                return half4(fcolor, Alpha);
            }
            ENDHLSL
        }
    }
}