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

        // 入口传送点默认激活
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
            // 未激活：显示激活提示
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
            // 已激活：显示传送提示
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
        // 找到另一个已激活的传送点
        TeleportPoint[] allPoints = FindObjectsOfType<TeleportPoint>();
        foreach (var point in allPoints)
        {
            if (point != this && point.isActivated)
            {
                // 传送到另一个点
                CharacterController cc = player.GetComponent<CharacterController>();
                if (cc != null) cc.enabled = false;

                player.transform.position = point.transform.position + Vector3.forward * 1.5f;

                if (cc != null) cc.enabled = true;

                ShowFloatText("传送到: " + point.teleportName, Color.cyan);
                return;
            }
        }

        ShowFloatText("没有可用的传送点", Color.red);
        if (SaveManager.Instance != null) SaveManager.Instance.Save();
    }

    void ShowPrompt(string text)
    {
        promptObj = new GameObject("Prompt");
        promptObj.transform.position = transform.position + Vector3.up * 1.5f;

        TextMesh tm = promptObj.AddComponent<TextMesh>();
        tm.text = text;
        tm.fontSize = 5;
        tm.color = Color.white;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
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
        tm.fontSize = 6;
        tm.color = color;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;

        StartCoroutine(FloatAndFade(obj, tm));
    }

    IEnumerator FloatAndFade(GameObject obj, TextMesh tm)
    {
        float timer = 0f;
        float lifetime = 2f;
        Vector3 startPos = obj.transform.position;

        while (timer < lifetime)
        {
            timer += Time.deltaTime;
            obj.transform.position = startPos + Vector3.up * (timer * 0.5f);

            Color c = tm.color;
            c.a = 1f - (timer / lifetime);
            tm.color = c;

            yield return null;
        }
        Destroy(obj);
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = isActivated ? Color.cyan : Color.gray;
        Gizmos.DrawWireSphere(transform.position, activateRange);
    }
}