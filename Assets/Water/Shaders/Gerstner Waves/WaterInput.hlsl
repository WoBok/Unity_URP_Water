#ifndef WATER_INPUT_INCLUDED
#define WATER_INPUT_INCLUDED

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
    float4 screenPos : TEXCOORD4;
    float4 positionCS : SV_POSITION;
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 5);
};

sampler2D _BaseMap;
float4 _BaseMap_ST;
half4 _BaseColor;
float _Smoothness, _Metallic;

#endif