using UnityEngine;
using System.Collections;

public class POI : MonoBehaviour
{
    [Header("兴趣点信息")]
    public string poiId = "abandoned_camp";
    public string poiName = "废弃营地";
    public float discoverRadius = 3f;
    public Color poiColor = Color.cyan;

    private bool isDiscovered = false;

    void Start()
    {
        if (WorldManager.Instance != null && WorldManager.Instance.IsPOIDiscovered(poiId))
        {
            isDiscovered = true;
        }
    }

    void Update()
    {
        if (isDiscovered) return;

        GameObject player = GameObject.FindGameObjectWithTag("Player");
        if (player == null) return;

        float dist = Vector3.Distance(player.transform.position, transform.position);
        if (dist <= discoverRadius)
        {
            Discover();
        }
    }

    void Discover()
    {
        isDiscovered = true;

        if (WorldManager.Instance != null)
            WorldManager.Instance.DiscoverPOI(poiId);

        ShowDiscoverPrompt();
    }

    void ShowDiscoverPrompt()
    {
        GameObject obj = new GameObject("DiscoverText");
        obj.transform.position = transform.position + Vector3.up * 2f;

        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = "发现: " + poiName;
        tm.fontSize = 6;
        tm.color = Color.cyan;
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
        Gizmos.color = isDiscovered ? Color.gray : poiColor;
        Gizmos.DrawWireSphere(transform.position, discoverRadius);
    }
}