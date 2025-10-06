using Assets.Scripts.Dev.Meta;
using UnityEngine;

namespace Assets.Scripts.Dev
{
    public class WaterSimulation : MonoBehaviour
    {
        public float wavelength1 = 10;
        public float amplitude1 = 1;
        public float speed1 = 1;
        public Vector2 direction1 = Vector2.right;
        public float steepness1 = 0.5f;

        public float wavelength2 = 10;
        public float amplitude2 = 1;
        public float speed2 = 1;
        public Vector2 direction2 = Vector2.right;
        public float steepness2 = 0.5f;

        // Update is called once per frame
        void OnDrawGizmos()
        {
            WaveVO wave1 = new()
            {
                Wavelength = wavelength1,
                Amplitude = amplitude1,
                Speed = speed1,
                Direction = direction1,
                Steepness = steepness1
            };

            WaveVO wave2 = new()
            {
                Wavelength = wavelength2,
                Amplitude = amplitude2,
                Speed = speed2,
                Direction = direction2,
                Steepness = steepness2
            };

            for (float i = 0; i < 30; i++)
            {
                for (float j = 0; j < 30; j++)
                {
                    Vector3 point = new(i, 0, j);

                    TangentSpaceVO tangentSpace = new();

                    point += GetGesternWave(wave1, ref tangentSpace, point, Time.time);
                    point += GetGesternWave(wave2, ref tangentSpace, point, Time.time);

                    Gizmos.color = Color.black;

                    Gizmos.DrawSphere(point, 0.15f);

                    Gizmos.color = Color.green;

                    tangentSpace = CalculateTangentSpace(tangentSpace);

                    Matrix4x4 texSpace = new Matrix4x4(tangentSpace.BiNormal, tangentSpace.Normal, tangentSpace.Tangent, new Vector3());

                    Vector3 normal = new Vector3(0, 1, 0);

                    Vector3 finalNormal = Vector3.Normalize(texSpace * normal);

                    Gizmos.DrawLine(point, point + finalNormal);
                }
            }
        }

        private static Vector3 GetGesternWave(WaveVO wave, ref TangentSpaceVO tangentSpace, Vector3 p, float t)
        {
            float w = Mathf.Sqrt(9.81f * (2f * Mathf.PI / wave.Wavelength));
            float PHI_t = wave.Speed * w * t;
            Vector2 D = wave.Direction;
            D.Normalize();
            float Q = wave.Steepness / (w * wave.Amplitude * 2);

            float f1 = w * Vector2.Dot(D, new Vector2(p.x, p.z)) + PHI_t;
            float S = Mathf.Sin(f1);
            float C = Mathf.Cos(f1);

            float WA = w * wave.Amplitude;
            float WAS = WA * S;
            float WAC = WA * C;

            tangentSpace.BiNormal += new Vector3
                  (
                      Q * (D.x * D.x) * WAS,
                      D.x * WAC,
                      Q * (D.x * D.y) * WAS
                  );

            tangentSpace.Tangent += new Vector3
            (
                Q * (D.x * D.y) * WAS,
                D.y * WAC,
                Q * (D.y * D.y) * WAS
            );

            tangentSpace.Normal += new Vector3
            (
                D.x * WAC,
                Q * WAS,
                D.y * WAC
            );

            float f3 = Mathf.Cos(f1);
            float f4 = Q * wave.Amplitude * f3;

            return new Vector3
            (
                f4 * D.x,                       // X
                wave.Amplitude * Mathf.Sin(f1), // Y
                f4 * D.y                        // Z
            );
        }

        private static TangentSpaceVO CalculateTangentSpace(TangentSpaceVO tangentSpace)
        {
            tangentSpace.BiNormal = new Vector3(
                1 - tangentSpace.BiNormal.x,
                tangentSpace.BiNormal.y,
                -tangentSpace.BiNormal.z
            );
            tangentSpace.Tangent = new Vector3(
                -tangentSpace.Tangent.x,
                tangentSpace.Tangent.y,
                1 - tangentSpace.Tangent.z
            );
            tangentSpace.Normal = new Vector3(
                -tangentSpace.Normal.x,
                1 - tangentSpace.Normal.y,
                -tangentSpace.Normal.z
            );

            return tangentSpace;
        }
    }
}