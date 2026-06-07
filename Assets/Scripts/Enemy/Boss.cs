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
    public Color bodyColor = new Color(0.5f, 0f, 0.8f);

    public event System.Action OnDeath;

    private Renderer rend;
    private Animator anim;
    private HPBarController hpBar;
    private float cooldownTimer = 0f;
    private bool facingRight = true;

    private enum BossState { Idle, Chase, Attack, Hurt, Dead }
    private BossState currentState = BossState.Idle;
    private float stateTimer = 0f;

    private GameObject playerCache;
    private float findTimer = 0f;

    void Start()
    {
        // ========== 修复碰撞：清理血条上的物理碰撞体 ==========
        // 场景里 HPBG/HPFill 有 MeshCollider(isTrigger=false)
        // Boss scale=3,3,3 这些碰撞体放大3倍和玩家CC碰撞导致卡住
        Collider[] allCols = GetComponentsInChildren<Collider>();
        foreach (var col in allCols)
        {
            // 只保留 Boss 根节点的碰撞体（改 trigger），血条的全部删
            if (col.gameObject == gameObject)
            {
                col.isTrigger = true;
            }
            else
            {
                Destroy(col);
            }
        }

        // 如果根节点没碰撞体，加一个 trigger 的 BoxCollider 让玩家能检测到
        if (GetComponent<Collider>() == null)
        {
            BoxCollider bc = gameObject.AddComponent<BoxCollider>();
            bc.isTrigger = true;
            bc.size = new Vector3(0.5f, 0.5f, 0.5f);
            bc.center = new Vector3(0f, 0.5f, 0f);
        }

        rend = GetComponentInChildren<Renderer>();
        rend.material.color = bodyColor;
        anim = GetComponentInChildren<Animator>();

        if (WorldManager.Instance != null && WorldManager.Instance.IsBossDefeated("forest_boss"))
        {
            Destroy(gameObject);
            return;
        }

        hpBar = GetComponentInChildren<HPBarController>();
        if (hpBar != null) hpBar.Setup(maxHp);
    }

    void Update()
    {
        if (currentState == BossState.Dead) return;

        cooldownTimer -= Time.deltaTime;
        stateTimer -= Time.deltaTime;

        findTimer -= Time.deltaTime;
        if (playerCache == null || findTimer <= 0f)
        {
            playerCache = GameObject.FindGameObjectWithTag("Player");
            findTimer = 0.5f;
        }

        if (playerCache == null)
        {
            SetAnimSpeed(0f);
            return;
        }

        float distX = Mathf.Abs(playerCache.transform.position.x - transform.position.x);
        float dirX = playerCache.transform.position.x - transform.position.x;

        switch (currentState)
        {
            case BossState.Idle:
                SetAnimSpeed(0f);
                if (distX <= detectRange)
                    currentState = BossState.Chase;
                break;

            case BossState.Chase:
                {
                    float moveDir = dirX > 0f ? 1f : -1f;
                    transform.position += new Vector3(moveDir * chaseSpeed * Time.deltaTime, 0f, 0f);
                    SetAnimSpeed(1f);

                    if (moveDir > 0f && !facingRight) { facingRight = true; Flip(); }
                    if (moveDir < 0f && facingRight) { facingRight = false; Flip(); }

                    if (distX <= attackRange && cooldownTimer <= 0f)
                    {
                        currentState = BossState.Attack;
                        stateTimer = 0.7f;
                        cooldownTimer = attackCooldown;
                        SetAnimSpeed(0f);
                        if (anim != null) anim.SetTrigger("AttackTrigger");

                        PlayerStats ps = playerCache.GetComponent<PlayerStats>();
                        if (ps != null)
                        {
                            ps.TakeDamage(attackDamage);
                            ShowFloatText("-" + attackDamage, Color.red, playerCache.transform.position);
                        }
                    }
                    else if (distX > detectRange * 1.3f)
                    {
                        currentState = BossState.Idle;
                    }
                    break;
                }

            case BossState.Attack:
                SetAnimSpeed(0f);
                if (dirX > 0f && !facingRight) { facingRight = true; Flip(); }
                if (dirX < 0f && facingRight) { facingRight = false; Flip(); }
                if (stateTimer <= 0f)
                    currentState = BossState.Chase;
                break;

            case BossState.Hurt:
                SetAnimSpeed(0f);
                if (stateTimer <= 0f)
                    currentState = BossState.Chase;
                break;
        }
    }

    private void SetAnimSpeed(float speed)
    {
        if (anim != null) anim.SetFloat("Speed", speed);
    }

    public void TakeDamage(int amount)
    {
        if (currentState == BossState.Dead) return;

        hp -= amount;
        hp = Mathf.Max(hp, 0);
        StartCoroutine(FlashWhite());

        if (hpBar != null) hpBar.UpdateBar(hp);

        if (hp <= 0)
        {
            currentState = BossState.Dead;
            OnDeath?.Invoke();
            if (QuestManager.Instance != null)
                QuestManager.Instance.OnBossDefeated();
            if (WorldManager.Instance != null)
                WorldManager.Instance.DefeatBoss("forest_boss");
            if (anim != null) { anim.SetTrigger("DeathTrigger"); SetAnimSpeed(0f); }
            Collider[] cols = GetComponentsInChildren<Collider>();
            foreach (var c in cols) c.enabled = false;
            Destroy(gameObject, 1.5f);
            return;
        }

        if (anim != null) anim.SetTrigger("HurtTrigger");
        currentState = BossState.Hurt;
        stateTimer = 0.25f;

        if (SaveManager.Instance != null) SaveManager.Instance.Save();
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
            body.localRotation = facingRight ? Quaternion.identity : Quaternion.Euler(0f, 180f, 0f);
    }
}