using UnityEngine;

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

    // 静态锁：防止同一帧多个传送点同时触发
    private static bool isTeleportLocked = false;

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

                if (Input.GetKeyDown(KeyCode.E) && !isTeleportLocked)
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
        // 上锁，防止同帧另一个传送点也触发
        isTeleportLocked = true;

        TeleportPoint[] allPoints = FindObjectsOfType<TeleportPoint>();

        foreach (var point in allPoints)
        {
            if (point != this && point.isActivated)
            {
                DoTeleport(player, point);
                return;
            }
        }

        ShowFloatText("没有可用的传送点", Color.red);
        isTeleportLocked = false;
    }

    void DoTeleport(GameObject player, TeleportPoint destination)
    {
        PlayerController pc = player.GetComponent<PlayerController>();

        if (pc != null) pc.BeginTeleport();

        player.transform.position = destination.transform.position;
        Physics.SyncTransforms();

        if (pc != null)
        {
            pc.ResetVelocity();
            pc.EndTeleport();
        }

        Debug.Log("[Teleport] 传送到: " + destination.teleportName + " pos=" + player.transform.position);

        ShowFloatText("传送到: " + destination.teleportName, Color.cyan);

        if (SaveManager.Instance != null) SaveManager.Instance.Save();

        // 延迟解锁，防止到达后立刻又被传送
        Invoke("UnlockTeleport", 0.5f);
    }

    void UnlockTeleport()
    {
        isTeleportLocked = false;
    }

    void ShowPrompt(string text)
    {
        promptObj = new GameObject("TeleportPrompt");
        promptObj.transform.position = transform.position + Vector3.up * 1.5f;
        promptObj.transform.localScale = Vector3.one * 0.5f;
        TextMesh tm = promptObj.AddComponent<TextMesh>();
        tm.text = text;
        tm.fontSize = 80;
        tm.color = Color.yellow;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        tm.characterSize = 0.1f;
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
        obj.transform.localScale = Vector3.one * 0.5f;
        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = text;
        tm.fontSize = 80;
        tm.color = color;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        tm.characterSize = 0.1f;
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