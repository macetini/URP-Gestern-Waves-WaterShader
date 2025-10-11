// GesternWave.hlsl - Calculates the 3D position offset (displacement) for a single wave.
#ifndef GESTERN_WAVE_CALCULATION
#define GESTERN_WAVE_CALCULATION

// Define PI constant (Better safe than sorry)
#ifndef PI
#define PI 3.14159265359
#endif

// Define G (Gravity) constant
#ifndef G
#define G 9.81
#endif

struct WaveInfo
{
    half wavelength; // (W)
    half amplitude; // (A)
    half speed; // (phi)
    half steepness; // (Q)
    half2 direction; // (D)
};

struct TangentSpace
{
    half3 normal;
    half3 binormal;
    half3 tangent;
};

// -- - CORE WAVE CALCULATION (Per Wave) -- -
half3 CalculateGesternWave(WaveInfo wave, inout TangentSpace tangentSpace, half3 vertPos, half l_time)
{
    // Wave Quotient
    half WaveQuotient = (2 * PI) / wave.wavelength;

    // Angular frequency
    half AngularFrequencyOmega = sqrt(G * WaveQuotient);

    // Phase
    half PHI_t = wave.speed * AngularFrequencyOmega * l_time;

    // Direction vector (normalized)
    half2 D = normalize(wave.direction.xy);

    // Steepness factor
    half Q = wave.steepness / (WaveQuotient * wave.amplitude * 2);

    // Wave value
    half f1 = WaveQuotient * dot(D, vertPos.xz) + PHI_t;
    half S = sin(f1);
    half C = cos(f1);

    // Pre - calculated common terms
    half WA = WaveQuotient * wave.amplitude;
    half WAS = WA * S; // w * A * sin(f1)
    half WAC = WA * C; // w * A * cos(f1)

    // Derivative X (Tangent contribution)
    tangentSpace.tangent += half3
    (
    // Px component : 1 - Q * (Dx ^ 2) * W * A * cos(f)
    - (Q * (D.x * D.x) * WAC),
    // Py component : Dx * W * A * sin(f)
    D.x * WAS,
    // Pz component : - Q * (Dx * Dy) * W * A * cos(f)
    - (Q * (D.x * D.y) * WAC)
    );

    // Derivative Z (Binormal contribution)
    tangentSpace.binormal += half3
    (
    // Px component : - Q * (Dx * Dy) * W * A * cos(f)
    - (Q * (D.x * D.y) * WAC),
    // Py component : Dy * W * A * sin(f)
    D.y * WAS,
    // Pz component : 1 - Q * (Dy ^ 2) * W * A * cos(f)
    - (Q * (D.y * D.y) * WAC)
    );

    // Derivative Y (Normal contribution)
    tangentSpace.normal += half3
    (
    D.x * WAC,
    Q * WAS,
    D.y * WAC
    );

    // Displacement for this wave, Delta P
    half f4 = Q * wave.amplitude * C;

    half3 gesternWavePoint = half3
    (
    f4 * D.x, // X Displacement
    wave.amplitude * S, // Y Displacement
    f4 * D.y // Z Displacement
    );

    return gesternWavePoint;
}

void GerstnerWave_float(

half3 WorldSpaceVertPos, // Object Space Position
half Time,

half Wavelength_1,
half Amplitude_1,
half Speed_1,
half Steepness_1,
half2 Direction_1,

half Wavelength_2,
half Amplitude_2,
half Speed_2,
half Steepness_2,
half2 Direction_2,

// Final Vertex (Gestern Wave Displacement)
out half3 WaveVertexPosition, // World Position - Will be transformed to OBJECT SPACE with Transform Node

// TBN MATRIX
out half3 WaveVertexNormal, // Final World Normal (calculated via cross(B, T))
out half3 WaveVertexBinormal, // Final World Binormal
out half3 WaveVertexTangent // Final World Tangent
)
{
    WaveInfo wave_1 = {Wavelength_1, Amplitude_1, Speed_1, Steepness_1, Direction_1.xy, };
    WaveInfo wave_2 = {Wavelength_2, Amplitude_2, Speed_2, Steepness_2, Direction_2.xy, };

    // Initialize the derivative vectors (Identity matrix for flat surface)
    TangentSpace tangentSpace = {
        half3(0, 0, 0), // N starts at (0, 0, 0)
        half3(0, 0, 1), // B starts at (0, 0, 1) - Z axis
        half3(1, 0, 0) // T starts at (1, 0, 0) - X axis
    };

    half3 displacedVertPos = WorldSpaceVertPos;

    // Accumulate vertex displacement and tangent derivatives
    displacedVertPos += CalculateGesternWave(wave_1, tangentSpace, displacedVertPos, Time);
    displacedVertPos += CalculateGesternWave(wave_2, tangentSpace, displacedVertPos, Time);

    WaveVertexPosition = displacedVertPos; // Will be transformed to OBJECT SPACE with Transform Node

    // Calculate the final Normal using the cross product of the accumulated Tangent and Binormal vectors.
    WaveVertexNormal = normalize(cross(tangentSpace.binormal, tangentSpace.tangent));
    WaveVertexBinormal = normalize(tangentSpace.binormal);
    WaveVertexTangent = normalize(tangentSpace.tangent);
}

#endif