#ifndef DEPTH_ABSORPTION_AND_BLENDING_NODE
#define DEPTH_ABSORPTION_AND_BLENDING_NODE

// Computes corrected UV for refraction / distortion
void DepthAbsorptionAndBlending_float(
half3 WaterFragment, // The base water color (Reflection + SSS + Glitter)
half2 CorrectedUV, // From UVCorrection Node (Second Pass)

half FinalDepthDifference,
half3 UnderwaterColor, // _CameraOpaqueTexture sampled at CorrectedUV

half3 WaterAbsorptionColor,
half WaterAbsorptionRate,

out half3 FinalColor
)
{
    float absorptionRate = max(0.001, _WaterAbsorptionRate);
    float extinction = exp(- FinalDepthDifference * absorptionRate); // Exponential decay (1 = clear, 0 = opaque)
    half3 absorbedColor = lerp(WaterAbsorptionColor, UnderwaterColor, extinction);

    FinalColor = lerp(absorbedColor, WaterFragment, 1.0 - extinction);
}

#endif
