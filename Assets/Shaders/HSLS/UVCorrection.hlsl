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

out half2 UV_Initial,
out half4 CameraDepthTexelSize
)
{
    // Compute camera depth texel size
    half4 cameraDepthTexelSize = half4(1 / ScreenWidth, 1 / ScreenHeight, ScreenWidth, ScreenHeight);
    CameraDepthTexelSize = cameraDepthTexelSize; // Output for second pass

    // Copy and scale distortion vector
    half3 distortionVector = DistortionVector;
    distortionVector.y *= cameraDepthTexelSize.z * abs(cameraDepthTexelSize.y);

    // 1st Pass : initial distortion & artifact correction
    UV_Initial = AlignWithGrabTexel((ScreenPos.xy + distortionVector.xy) / ScreenPos.w, cameraDepthTexelSize);
}

void UVCorrection_SecondPass_float(
half2 UV_Initial, // From first pass
half4 CameraDepthTexelSize, // From first pass

half3 DistortionVector,
half4 ScreenPos,

half SurfaceDepth,
half BackgroundDepth, // from Scene Depth node (sampled at UV_Initial)

out half2 CorrectedUV
)
{
    // Calculate difference between background depth and object depth
    half depthDifference = BackgroundDepth - SurfaceDepth;

    // Fade distortion near intersections
    half distortionFade = saturate(depthDifference * 100.0);

    half3 correctedDistortion = DistortionVector * distortionFade;

    // Final corrected UV
    CorrectedUV = AlignWithGrabTexel((ScreenPos.xy + correctedDistortion.xy) / ScreenPos.w, CameraDepthTexelSize);
}

#endif
