#ifndef SUBSURFACE_SCATTERING_NODE
#define SUBSURFACE_SCATTERING_NODE

void SubsurfaceScattering_float(
half3 FinalNormal, // setupVectors.finalNormal (World space, potentially distorted)
half3 LightDir, // setupVectors.lightDir (World space, from Main Light)

// Shader Properties passed as Inputs
half3 SSColor, // Subsurface Scattering RGB Color
half SSDiffusion, // Subsurface Scattering Diffusion
half SSPower, // Subsurface Scattering Power
half SSScale, // Subsurface Scattering Scale

out half3 SubsurfaceScatterColor // Calculated Subsurface Scattering color to add
)
{
    // Calculate NdotL using the final distorted normal
    float NdotL = dot(FinalNormal, LightDir);

    // 1. Calculate the 'Transmission' lobe
    // The saturate() function clamps the result to [0, 1] before powering.
    float SSS_Lobe = pow(saturate(- NdotL + SSDiffusion), SSPower);

    // 2. Apply SSS properties
    SubsurfaceScatterColor = SSS_Lobe * SSColor * SSScale;
}

#endif