using UnityEngine;

public class PlayerStats : MonoBehaviour
{
    public int maxHp = 100;
    public int hp = 100;

    public void TakeDamage(int amount)
    {
        hp -= amount;
        hp = Mathf.Max(hp, 0);
        Debug.Log("玩家受伤! -" + amount + " HP: " + hp + "/" + maxHp);

        Animator anim = GetComponentInChildren<Animator>();
        if (hp <= 0)
        {
            if (anim != null) anim.SetTrigger("DeathTrigger");
            Debug.Log("玩家阵亡!");
            hp = maxHp;

            // 复活到最近的已激活传送点，而不是固定中心点
            RespawnAtTeleportPoint();

            Debug.Log("已复活");
            if (anim != null) anim.SetTrigger("IdleTrigger");
        }
        else
        {
            if (anim != null) anim.SetTrigger("HurtTrigger");
        }
    }

    void RespawnAtTeleportPoint()
    {
        TeleportPoint[] allPoints = FindObjectsOfType<TeleportPoint>();
        TeleportPoint nearest = null;
        float minDist = float.MaxValue;

        foreach (var point in allPoints)
        {
            if (point.IsActivated())
            {
                float dist = Vector3.Distance(transform.position, point.transform.position);
                if (dist < minDist)
                {
                    minDist = dist;
                    nearest = point;
                }
            }
        }

        if (nearest != null)
        {
            CharacterController cc = GetComponent<CharacterController>();
            if (cc != null) cc.enabled = false;
            transform.position = nearest.transform.position + Vector3.forward * 1.5f;
            PlayerController pc = GetComponent<PlayerController>();
            if (pc != null) pc.ResetVelocity();
            if (cc != null) cc.enabled = true;
        }
        else
        {
            // 没有激活的传送点，才用默认位置
            transform.position = Vector3.up;
        }
    }
}