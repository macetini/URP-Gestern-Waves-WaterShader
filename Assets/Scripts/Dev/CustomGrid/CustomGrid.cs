using UnityEngine;

public class CustomGrid : MonoBehaviour
{
    public GameObject tile;

    public int gridSizeX = 3; // Number of tiles in X direction
    public int gridSizeZ = 3; // Number of tiles in Z direction

    void Start()
    {
        for (int x = 0; x < gridSizeX; x++)
        {
            for (int z = 0; z < gridSizeZ; z++)
            {
                Vector3 position = new(x * (tile.transform.localScale.x * 10) + tile.transform.localScale.x, 0, z * (tile.transform.localScale.z * 10));
                GameObject tileInstance = Instantiate(tile, position, Quaternion.identity, transform);
                tileInstance.name = $"{tileInstance.name}_{x}_{z}";
            }
        }
    }
}
