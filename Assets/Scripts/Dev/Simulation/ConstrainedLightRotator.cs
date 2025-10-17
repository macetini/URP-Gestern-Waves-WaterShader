using UnityEngine;

public class ConstrainedLightRotator : MonoBehaviour
{
    [Tooltip("The speed of rotation around the Y-axis (horizontal sweep).")]
    public float yRotationSpeed = 5f;

    [Tooltip("The speed of tilt (pitch) rotation around the X-axis.")]
    public float xTiltSpeed = 1f;

    [Tooltip("The minimum angle the light can tilt down towards the plane (e.g., 10 for a slight tilt).")]
    [Range(0f, 90f)]
    public float minTiltAngle = 0f; // 0 degrees (pointing straight down)

    [Tooltip("The maximum angle the light can tilt towards the horizon.")]
    [Range(90f, 180f)]
    public float maxTiltAngle = 80f; // 90 degrees (pointing straight at horizon) - set to 80 to be safe

    // The current pitch angle, stored to ensure it stays within bounds.
    private float currentPitch = 0f;

    void Update()
    {
        // 1. Horizontal Rotation (Yaw - around the Y-axis)
        // This can spin freely.
        transform.Rotate(Vector3.up, yRotationSpeed * Time.deltaTime, Space.World);

        // 2. Vertical Tilt (Pitch - around the light's local X-axis)

        // Calculate the next raw pitch change
        //float pitchChange = xTiltSpeed * Time.deltaTime;

        // Use a ping-pong function to make the light oscillate between min and max tilt angles
        // The total range is (maxTiltAngle - minTiltAngle).
        // The light will tilt down and then back up to the maximum.

        // This is a time-based oscillation that goes from 0 to 1 and back
        float t = Mathf.PingPong(Time.time * (xTiltSpeed / 10f), 1f);

        // Map t to the desired pitch range (from minTiltAngle to maxTiltAngle)
        float targetPitch = Mathf.Lerp(minTiltAngle, maxTiltAngle, t);

        // Calculate the actual rotation needed to get from the current pitch to the target pitch
        float deltaPitch = targetPitch - currentPitch;

        // Apply the pitch rotation around the local X-axis
        transform.Rotate(Vector3.right, deltaPitch, Space.Self);

        // Update the stored pitch
        currentPitch = targetPitch;
    }
}