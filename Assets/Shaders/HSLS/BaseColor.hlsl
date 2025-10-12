// GesternWave.hlsl - Calculates the 3D position offset (displacement) for a single wave.
#ifndef BASE_COLOR_NODE
#define BASE_COLOR_NODE

void BaseColor_float(
float3 SurfaceColor,
float3 ReflectionColor,

half ViewDotNormal,

out float3 BlendedColor
)
{
    half reflectionFactor = pow(1.0 - saturate(ViewDotNormal), 5.0); // Standard Fresnel
    half3 blendedColor = lerp(SurfaceColor, ReflectionColor, reflectionFactor);

    BlendedColor = blendedColor;
}

#endif