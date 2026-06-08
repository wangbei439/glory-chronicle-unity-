using UnityEngine;
using System.Collections;

public class HubNPC : MonoBehaviour
{
    public float interactRange = 2f;
    private GameObject promptObj;
    private bool hasGivenReward = false;

    void Update()
    {
        GameObject player = GameObject.FindGameObjectWithTag("Player");
        if (player == null) return;

        float dist = Vector3.Distance(player.transform.position, transform.position);

        if (dist <= interactRange)
        {
            if (promptObj == null)
                ShowPrompt();

            if (Input.GetKeyDown(KeyCode.E))
            {
                Interact();
            }
        }
        else
        {
            if (promptObj != null)
            {
                Destroy(promptObj);
                promptObj = null;
            }
        }
    }

    void Interact()
    {
        if (QuestManager.Instance == null) return;

        if (QuestManager.Instance.currentStep == QuestStep.TalkToNPC)
        {
            QuestManager.Instance.currentStep = QuestStep.ReachCamp;
            ShowFloatText("去探索暗影森林吧!", Color.cyan);
        }
        else if (QuestManager.Instance.currentStep == QuestStep.ReturnToHub && !hasGivenReward)
        {
            hasGivenReward = true;
            QuestManager.Instance.currentStep = QuestStep.Complete;
            ShowFloatText("任务完成! 获得奖励!", Color.yellow);
            Debug.Log("===== 任务完成: 林边低语 =====");
        }
        else
        {
            string hint = QuestManager.Instance.GetStepHint(QuestManager.Instance.currentStep);
            ShowFloatText(hint, Color.white);
        }
    }

    void ShowPrompt()
    {
        if (promptObj != null) return;
        promptObj = new GameObject("Prompt");
        promptObj.transform.position = transform.position + Vector3.up * 1.8f;
        promptObj.transform.localScale = Vector3.one * 0.5f;
        TextMesh tm = promptObj.AddComponent<TextMesh>();
        tm.text = "[E] 对话";
        tm.fontSize = 80;
        tm.color = Color.white;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        tm.characterSize = 0.1f;
    }

    void ShowFloatText(string text, Color color)
    {
        GameObject obj = new GameObject("NPCText");
        obj.transform.position = transform.position + Vector3.up * 2.5f;
        obj.transform.localScale = Vector3.one * 0.5f;
        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = text;
        tm.fontSize = 80;
        tm.color = color;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;
        tm.characterSize = 0.1f;
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
}