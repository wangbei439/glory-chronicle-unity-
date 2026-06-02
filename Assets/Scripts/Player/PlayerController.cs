using UnityEngine;
using System.Collections;

public class PlayerController : MonoBehaviour
{
    [Header("移动")]
    public float moveSpeed = 6f;
    public float gravity = -20f;

    [Header("攻击")]
    public float attackRange = 1.8f;
    public float attackDuration = 0.35f;
    public int attackDamage = 10;

    [Header("闪避")]
    public float dodgeDuration = 0.3f;
    public float dodgeSpeed = 12f;
    public float dodgeCooldown = 1f;

    private CharacterController cc;
    private Vector3 velocity;
    private bool isAttacking = false;
    private float attackTimer = 0f;
    private Renderer bodyRenderer;
    private Transform bodyTransform;
    private bool facingRight = true;
    private bool isDodging = false;
    private float dodgeTimer = 0f;
    private float dodgeCooldownTimer = 0f;
    private Vector3 dodgeDir;
    private CameraFollow camFollow;
    private Animator anim;

    void Start()
    {
        cc = GetComponent<CharacterController>();
        bodyTransform = transform.Find("Body");
        if (bodyTransform != null)
            bodyRenderer = bodyTransform.GetComponent<Renderer>();

        camFollow = Camera.main.GetComponent<CameraFollow>();
        anim = GetComponentInChildren<Animator>();
    }

    void Update()
    {
        HandleGravity();
        HandleDodge();
        HandleMovement();
        HandleAttack();
        FaceDirection();
    }

    void HandleGravity()
    {
        if (cc.isGrounded && velocity.y < 0)
            velocity.y = -2f;
        else
            velocity.y += gravity * Time.deltaTime;
    }

    void HandleDodge()
    {
        if (dodgeCooldownTimer > 0)
            dodgeCooldownTimer -= Time.deltaTime;

        if (isDodging)
        {
            dodgeTimer -= Time.deltaTime;
            cc.Move(dodgeDir * dodgeSpeed * Time.deltaTime);
            cc.Move(velocity * Time.deltaTime);

            if (dodgeTimer <= 0)
            {
                isDodging = false;
                dodgeCooldownTimer = dodgeCooldown;
            }
            return;
        }

        if (Input.GetKeyDown(KeyCode.K) && dodgeCooldownTimer <= 0 && !isAttacking)
        {
            isDodging = true;
            dodgeTimer = dodgeDuration;
            if (anim != null) anim.SetTrigger("DodgeTrigger");

            float h = Input.GetAxisRaw("Horizontal");
            float v = Input.GetAxisRaw("Vertical");
            if (h != 0 || v != 0)
                dodgeDir = new Vector3(h, 0, v).normalized;
            else
                dodgeDir = facingRight ? Vector3.right : Vector3.left;

            // 闪避时半透明
            if (bodyRenderer != null)
            {
                Color c = bodyRenderer.material.color;
                c.a = 0.4f;
                bodyRenderer.material.color = c;
            }
        }

        // 闪避结束恢复
        if (!isDodging && bodyRenderer != null && bodyRenderer.material.color.a < 1f)
        {
            Color c = bodyRenderer.material.color;
            c.a = 1f;
            bodyRenderer.material.color = c;
        }
    }

    void HandleMovement()
    {
        if (anim != null && !isAttacking && !isDodging && (Input.GetAxisRaw("Horizontal") == 0 && Input.GetAxisRaw("Vertical") == 0))
            anim.SetFloat("Speed", 0f);
        if (isAttacking || isDodging) return;

        float h = Input.GetAxisRaw("Horizontal");
        float v = Input.GetAxisRaw("Vertical");
        Vector3 dir = new Vector3(h, 0, v).normalized;

        if (dir.magnitude > 0f)
        {
            Vector3 move = dir * moveSpeed;
            cc.Move(move * Time.deltaTime);
            if (anim != null) anim.SetFloat("Speed", dir.magnitude);
        }

        cc.Move(velocity * Time.deltaTime);
    }

    void HandleAttack()
    {
        if (isAttacking)
        {
            attackTimer -= Time.deltaTime;
            if (attackTimer <= 0f)
                isAttacking = false;
            return;
        }

        if (isDodging) return;

        if (Input.GetKeyDown(KeyCode.J))
        {
            isAttacking = true;
            attackTimer = attackDuration;
            if (anim != null) anim.SetTrigger("AttackTrigger");
            StartCoroutine(FlashWhite());

            Collider[] hits = Physics.OverlapSphere(
                transform.position + transform.forward * 0.5f,
                attackRange,
                LayerMask.GetMask("Enemy")
            );

            bool hitSomething = false;

            foreach (var hit in hits)
            {
                Dummy dummy = hit.GetComponent<Dummy>();
                if (dummy != null)
                {
                    dummy.TakeDamage(attackDamage);
                    hitSomething = true;
                    PushBack(hit.transform);
                }

                Boss boss = hit.GetComponent<Boss>();
                if (boss != null)
                {
                    boss.TakeDamage(attackDamage);
                    hitSomething = true;
                    PushBack(hit.transform);
                }
            }

            if (hitSomething)
            {
                // 命中时震屏
                if (camFollow != null)
                    camFollow.Shake(0.15f, 0.2f);

                // 命中时顿帧
                StartCoroutine(Hitstop(0.06f));
            }
        }
    }

    IEnumerator FlashWhite()
    {
        if (bodyRenderer != null)
        {
            Color orig = bodyRenderer.material.color;
            bodyRenderer.material.color = Color.white;
            yield return new WaitForSeconds(0.08f);
            bodyRenderer.material.color = orig;
        }
    }

    IEnumerator Hitstop(float duration)
    {
        Time.timeScale = 0f;
        yield return new WaitForSecondsRealtime(duration);
        Time.timeScale = 1f;
    }

    void PushBack(Transform target)
    {
        // 击退效果：给敌人一个方向推力
        Vector3 pushDir = (target.position - transform.position).normalized;
        pushDir.y = 0;

        CharacterController targetCC = target.GetComponent<CharacterController>();
        if (targetCC != null)
        {
            targetCC.Move(pushDir * 0.5f);
        }
    }

    void FaceDirection()
    {
        float h = Input.GetAxisRaw("Horizontal");
        if (h > 0 && !facingRight)
        {
            facingRight = true;
            FlipBody();
        }
        else if (h < 0 && facingRight)
        {
            facingRight = false;
            FlipBody();
        }
    }

    void FlipBody()
    {
        if (bodyTransform != null)
        {
            bodyTransform.localRotation = facingRight
                ? Quaternion.identity
                : Quaternion.Euler(0f, 180f, 0f);
        }
    }
}