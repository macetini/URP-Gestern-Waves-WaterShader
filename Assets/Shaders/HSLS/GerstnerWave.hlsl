// HLSL code for a Shader Graph Custom Function Node.
// This function calculates both the vertex position displacement and the new world normal
// for a single vertex based on two Gerstner waves.

#ifndef GERSTNER_WAVE_CORE_INCLUDED
#define GERSTNER_WAVE_CORE_INCLUDED

// Structure to hold single wave properties
struct WaveInfo
{
    float wavelength; // (W)
    float amplitude; // (A)
    float speed; // (phi)
    float2 direction; // (D)
    float steepness; // (Q)
};

// Structure to accumulate displacement and TBN contributions
struct WaveResult
{
    float3 displacement;
    float3 normal;
    float3 tangent;
    float3 binormal;
};

// Calculates displacement and partial derivatives for a single Gerstner wave
WaveResult CalculateSingleGerstnerWave(WaveInfo wave, float3 p, float t)
{
    WaveResult result = { float3(0, 0, 0), float3(0, 0, 0), float3(0, 0, 0), float3(0, 0, 0) };

    // Physics constant (Gravity)
    const float g = 9.81;    

    // Angular frequency (w = sqrt(g * k)) where k = 2 * PI / wavelength
    float w = sqrt(g * ((2 * PI) / wave.wavelength));

    // Phase shift (w * speed * time)
    float PHI_t = wave.speed * w * t;

    // Normalized direction vector
    float2 D = normalize(wave.direction.xy);

    // Steepness factor (Q = Steepness / (w * A))
    float Q = wave.steepness / (w * wave.amplitude);

    // Wave number * xz position + phase shift
    float f1 = w * dot(D, p.xz) + PHI_t;

    float S = sin(f1);
    float C = cos(f1);

    // Displacement (x, y, z)
    result.displacement = float3(
    Q * wave.amplitude * C * D.x, // X
    wave.amplitude * S, // Y
    Q * wave.amplitude * C * D.y // Z
    );

    // -- - Analytical Normal Calculation -- -
    // The Normal is derived from the partial derivatives (slope)

    float3 tangentSlope = float3(
    1.0 - D.x * D.x * Q * w * wave.amplitude * S, // Tx = 1 - (Dx * Dx) * derivative_x
    D.x * w * wave.amplitude * C, // Ty = Dx * derivative_y
    - D.x * D.y * Q * w * wave.amplitude * S // Tz = - (Dx * Dy) * derivative_z (Note : this is often the Binormal contribution in Gerstner literature)
    );

    float3 binormalSlope = float3(
    - D.x * D.y * Q * w * wave.amplitude * S, // Bx
    D.y * w * wave.amplitude * C, // By
    1.0 - D.y * D.y * Q * w * wave.amplitude * S // Bz = 1 - (Dy * Dy) * derivative_z
    );

    // We only need the resulting World Normal, which is the cross product of the Tangent and Binormal (or Tangent and Binormal Slopes)
    // The tangent / binormal contribution accumulation is simplified here to just calculate the final normal.
    result.normal = normalize(cross(binormalSlope, tangentSlope));

    return result;
}

// Main custom function entry point for Shader Graph
// The name of this function (GerstnerWave) must match the name used in the Custom Function Node.
void GerstnerWave_float(

float3 WorldPos, 
float LocalTime,

float Wavelength1, float Amplitude1, float Speed1, float Steepness1, float2 Direction1,
float Wavelength2, float Amplitude2, float Speed2, float Steepness2, float2 Direction2,

out float3 DisplacedPos,
out float3 WorldNormal)
{
    // Initialize accumulation
    float3 totalDisplacement = float3(0, 0, 0);
    float3 totalNormal = float3(0, 0, 0);

    // -- - Wave 1 -- -
    WaveInfo wave1 = {Wavelength1, Amplitude1, Speed1, Direction1, Steepness1};
    WaveResult res1 = CalculateSingleGerstnerWave(wave1, WorldPos, LocalTime);
    totalDisplacement += res1.displacement;
    totalNormal += res1.normal;

    // -- - Wave 2 -- -
    WaveInfo wave2 = {Wavelength2, Amplitude2, Speed2, Direction2, Steepness2};
    WaveResult res2 = CalculateSingleGerstnerWave(wave2, WorldPos, LocalTime);
    totalDisplacement += res2.displacement;
    totalNormal += res2.normal;

    // Final Outputs
    DisplacedPos = WorldPos.xyz + totalDisplacement;
    // Normalize the final accumulated normal
    WorldNormal = normalize(totalNormal);
}

#endif // GERSTNER_WAVE_CORE_INCLUDED