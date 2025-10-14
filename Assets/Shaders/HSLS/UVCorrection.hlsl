#ifndef UV_CORRECTION_NODE
#define UV_CORRECTION_NODE

// Aligns UVs to camera depth texel centers
half2 AlignWithGrabTexel(half2 uv, half4 cameraDepthTexelSize)
{
    // Handle flipped render targets (URP sometimes inverts Y in depth or color RTs)
    #if defined(UNITY_UV_STARTS_AT_TOP)
    if (cameraDepthTexelSize.y < 0)
    {
        uv.y = 1.0 - uv.y;
    }
    #endif

    // Align UVs to texel centers
    return (floor(uv * cameraDepthTexelSize.zw) + 0.5) * abs(cameraDepthTexelSize.xy);
}

// Computes corrected UV for refraction / distortion
void UVCorrection_FirstPass_float(
half ScreenWidth,
half ScreenHeight,
half3 DistortionVector,
half4 ScreenPos,

out half2 UV_Initial
)
{
    // Compute camera depth texel size
    half4 cameraDepthTexelSize = half4(1 / ScreenWidth, 1 / ScreenHeight, ScreenWidth, ScreenHeight);

    // Copy and scale distortion vector
    half3 distortionVector = DistortionVector;
    distortionVector.y *= cameraDepthTexelSize.z * abs(cameraDepthTexelSize.y);

    // 1st Pass : initial distortion & artifact correction
    UV_Initial = AlignWithGrabTexel((ScreenPos.xy + distortionVector.xy) / ScreenPos.w, cameraDepthTexelSize);
}

void UVCorrection_SecondPass_float(
half2 UV_Initial, // from first pass
half SurfaceDepth, // from Scene Depth node (sampled at current pixel)
half BackgroundDepth, // from Scene Depth node (sampled at UV_Initial)
half3 DistortionVector,
half4 ScreenPos,
half ScreenWidth,
half ScreenHeight,

out half2 CorrectedUV
)
{
    // Compute camera depth texel size
    half4 cameraDepthTexelSize = half4(1 / ScreenWidth, 1 / ScreenHeight, ScreenWidth, ScreenHeight);

    // Calculate difference between background depth and object depth
    half depthDifference = BackgroundDepth - SurfaceDepth;

    // Fade distortion near intersections
    half distortionFade = saturate(depthDifference * 100.0);

    half3 correctedDistortion = DistortionVector * distortionFade;

    // Final corrected UV
    half2 uvFinal = AlignWithGrabTexel((ScreenPos.xy + correctedDistortion.xy) / ScreenPos.w, cameraDepthTexelSize);

    CorrectedUV = uvFinal;
}

#endif
