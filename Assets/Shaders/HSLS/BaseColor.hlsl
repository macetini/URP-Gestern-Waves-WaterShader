#ifndef BASE_COLOR_NODE
#define BASE_COLOR_NODE

void BaseColor_float(
half ViewDotNormal,
float3 ReflectionColor,
half3 SurfaceColor,

out float3 BlendedSurfaceColor
)
{
    half reflectionFactor = pow(1.0 - saturate(ViewDotNormal), 5.0); // Standard Fresnel
    half3 blendedColor = lerp(SurfaceColor, ReflectionColor, reflectionFactor);

    BlendedSurfaceColor = blendedColor;
}

#endif