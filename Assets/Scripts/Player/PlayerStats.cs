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
            RespawnAtTeleportPoint();
            if (anim != null) anim.SetTrigger("IdleTrigger");
            Debug.Log("已复活");
        }
        else
        {
            if (anim != null) anim.SetTrigger("HurtTrigger");
        }
    }

    void RespawnAtTeleportPoint()
    {
        PlayerController pc = GetComponent<PlayerController>();

        if (pc != null) pc.BeginTeleport();

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
            transform.position = nearest.transform.position;
        else
            transform.position = Vector3.up;

        Physics.SyncTransforms();

        if (pc != null)
        {
            pc.ResetVelocity();
            pc.EndTeleport();
        }
    }
}