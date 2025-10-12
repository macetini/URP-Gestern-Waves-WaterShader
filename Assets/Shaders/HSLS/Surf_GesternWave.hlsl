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

struct SurfaceDataVectors
{
    float4 screenPos;
    float3 worldPos;
    half2 uvBase;

    half4 normalMapCoords;
    half4 duDvMapCoords;

    half3x3 tangentSpaceMatrix;

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

SurfaceDataVectors InitDataVectors(SurfaceDataVectors dataVectors, half3 worldPos, half4 screenPos, half2 uvBase)
{
    dataVectors.worldPos = worldPos;
    dataVectors.screenPos = screenPos;
    dataVectors.uvBase = uvBase;

    return dataVectors;
}

half3 CalculateDistortionNormal(UnityTexture2D duDvMap1, UnityTexture2D duDvMap2, half4 duDvMapCoords, half3x3 tangentSpaceMatrix)
{
    half3 duDvMap1s = UnpackNormal(tex2D(duDvMap1, duDvMapCoords.xy));
    half3 duDvMap2s = UnpackNormal(tex2D(duDvMap2, duDvMapCoords.zw));

    half3 duDVMapSum = duDvMap1s + duDvMap2s;

    // Transform the combined tangent space DuDv map into a world space direction vector
    half3 combinedDuDvNormal = normalize(mul(tangentSpaceMatrix, duDVMapSum));
    return combinedDuDvNormal;
}

SurfaceDataVectors SampleMaps(half time, SurfaceDataVectors dataVectors, UnityTexture2D normalMap1, UnityTexture2D duDvMap1, half2 normalMap1speed, UnityTexture2D normalMap2, UnityTexture2D duDvMap2, half2 normalMap2speed, half distortionFactor)
{
    // UVs for the actual lighting normal maps
    // We use a slightly faster scroll speed or a different tiling factor (0.5 here)
    // to make the two sets of maps look slightly different
    dataVectors.normalMapCoords.xy = dataVectors.uvBase.xy + normalMap1speed.xy * time * 0.5;
    dataVectors.normalMapCoords.zw = dataVectors.uvBase.xy + normalMap2speed.xy * time * 0.5;

    // Calculate the final, combined TANGENT SPACE normal vector for the surface lighting
    half3 normalMap1s = UnpackNormal(tex2D(normalMap1, dataVectors.normalMapCoords.xy));
    half3 normalMap2s = UnpackNormal(tex2D(normalMap2, dataVectors.normalMapCoords.zw));
    // Combine both normal maps in tangent space
    dataVectors.combinedTangentNormal = normalMap1s + normalMap2s;
    //

    // UVs for DuDv distortion maps
    dataVectors.duDvMapCoords.xy = dataVectors.uvBase.xy + normalMap1speed.xy * time;
    dataVectors.duDvMapCoords.zw = dataVectors.uvBase.xy + normalMap2speed.xy * time;

    // Distortion Calculation (Uses DuDv maps and is used for refraction)
    dataVectors.combinedDuDvNormal = CalculateDistortionNormal(
    duDvMap1, duDvMap2, dataVectors.duDvMapCoords, dataVectors.tangentSpaceMatrix);

    dataVectors.distortionVector = dataVectors.combinedDuDvNormal * distortionFactor;

    return dataVectors;
}

SurfaceDataVectors CalculateGesternWaveTangentSpaceMatrix(SurfaceDataVectors dataVectors)
{
    // ddx / ddy calculate the vector change in X and Y screen space directions (local derivatives)
    half3 worldTangent = normalize(ddx(dataVectors.worldPos));
    half3 worldBinormal = normalize(ddy(dataVectors.worldPos));
    half3 geometricWorldNormal = normalize(cross(worldTangent, worldBinormal)); // Gerstner Wave Normal
    dataVectors.worldNormal = geometricWorldNormal;

    // Re - orthogonalize T and B relative to the correct geometric normal
    worldBinormal = normalize(cross(dataVectors.worldNormal, worldTangent));
    worldTangent = normalize(cross(worldBinormal, dataVectors.worldNormal));

    // Build the TBN matrix for applying normal map details
    dataVectors.tangentSpaceMatrix = half3x3(worldTangent, worldBinormal, dataVectors.worldNormal);
    // -- CALCULATE TBN BASIS VECTORS END --

    return dataVectors;
}

SurfaceDataVectors CalculateFinalDistortedNormal(SurfaceDataVectors dataVectors, half glintChoppiness)
{
    // Transform the combined tangent space normal to world space
    half3 worldSpaceCombinedNormal = normalize(mul(dataVectors.tangentSpaceMatrix, dataVectors.combinedTangentNormal));
    // Blend the base Gerstner normal (worldNormal) with the high - frequency normal map detail (worldSpaceCombinedNormal),
    // weighted by _GlintChoppiness (which acts as a normal strength factor)
    dataVectors.finalNormal = normalize(dataVectors.worldNormal + (worldSpaceCombinedNormal * glintChoppiness));
    return dataVectors;
}

SurfaceDataVectors CalculateLightningData(SurfaceDataVectors dataVectors, half3 mainLightDirection)
{
    //dataVectors.worldViewDir = normalize(UnityWorldSpaceViewDir(input.worldPos));
    dataVectors.worldViewDir = normalize(CalculateWorldSpaceViewDir(dataVectors.worldPos));
    dataVectors.lightDir = mainLightDirection; //normalize(_MainLightPosition.xyz); // TODO - Make sure switch to node works !

    // The Shared Reflection Vector (Calculated once)
    dataVectors.reflectionVector = reflect(- dataVectors.worldViewDir, dataVectors.finalNormal);
    dataVectors.viewDotNormal = dot(dataVectors.worldViewDir, dataVectors.finalNormal);

    return dataVectors;
}

SurfaceDataVectors CalculateDataVectors(half time, half3 worldPos, half4 screenPos, half2 uvBase, half glintChoppiness, UnityTexture2D normalMap1, UnityTexture2D duDvMap1, half2 normalMap1speed, UnityTexture2D normalMap2, UnityTexture2D duDvMap2, half2 normalMap2speed, half3 mainLightDirection, half distortionFactor)
{
    SurfaceDataVectors dataVectors;

    // SET UP MAIN VECTORS
    dataVectors = InitDataVectors(dataVectors, worldPos, screenPos, uvBase);

    // -- SAMPLE TEXTURE MAPS --
    dataVectors = SampleMaps(time, dataVectors, normalMap1, duDvMap1, normalMap1speed, normalMap2, duDvMap2, normalMap2speed, distortionFactor);

    // -- CALCULATE TBN SPACE MATRIX --
    dataVectors = CalculateGesternWaveTangentSpaceMatrix(dataVectors);

    // The Final Distorted World Normal (Used for ALL lighting / reflection)
    dataVectors = CalculateFinalDistortedNormal(dataVectors, glintChoppiness);

    // CALCULATE LIGHTING DATA
    dataVectors = CalculateLightningData(dataVectors, mainLightDirection);

    return dataVectors;
}

half3 GetBaseSurfaceColor(SurfaceDataVectors dataVectors, half3 reflectionColor, float3 baseWaterColor)
{
    // Now _WaveColor is the primary base color, no need for redundant texture sampling.
    //half3 baseWaterColor = waveColor.rgb;

    // -- - TEXTURE SURFACE CHECK -- -
    //#ifdef _ENABLE_COLOR_SURFACE_ON
    // If pure texture mode is on, return the tinted wave color directly.
    //return baseWaterColor;
    //#else
    // Otherwise, use Fresnel to blend the base color with the reflection color.
    half reflectionFactor = pow(1.0 - saturate(dataVectors.viewDotNormal), 5.0); // Standard Fresnel
    half3 blendedColor = lerp(baseWaterColor, reflectionColor, reflectionFactor);

    return blendedColor;
    //#endif
}

void Surf_GerstnerWave_float(
half Time,

half3 WorldPos, // World Position - Will be transformed to OBJECT SPACE with Transform Node
half4 ScreenPos,
half2 UV_Base,

float3 WaveColor,

UnityTexture2D NormalMap1,
UnityTexture2D DuDvMap1,
half2 NormalMap_1_ScrollSpeed,

UnityTexture2D NormalMap2,
UnityTexture2D DuDvMap2,
half2 NormalMap_2_ScrollSpeed,

half DistortionFactor,
half GlintChoppiness,

half3 MainLightDirection,

out half3 Emission,
out half3 FinalNormal
) {
    SurfaceDataVectors dataVectors = CalculateDataVectors (
    Time,

    WorldPos,
    ScreenPos,
    UV_Base,

    GlintChoppiness,

    NormalMap1,
    DuDvMap1,
    NormalMap_1_ScrollSpeed,

    NormalMap2,
    DuDvMap2,
    NormalMap_1_ScrollSpeed,
    DistortionFactor,

    MainLightDirection
    );

    half3 skyReflection = 0;

    half3 emission = GetBaseSurfaceColor(dataVectors, skyReflection, WaveColor);

    Emission = emission;
    FinalNormal = dataVectors.finalNormal;
}

#endif