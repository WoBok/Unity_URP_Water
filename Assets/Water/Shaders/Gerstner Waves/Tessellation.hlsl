#if !defined(TESSELLATION_INCLUDED)
#define TESSELLATION_INCLUDED

float _TessellationUniform;
float _TessellationEdgeLength;

struct TessellationControlPoint {
    float4 positionOS : INTERNALTESSPOS;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
};

struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

TessellationControlPoint TessellationVertexProgram(Attributes v) {
    TessellationControlPoint p;
    p.positionOS = v.positionOS;
    p.normalOS = v.normalOS;
    p.texcoord = v.texcoord;
    return p;
}

float TessellationEdgeFactor(float3 p0, float3 p1) {
    #if defined(_TESSELLATION_EDGE_ON)
        float edgeLength = distance(p0, p1);

        float3 edgeCenter = (p0 + p1) * 0.5;
        float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

        return edgeLength * _ScreenParams.y /
        (_TessellationEdgeLength * viewDistance);
    #else
        return _TessellationUniform;
    #endif
}

TessellationFactors  PatchConstantFunction(
    InputPatch < TessellationControlPoint, 3 > patch
) {
    float3 p0 = mul(unity_ObjectToWorld, patch[0].positionOS).xyz;
    float3 p1 = mul(unity_ObjectToWorld, patch[1].positionOS).xyz;
    float3 p2 = mul(unity_ObjectToWorld, patch[2].positionOS).xyz;
    TessellationFactors f;
    f.edge[0] = TessellationEdgeFactor(p1, p2);
    f.edge[1] = TessellationEdgeFactor(p2, p0);
    f.edge[2] = TessellationEdgeFactor(p0, p1);
    f.inside =
    (TessellationEdgeFactor(p1, p2) +
    TessellationEdgeFactor(p2, p0) +
    TessellationEdgeFactor(p0, p1)) * (1 / 3.0);
    return f;
}

[domain("tri")]
[outputcontrolpoints(3)]
[outputtopology("triangle_cw")]
[partitioning("fractional_odd")]
[patchconstantfunc("PatchConstantFunction")]
TessellationControlPoint HullProgram(
    InputPatch < TessellationControlPoint, 3 > patch,
    uint id : SV_OutputControlPointID
) {
    return patch[id];
}

[domain("tri")]
Varyings  DomainProgram(
    TessellationFactors factors,
    OutputPatch < TessellationControlPoint, 3 > patch,
    float3 barycentricCoordinates : SV_DomainLocation
) {
    Attributes data;

    #define  DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
    patch[0].fieldName * barycentricCoordinates.x + \
    patch[1].fieldName * barycentricCoordinates.y + \
    patch[2].fieldName * barycentricCoordinates.z;

    DOMAIN_PROGRAM_INTERPOLATE(positionOS)
    DOMAIN_PROGRAM_INTERPOLATE(normalOS)
    DOMAIN_PROGRAM_INTERPOLATE(texcoord)

    return Vertex(data);
}
#endif