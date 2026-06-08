using UnityEngine;
using System.Collections;

public class HarvestNode : MonoBehaviour
{
    [Header("采集设置")]
    public string itemId = "spore_cluster";
    public string itemName = "孢子团";
    public float collectRange = 2f;
    public float cooldownTime = 10f;
    public Color nodeColor = new Color(1f, 0.8f, 0f);
    public Color cooldownColor = new Color(0.3f, 0.3f, 0.3f);

    private bool onCooldown = false;
    private Renderer rend;
    private GameObject promptObj;

    void Start()
    {
        rend = GetComponent<Renderer>();
        rend.material.color = nodeColor;
    }

    void Update()
    {
        if (onCooldown) return;

        GameObject player = GameObject.FindGameObjectWithTag("Player");
        if (player == null) return;

        float dist = Vector3.Distance(player.transform.position, transform.position);

        // 显示/隐藏提示
        if (dist <= collectRange)
        {
            if (promptObj == null)
                ShowPrompt();
        }
        else
        {
            if (promptObj != null)
            {
                Destroy(promptObj);
                promptObj = null;
            }
        }

        if (dist <= collectRange && Input.GetKeyDown(KeyCode.E))
        {
            Collect();
        }
    }

    void ShowPrompt()
    {
        if (promptObj != null) return;
        promptObj = new GameObject("Prompt");
        promptObj.transform.position = transform.position + Vector3.up * 1.5f;
        promptObj.transform.localScale = Vector3.one * 0.5f;
        TextMesh tm = promptObj.AddComponent<TextMesh>();
        tm.text = "[E] 采集";
        tm.fontSize = 80;
        tm.color = Color.white;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        tm.characterSize = 0.1f;
    }

    void Collect()
    {
        onCooldown = true;
        rend.material.color = cooldownColor;

        if (promptObj != null)
        {
            Destroy(promptObj);
            promptObj = null;
        }

        ShowCollectText();

        if (WorldManager.Instance != null)
            WorldManager.Instance.AddMaterial(itemId);
        if (QuestManager.Instance != null)
            QuestManager.Instance.OnSporeCollected();

        StartCoroutine(Cooldown());
    }

    void ShowCollectText()
    {
        GameObject obj = new GameObject("CollectText");
        obj.transform.position = transform.position + Vector3.up * 2f;
        obj.transform.localScale = Vector3.one * 0.5f;
        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = "+1 " + itemName;
        tm.fontSize = 80;
        tm.color = Color.yellow;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        tm.characterSize = 0.1f;
        StartCoroutine(FloatAndFade(obj, tm));
    }

    IEnumerator Cooldown()
    {
        yield return new WaitForSeconds(cooldownTime);
        onCooldown = false;
        rend.material.color = nodeColor;
    }

    IEnumerator FloatAndFade(GameObject obj, TextMesh tm)
    {
        float timer = 0f;
        float lifetime = 1.2f;
        Vector3 startPos = obj.transform.position;

        while (timer < lifetime)
        {
            timer += Time.deltaTime;
            obj.transform.position = startPos + Vector3.up * (timer * 1f);

            Color c = tm.color;
            c.a = 1f - (timer / lifetime);
            tm.color = c;

            yield return null;
        }
        Destroy(obj);
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = onCooldown ? Color.gray : Color.yellow;
        Gizmos.DrawWireSphere(transform.position, collectRange);
    }
}