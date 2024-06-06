#ifndef LOOKING_THROUGH_WATER_INCLUDED
#define LOOKING_THROUGH_WATER_INCLUDED

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

//TEXTURE2D(_CameraDepthTexture);
//SAMPLER(sampler_CameraDepthTexture);
sampler2D _CameraDepthTexture;
//float4 _CameraDepthTexture_TexelSize;

half3 _ShallowCollor;
half3 _DeepColor;
float _DepthRange;
float _TransDepthRange;

half4 ColorBelowWater(float4 screenPos) {
    float2 uv = screenPos.xy / screenPos.w;

    //#if UNITY_UV_STARTS_AT_TOP
    //    if (_CameraDepthTexture_TexelSize.y < 0) {
    //        uv.y = 1 - uv.y;
    //    }
    //#endif

    //float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv), _ZBufferParams);

    //float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
    //float depthDifference = backgroundDepth - surfaceDepth;

    float backgroundDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, screenPos), _ZBufferParams);
    float depthDifference = backgroundDepth - screenPos.z;

    //float depth = LinearEyeDepth(SampleSceneDepth(uv), _ZBufferParams);
    //float depthDifference = depth - screenPos.w;

    half4 color;
    float depth = saturate(depthDifference / _DepthRange);
    color.rgb = lerp(_ShallowCollor, _DeepColor, depth);//min(_DepthRange, depthDifference) / _DepthRange
    color.a = saturate(depthDifference/_TransDepthRange);

    return color;
}

#endif