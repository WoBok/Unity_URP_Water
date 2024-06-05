#ifndef  GERSTNERWAVE_INCLUDED
#define GERSTNERWAVE_INCLUDED

float _WaveSpeed;
float4 _Wave1, _Wave2, _Wave3, _Wave4, _Wave5, _Wave6, _Wave7, _Wave8, _Wave9, _Wave10, _Wave11, _Wave12;

float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal) {//将位置和法线计算分开
    float period = 2 * PI;
    float k = period / wave.x;
    float c = sqrt(9.8 / k) * _WaveSpeed;
    float2 d = normalize(wave.zw);
    float f = k * (dot(d, p.xz) - c * _Time.y);

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
        d.x * a * cos(f),
        a * sin(f),
        d.y * a * cos(f)
    );
}

#define GERSTNER_WAVE(wave) input.positionOS.xyz += GerstnerWave(wave, position, tangent, binormal);

#endif