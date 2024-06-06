Shader "URP/URPUnlitShader" {
    Properties {
        _MainTex ("MainTex", 2D) = "White" { }
        _color ("color", Color) = (0.325, 0.807, 0.971, 0.725)
        [Normal]_NormalMap ("normalMap�����Ŷ�", 2D) = "bump" { }
        _NormalIntensity ("NormalIntensity�����Ŷ�ǿ��", Range(0, 5)) = 1
        _NormalScale ("NormalScale��������", Range(0, 5)) = 1
        _Offset ("Offsetƫ��", Range(-1, 1)) = 0
        
        _WaveXSpeed ("WaveXSpeed", Range(0, 1)) = 0.5
        _WaveYSpeed ("WaveYSpeed", Range(0, 1)) = 0.5
        _NormalRefract ("NormalRefract", Range(0, 1)) = 0.5
        
        _DepthGradientShallow ("Depth Gradient Shallowǳ", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep ("Depth Gradient Deep��", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance ("Depth Maximum Distance����", Float) = 1
        _Range ("Range", vector) = (0.13, 1.53, 0.37, 0.78)
        //��Ե��ĭ
        _WaveTex ("Gradient", 2D) = "white" { } //��ˮ����
        _WaterSpeed ("WaterSpeed", float) = 0.74  //��ˮ�ٶ�
        _WaveSpeed ("WaveSpeed", float) = -12.64 //�����ٶ�
        _WaveRange ("WaveRange", float) = 0.3
        _NoiseRange ("NoiseRange", float) = 6.43
        _WaveDelta ("WaveDelta", float) = 2.43

        _NoiseTex ("Noise�����겨", 2D) = "white" { }//�����겨
        _SurfaceNoiseCutoff ("Surface Noise Cutoff�����겨ϵ��", Range(0, 1)) = 0.777
        _FoamDistance ("Foam Distance��ĭ", Float) = 0.4
        [NoScaleOffset]_CubeMap ("Cubemap", CUBE) = "white" { }
        _CubemapMip ("CubemapMip", Range(0, 7)) = 0
        _Amount ("amount����ǿ��", float) = 100
        _FresnelPower ("Fresnel Power�����ǿ��", Range(0.1, 50)) = 5
    }

    SubShader {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
        #define REQUIRE_DEPTH_TEXTURE //ֱ�������������ʡȥ��������Ĳ���(ֱ��ʹ���ڲ�hlsl�еĶ���)

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
        //����
        sampler2D _ReflectionTex;
        sampler2D _ReflectionBlockTex;
        
        TEXTURECUBE(_CubeMap);
        SAMPLER(sampler_CubeMap);
        SAMPLER(_CameraColorTexture);
        float4 _CameraColorTexture_TexelSize;//�������ǷǱ�shader���У����ܷ��ڳ���������
        
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
            float4 tangentWS : TANGENT;               //����
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
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);     //���㲻ͬ�ռ䣨��ͼ�ռ䡢����ռ䡢��βü��ռ䣩�е�λ��
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);    //��������ռ��еķ��ߺ�����

                o.positionHCS = positionInputs.positionCS;             //�ü��ռ䶥��λ��
                o.positionWS = positionInputs.positionWS;             //����ռ��¶���λ��
                o.normalWS = normalInputs.normalWS;
                o.tangentWS = half4(normalInputs.tangentWS, v.tangentOS.w * GetOddNegativeScale());      //����ռ������
                
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
                float3 hdir = normalize(lightDir + vdirWS); //�ⷽ��+�ӷ���
                
                //uvƫ��
                float4 offsetColor = (SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv
                + float2(_WaveXSpeed * _Time.x, 0))
                + SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, float2(i.uv.y, i.uv.x)
                + float2(_WaveYSpeed * _Time.x, 0))) / 2;
                half2 offset = UnpackNormal(offsetColor).xy * _NormalRefract; //����ƫ�Ƴ̶ȿɿ�֮��offset����������
                
                //����ת����
                half3 normalTS1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv * _NormalScale + offset));    //�Է���������������ߣ�
                half3 normalTS2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv * _NormalScale - offset));    //�Է���������������ߣ�
                half3 normalTS3 = normalize(normalTS1 + normalTS2);
                normalTS3.xy *= _NormalIntensity;
                normalTS3.z = sqrt(1 - saturate(dot(normalTS3.xy, normalTS3.xy)));
                half3 binormalWS = cross(i.normalWS, normalTS3.xyz) * i.tangentWS.w;                          //����ռ��µĸ�����
                float3 NormalWS = normalize(mul(normalTS3, half3x3(i.tangentWS.xyz, binormalWS, i.normalWS)));       //�����߿ռ��еķ���ת��������ռ���

                //���ͼ
                
                float2 screenPos = i.screenPosition.xy / i.screenPosition .w;
                float depth = LinearEyeDepth(SampleSceneDepth(screenPos), _ZBufferParams);
                float depthDifference = depth - i.screenPosition.w;
                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);

                //return waterColor;
                
                //������ĭ
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
                
                //����
                float3 vrDirWS = reflect(-vdirWS, NormalWS);       // ����
                half3 SampleCubeMap = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, vrDirWS, _CubemapMip).rgb;// ����Cubemap
                
                //����
                float2 SS_texcoord = i.positionHCS.xy / _ScreenParams.xy;//��ȡ��ĻUV
                float2 SS_bias = normalTS3.xy * _Amount * _CameraColorTexture_TexelSize;//���ȡ�������߿ռ�ķ�����ִ��������ƫ�ƣ��������߿ռ�ķ��߲�����ģ�͵���ת���任��
                half3 refract = tex2D(_CameraColorTexture, SS_texcoord + SS_bias).rgb;
                //�����
                half fresnel = pow((1 - (dot(NormalWS, vdirWS))), _FresnelPower);
                
                half3 ref = lerp(refract, SampleCubeMap, fresnel) + pow(fresnel, 100);
                half3 fcolor = (waterColor + surfaceNoise1 + ref);
                float Alpha = min(_Range.w, depth) / _Range.w; //͸����
                

                return half4(fcolor, Alpha);
            }
            ENDHLSL
        }
    }
}