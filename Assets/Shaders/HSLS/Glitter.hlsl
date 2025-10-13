#ifndef GLITTER_FUNCTION
#define GLITTER_FUNCTION

void Glitter_float(
// Inputs from Gestern Wave Node
half3 ReflectionVector, // Reflection Vector (calculated outside the function)
half3 ViewDotNormal, // Dot product of View Dir and Normal
half2 GlintMaskUV, // UV coordinates for texture sampling
half3 LightDir, // Main Light Direction

// Shader Properties passed as Inputs
UnityTexture2D GlintMaskTexture,

half GlitterSharpness,
half GlintMaskTiling,
half GlitterIntensity,

// OUTPUT for Shader Graph
out half3 GlitterAdditiveColor // The final glitter color to add to the base color
)
{
    // -- - URP Light Data Access -- -
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

    // Texture Sampling : Use the Texture2D input and SamplerState to sample the mask
    //half textureMask = tex2D(GlintMask, GlintMaskUV * GlintMaskTiling).r; //GlintMask.Sample(Sampler_GlintMask, GlintMaskUV * GlintMaskTiling).r;
    half textureMask = tex2D(GlintMaskTexture, GlintMaskUV * GlintMaskTiling).r;

    // Add a subtle mask for breakup (flicker)
    sunGlitterFactor *= (textureMask * 0.5 + 0.5);

    // Calculate the Fresnel factor for view - angle scattering
    half fresnelFactor = pow(1.0 - ViewDotNormal, 5.0);

    // Apply Fresnel, Intensity, and the Light Color
    half finalGlitterFactor = sunGlitterFactor * fresnelFactor * GlitterIntensity;

    // Output the final glitter color
    GlitterAdditiveColor = finalGlitterFactor * lightColor;
}

#endif