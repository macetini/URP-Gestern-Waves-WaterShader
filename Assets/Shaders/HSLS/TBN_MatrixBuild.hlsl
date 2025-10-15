#ifndef TBN_MATRIXBUILD_NODE
#define TBN_MATRIXBUILD_NODE

void TBN_Matrix_float(
half3 WorldTangentDir,
half TangentHandedness,
half3 WorldNormal,

out half3x3 TBN
)
{
    half3 N = normalize(WorldNormal);

    // Start with the normalized input Tangent
    half3 T = normalize(WorldTangentDir);

    // Compute a temporary Bitangent B (orthogonal to N and T)
    // NOT normalized yet
    half3 B_tmp = cross(N, T);

    // Recompute Tangent T, making it strictly orthogonal to N and B_tmp
    // T is now perfectly orthogonal to N
    T = normalize(cross(B_tmp, N));

    // Compute the final Bitangent B.
    // It's the cross product of N and the newly computed T,
    // then we apply the handedness factor (TangentHandedness / WorldTangent.w)
    // This ensures B is orthogonal to N and T, and has the correct direction.
    half3 B = cross(N, T) * TangentHandedness;

    // Build the matrix (T, B, N)
    TBN = half3x3(T, B, N);
}

#endif