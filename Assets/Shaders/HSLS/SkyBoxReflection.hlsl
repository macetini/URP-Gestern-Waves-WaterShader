// CalculateReflection.hlsl - Calculates blended skybox reflection using Fresnel.
#ifndef CALCULATE_SKYBOX_REFLECTION_NODE
#define CALCULATE_SKYBOX_REFLECTION_NODE

void SkyBoxReflection_float(
float3 SurfaceColor,
half ViewDotNormal,
float3 ReflectionVector,
half ReflectionIntensity,

out half3 ReflectedColor
)
{
    half4 skyData = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, ReflectionVector, 0);

    // Decode HDR Data (Manual Implementation)
    // We manually decode the HDR data, which is mathematically the equivalent of DecodeHDR
    // for standard reflection probes : sampled RGB multiplied by the HDR multiplier (.x component).
    half3 skyColor = (skyData.rgb * unity_SpecCube0_HDR.x) * ReflectionIntensity;

    // 3. Calculate Fresnel Factor
    // Schlick's approximation : pow(1 - V.N, 5.0)
    half reflectionFactor = pow(1.0 - saturate(ViewDotNormal), 5.0);

    // Boost base reflection (as per original file's logic)
    // This pushes the minimum reflection factor higher, useful for materials like water.
    reflectionFactor = saturate(reflectionFactor + 0.5);

    // 4. Blend Colors (Lerp)
    // Blends SurfaceColor (0 %) and skyColor (100 %) based on the reflectionFactor.
    half3 finalColor = lerp((half3)SurfaceColor, skyColor, reflectionFactor);

    // 5. Assign to Output and SATURATE (Clamp to 0 - 1)
    // This is the safety step that prevents the final color from blowing out past white.
    ReflectedColor = saturate(finalColor);
}

#endif