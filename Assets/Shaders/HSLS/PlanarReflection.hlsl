#ifndef PLANAR_REFLECTION_NODE
#define PLANAR_REFLECTION_NODE

void PlanarReflection_float(
half3 FinalNormal, // Fragment's surface normal
half3 WorldPos, // Fragment's position in world space
half3 ViewDir, // View direction vector (for Fresnel)

float2 DistortionVector, // UVs for sampling the Distortion Texture (e.g., tiling / scrolling noise UVs)

out half3 ReflectedColor // Calculated Reflected Color (to be added / Lerped with Albedo)
)
{
    // -- - 1. Calculate Reflection Texture UVs -- -

    // Transform World Position to homogeneous clip space using the projection matrix
    float4 reflectionUV_Homogeneous = mul(_WorldToReflection, float4(WorldPos, 1.0));

    // Perform Perspective Division : xy / w to get normalized screen coordinates (UVs)
    float2 reflectionUV = reflectionUV_Homogeneous.xy / reflectionUV_Homogeneous.w + DistortionVector;

    // -- - 2. Sample the Reflection Texture -- -
    // Sample the texture using the calculated UVs.
    // Use the SAMPLER defined by the Shader Graph 'Sample Texture 2D' node.
    half3 reflectionSample = SAMPLE_TEXTURE2D(_PlanarReflectionTex, sampler_PlanarReflectionTex, reflectionUV).rgb;

    // -- - 3. Calculate Fresnel Factor -- -
    // Fresnel makes the reflection strongest at grazing angles (where ViewDir is nearly perpendicular to Normal).

    // Ensure both vectors are normalized (WorldPos and ViewDir should be, but it's safe to check)
    half3 normalizedNormal = normalize(FinalNormal);
    half3 normalizedViewDir = normalize(ViewDir);

    // Calculate the cosine of the angle between ViewDir and Normal (dot product)
    // The result is 1 when looking straight down, and 0 when looking at a grazing angle.
    half NdotV = saturate(dot(normalizedNormal, normalizedViewDir));

    // The standard Fresnel calculation : (1 - NdotV) ^ power
    // The 'power' (e.g., 5.0) controls the falloff; a higher power makes the reflection tighter to the edge.
    half fresnelFactor = pow(1.0 - NdotV, 5.0);

    // -- - 4. Final Color Calculation -- -
    // Multiply the sampled reflection color by the calculated Fresnel factor.
    // This creates the final reflected color that fades out towards the center of the surface.
    ReflectedColor = reflectionSample * fresnelFactor;

    // Note : The 'SampledColor' input parameter was ignored, as the sampling is performed inside
    // the HLSL to use the dynamic _WorldToReflection matrix.
}

#endif