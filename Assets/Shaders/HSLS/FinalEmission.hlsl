#ifndef FINAL_EMISSION_NODE
#define FINAL_EMISSION_NODE

half3 DepthAbsorptionAndBlending(
half3 WaterFragment,
float FinalDepthDifference,
half3 SceneColorAtUV, // Scene Color Node sampled at CorrectedUV
half3 WaterAbsorptionColor,
float WaterAbsorptionRate
)
{
    float extinction = exp(- FinalDepthDifference * max(0.001, WaterAbsorptionRate)); // Exponential decay
    half3 absorbedColor = lerp(WaterAbsorptionColor, SceneColorAtUV, extinction);
    half3 finalColor = lerp(absorbedColor, WaterFragment, 1.0 - extinction);
    return finalColor;
}
// Computes corrected UV for refraction / distortion
void FinalEmission_float(
half2 CorrectedUV, // From UVCorrection Node (Second Pass)
float SurfaceDepth, // Scene Depth Node at current fragment (surface)
float BackgroundDepth, // Scene Depth Node sampled at CorrectedUV
half3 WaterFragment, // The base water color (Reflection + SSS + Glitter)

half3 SceneColorAtUV, // Scene Color Node sampled at CorrectedUV


half3 WaterAbsorptionColor,
half WaterAbsorptionRate,

out half3 FinalEmissionColor
)
{
    float finalDepthDifference = BackgroundDepth - SurfaceDepth; // True distance to background

    FinalEmissionColor =
    DepthAbsorptionAndBlending(
    WaterFragment,
    finalDepthDifference,
    SceneColorAtUV,
    WaterAbsorptionColor,
    WaterAbsorptionRate
    );
}

#endif
