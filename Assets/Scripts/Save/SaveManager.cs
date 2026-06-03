using UnityEngine;
using System.IO;
using System.Collections.Generic;

public class SaveManager : MonoBehaviour
{
    public static SaveManager Instance { get; private set; }

    private string savePath;

    void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        DontDestroyOnLoad(gameObject);
        savePath = Path.Combine(Application.persistentDataPath, "save.json");
    }

    // ── 存档 ──
    public void Save()
    {
        SaveData data = new SaveData();

        // 玩家
        GameObject player = GameObject.FindGameObjectWithTag("Player");
        if (player != null)
        {
            data.playerPosX = player.transform.position.x;
            data.playerPosY = player.transform.position.y;
            data.playerPosZ = player.transform.position.z;

            PlayerStats ps = player.GetComponent<PlayerStats>();
            if (ps != null) data.playerHp = ps.hp;

            PlayerController pc = player.GetComponent<PlayerController>();
            // facingRight是private，后面加个public属性
        }

        // 世界
        WorldManager wm = WorldManager.Instance;
        if (wm != null)
        {
            data.discoveredPOIs = new List<string>(wm.GetDiscoveredPOIs());
            data.unlockedTeleports = new List<string>(wm.GetUnlockedTeleports());
            data.defeatedBosses = new List<string>(wm.GetDefeatedBosses());

            foreach (var kvp in wm.GetMaterials())
            {
                data.materials.Add(new MaterialEntry { itemId = kvp.Key, count = kvp.Value });
            }
        }

        // 任务
        QuestManager qm = QuestManager.Instance;
        if (qm != null)
        {
            data.questStep = (int)qm.currentStep;
            data.enemiesKilled = qm.enemiesKilled;
            data.sporesCollected = qm.sporesCollected;
        }

        // 写入文件
        string json = JsonUtility.ToJson(data, true);
        File.WriteAllText(savePath, json);
        Debug.Log($"[SaveManager] 存档成功 → {savePath}");
    }

    // ── 读档 ──
    public bool Load()
    {
        if (!File.Exists(savePath))
        {
            Debug.Log("[SaveManager] 没有存档文件");
            return false;
        }

        string json = File.ReadAllText(savePath);
        SaveData data = JsonUtility.FromJson<SaveData>(json);

        // 玩家
        GameObject player = GameObject.FindGameObjectWithTag("Player");
        if (player != null)
        {
            player.transform.position = new Vector3(data.playerPosX, data.playerPosY, data.playerPosZ);

            PlayerStats ps = player.GetComponent<PlayerStats>();
            if (ps != null) ps.hp = data.playerHp;

            CharacterController cc = player.GetComponent<CharacterController>();
            if (cc != null) cc.enabled = false;
            player.transform.position = new Vector3(data.playerPosX, data.playerPosY, data.playerPosZ);
            if (cc != null) cc.enabled = true;
        }

        // 世界
        WorldManager wm = WorldManager.Instance;
        if (wm != null)
        {
            wm.GetDiscoveredPOIs().Clear();
            foreach (string id in data.discoveredPOIs) wm.GetDiscoveredPOIs().Add(id);

            wm.GetUnlockedTeleports().Clear();
            foreach (string id in data.unlockedTeleports) wm.GetUnlockedTeleports().Add(id);

            wm.GetDefeatedBosses().Clear();
            foreach (string id in data.defeatedBosses) wm.GetDefeatedBosses().Add(id);

            wm.GetMaterials().Clear();
            foreach (MaterialEntry entry in data.materials)
                wm.GetMaterials()[entry.itemId] = entry.count;
        }

        // 任务
        QuestManager qm = QuestManager.Instance;
        if (qm != null)
        {
            qm.currentStep = (QuestStep)data.questStep;
            qm.enemiesKilled = data.enemiesKilled;
            qm.sporesCollected = data.sporesCollected;
        }

        Debug.Log("[SaveManager] 读档成功");
        return true;
    }

    // ── 删档 ──
    public void DeleteSave()
    {
        if (File.Exists(savePath))
        {
            File.Delete(savePath);
            Debug.Log("[SaveManager] 存档已删除");
        }
    }

    // ── 是否有存档 ──
    public bool HasSave()
    {
        return File.Exists(savePath);
    }
}