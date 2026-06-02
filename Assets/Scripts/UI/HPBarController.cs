using UnityEngine;

public class HPBarController : MonoBehaviour
{
    public Transform fillTransform;
    private float fullWidth = 1f;
    private int maxHp;

    public void Setup(int max)
    {
        maxHp = max;
        if (fillTransform != null)
            fullWidth = fillTransform.localScale.x;
        UpdateBar(maxHp);
    }

    public void UpdateBar(int currentHp)
    {
        if (fillTransform != null && maxHp > 0)
        {
            float ratio = (float)currentHp / maxHp;
            fillTransform.localScale = new Vector3(
                fullWidth * ratio,
                fillTransform.localScale.y,
                fillTransform.localScale.z
            );
            float offsetX = (ratio - 1f) * 0.5f;
            fillTransform.localPosition = new Vector3(
                offsetX,
                fillTransform.localPosition.y,
                fillTransform.localPosition.z
            );
        }
    }

    void LateUpdate()
    {
        // 抵消父物体（敌人根物体）的缩放，保持HP条固定大小
        Transform parent = transform.parent;
        if (parent != null)
        {
            Vector3 ps = parent.localScale;
            transform.localScale = new Vector3(1f / ps.x, 1f / ps.y, 1f / ps.z);
        }
        // HP条固定在头顶位置
        transform.localPosition = new Vector3(0f, 0.5f, 0f);
    }
}