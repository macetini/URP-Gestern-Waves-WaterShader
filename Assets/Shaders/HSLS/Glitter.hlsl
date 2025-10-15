#ifndef GLITTER_NODE
#define GLITTER_NODE

void Glitter_float(
half GlitterMask, // Glitter Mask Texture Sample (R Channel)

half3 ViewDotNormal, // Dot product of View Dir and Normal
half3 ReflectionVector, // Reflection Vector (calculated outside the function)
half3 LightDir, // Main Light Direction

half GlitterSharpness,
half GlitterIntensity,

// OUTPUT for Shader Graph
out half3 GlitterAdditiveColor // The final glitter color to add to the base color
)
{
    // Get the main light data struct from URP's library
    // This is defined in URP's Lighting.hlsl
    #ifdef SHADERGRAPH_PREVIEW
    // Fallback for preview
    half3 lightColor = half3(1.0, 1.0, 1.0);
    #else
    // Get the light color and intensity from URP
    Light mainLight = GetMainLight();
    half3 lightColor = mainLight.color;
    #endif

    // Calculate the alignment with the light direction using the reflection vector
    half lightDotRefl = max(0, dot(LightDir, ReflectionVector));

    // Calculate the base glint factor (sharp specular highlight)
    half sunGlitterFactor = pow(lightDotRefl, GlitterSharpness);    

    // Add a subtle mask for breakup (flicker)
    sunGlitterFactor *= (GlitterMask * 0.5 + 0.5);

    // Calculate the Fresnel factor for view - angle scattering
    half fresnelFactor = pow(1.0 - ViewDotNormal, 5.0);

    // Apply Fresnel, Intensity, and the Light Color
    half finalGlitterFactor = sunGlitterFactor * fresnelFactor * GlitterIntensity;

    // Output the final glitter color
    GlitterAdditiveColor = finalGlitterFactor * lightColor;
}

#endif