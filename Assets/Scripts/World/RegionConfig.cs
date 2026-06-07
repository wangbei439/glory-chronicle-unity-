using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 区域配置 ScriptableObject
/// 定义每个区域的类型、范围、模型池和生成规则
/// </summary>
[CreateAssetMenu(fileName = "RegionConfig_New", menuName = "Glory Chronicle/Region Config")]
public class RegionConfig : ScriptableObject
{
    [Header("=== 区域基本信息 ===")]
    [Tooltip("区域唯一ID，对应WorldManager中的ID")]
    public string regionId = "hub";

    [Tooltip("区域显示名称")]
    public string regionName = "休息站";

    [Tooltip("区域中心坐标")]
    public Vector3 center = Vector3.zero;

    [Tooltip("区域半径")]
    public float radius = 15f;

    [Header("=== 区域类型 ===")]
    public RegionType regionType = RegionType.Hub;

    [Header("=== 地面设置 ===")]
    [Tooltip("地面材质")]
    public Material groundMaterial;

    [Tooltip("地面Y偏移（默认0）")]
    public float groundY = 0f;

    [Header("=== 危险等级 ===")]
    [Range(1, 5)]
    [Tooltip("1=安全 5=最危险，影响敌人密度和类型")]
    public int dangerLevel = 1;

    [Header("=== 环境模型池 ===")]
    [Tooltip("大型结构物（帐篷/祭坛/石柱等），稀疏放置")]
    public List<PrefabEntry> structures = new List<PrefabEntry>();

    [Tooltip("中型道具（木桶/火把/箱子等），中等密度")]
    public List<PrefabEntry> props = new List<PrefabEntry>();

    [Tooltip("自然物体（树木/岩石/蘑菇等），高密度放置")]
    public List<PrefabEntry> natureObjects = new List<PrefabEntry>();

    [Tooltip("装饰物（草/花/落叶等），超高密度，无碰撞")]
    public List<PrefabEntry> decorations = new List<PrefabEntry>();

    [Header("=== 生成密度 ===")]
    [Range(0f, 1f)]
    [Tooltip("结构物密度系数")]
    public float structureDensity = 0.3f;

    [Range(0f, 1f)]
    [Tooltip("道具密度系数")]
    public float propDensity = 0.5f;

    [Range(0f, 1f)]
    [Tooltip("自然物体密度系数")]
    public float natureDensity = 0.7f;

    [Range(0f, 1f)]
    [Tooltip("装饰物密度系数")]
    public float decorationDensity = 0.9f;

    [Header("=== 连接区域 ===")]
    [Tooltip("此区域连接的其他区域ID")]
    public List<string> connectedRegions = new List<string>();

    [Tooltip("路径宽度")]
    public float pathWidth = 4f;

    [Header("=== 随机种子 ===")]
    [Tooltip("相同种子生成相同布局，-1为随机")]
    public int seed = 12345;

    /// <summary>
    /// 获取所有模型池的合并列表
    /// </summary>
    public List<PrefabEntry> GetAllEntries()
    {
        var all = new List<PrefabEntry>();
        all.AddRange(structures);
        all.AddRange(props);
        all.AddRange(natureObjects);
        all.AddRange(decorations);
        return all;
    }
}

[System.Serializable]
public class PrefabEntry
{
    [Tooltip("预制体引用")]
    public GameObject prefab;

    [Tooltip("最小缩放")]
    public float minScale = 0.8f;

    [Tooltip("最大缩放")]
    public float maxScale = 1.2f;

    [Tooltip("是否需要碰撞体")]
    public bool needsCollider = true;

    [Tooltip("是否允许旋转（Y轴随机旋转）")]
    public bool randomRotation = true;

    [Tooltip("最小生成数量")]
    public int minCount = 1;

    [Tooltip("最大生成数量")]
    public int maxCount = 5;

    [Tooltip("放置模式：散布/集群/环形/路径")]
    public PlacementMode placementMode = PlacementMode.Scatter;

    [Tooltip("集群模式时的集群半径")]
    public float clusterRadius = 3f;

    [Tooltip("离区域中心的最小距离（0=无限制）")]
    public float minDistanceFromCenter = 0f;

    [Tooltip("离区域中心的最大距离（0=无限制，使用区域半径）")]
    public float maxDistanceFromCenter = 0f;
}

public enum RegionType
{
    Hub,            // 安全区/休息站
    Forest,         // 森林
    Clearing,       // 空地
    Camp,           // 营地
    Swamp,          // 沼泽
    Ruins,          // 遗迹
    Shrine,         // 神殿
    Path,           // 路径
    Cave            // 洞穴
}

public enum PlacementMode
{
    Scatter,    // 随机散布在整个区域
    Cluster,    // 集群放置（一群聚在一起）
    Ring,       // 环形放置（围绕中心）
    Path,       // 沿路径放置
    Center,     // 放在中心附近
    Edge        // 放在区域边缘
}