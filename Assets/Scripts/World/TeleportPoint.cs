using UnityEngine;
using System.Collections;

public class TeleportPoint : MonoBehaviour
{
    [Header("传送点设置")]
    public string teleportId = "forest_teleport";
    public string teleportName = "暗影森林传送点";
    public float activateRange = 2f;
    public Color inactiveColor = new Color(0.3f, 0.3f, 0.3f);
    public Color activeColor = new Color(0f, 0.8f, 1f);

    private bool isActivated = false;
    private Renderer rend;
    private GameObject promptObj;

    void Start()
    {
        rend = GetComponent<Renderer>();

        if (teleportId == "entrance_teleport")
        {
            isActivated = true;
            rend.material.color = activeColor;
            if (WorldManager.Instance != null)
                WorldManager.Instance.UnlockTeleport(teleportId);
            return;
        }

        if (WorldManager.Instance != null && WorldManager.Instance.IsTeleportUnlocked(teleportId))
        {
            isActivated = true;
            rend.material.color = activeColor;
        }
        else
        {
            rend.material.color = inactiveColor;
        }
    }

    void Update()
    {
        GameObject player = GameObject.FindGameObjectWithTag("Player");
        if (player == null) return;

        float dist = Vector3.Distance(player.transform.position, transform.position);

        if (!isActivated)
        {
            if (dist <= activateRange)
            {
                if (promptObj == null)
                    ShowPrompt("[E] 激活传送点");

                if (Input.GetKeyDown(KeyCode.E))
                    Activate();
            }
            else
            {
                HidePrompt();
            }
        }
        else
        {
            if (dist <= activateRange)
            {
                if (promptObj == null)
                    ShowPrompt("[E] 传送");

                if (Input.GetKeyDown(KeyCode.E))
                    TeleportPlayer(player);
            }
            else
            {
                HidePrompt();
            }
        }
    }

    void Activate()
    {
        isActivated = true;
        rend.material.color = activeColor;

        if (WorldManager.Instance != null)
            WorldManager.Instance.UnlockTeleport(teleportId);

        ShowFloatText("已激活: " + teleportName, Color.cyan);
    }

    void TeleportPlayer(GameObject player)
    {
        TeleportPoint[] allPoints = FindObjectsOfType<TeleportPoint>();
        foreach (var point in allPoints)
        {
            if (point != this && point.isActivated)
            {
                StartCoroutine(DoTeleport(player, point));
                return;
            }
        }

        ShowFloatText("没有可用的传送点", Color.red);
    }

    IEnumerator DoTeleport(GameObject player, TeleportPoint destination)
    {
        // 关键修复：禁用CC后，设置位置，等一帧再重新启用CC
        CharacterController cc = player.GetComponent<CharacterController>();
        if (cc != null) cc.enabled = false;

        // 传送到目标传送点旁边
        player.transform.position = destination.transform.position + Vector3.forward * 1.5f;

        // 重置玩家的下落速度，防止传送后继续下落
        PlayerController pc = player.GetComponent<PlayerController>();
        if (pc != null) pc.ResetVelocity();

        // 等一帧，让CC内部状态更新
        yield return null;

        if (cc != null) cc.enabled = true;

        ShowFloatText("传送到: " + destination.teleportName, Color.cyan);

        if (SaveManager.Instance != null) SaveManager.Instance.Save();
    }

    void ShowPrompt(string text)
    {
        promptObj = new GameObject("TeleportPrompt");
        promptObj.transform.position = transform.position + Vector3.up * 1.5f;
        TextMesh tm = promptObj.AddComponent<TextMesh>();
        tm.text = text;
        tm.fontSize = 10;
        tm.color = Color.yellow;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        FloatText ft = promptObj.AddComponent<FloatText>();
        ft.floatSpeed = 0f;
        ft.lifetime = 999f;
    }

    void HidePrompt()
    {
        if (promptObj != null)
        {
            Destroy(promptObj);
            promptObj = null;
        }
    }

    void ShowFloatText(string text, Color color)
    {
        GameObject obj = new GameObject("TeleportText");
        obj.transform.position = transform.position + Vector3.up * 2f;
        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = text;
        tm.fontSize = 10;
        tm.color = color;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        FloatText ft = obj.AddComponent<FloatText>();
        ft.floatSpeed = 1.5f;
        ft.lifetime = 1.5f;
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = isActivated ? activeColor : inactiveColor;
        Gizmos.DrawWireSphere(transform.position, activateRange);
    }
    public bool IsActivated()
    {
        return isActivated;
    }
}