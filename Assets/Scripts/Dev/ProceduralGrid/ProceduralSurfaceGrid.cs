using UnityEngine;

namespace Assets.Scripts.Dev.ProceduralGrid
{
    public class ProceduralSurfaceGrid : MonoBehaviour
    {
        public ProceduralSurfaceTile tilePrefab;
        public int gridSizeX = 3; // Number of tiles in X direction
        public int gridSizeZ = 3; // Number of tiles in Z direction

        // Start is called once before the first execution of Update after the MonoBehaviour is created
        void Start()
        {
            for (int x = 0; x < gridSizeX; x++)
            {
                for (int z = 0; z < gridSizeZ; z++)
                {
                    Vector3 position = new(x * tilePrefab.xSize * tilePrefab.scale, 0, z * tilePrefab.zSize * tilePrefab.scale);
                    Instantiate(tilePrefab, position, Quaternion.identity, transform);
                }
            }
        }
    }
}