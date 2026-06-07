using UnityEngine;
using UnityEditor;
using System.IO;

/// <summary>
/// 区域配置快速创建器
/// 菜单：Tools > Glory Chronicle > Create Default Regions
/// 一键创建6个区域的RegionConfig资产，基于中心辐射式地图设计
/// </summary>
public static class RegionConfigPresets
{
    private const string CONFIG_FOLDER = "Assets/ScriptableObjects/Regions";

    [MenuItem("Tools/Glory Chronicle/Create Default Regions", false, 101)]
    public static void CreateAllDefaultRegions()
    {
        if (!EditorUtility.DisplayDialog("创建默认区域配置",
            "将创建6个区域配置到 " + CONFIG_FOLDER + "\n已有同名文件会被跳过。\n\n是否继续？",
            "创建", "取消"))
            return;

        // 确保文件夹存在
        if (!Directory.Exists(CONFIG_FOLDER))
        {
            Directory.CreateDirectory(CONFIG_FOLDER);
            AssetDatabase.Refresh();
        }

        CreateHubConfig();
        CreateForestEntranceConfig();
        CreateForestClearingConfig();
        CreateAbandonedCampConfig();
        CreateSporeJungleConfig();
        CreateCorruptedShrineConfig();

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        EditorUtility.DisplayDialog("完成",
            "6个区域配置已创建！\n\n下一步：\n1. 选中每个配置，拖入对应模型Prefab\n2. 打开 Tools > Glory Chronicle > Map Generator\n3. 点击\"生成全部地图\"",
            "OK");
    }

    static RegionConfig CreateConfig(string fileName, string regionId, string regionName,
        Vector3 center, float radius, RegionType type, int dangerLevel,
        string[] connectedRegions, float structureDensity, float propDensity,
        float natureDensity, float decorationDensity, int seed)
    {
        string path = $"{CONFIG_FOLDER}/{fileName}.asset";

        // 跳过已存在的
        if (File.Exists(path))
        {
            Debug.Log($"[RegionPresets] 跳过已存在: {fileName}");
            return AssetDatabase.LoadAssetAtPath<RegionConfig>(path);
        }

        var cfg = ScriptableObject.CreateInstance<RegionConfig>();
        cfg.regionId = regionId;
        cfg.regionName = regionName;
        cfg.center = center;
        cfg.radius = radius;
        cfg.regionType = type;
        cfg.dangerLevel = dangerLevel;
        cfg.structureDensity = structureDensity;
        cfg.propDensity = propDensity;
        cfg.natureDensity = natureDensity;
        cfg.decorationDensity = decorationDensity;
        cfg.seed = seed;
        cfg.pathWidth = 4f;

        if (connectedRegions != null)
        {
            cfg.connectedRegions = new System.Collections.Generic.List<string>(connectedRegions);
        }

        AssetDatabase.CreateAsset(cfg, path);
        Debug.Log($"[RegionPresets] 创建: {regionName} @ {center}");
        return cfg;
    }

    static void CreateHubConfig()
    {
        var cfg = CreateConfig(
            "Region_Hub",
            "hub", "休息站",
            new Vector3(0, 0, 0), 15f,
            RegionType.Hub, 1,
            new[] { "forest_entrance" },
            0.4f, 0.6f, 0.2f, 0.1f,
            12345
        );

        // Hub特有：营火、帐篷放在中心
        cfg.structures = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                minScale = 1f, maxScale = 1f,
                needsCollider = true, randomRotation = false,
                minCount = 1, maxCount = 1,
                placementMode = PlacementMode.Center,
                minDistanceFromCenter = 2f
            },
            new PrefabEntry
            {
                minScale = 0.9f, maxScale = 1.1f,
                needsCollider = true, randomRotation = true,
                minCount = 2, maxCount = 3,
                placementMode = PlacementMode.Ring,
                minDistanceFromCenter = 5f,
                maxDistanceFromCenter = 8f
            }
        };

        cfg.props = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                minScale = 0.8f, maxScale = 1.2f,
                needsCollider = true, randomRotation = true,
                minCount = 3, maxCount = 6,
                placementMode = PlacementMode.Scatter,
                minDistanceFromCenter = 3f
            }
        };

        EditorUtility.SetDirty(cfg);
    }

    static void CreateForestEntranceConfig()
    {
        var cfg = CreateConfig(
            "Region_ForestEntrance",
            "forest_entrance", "幽暗森林外环",
            new Vector3(0, 0, 30), 25f,
            RegionType.Forest, 2,
            new[] { "hub", "forest_clearing", "deadwood", "mossy_path", "misty_trail" },
            0.2f, 0.3f, 0.8f, 0.7f,
            23456
        );

        cfg.natureObjects = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 枯树
                minScale = 0.8f, maxScale = 1.5f,
                needsCollider = true, randomRotation = true,
                minCount = 8, maxCount = 15,
                placementMode = PlacementMode.Scatter,
                minDistanceFromCenter = 5f
            },
            new PrefabEntry
            {
                // 苔藓石
                minScale = 0.5f, maxScale = 1.2f,
                needsCollider = true, randomRotation = true,
                minCount = 5, maxCount = 10,
                placementMode = PlacementMode.Scatter
            },
            new PrefabEntry
            {
                // 蘑菇
                minScale = 0.6f, maxScale = 1.3f,
                needsCollider = false, randomRotation = true,
                minCount = 4, maxCount = 8,
                placementMode = PlacementMode.Cluster,
                clusterRadius = 2f
            }
        };

        cfg.decorations = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 落叶/草
                minScale = 0.5f, maxScale = 1.5f,
                needsCollider = false, randomRotation = true,
                minCount = 10, maxCount = 20,
                placementMode = PlacementMode.Scatter
            }
        };

        EditorUtility.SetDirty(cfg);
    }

    static void CreateForestClearingConfig()
    {
        var cfg = CreateConfig(
            "Region_ForestClearing",
            "forest_clearing", "林间空地",
            new Vector3(50, 0, 10), 18f,
            RegionType.Clearing, 3,
            new[] { "forest_entrance", "abandoned_camp" },
            0.3f, 0.5f, 0.6f, 0.4f,
            34567
        );

        cfg.structures = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 篝火残迹/路障
                minScale = 0.9f, maxScale = 1.2f,
                needsCollider = true, randomRotation = true,
                minCount = 1, maxCount = 3,
                placementMode = PlacementMode.Cluster,
                clusterRadius = 4f
            }
        };

        cfg.natureObjects = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 大树
                minScale = 1f, maxScale = 1.8f,
                needsCollider = true, randomRotation = true,
                minCount = 3, maxCount = 6,
                placementMode = PlacementMode.Edge
            },
            new PrefabEntry
            {
                // 树桩
                minScale = 0.7f, maxScale = 1.1f,
                needsCollider = true, randomRotation = true,
                minCount = 2, maxCount = 5,
                placementMode = PlacementMode.Scatter
            }
        };

        EditorUtility.SetDirty(cfg);
    }

    static void CreateAbandonedCampConfig()
    {
        var cfg = CreateConfig(
            "Region_AbandonedCamp",
            "abandoned_camp", "废弃营地",
            new Vector3(25, 0, 55), 15f,
            RegionType.Camp, 3,
            new[] { "forest_clearing", "spore_jungle", "shadow_rift" },
            0.6f, 0.7f, 0.3f, 0.2f,
            45678
        );

        cfg.structures = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 破帐篷
                minScale = 0.9f, maxScale = 1.2f,
                needsCollider = true, randomRotation = true,
                minCount = 2, maxCount = 4,
                placementMode = PlacementMode.Cluster,
                clusterRadius = 6f,
                minDistanceFromCenter = 3f
            }
        };

        cfg.props = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 木桌椅/木桶/火把架
                minScale = 0.8f, maxScale = 1.1f,
                needsCollider = true, randomRotation = true,
                minCount = 4, maxCount = 8,
                placementMode = PlacementMode.Scatter,
                minDistanceFromCenter = 3f,
                maxDistanceFromCenter = 10f
            },
            new PrefabEntry
            {
                // 铁笼/枯井
                minScale = 0.9f, maxScale = 1.1f,
                needsCollider = true, randomRotation = false,
                minCount = 1, maxCount = 2,
                placementMode = PlacementMode.Edge
            }
        };

        EditorUtility.SetDirty(cfg);
    }

    static void CreateSporeJungleConfig()
    {
        var cfg = CreateConfig(
            "Region_SporeJungle",
            "spore_jungle", "孢子丛林",
            new Vector3(50, 0, 65), 20f,
            RegionType.Swamp, 4,
            new[] { "abandoned_camp", "corrupted_shrine" },
            0.2f, 0.3f, 0.9f, 0.8f,
            56789
        );

        cfg.natureObjects = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 巨型蘑菇
                minScale = 1.2f, maxScale = 2.5f,
                needsCollider = true, randomRotation = true,
                minCount = 4, maxCount = 8,
                placementMode = PlacementMode.Scatter,
                minDistanceFromCenter = 5f
            },
            new PrefabEntry
            {
                // 藤蔓
                minScale = 0.8f, maxScale = 1.5f,
                needsCollider = false, randomRotation = true,
                minCount = 5, maxCount = 10,
                placementMode = PlacementMode.Edge
            },
            new PrefabEntry
            {
                // 怪树
                minScale = 1f, maxScale = 2f,
                needsCollider = true, randomRotation = true,
                minCount = 3, maxCount = 6,
                placementMode = PlacementMode.Scatter
            }
        };

        cfg.decorations = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 孢子雾效果/小花
                minScale = 0.3f, maxScale = 0.8f,
                needsCollider = false, randomRotation = true,
                minCount = 15, maxCount = 25,
                placementMode = PlacementMode.Scatter
            }
        };

        EditorUtility.SetDirty(cfg);
    }

    static void CreateCorruptedShrineConfig()
    {
        var cfg = CreateConfig(
            "Region_CorruptedShrine",
            "corrupted_shrine", "腐化神殿",
            new Vector3(10, 0, 110), 20f,
            RegionType.Shrine, 5,
            new[] { "spore_jungle" },
            0.7f, 0.5f, 0.3f, 0.2f,
            67890
        );

        cfg.structures = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 祭坛（中心）
                minScale = 1.2f, maxScale = 1.5f,
                needsCollider = true, randomRotation = false,
                minCount = 1, maxCount = 1,
                placementMode = PlacementMode.Center,
                minDistanceFromCenter = 3f
            },
            new PrefabEntry
            {
                // 石柱
                minScale = 0.9f, maxScale = 1.5f,
                needsCollider = true, randomRotation = true,
                minCount = 4, maxCount = 8,
                placementMode = PlacementMode.Ring,
                minDistanceFromCenter = 8f,
                maxDistanceFromCenter = 14f
            }
        };

        cfg.props = new System.Collections.Generic.List<PrefabEntry>
        {
            new PrefabEntry
            {
                // 符文石/黑水晶
                minScale = 0.6f, maxScale = 1.2f,
                needsCollider = true, randomRotation = true,
                minCount = 4, maxCount = 8,
                placementMode = PlacementMode.Scatter,
                minDistanceFromCenter = 5f
            },
            new PrefabEntry
            {
                // 雕像
                minScale = 1f, maxScale = 1.5f,
                needsCollider = true, randomRotation = false,
                minCount = 2, maxCount = 4,
                placementMode = PlacementMode.Ring,
                minDistanceFromCenter = 10f,
                maxDistanceFromCenter = 16f
            }
        };

        EditorUtility.SetDirty(cfg);
    }
}