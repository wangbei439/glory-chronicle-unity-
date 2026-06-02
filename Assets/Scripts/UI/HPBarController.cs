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
}