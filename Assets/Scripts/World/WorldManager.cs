using UnityEngine;
using System.Collections.Generic;

public class WorldManager : MonoBehaviour
{
    public static WorldManager Instance;

    private HashSet<string> discoveredPOIs = new HashSet<string>();
    private HashSet<string> unlockedTeleports = new HashSet<string>();
    private HashSet<string> defeatedBosses = new HashSet<string>();
    private Dictionary<string, int> materials = new Dictionary<string, int>();

    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }

    public bool IsPOIDiscovered(string poiId)
    {
        return discoveredPOIs.Contains(poiId);
    }

    public void DiscoverPOI(string poiId)
    {
        if (!discoveredPOIs.Contains(poiId))
        {
            discoveredPOIs.Add(poiId);
            Debug.Log("发现兴趣点: " + poiId);
        }
    }

    public bool IsTeleportUnlocked(string teleportId)
    {
        return unlockedTeleports.Contains(teleportId);
    }

    public void UnlockTeleport(string teleportId)
    {
        if (!unlockedTeleports.Contains(teleportId))
        {
            unlockedTeleports.Add(teleportId);
            Debug.Log("解锁传送点: " + teleportId);
        }
    }

    public bool IsBossDefeated(string bossId)
    {
        return defeatedBosses.Contains(bossId);
    }

    public void DefeatBoss(string bossId)
    {
        if (!defeatedBosses.Contains(bossId))
        {
            defeatedBosses.Add(bossId);
            Debug.Log("击败Boss: " + bossId);
        }
    }

    public void AddMaterial(string itemId)
    {
        if (!materials.ContainsKey(itemId))
            materials[itemId] = 0;
        materials[itemId]++;
        Debug.Log("获得材料: " + itemId + " 数量: " + materials[itemId]);
    }

    public int GetMaterialCount(string itemId)
    {
        if (materials.ContainsKey(itemId))
            return materials[itemId];
        return 0;
    }
}