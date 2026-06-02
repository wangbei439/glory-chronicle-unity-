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
            transform.position = Vector3.up;
            Debug.Log("已复活");
            if (anim != null) anim.SetTrigger("IdleTrigger");
        }
        else
        {
            if (anim != null) anim.SetTrigger("HurtTrigger");
        }
    }
}