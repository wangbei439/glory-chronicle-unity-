using UnityEngine;
using System.Collections;

public class Dummy : MonoBehaviour
{
    [Header(" Ù–‘")]
    public int hp = 100;
    public int maxHp = 100;
    public int attackDamage = 10;
    public Color bodyColor = new Color(0.2f, 0.7f, 0.2f);

    [Header("AI")]
    public float detectRange = 6f;
    public float chaseSpeed = 2.5f;
    public float attackRange = 1.5f;
    public float attackCooldown = 1.5f;
    public float loseSightRange = 10f;

    public event System.Action OnDeath;

    private Animator anim;
    private Renderer rend;
    private HPBarController hpBar;
    private float cooldownTimer = 0f;
    private bool facingRight = true;
    private GameObject playerCache;
    private float findTimer = 0f;

    private enum EnemyState { Idle, Chase, Attack, Hurt, Dead }
    private EnemyState currentState = EnemyState.Idle;
    private float stateTimer = 0f;

    void Start()
    {
        Collider col = GetComponent<Collider>();
        if (col != null) { col.isTrigger = true; }
        else { BoxCollider bc = gameObject.AddComponent<BoxCollider>(); bc.isTrigger = true; bc.size = new Vector3(0.23f, 0.18f, 0.2f); }

        Collider[] childCols = GetComponentsInChildren<Collider>();
        foreach (var c in childCols) { if (c.gameObject != gameObject) Destroy(c); }

        rend = GetComponentInChildren<Renderer>();
        rend.material.color = bodyColor;
        anim = GetComponentInChildren<Animator>();
        hpBar = GetComponentInChildren<HPBarController>();
        if (hpBar != null) hpBar.Setup(maxHp);
    }

    void Update()
    {
        if (currentState == EnemyState.Dead) return;

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
        float distZ = Mathf.Abs(playerCache.transform.position.z - transform.position.z);
        float dist = Vector3.Distance(playerCache.transform.position, transform.position);
        float dirX = playerCache.transform.position.x - transform.position.x;
        float dirZ = playerCache.transform.position.z - transform.position.z;

        switch (currentState)
        {
            case EnemyState.Idle:
                SetAnimSpeed(0f);
                if (dist <= detectRange)
                    currentState = EnemyState.Chase;
                break;

            case EnemyState.Chase:
                {
                    Vector3 dir = new Vector3(dirX, 0f, dirZ).normalized;
                    transform.position += dir * chaseSpeed * Time.deltaTime;
                    SetAnimSpeed(1f);

                    if (dirX > 0.1f && !facingRight) { facingRight = true; Flip(); }
                    if (dirX < -0.1f && facingRight) { facingRight = false; Flip(); }

                    if (dist <= attackRange && cooldownTimer <= 0f)
                    {
                        currentState = EnemyState.Attack;
                        stateTimer = 0.5f;
                        cooldownTimer = attackCooldown;
                        SetAnimSpeed(0f);
                        if (anim != null) anim.SetTrigger("AttackTrigger");

                        PlayerStats ps = playerCache.GetComponent<PlayerStats>();
                        if (ps != null)
                        {
                            ps.TakeDamage(attackDamage);
                        }
                    }
                    else if (dist > loseSightRange)
                    {
                        currentState = EnemyState.Idle;
                    }
                    break;
                }

            case EnemyState.Attack:
                SetAnimSpeed(0f);
                if (dirX > 0.1f && !facingRight) { facingRight = true; Flip(); }
                if (dirX < -0.1f && facingRight) { facingRight = false; Flip(); }
                if (stateTimer <= 0f)
                    currentState = EnemyState.Chase;
                break;

            case EnemyState.Hurt:
                SetAnimSpeed(0f);
                if (stateTimer <= 0f)
                    currentState = EnemyState.Chase;
                break;
        }
    }

    private void SetAnimSpeed(float speed)
    {
        if (anim != null) anim.SetFloat("Speed", speed);
    }

    public void TakeDamage(int amount)
    {
        if (currentState == EnemyState.Dead) return;

        hp -= amount;
        hp = Mathf.Max(hp, 0);
        ShowDamageNumber(amount);
        StartCoroutine(FlashRed());
        if (anim != null) anim.SetTrigger("HurtTrigger");

        if (hpBar != null) hpBar.UpdateBar(hp);

        if (hp <= 0)
        {
            currentState = EnemyState.Dead;
            OnDeath?.Invoke();
            if (QuestManager.Instance != null)
                QuestManager.Instance.OnEnemyKilled();
            if (anim != null) { anim.SetTrigger("DeathTrigger"); SetAnimSpeed(0f); }
            Collider[] cols = GetComponentsInChildren<Collider>();
            foreach (var c in cols) c.enabled = false;
            Destroy(gameObject, 0.6f);
            return;
        }

        currentState = EnemyState.Hurt;
        stateTimer = 0.2f;

        if (SaveManager.Instance != null) SaveManager.Instance.Save();
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
        obj.transform.localScale = Vector3.one * 0.5f;
        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = amount.ToString();
        tm.fontSize = 80;
        tm.color = Color.yellow;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        tm.characterSize = 0.1f;
        FloatText ft = obj.AddComponent<FloatText>();
        ft.floatSpeed = 2f;
        ft.lifetime = 0.8f;
    }

    void Flip()
    {
        Transform body = transform.Find("Body");
        if (body != null)
            body.localRotation = facingRight ? Quaternion.identity : Quaternion.Euler(0f, 180f, 0f);
    }
}