using UnityEngine;
using System.Collections;

public enum QuestStep
{
    None,
    TalkToNPC,          // 跟NPC对话
    ReachCamp,          // 到达废弃营地
    KillEnemies,        // 击杀3个森林生物
    HarvestSpores,      // 采集2个孢子团
    ActivateTeleport,   // 激活传送点
    InvestigateShrine,  // 调查腐蚀神殿
    DefeatBoss,         // 击败区域Boss
    ReturnToHub,        // 返回据点
    Complete            // 完成
}

public class QuestManager : MonoBehaviour
{
    public static QuestManager Instance;

    [Header("当前任务")]
    public string questName = "林边低语";
    public QuestStep currentStep = QuestStep.TalkToNPC;

    [Header("计数器")]
    public int enemiesKilled = 0;
    public int sporesCollected = 0;
    public int requiredKills = 3;
    public int requiredSpores = 2;

    private GameObject promptObj;

    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    void Start()
    {
        ShowStepPrompt();
    }

    void Update()
    {
        CheckProgress();

        // 按Tab查看当前任务
        if (Input.GetKeyDown(KeyCode.Tab))
        {
            ShowQuestLog();
        }
    }

    void CheckProgress()
    {
        switch (currentStep)
        {
            case QuestStep.ReachCamp:
                if (WorldManager.Instance != null && WorldManager.Instance.IsPOIDiscovered("abandoned_camp"))
                    AdvanceStep(QuestStep.KillEnemies);
                break;

            case QuestStep.KillEnemies:
                if (enemiesKilled >= requiredKills)
                    AdvanceStep(QuestStep.HarvestSpores);
                break;

            case QuestStep.HarvestSpores:
                if (sporesCollected >= requiredSpores)
                    AdvanceStep(QuestStep.ActivateTeleport);
                break;

            case QuestStep.ActivateTeleport:
                if (WorldManager.Instance != null && WorldManager.Instance.IsTeleportUnlocked("forest_teleport"))
                    AdvanceStep(QuestStep.InvestigateShrine);
                break;

            case QuestStep.InvestigateShrine:
                if (WorldManager.Instance != null && WorldManager.Instance.IsPOIDiscovered("corrupted_shrine"))
                    AdvanceStep(QuestStep.DefeatBoss);
                break;
        }
    }

    void AdvanceStep(QuestStep newStep)
    {
        currentStep = newStep;
        ShowFloatText(GetStepDescription(newStep), Color.cyan);
        ShowStepPrompt();

        if (newStep == QuestStep.Complete)
        {
            Debug.Log("任务完成: " + questName);
        }
    }

    public void OnEnemyKilled()
    {
        if (currentStep == QuestStep.KillEnemies)
        {
            enemiesKilled++;
            Debug.Log("击杀进度: " + enemiesKilled + "/" + requiredKills);
        }
    }

    public void OnSporeCollected()
    {
        if (currentStep == QuestStep.HarvestSpores)
        {
            sporesCollected++;
            Debug.Log("采集进度: " + sporesCollected + "/" + requiredSpores);
        }
    }

    public void OnBossDefeated()
    {
        if (currentStep == QuestStep.DefeatBoss)
        {
            AdvanceStep(QuestStep.ReturnToHub);
        }
    }

    string GetStepDescription(QuestStep step)
    {
        switch (step)
        {
            case QuestStep.TalkToNPC: return "任务开始: 前往废弃营地";
            case QuestStep.ReachCamp: return "到达废弃营地";
            case QuestStep.KillEnemies: return "击杀森林生物 (" + enemiesKilled + "/" + requiredKills + ")";
            case QuestStep.HarvestSpores: return "采集孢子团 (" + sporesCollected + "/" + requiredSpores + ")";
            case QuestStep.ActivateTeleport: return "激活传送点";
            case QuestStep.InvestigateShrine: return "调查腐蚀神殿";
            case QuestStep.DefeatBoss: return "击败区域Boss";
            case QuestStep.ReturnToHub: return "返回据点领取奖励";
            case QuestStep.Complete: return "任务完成!";
            default: return "";
        }
    }

    public string GetStepHint(QuestStep step)
    {
        switch (step)
        {
            case QuestStep.TalkToNPC: return "前往废弃营地";
            case QuestStep.ReachCamp: return "探索废弃营地";
            case QuestStep.KillEnemies: return "击杀敌人 " + enemiesKilled + "/" + requiredKills;
            case QuestStep.HarvestSpores: return "采集孢子 " + sporesCollected + "/" + requiredSpores;
            case QuestStep.ActivateTeleport: return "找到并激活传送点";
            case QuestStep.InvestigateShrine: return "前往腐蚀神殿";
            case QuestStep.DefeatBoss: return "击败区域Boss";
            case QuestStep.ReturnToHub: return "返回据点";
            case QuestStep.Complete: return "任务已完成";
            default: return "";
        }
    }

    void ShowStepPrompt()
    {
        // UI提示后续做，先用Tab键查看
    }

    void ShowQuestLog()
    {
        string log = "===== " + questName + " =====\n";
        log += "当前目标: " + GetStepHint(currentStep);
        if (currentStep == QuestStep.KillEnemies)
            log += "\n击杀: " + enemiesKilled + "/" + requiredKills;
        if (currentStep == QuestStep.HarvestSpores)
            log += "\n采集: " + sporesCollected + "/" + requiredSpores;

        Debug.Log(log);
        ShowFloatText(GetStepHint(currentStep), Color.white);
    }

    void ShowFloatText(string text, Color color)
    {
        GameObject obj = new GameObject("QuestText");
        obj.transform.position = GameObject.FindGameObjectWithTag("Player").transform.position + Vector3.up * 2.5f;

        TextMesh tm = obj.AddComponent<TextMesh>();
        tm.text = text;
        tm.fontSize = 5;
        tm.color = color;
        tm.alignment = TextAlignment.Center;
        tm.anchor = TextAnchor.MiddleCenter;

        StartCoroutine(FloatAndFade(obj, tm, 2f));
    }

    IEnumerator FloatAndFade(GameObject obj, TextMesh tm, float lifetime)
    {
        float timer = 0f;
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