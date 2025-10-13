#ifndef BASE_COLOR_NODE
#define BASE_COLOR_NODE

void BaseColor_float(
UnityTexture2D SurfaceTexture,
half3 SurfaceColor,
half ViewDotNormal,
half2 UV_Base,
float3 ReflectionColor,

out float3 BlendedColor
)
{
    half3 surfaceColor = saturate(SAMPLE_TEXTURE2D(SurfaceTexture, SurfaceTexture.samplerstate, UV_Base).rgb + SurfaceColor);
    //half3 surfaceColor = SurfaceColor;

    half reflectionFactor = pow(1.0 - saturate(ViewDotNormal), 5.0); // Standard Fresnel
    half3 blendedColor = lerp(surfaceColor, ReflectionColor, reflectionFactor);

    BlendedColor = blendedColor;
}

#endif