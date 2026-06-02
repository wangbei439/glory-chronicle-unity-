using UnityEngine;
using System.Collections;

public class FloatText : MonoBehaviour
{
    public float floatSpeed = 2f;
    public float lifetime = 0.8f;

    private TextMesh tm;
    private Vector3 startPos;

    void Awake()
    {
        tm = GetComponent<TextMesh>();
        startPos = transform.position;
    }

    void Start()
    {
        StartCoroutine(Run());
    }

    IEnumerator Run()
    {
        float timer = 0f;

        while (timer < lifetime)
        {
            timer += Time.deltaTime;
            transform.position = startPos + Vector3.up * (timer * floatSpeed);

            Color c = tm.color;
            c.a = 1f - (timer / lifetime);
            tm.color = c;

            yield return null;
        }

        Destroy(gameObject);
    }
}