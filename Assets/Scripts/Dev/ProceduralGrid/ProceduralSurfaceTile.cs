using UnityEngine;

namespace Assets.Scripts.Dev.ProceduralSurface
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class ProceduralSurfaceTile : MonoBehaviour
    {
        public int xSize = 100; // Number of subdivisions in X
        public int zSize = 100; // Number of subdivisions in Z
        public float scale = 1.0f; // Scale factor for the overall size

        void Start()
        {
            GenerateGrid();
        }

        private void GenerateGrid()
        {
            Vector3[] vertices = new Vector3[(xSize + 1) * (zSize + 1)];
            Vector2[] uv = new Vector2[vertices.Length];
            int[] triangles = new int[xSize * zSize * 6];
            int vert = 0;
            int tris = 0;

            // 1. Generate Vertices and UVs
            for (int z = 0; z <= zSize; z++)
            {
                for (int x = 0; x <= xSize; x++)
                {
                    // Position vertices on the XZ plane
                    vertices[vert] = new Vector3((float)x * scale, 0, (float)z * scale);
                    // Simple UV mapping (from 0 to 1)
                    uv[vert] = new Vector2((float)x / xSize, (float)z / zSize);
                    vert++;
                }
            }

            // 2. Generate Triangles (indices)
            vert = 0;
            for (int z = 0; z < zSize; z++)
            {
                for (int x = 0; x < xSize; x++)
                {
                    int lowerLeft = vert;
                    int lowerRight = vert + 1;
                    int upperLeft = vert + xSize + 1;
                    int upperRight = vert + xSize + 2;

                    // First triangle of the quad (Lower Left, Upper Left, Lower Right)
                    triangles[tris + 0] = lowerLeft;
                    triangles[tris + 1] = upperLeft;
                    triangles[tris + 2] = lowerRight;

                    // Second triangle of the quad (Lower Right, Upper Left, Upper Right)
                    triangles[tris + 3] = lowerRight;
                    triangles[tris + 4] = upperLeft;
                    triangles[tris + 5] = upperRight;

                    vert++;
                    tris += 6;
                }
                vert++; // Skip the last vertex of the row
            }

            // 3. Apply to Mesh
            Mesh mesh = new()
            {
                vertices = vertices,
                uv = uv,
                triangles = triangles
            };
            mesh.RecalculateNormals(); // Crucial for initial lighting

            GetComponent<MeshFilter>().mesh = mesh;
        }
    }
}