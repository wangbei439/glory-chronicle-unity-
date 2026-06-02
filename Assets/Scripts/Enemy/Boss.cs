using UnityEngine;
using System.Collections;

public class Boss : MonoBehaviour
{
    public int hp = 300;
    public int maxHp = 300;
    public int attackDamage = 20;
    public float attackRange = 3f;
    public float attackCooldown = 2f;
    public float chaseSpeed = 3f;
    public float detectRange = 10f;
    public Color bodyColor = new Color(0.5f, 0f, 0.8f); // ×ÏÉ«

    public event System.Action OnDeath;

    private Renderer rend;
    private Animator anim;
    private HPBarController hpBar;
    private float cooldownTimer = 0f;
    private bool facingRight = true;

    void Start()
    {
        rend = GetComponentInChildren<Renderer>();
        rend.material.color = bodyColor;
        anim = GetComponentInChildren<Animator>();

        hpBar = GetComponentInChildren<HPBarController>();
        if (hpBar != null)
            hpBar.Setup(maxHp);
    }

    void Update()
    {
        if (hp <= 0) return;

        cooldownTimer -= Time.deltaTime;

        GameObject player = GameObject.FindGameObjectWithTag("Player");
        if (player == null) return;

        float dist = Vector3.Distance(player.transform.position, transform.position);

        if (dist > attackRange && dist <= detectRange)
        {
            // ×·»÷
            Vector3 dir = (player.transform.position - transform.position).normalized;
            dir.y = 0;
            transform.position += dir * chaseSpeed * Time.deltaTime;

            // ·­×ª³¯ÏòÍæ¼Ò
            if (dir.x > 0 && !facingRight)
            {
                facingRight = true;
                Flip();
            }
            else if (dir.x < 0 && facingRight)
            {
                facingRight = false;
                Flip();
            }
        }
        else if (dist <= attackRange && cooldownTimer <= 0)
        {
            // ¹¥»÷
            cooldownTimer = attackCooldown;
            if (anim != null) anim.SetTrigger("AttackTrigger");
            if (anim != null) anim.SetFloat("Speed", 0f);
            PlayerStats playerStats = player.GetComponent<PlayerStats>();
            if (playerStats != null)
            {
                playerStats.TakeDamage(attackDamage);
                ShowFloatText("-" + attackDamage, Color.red, player.transform.position);
            }
        }
    }

    public void TakeDamage(int amount)
    {
        hp -= amount;
        hp = Mathf.Max(hp, 0);
        StartCoroutine(FlashWhite());
        if (anim != null) anim.SetTrigger("HurtTrigger");

        if (hpBar != null)
            hpBar.UpdateBar(hp);

        if (hp <= 0)
        {
            OnDeath?.Invoke();
            if (QuestManager.Instance != null)
                QuestManager.Instance.OnBossDefeated();
            if (WorldManager.Instance != null)
                WorldManager.Instance.DefeatBoss("forest_boss");
            if (anim != null) anim.SetTrigger("DeathTrigger");
            Destroy(gameObject, 0.8f);
        }
    }

    IEnumerator FlashWhite()
    {
        rend.material.color = Color.white;
        yield return new WaitForSeconds(0.1f);
        rend.material.color = bodyColor;
    }

    void ShowFloatText(string text, Color color, Vector3 pos)
    {
        GameObject obj = new GameObject("BossDmgText");
        obj.transform.position = pos + Vector3.up * 1.5f;

        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = text;
        tm.fontSize = 8;
        tm.color = color;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;

        FloatText ft = obj.AddComponent<FloatText>();
        ft.floatSpeed = 2f;
        ft.lifetime = 1f;
    }
    void Flip()
    {
        Transform body = transform.Find("Body");
        if (body != null)
        {
            body.localRotation = facingRight
                ? Quaternion.identity
                : Quaternion.Euler(0f, 180f, 0f);
        }
    }
}