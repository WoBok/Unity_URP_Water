Shader "URP Shader/Water" {
    Properties {
        _BaseMap ("Albedo", 2D) = "white" { }
        _BaseColor ("Color", Color) = (1, 1, 1, 1)

        [Header(PBR)]
        [Space(5)]
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metallic", Range(0, 1)) = 0

        [Header(Wave)]
        [Space(5)]
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
        [Space(5)]
        _TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
        _TessellationEdgeLength ("Tessellation Edge Length", Range(5, 100)) = 50
        [Toggle(_TESSELLATION_EDGE)]_TESSELLATION_EDGE ("Tessellation Edge", float) = 0

        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", Float) = 1
    }

    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }

        Pass {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
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

            #include "WaterForwardPass.hlsl"
            
            ENDHLSL
        }
    }
}