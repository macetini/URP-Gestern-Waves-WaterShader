using UnityEngine;

namespace Assets.Scripts.Dev.Simulation
{
    public class SimpleWaterBob : MonoBehaviour
    {
        // Adjust these in the Inspector
        public float amplitude = 0.1f; // The height of the bob (half the total up-and-down distance)
        public float frequency = 1f;   // The speed of the bobbing (how fast it moves)

        private Vector3 startPos;

        void Start()
        {
            // Store the object's starting position
            startPos = transform.position;
        }

        void Update()
        {
            // Calculate the new Y position using a sine wave
            // Mathf.Sin(Time.time * frequency) gives a value between -1 and 1
            float newY = startPos.y + Mathf.Sin(Time.time * frequency) * amplitude;
            float newZ = startPos.z + Mathf.Cos(Time.time * frequency) * amplitude;
            float newX = startPos.z + Mathf.Sin(newY + newZ) * amplitude;

            // Apply the new position, keeping the original X and Z
            transform.position = new Vector3(newX, newY, newZ);
        }
    }
}