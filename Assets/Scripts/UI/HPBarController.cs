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
        // 抵消父物体缩放，保持HP条固定大小
        transform.localScale = new Vector3(1f / transform.lossyScale.x,
                                           1f / transform.lossyScale.y,
                                           1f / transform.lossyScale.z);
        // 修正位置到头顶
        transform.localPosition = new Vector3(0f, 1f, 0f);
    }
}