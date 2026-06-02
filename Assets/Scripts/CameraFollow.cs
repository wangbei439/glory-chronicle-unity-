using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Transform target;
    public float height = 10f;
    public float distance = 10f;

    private Vector3 offset;
    private Vector3 shakeOffset;
    private float shakeDuration = 0f;
    private float shakeIntensity = 0f;

    void LateUpdate()
    {
        if (target == null) return;

        offset = new Vector3(0f, height, -distance);

        // ÕðÆÁ
        if (shakeDuration > 0f)
        {
            shakeDuration -= Time.deltaTime;
            shakeOffset = Random.insideUnitSphere * shakeIntensity;
            shakeIntensity *= 0.9f; // Ë¥¼õ
        }
        else
        {
            shakeOffset = Vector3.zero;
        }

        transform.position = target.position + offset + shakeOffset;
        transform.LookAt(target.position + Vector3.up * 1f);
    }

    public void Shake(float duration, float intensity)
    {
        shakeDuration = duration;
        shakeIntensity = intensity;
    }
}