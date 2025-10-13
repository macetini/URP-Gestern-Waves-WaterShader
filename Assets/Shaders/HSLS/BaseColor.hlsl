// GesternWave.hlsl - Calculates the 3D position offset (displacement) for a single wave.
#ifndef BASE_COLOR_NODE
#define BASE_COLOR_NODE

void BaseColor_float(
UnityTexture2D SurfaceTexture,
half ViewDotNormal,
half2 UV_Base,
float3 ReflectionColor,

out float3 BlendedColor
)
{
    half3 surfaceColor = tex2D(SurfaceTexture, UV_Base).rgb;

    half reflectionFactor = pow(1.0 - saturate(ViewDotNormal), 5.0); // Standard Fresnel
    half3 blendedColor = lerp(surfaceColor, ReflectionColor, reflectionFactor);

    BlendedColor = blendedColor;
}

#endif