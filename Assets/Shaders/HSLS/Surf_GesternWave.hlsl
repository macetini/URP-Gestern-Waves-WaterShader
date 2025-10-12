// GesternWave.hlsl - Calculates the 3D position offset (displacement) for a single wave.
#ifndef SURF_GESTERN_WAVE_CALCULATION
#define SURF_GESTERN_WAVE_CALCULATION

// TODO - Put in Include Later on

// Define PI constant (Better safe than sorry)
#ifndef PI
#define PI 3.14159265359
#endif

// Define G (Gravity) constant
#ifndef G
#define G 9.81
#endif

half3 CalculateWorldSpaceViewDir(half3 WorldPos)
{
    // View Direction (V) = normalize(Camera Position - Fragment Position)
    return normalize(_WorldSpaceCameraPos.xyz - WorldPos);
}
//

struct SurfaceDataVectors
{
    // Set Up
    float4 screenPos;
    float3 worldPos;

    half4 normalMapCoords;
    half4 duDvMapCoords;

    half3x3 tangentSpaceMatrix;

    // Calculated

    half3 combinedTangentNormal; // Combined tangent space normal for lighting

    half3 combinedDuDvNormal;
    half3 distortionVector;

    half3 worldNormal;
    half3 worldViewDir;
    half3 lightDir;

    half3 finalNormal;
    half3 reflectionVector;
    half viewDotNormal;
};

half3 CalculateDistortionNormal
(
UnityTexture2D duDvMap1,
UnityTexture2D duDvMap2,

half4 duDvMapCoords,

half3x3 tangentSpaceMatrix
) {
    half3 duDvMap1s = UnpackNormal(tex2D(duDvMap1, duDvMapCoords.xy));
    half3 duDvMap2s = UnpackNormal(tex2D(duDvMap2, duDvMapCoords.zw));

    half3 duDVMapSum = duDvMap1s + duDvMap2s;

    // Transform the combined tangent space DuDv map into a world space direction vector
    half3 combinedDuDvNormal = normalize(mul(tangentSpaceMatrix, duDVMapSum));

    return combinedDuDvNormal;
}

SurfaceDataVectors CalculateSetupVectors(
half time,

half3 worldPos,
half4 screenPos,
half2 uvBase,

UnityTexture2D normalMap1,
UnityTexture2D duDvMap1,
half2 normalMap1speed,

UnityTexture2D normalMap2,
UnityTexture2D duDvMap2,
half2 normalMap2speed,

half3 mainLightDirection,

half distortionFactor
) {
    // Return struct
    SurfaceDataVectors setupVectors;
    //

    // SET UP MAIN VECTORS
    setupVectors.worldPos = worldPos;
    setupVectors.screenPos = screenPos;
    //


    // -- SAMPLE TEXTURES START --
    // UVs for the actual lighting normal maps
    // We use a slightly faster scroll speed or a different tiling factor (0.5 here)
    // to make the two sets of maps look slightly different
    setupVectors.normalMapCoords.xy = uvBase.xy + normalMap1speed.xy * time * 0.5;
    setupVectors.normalMapCoords.zw = uvBase.xy + normalMap2speed.xy * time * 0.5;

    // Calculate the final, combined TANGENT SPACE normal vector for the surface lighting
    half3 normalMap1s = UnpackNormal(tex2D(normalMap1, setupVectors.normalMapCoords.xy));
    half3 normalMap2s = UnpackNormal(tex2D(normalMap2, setupVectors.normalMapCoords.zw));
    // Combine both normal maps in tangent space
    setupVectors.combinedTangentNormal = normalMap1s + normalMap2s;
    //

    // UVs for DuDv distortion maps
    setupVectors.duDvMapCoords.xy = uvBase.xy + normalMap1speed.xy * time;
    setupVectors.duDvMapCoords.zw = uvBase.xy + normalMap2speed.xy * time;

    // Distortion Calculation (Uses DuDv maps and is used for refraction)
    setupVectors.combinedDuDvNormal = CalculateDistortionNormal(
    duDvMap1, duDvMap2, setupVectors.duDvMapCoords, setupVectors.tangentSpaceMatrix);

    setupVectors.distortionVector = setupVectors.combinedDuDvNormal * distortionFactor;
    //
    // -- SAMPLE TEXTURES END --


    // -- CALCULATE TBN BASIS VECTORS START (Based on Gerstner Waves) --
    // ddx / ddy calculate the vector change in X and Y screen space directions (local derivatives)
    half3 worldTangent = normalize(ddx(worldPos));
    half3 worldBinormal = normalize(ddy(worldPos));
    half3 geometricWorldNormal = normalize(cross(worldTangent, worldBinormal)); // Gerstner Wave Normal
    setupVectors.worldNormal = geometricWorldNormal;

    // Re - orthogonalize T and B relative to the correct geometric normal
    worldBinormal = normalize(cross(geometricWorldNormal, worldTangent));
    worldTangent = normalize(cross(worldBinormal, geometricWorldNormal));

    // Build the TBN matrix for applying normal map details
    setupVectors.tangentSpaceMatrix = half3x3(worldTangent, worldBinormal, geometricWorldNormal);
    // -- CALCULATE TBN BASIS VECTORS END --


    // The Final Distorted World Normal (Used for ALL lighting / reflection)
    // Transform the combined tangent space normal to world space
    half3 worldSpaceCombinedNormal = normalize(mul(setupVectors.tangentSpaceMatrix, setupVectors.combinedTangentNormal));
    // Blend the base Gerstner normal (worldNormal) with the high - frequency normal map detail (worldSpaceCombinedNormal),
    // weighted by _GlintChoppiness (which acts as a normal strength factor)
    setupVectors.finalNormal = normalize(setupVectors.worldNormal + (worldSpaceCombinedNormal)); // * _GlintChoppiness)); TODO - Dont forget to implement
    //

    // CALCULATE LIGHTING DATA
    //setupVectors.worldViewDir = normalize(UnityWorldSpaceViewDir(input.worldPos));
    setupVectors.worldViewDir = normalize(CalculateWorldSpaceViewDir(worldPos));
    setupVectors.lightDir = mainLightDirection; //normalize(_MainLightPosition.xyz); // TODO - Make sure switch to node works !
    // The Shared Reflection Vector (Calculated once)
    setupVectors.reflectionVector = reflect(- setupVectors.worldViewDir, setupVectors.finalNormal);
    setupVectors.viewDotNormal = dot(setupVectors.worldViewDir, setupVectors.finalNormal);
    //

    return setupVectors;
}

void Surf_GerstnerWave_float(
half Time,

half3 WorldPos, // World Position - Will be transformed to OBJECT SPACE with Transform Node
half4 ScreenPos,
half2 UV_Base,

UnityTexture2D NormalMap1,
UnityTexture2D DuDvMap1,
half2 NormalMap_1_ScrollSpeed,

UnityTexture2D NormalMap2,
UnityTexture2D DuDvMap2,
half2 NormalMap_2_ScrollSpeed,
half DistortionFactor,

half3 MainLightDirection,

out half3 Out
) {
    SurfaceDataVectors v = CalculateSetupVectors (
    Time,

    WorldPos,
    ScreenPos,
    UV_Base,

    NormalMap1,
    DuDvMap1,
    NormalMap_1_ScrollSpeed,

    NormalMap2,
    DuDvMap2,
    NormalMap_1_ScrollSpeed,
    DistortionFactor,

    MainLightDirection
    );

    Out = v.worldPos;
}

#endif