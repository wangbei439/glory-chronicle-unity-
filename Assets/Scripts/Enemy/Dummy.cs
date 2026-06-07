using UnityEngine;
using System.Collections;

public class Dummy : MonoBehaviour
{
    public int hp = 100;
    public int maxHp = 100;
    public Color bodyColor = new Color(0.2f, 0.7f, 0.2f);

    public event System.Action OnDeath;
    private Animator anim;
    private Renderer rend;
    private HPBarController hpBar;

    void Start()
    {
        // ========== 修复碰撞：把 BoxCollider 改成 trigger ==========
        // Dummy 根节点有 BoxCollider(isTrigger=false)
        // scale=3,3,0.3 放大后和玩家 CharacterController 互相推挤
        Collider col = GetComponent<Collider>();
        if (col != null)
        {
            col.isTrigger = true;
        }
        // 如果没有碰撞体，加一个 trigger 的让玩家能检测到
        else
        {
            BoxCollider bc = gameObject.AddComponent<BoxCollider>();
            bc.isTrigger = true;
            bc.size = new Vector3(0.23f, 0.18f, 0.2f);
        }

        // 清理血条子物体上的物理碰撞体
        Collider[] childCols = GetComponentsInChildren<Collider>();
        foreach (var c in childCols)
        {
            if (c.gameObject != gameObject)
            {
                Destroy(c);
            }
        }

        rend = GetComponentInChildren<Renderer>();
        rend.material.color = bodyColor;
        anim = GetComponentInChildren<Animator>();
        hpBar = GetComponentInChildren<HPBarController>();
        if (hpBar != null)
            hpBar.Setup(maxHp);
    }

    public void TakeDamage(int amount)
    {
        hp -= amount;
        hp = Mathf.Max(hp, 0);
        StartCoroutine(FlashRed());
        if (anim != null) anim.SetTrigger("HurtTrigger");
        ShowDamageNumber(amount);

        if (hpBar != null)
            hpBar.UpdateBar(hp);

        if (hp <= 0)
        {
            OnDeath?.Invoke();
            if (QuestManager.Instance != null)
                QuestManager.Instance.OnEnemyKilled();
            if (anim != null) anim.SetTrigger("DeathTrigger");
            // 死后禁用碰撞体
            Collider[] cols = GetComponentsInChildren<Collider>();
            foreach (var c in cols) c.enabled = false;
            Destroy(gameObject, 0.6f);
        }
    }

    IEnumerator FlashRed()
    {
        rend.material.color = Color.white;
        yield return new WaitForSeconds(0.1f);
        rend.material.color = bodyColor;
    }

    void ShowDamageNumber(int amount)
    {
        GameObject obj = new GameObject("DmgText");
        obj.transform.position = transform.position + Vector3.up * 1.5f;

        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = amount.ToString();
        tm.fontSize = 8;
        tm.color = Color.yellow;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;

        FloatText ft = obj.AddComponent<FloatText>();
        ft.floatSpeed = 2f;
        ft.lifetime = 0.8f;
    }
}