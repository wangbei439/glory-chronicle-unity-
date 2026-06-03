using System;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class SaveData
{
    // ── 玩家 ──
    public float playerPosX, playerPosY, playerPosZ;
    public int playerHp;
    public bool playerFacingRight;

    // ── 世界 ──
    public List<string> discoveredPOIs = new List<string>();
    public List<string> unlockedTeleports = new List<string>();
    public List<string> defeatedBosses = new List<string>();
    public List<MaterialEntry> materials = new List<MaterialEntry>();

    // ── 任务 ──
    public int questStep;           // QuestStep转int
    public int enemiesKilled;
    public int sporesCollected;
}

[Serializable]
public class MaterialEntry
{
    public string itemId;
    public int count;
}