#ifndef FOAM_NODE
#define FOAM_NODE

void Foam_float(
half3 BlendedColor,
half2 FinalUV, // From UVCorrection Node (Second Pass)
half FinalDepthDifference, // From DepthAbsorptionAndBlending Node (Second Pass)

half FoamTexMask,

half3 FoamColor,
half FoamTiling,
half FoamMaxDistance,
half FoamSharpness,

out half3 ColorWithFoam
)
{
    // Calculate Foam Factor based on distance to background
    // Foam factor is high (near 1) when finalDepthDifference is small.
    // FoamMaxDistance controls the width of the foam band.
    half foamFactor = 1.0 - saturate(FinalDepthDifference / FoamMaxDistance);

    // Sharpen the edge and apply texture mask
    foamFactor = pow(foamFactor, FoamSharpness);
    foamFactor *= FoamTexMask;

    ColorWithFoam = lerp(BlendedColor, FoamColor, foamFactor);
}

#endif