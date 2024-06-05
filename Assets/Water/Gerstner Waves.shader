Shader "URP Shader/Gerstner Waves" {
    Properties {
        _BaseMap ("Albedo", 2D) = "white" { }
        _BaseColor ("Color", Color) = (1, 1, 1, 1)

        [Header(PBR)]
        [Space(5)]
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0

        [Header(Water)]
        _WaveSpeed ("Wave Speed", Float) = 1
        _Wave1 ("Wave 1 Wavelength, Steepness, Direction", Vector) = (10, 0.5, 1, 0)
        _Wave2 ("Wave 2 Wavelength, Steepness, Direction", Vector) = (20, 0.25, 0, 1)
        _Wave3 ("Wave 3 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave4 ("Wave 4 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave5 ("Wave 5 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave6 ("Wave 6 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave7 ("Wave 7 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave8 ("Wave 8 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave9 ("Wave 9 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave10 ("Wave 10 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave11 ("Wave 11 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)
        _Wave12 ("Wave 12 Wavelength, Steepness, Direction", Vector) = (10, 0.15, 1, 1)

        [Header(Tessellation)]
        _TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
        _TessellationEdgeLength ("Tessellation Edge Length", Range(5, 100)) = 50
        [Toggle(_TESSELLATION_EDGE)]_TESSELLATION_EDGE ("Tessellation Edge", float) = 0

        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", Float) = 1
    }

    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass {
            //Blend SrcAlpha OneMinusSrcAlpha
            Cull[_Cull]

            HLSLPROGRAM

            #pragma vertex  TessellationVertexProgram
            #pragma fragment Fragment
            #pragma hull  HullProgram
            #pragma domain  DomainProgram
            #pragma shader_feature _TESSELLATION_EDGE

            #pragma multi_compile  _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile  _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texcoord : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
            };

            struct Varyings {
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float3 viewDirectionWS : TEXCOORD3;
                float4 positionCS : SV_POSITION;
                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 4);
            };
            
            sampler2D _BaseMap;
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;

            float _Smoothness, _Metallic;

            float _WaveSpeed;
            float4 _Wave1, _Wave2, _Wave3, _Wave4, _Wave5, _Wave6, _Wave7, _Wave8, _Wave9, _Wave10, _Wave11, _Wave12;
            CBUFFER_END

            float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal) {
                float period = 2 * PI;
                float k = period / wave.x;
                float c = sqrt(9.8 / k) * _WaveSpeed;
                //float f = k * input.positionOS.x - c * _Time.y * period;//每秒移动一个周期(_Wavelenght)的距离
                float2 d = normalize(wave.zw);
                float f = k * (dot(d, p.xz) - c * _Time.y);//每秒波峰移动1/_Wavelenght的距离，_Wavelenght秒移动_Wavelenght的距离

                tangent += float3(
                    - d.x * d.x * wave.y * sin(f),
                    d.x * wave.y * cos(f),
                    - d.x * d.y * wave.y * sin(f)
                );

                binormal += float3(
                    - d.x * d.y * wave.y * sin(f),
                    d.y * wave.y * cos(f),
                    - d.y * d.y * wave.y * sin(f)
                );

                float a = wave.y / k;

                return float3(
                    d.x * a * cos(f), //每个顶点的偏移量（间距增加）由大变小后变大，循环往复
                    a * sin(f),
                    d.y * a * cos(f)
                );
            }

            Varyings Vertex(Attributes input) {
                Varyings output;
                
                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);
                float3 p = input.positionOS.xyz;

                input.positionOS.xyz += GerstnerWave(_Wave1, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave2, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave3, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave4, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave5, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave6, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave7, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave8, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave9, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave10, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave11, p, tangent, binormal);
                input.positionOS.xyz += GerstnerWave(_Wave12, p, tangent, binormal);

                float3 normal = normalize(cross(binormal, tangent));

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(normal);
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionWS = positionWS;
                output.viewDirectionWS = normalize(_WorldSpaceCameraPos - positionWS);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                return output;
            }

            void InitializeInputData(Varyings input, out InputData inputData) {
                inputData = (InputData)0;
                inputData.normalWS = normalize(input.normalWS);
                inputData.viewDirectionWS = input.viewDirectionWS;
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, input.normalWS);
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
            }

            void InitializeSurfaceData(float2 uv, out SurfaceData surfaceData) {
                surfaceData = (SurfaceData)0;
                half4 albedo = tex2D(_BaseMap, uv);
                surfaceData.albedo = albedo.rgb * _BaseColor.rgb;
                surfaceData.metallic = _Metallic;
                surfaceData.smoothness = _Smoothness;
                surfaceData.occlusion = 1;
                surfaceData.alpha = albedo.a * _BaseColor.a;
            }

            #include "Tessellation.hlsl"

            half4 Fragment(Varyings input) : SV_Target {
                InputData inputData;
                InitializeInputData(input, inputData);

                SurfaceData surfaceData;
                InitializeSurfaceData(input.uv, surfaceData);

                return UniversalFragmentPBR(inputData, surfaceData);
            }
            ENDHLSL
        }
    }
}