using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

#if UNITY_EDITOR
using UnityEditor;
#endif


[ExecuteAlways]
public class PlanarReflection : MonoBehaviour
{
    // The name of the properties in your Shader Graph
    private const string ReflectionTextureName = "_PlanarReflectionTex";
    // NEW: The matrix needed by the shader to map world space to the texture's UVs
    private const string ReflectionMatrixName = "_WorldToReflection";

    [Header("Reflection Settings")]
    public float clipPlaneOffset = 0.07f;
    public LayerMask reflectionLayer = -1;
    public int textureSize = 512;

    private Camera reflectionCamera;
    private RenderTexture reflectionTexture;
    private Material targetMaterial;

    private void OnEnable()
    {
        if (TryGetComponent<Renderer>(out var renderer))
        {
            targetMaterial = renderer.sharedMaterial;
        }

        RenderPipelineManager.beginCameraRendering += ExecuteReflectionRender;
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= ExecuteReflectionRender;

        if (reflectionCamera)
        {
            DestroyImmediate(reflectionCamera.gameObject);
        }
        if (reflectionTexture)
        {
            DestroyImmediate(reflectionTexture);
        }
    }

    private void ExecuteReflectionRender(ScriptableRenderContext context, Camera cam)
    {
        if (cam.cameraType != CameraType.Game || (reflectionCamera != null && cam == reflectionCamera))
        {
            return;
        }

        // 1. Initialize Camera and Texture
        CreateReflectionObjects(cam);

        // 2. Calculate Mirror Transform
        Vector3 surfaceNormal = transform.up;
        Vector3 surfacePos = transform.position;

        CopyCameraData(cam, reflectionCamera);
        MirrorCamera(cam.transform.position, surfaceNormal, surfacePos, cam.transform);

        // 3. Calculate Oblique Clip Plane and Projection
        Vector4 clipPlane = CameraSpacePlane(reflectionCamera, surfaceNormal, surfacePos, clipPlaneOffset);
        Matrix4x4 projection = cam.projectionMatrix;

        // This function MUST be implemented to avoid clipping errors (was missing implementation)
        CalculateObliqueMatrix(ref projection, clipPlane);
        reflectionCamera.projectionMatrix = projection;


        // 4. Calculate the World-to-Reflection UV Matrix (ADDED LOGIC)

        // a) Get the combined View-Projection matrix of the reflection camera
        Matrix4x4 reflectionVP = reflectionCamera.projectionMatrix * reflectionCamera.worldToCameraMatrix;

        // b) Matrix to scale Clip Space [-1, 1] to UV Space [0, 1]
        Matrix4x4 scaleOffset = Matrix4x4.identity;
        scaleOffset.m00 = 0.5f;
        scaleOffset.m11 = 0.5f;
        scaleOffset.m03 = 0.5f;
        scaleOffset.m13 = 0.5f;

        // c) Final World-to-UV matrix
        Matrix4x4 worldToReflectionMatrix = scaleOffset * reflectionVP;


        // 5. Render the Reflection (using the older, but functional, URP API)
        reflectionCamera.targetTexture = reflectionTexture;

#pragma warning disable CS0618 // Type or member is obsolete
        UniversalRenderPipeline.RenderSingleCamera(context, reflectionCamera);
#pragma warning restore CS0618

        // 6. Pass Texture AND Matrix to Material (ADDED LOGIC)
        if (targetMaterial != null)
        {
            targetMaterial.SetTexture(ReflectionTextureName, reflectionTexture);
            targetMaterial.SetMatrix(ReflectionMatrixName, worldToReflectionMatrix); // PASS THE MATRIX
        }
    }

    // --- Utility Methods ---

    private void CreateReflectionObjects(Camera currentCamera)
    {
        if (reflectionTexture == null || reflectionTexture.width != textureSize)
        {
            if (reflectionTexture) DestroyImmediate(reflectionTexture);

            reflectionTexture = new RenderTexture(textureSize, textureSize, 24)
            {
                name = "PlanarReflectionTexture",
                hideFlags = HideFlags.DontSave,
                filterMode = FilterMode.Bilinear
            };
        }

        if (reflectionCamera == null)
        {
            GameObject go = new GameObject("ReflectionCamera", typeof(Camera));
            go.hideFlags = HideFlags.HideAndDontSave;
            reflectionCamera = go.GetComponent<Camera>();

            CopyCameraData(currentCamera, reflectionCamera);
            reflectionCamera.enabled = false;
            reflectionCamera.cullingMask = reflectionLayer;
            reflectionCamera.cameraType = CameraType.Reflection; // Crucial to prevent recursion
        }
    }

    private void CopyCameraData(Camera src, Camera dest)
    {
        dest.CopyFrom(src);
        dest.enabled = false;
        dest.cullingMask = reflectionLayer;
    }

    private void MirrorCamera(Vector3 camPos, Vector3 planeNormal, Vector3 planePos, Transform camTransform)
    {
        float d = -Vector3.Dot(planeNormal, planePos);
        Vector4 plane = new Vector4(planeNormal.x, planeNormal.y, planeNormal.z, d);

        Matrix4x4 reflectionMatrix = Matrix4x4.identity;
        reflectionMatrix.m00 = (1F - 2F * plane.x * plane.x);
        reflectionMatrix.m01 = (-2F * plane.x * plane.y);
        reflectionMatrix.m02 = (-2F * plane.x * plane.z);
        reflectionMatrix.m03 = (-2F * plane.w * plane.x);

        reflectionMatrix.m10 = (-2F * plane.y * plane.x);
        reflectionMatrix.m11 = (1F - 2F * plane.y * plane.y);
        reflectionMatrix.m12 = (-2F * plane.y * plane.z);
        reflectionMatrix.m13 = (-2F * plane.w * plane.y);

        reflectionMatrix.m20 = (-2F * plane.z * plane.x);
        reflectionMatrix.m21 = (-2F * plane.z * plane.y);
        reflectionMatrix.m22 = (1F - 2F * plane.z * plane.z);
        reflectionMatrix.m23 = (-2F * plane.w * plane.z);

        reflectionMatrix.m30 = 0F;
        reflectionMatrix.m31 = 0F;
        reflectionMatrix.m32 = 0F;
        reflectionMatrix.m33 = 1F;

        // **FIXED POSITION CALCULATION**
        reflectionCamera.transform.position = reflectionMatrix.MultiplyPoint(camPos);

        // **THE FIX FOR ROTATION:**
        // We now mirror the main camera's forward and up vectors.
        reflectionCamera.transform.rotation = Quaternion.LookRotation(
            reflectionMatrix.MultiplyVector(camTransform.forward), // Mirror the main camera's forward
            reflectionMatrix.MultiplyVector(camTransform.up)       // Mirror the main camera's up
        );
    }

    private static Vector4 CameraSpacePlane(Camera cam, Vector3 normal, Vector3 point, float offset)
    {
        Vector3 cpos = cam.worldToCameraMatrix.MultiplyPoint(point + normal * offset);
        Vector3 cnormal = cam.worldToCameraMatrix.MultiplyVector(normal).normalized;
        return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cnormal, cpos));
    }

    private static void CalculateObliqueMatrix(ref Matrix4x4 projection, Vector4 clipPlane)
    {
        Vector4 q = projection.inverse * new Vector4(
            Mathf.Sign(clipPlane.x),
            Mathf.Sign(clipPlane.y),
            1.0f,
            1.0f
        );
        Vector4 c = clipPlane * (2.0f / Vector4.Dot(clipPlane, q));

        projection[2] = c.x - projection[3];
        projection[6] = c.y - projection[7];
        projection[10] = c.z - projection[11];
        projection[14] = c.w - projection[15];
    }
}