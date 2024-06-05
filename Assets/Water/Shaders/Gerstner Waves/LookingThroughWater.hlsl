#ifndef LOOKING_THROUGH_WATER_INCLUDED
#define LOOKING_THROUGH_WATER_INCLUDED

TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
float4 _CameraDepthTexture_TexelSize;

float3 ColorBelowWater(float4 screenPos) {
    float2 uv = screenPos.xy / screenPos.w;

    #if UNITY_UV_STARTS_AT_TOP
        if (_CameraDepthTexture_TexelSize.y < 0) {
            uv.y = 1 - uv.y;
        }
    #endif

    float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv), _ZBufferParams);
    float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
    float depthDifference = backgroundDepth - surfaceDepth;
    return depthDifference / 20;
}

#endif