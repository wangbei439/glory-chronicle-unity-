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
        // 反向缩放，让血条不受父物体缩放影响
        Transform parent = transform.parent;
        if (parent != null)
        {
            Vector3 ps = parent.localScale;
            if (ps.x != 0f && ps.y != 0f && ps.z != 0f)
            {
                transform.localScale = new Vector3(1f / ps.x, 1f / ps.y, 1f / ps.z);
            }
        }
        // 注意：不再设置 transform.localPosition
        // 因为 HPBarController 挂在 Boss 根对象上，设 localPosition 会把 Boss 拉回原点
    }
}