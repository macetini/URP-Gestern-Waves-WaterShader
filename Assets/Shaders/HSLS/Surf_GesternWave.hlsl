// GesternWave.hlsl - Calculates the 3D position offset (displacement) for a single wave.
#ifndef SURF_GESTERN_WAVE_NODE
#define SURF_GESTERN_WAVE_NODE

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
    half3 worldPos;
    half2 uvBase;

    half4 normalMapCoords;
    half4 duDvMapCoords;

    half3x3 tangentSpaceMatrix;

    half3 combinedTangentNormal; // Combined tangent space normal for lighting

    half3 distortionVector;

    half3 worldNormal;
    half3 worldViewDir;
    half3 lightDir;

    half3 finalNormal;
    half3 reflectionVector;
    half viewDotNormal;
};

struct InitMeta
{
    half3 worldPos;
    half4 screenPos; //Used once
    half2 uvBase;
};

struct MapsMeta
{
    half time;

    UnityTexture2D normalMap1;
    UnityTexture2D duDvMap1;
    half2 normalMap1speed;

    UnityTexture2D normalMap2;
    UnityTexture2D duDvMap2;
    half2 normalMap2speed;

    half distortionFactor;
};

SurfaceDataVectors InitSurfaceData(InitMeta initMeta)
{
    SurfaceDataVectors dataVectors = (SurfaceDataVectors)0;

    dataVectors.worldPos = initMeta.worldPos;
    dataVectors.uvBase = initMeta.uvBase;

    return dataVectors;
}

half3 CalculateDistortionNormal(SurfaceDataVectors dataVectors, MapsMeta mapsMeta)
{
    half3 duDvMap1s = UnpackNormal(tex2D(mapsMeta.duDvMap1, dataVectors.duDvMapCoords.xy));
    half3 duDvMap2s = UnpackNormal(tex2D(mapsMeta.duDvMap2, dataVectors.duDvMapCoords.zw));

    half3 duDVMapSum = normalize(duDvMap1s + duDvMap2s);

    // Transform the combined tangent space DuDv map into a world space direction vector
    half3 combinedDuDvNormal = normalize(mul(dataVectors.tangentSpaceMatrix, duDVMapSum));
    return combinedDuDvNormal;
}

SurfaceDataVectors SampleMaps(SurfaceDataVectors dataVectors, MapsMeta mapsMeta)
{
    // UVs for the actual lighting normal maps
    // We use a slightly faster scroll speed or a different tiling factor (0.5 here)
    // to make the two sets of maps look slightly different
    dataVectors.normalMapCoords.xy = dataVectors.uvBase.xy + mapsMeta.normalMap1speed.xy * mapsMeta.time * 0.5;
    dataVectors.normalMapCoords.zw = dataVectors.uvBase.xy + mapsMeta.normalMap2speed.xy * mapsMeta.time * 0.5;

    // Calculate the final, combined TANGENT SPACE normal vector for the surface lighting
    half3 normalMap1s = UnpackNormal(tex2D(mapsMeta.normalMap1, dataVectors.normalMapCoords.xy));
    half3 normalMap2s = UnpackNormal(tex2D(mapsMeta.normalMap2, dataVectors.normalMapCoords.zw));
    // Combine both normal maps in tangent space
    dataVectors.combinedTangentNormal = normalMap1s + normalMap2s;
    //

    // UVs for DuDv distortion maps
    dataVectors.duDvMapCoords.xy = dataVectors.uvBase.xy + mapsMeta.normalMap1speed.xy * mapsMeta.time;
    dataVectors.duDvMapCoords.zw = dataVectors.uvBase.xy + mapsMeta.normalMap2speed.xy * mapsMeta.time;

    // Distortion Calculation (Uses DuDv maps and is used for refraction)
    half3 combinedDuDvNormal = CalculateDistortionNormal(dataVectors, mapsMeta);

    dataVectors.distortionVector = combinedDuDvNormal * mapsMeta.distortionFactor;

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
    dataVectors.worldViewDir = normalize(CalculateWorldSpaceViewDir(dataVectors.worldPos));
    dataVectors.lightDir = mainLightDirection;

    // The Shared Reflection Vector (Calculated once)
    dataVectors.reflectionVector = reflect(- dataVectors.worldViewDir, dataVectors.finalNormal);
    dataVectors.viewDotNormal = dot(dataVectors.worldViewDir, dataVectors.finalNormal);

    return dataVectors;
}

void Surf_GerstnerWave_float(

// Input
half Time,

half3 WorldPos,
half4 ScreenPos,
half2 UV_Base,

UnityTexture2D NormalMap1,
UnityTexture2D DuDvMap1,
half2 NormalMap_1_ScrollSpeed,

UnityTexture2D NormalMap2,
UnityTexture2D DuDvMap2,
half2 NormalMap_2_ScrollSpeed,

half DistortionFactor,
half GlintChoppiness,

half3 MainLightDirection,

// Output
out half3 FinalNormal,
out half ViewDotNormal,
out half3 ReflectionVector,
out half3 DistortionVector,
out half3 LightDir
) {
    // SET UP MAIN DATA
    InitMeta initMeta;
    initMeta.worldPos = WorldPos;
    initMeta.screenPos = ScreenPos;
    initMeta.uvBase = UV_Base;

    SurfaceDataVectors dataVectors = InitSurfaceData(initMeta);
    //

    // -- SAMPLE TEXTURE MAPS --
    MapsMeta mapsMeta;

    mapsMeta.time = Time;
    mapsMeta.normalMap1 = NormalMap1;
    mapsMeta.duDvMap1 = DuDvMap1;
    mapsMeta.normalMap1speed = NormalMap_1_ScrollSpeed;
    mapsMeta.normalMap2 = NormalMap2;
    mapsMeta.duDvMap2 = DuDvMap2;
    mapsMeta.normalMap2speed = NormalMap_2_ScrollSpeed;
    mapsMeta.distortionFactor = DistortionFactor;

    dataVectors = SampleMaps(dataVectors, mapsMeta);
    //

    // -- CALCULATE TBN SPACE MATRIX --
    dataVectors = CalculateGesternWaveTangentSpaceMatrix(dataVectors);

    // The Final Distorted World Normal (Used for ALL lighting / reflection)
    dataVectors = CalculateFinalDistortedNormal(dataVectors, GlintChoppiness);

    // CALCULATE LIGHTING DATA
    dataVectors = CalculateLightningData(dataVectors, MainLightDirection);

    FinalNormal = dataVectors.finalNormal;
    ViewDotNormal = dataVectors.viewDotNormal;
    ReflectionVector = dataVectors.reflectionVector;
    DistortionVector = dataVectors.distortionVector;
    LightDir = dataVectors.lightDir;
}

#endif