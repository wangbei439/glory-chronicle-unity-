using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// 地图生成器 Editor Window
/// 基于RegionConfig自动生成地图布局
/// 菜单：Tools > Glory Chronicle > Map Generator
/// </summary>
public class MapGeneratorWindow : EditorWindow
{
    // ========== 状态 ==========
    private Vector2 scrollPos;
    private List<RegionConfig> regionConfigs = new List<RegionConfig>();
    private GameObject worldRoot;
    private int selectedRegionIndex = -1;
    private bool showHelp = true;
    private bool showPreview = true;
    private bool showAdvanced = false;

    // 生成结果
    private Dictionary<string, GameObject> generatedRegions = new Dictionary<string, GameObject>();
    private Dictionary<string, List<GameObject>> generatedObjects = new Dictionary<string, List<GameObject>>();
    private int totalGeneratedCount = 0;

    // 全局设置
    private float globalScaleMultiplier = 1f;
    private bool addCollidersAuto = true;
    private bool setStaticFlags = true;
    private string parentName = "World";

    // 预览颜色
    private readonly Color[] regionColors = {
        new Color(0.2f, 0.8f, 0.2f, 0.3f),   // Hub - 绿
        new Color(0.4f, 0.7f, 0.2f, 0.3f),   // Forest - 深绿
        new Color(0.7f, 0.7f, 0.2f, 0.3f),   // Clearing - 黄绿
        new Color(0.8f, 0.6f, 0.2f, 0.3f),   // Camp - 橙
        new Color(0.3f, 0.5f, 0.6f, 0.3f),   // Swamp - 青灰
        new Color(0.6f, 0.3f, 0.3f, 0.3f),   // Ruins - 暗红
        new Color(0.5f, 0.2f, 0.7f, 0.3f),   // Shrine - 紫
        new Color(0.5f, 0.5f, 0.5f, 0.3f),   // Path - 灰
        new Color(0.3f, 0.3f, 0.3f, 0.3f),   // Cave - 深灰
    };

    [MenuItem("Tools/Glory Chronicle/Map Generator", false, 100)]
    public static void ShowWindow()
    {
        var window = GetWindow<MapGeneratorWindow>("Map Generator");
        window.minSize = new Vector2(420, 600);
        window.Show();
    }

    void OnEnable()
    {
        // 尝试加载已有配置
        LoadRegionConfigs();
    }

    void OnGUI()
    {
        scrollPos = EditorGUILayout.BeginScrollView(scrollPos);

        DrawHeader();
        DrawHelpBox();

        EditorGUILayout.Space(8);

        DrawGlobalSettings();
        DrawRegionList();
        DrawRegionEditor();
        DrawActionButtons();
        DrawStatistics();

        EditorGUILayout.Space(10);

        DrawPreviewButton();

        EditorGUILayout.EndScrollView();
    }

    // ========== 绘制UI ==========

    void DrawHeader()
    {
        EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
        GUILayout.Label("⚔ Glory Chronicle 地图生成器", EditorStyles.boldLabel);
        if (GUILayout.Button("⟳ 刷新", EditorStyles.toolbarButton, GUILayout.Width(60)))
        {
            LoadRegionConfigs();
        }
        EditorGUILayout.EndHorizontal();
    }

    void DrawHelpBox()
    {
        if (!showHelp) return;

        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        EditorGUILayout.BeginHorizontal();
        showHelp = EditorGUILayout.Foldout(showHelp, "使用说明");
        EditorGUILayout.EndHorizontal();

        if (showHelp)
        {
            EditorGUILayout.LabelField("1. 创建RegionConfig资产（右键>Create>Glory Chronicle>Region Config）");
            EditorGUILayout.LabelField("2. 配置每个区域的模型池和密度");
            EditorGUILayout.LabelField("3. 点击\"加载配置\"读取所有RegionConfig");
            EditorGUILayout.LabelField("4. 点击\"生成地图\"一键创建场景");
            EditorGUILayout.LabelField("5. 不满意可\"清空地图\"重新生成");
            EditorGUILayout.Space(4);
            EditorGUILayout.LabelField("提示：相同Seed生成相同布局，修改Seed可随机", EditorStyles.miniLabel);
        }
        EditorGUILayout.EndVertical();
    }

    void DrawGlobalSettings()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        GUILayout.Label("全局设置", EditorStyles.boldLabel);

        parentName = EditorGUILayout.TextField("根物体名称", parentName);
        globalScaleMultiplier = EditorGUILayout.Slider("全局缩放系数", globalScaleMultiplier, 0.5f, 3f);
        addCollidersAuto = EditorGUILayout.Toggle("自动添加碰撞体", addCollidersAuto);
        setStaticFlags = EditorGUILayout.Toggle("标记Static", setStaticFlags);

        showAdvanced = EditorGUILayout.Foldout(showAdvanced, "高级选项");
        if (showAdvanced)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.LabelField("说明：碰撞体类型优先级", EditorStyles.miniLabel);
            EditorGUILayout.LabelField("  已有Collider → 保留", EditorStyles.miniLabel);
            EditorGUILayout.LabelField("  需要Collider + Mesh → MeshCollider", EditorStyles.miniLabel);
            EditorGUILayout.LabelField("  需要Collider + 无Mesh → BoxCollider", EditorStyles.miniLabel);
            EditorGUI.indentLevel--;
        }

        EditorGUILayout.EndVertical();
    }

    void DrawRegionList()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        GUILayout.Label("区域配置列表", EditorStyles.boldLabel);

        if (regionConfigs.Count == 0)
        {
            EditorGUILayout.HelpBox("没有加载任何区域配置。\n请先创建RegionConfig资产，然后点击\"加载配置\"。", MessageType.Info);
        }
        else
        {
            for (int i = 0; i < regionConfigs.Count; i++)
            {
                var cfg = regionConfigs[i];
                if (cfg == null) continue;

                EditorGUILayout.BeginHorizontal();

                // 选中高亮
                var style = (i == selectedRegionIndex)
                    ? new GUIStyle(EditorStyles.helpBox) { normal = { background = MakeTex(2, 2, new Color(0.3f, 0.5f, 0.8f, 0.3f)) } }
                    : EditorStyles.helpBox;

                GUILayout.Box("", GUILayout.Width(8), GUILayout.Height(20));
                var lastRect = GUILayoutUtility.GetLastRect();
                var colorIdx = Mathf.Min((int)cfg.regionType, regionColors.Length - 1);
                EditorGUI.DrawRect(lastRect, regionColors[colorIdx]);

                if (GUILayout.Button($"{cfg.regionName} ({cfg.regionId})", EditorStyles.label))
                {
                    selectedRegionIndex = i;
                    Selection.activeObject = cfg;
                    EditorGUIUtility.PingObject(cfg);
                }

                // 状态指示
                bool isGenerated = generatedRegions.ContainsKey(cfg.regionId);
                var statusIcon = isGenerated ? "✅" : "⬜";
                GUILayout.Label(statusIcon, GUILayout.Width(24));

                EditorGUILayout.EndHorizontal();
            }
        }

        EditorGUILayout.Space(4);
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("加载配置", GUILayout.Height(28)))
        {
            LoadRegionConfigs();
        }
        if (GUILayout.Button("创建新配置", GUILayout.Height(28)))
        {
            var cfg = CreateInstance<RegionConfig>();
            var path = EditorUtility.SaveFilePanelInProject(
                "保存区域配置", "RegionConfig_New", "asset",
                "选择保存位置", "Assets/ScriptableObjects/Regions/");
            if (!string.IsNullOrEmpty(path))
            {
                AssetDatabase.CreateAsset(cfg, path);
                AssetDatabase.SaveAssets();
                LoadRegionConfigs();
                EditorUtility.FocusProjectWindow();
                Selection.activeObject = cfg;
            }
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.EndVertical();
    }

    void DrawRegionEditor()
    {
        if (selectedRegionIndex < 0 || selectedRegionIndex >= regionConfigs.Count) return;
        var cfg = regionConfigs[selectedRegionIndex];
        if (cfg == null) return;

        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        GUILayout.Label($"编辑区域: {cfg.regionName}", EditorStyles.boldLabel);

        EditorGUI.BeginDisabledGroup(true);
        EditorGUILayout.ObjectField("配置资产", cfg, typeof(RegionConfig), false);
        EditorGUI.EndDisabledGroup();

        if (GUILayout.Button("在Inspector中编辑"))
        {
            Selection.activeObject = cfg;
        }

        EditorGUILayout.EndVertical();
    }

    void DrawActionButtons()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        GUILayout.Label("生成操作", EditorStyles.boldLabel);

        // 生成单个区域
        EditorGUILayout.BeginHorizontal();
        if (selectedRegionIndex >= 0 && selectedRegionIndex < regionConfigs.Count)
        {
            var cfg = regionConfigs[selectedRegionIndex];
            GUI.enabled = cfg != null;
            if (GUILayout.Button($"生成: {cfg.regionName}", GUILayout.Height(32)))
            {
                GenerateRegion(cfg);
            }
            if (GUILayout.Button($"清空: {cfg.regionName}", GUILayout.Height(32)))
            {
                ClearRegion(cfg.regionId);
            }
            GUI.enabled = true;
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space(4);

        // 全部生成/清空
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("⚔ 生成全部地图", GUILayout.Height(36)))
        {
            GenerateAllRegions();
        }
        if (GUILayout.Button("✕ 清空全部地图", GUILayout.Height(36)))
        {
            ClearAllRegions();
        }
        EditorGUILayout.EndHorizontal();

        // 只生成地面
        if (GUILayout.Button("只生成地面", GUILayout.Height(28)))
        {
            GenerateAllGrounds();
        }

        EditorGUILayout.EndVertical();
    }

    void DrawStatistics()
    {
        if (totalGeneratedCount <= 0) return;

        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        GUILayout.Label("生成统计", EditorStyles.boldLabel);
        EditorGUILayout.LabelField("总物体数", totalGeneratedCount.ToString());
        EditorGUILayout.LabelField("已生成区域", generatedRegions.Count.ToString());

        foreach (var kvp in generatedObjects)
        {
            EditorGUILayout.LabelField($"  {kvp.Key}", $"{kvp.Value.Count} 个物体");
        }
        EditorGUILayout.EndVertical();
    }

    void DrawPreviewButton()
    {
        if (GUILayout.Button("在Scene视图中显示区域预览", GUILayout.Height(28)))
        {
            DrawRegionPreview();
        }
    }

    // ========== 核心生成逻辑 ==========

    void LoadRegionConfigs()
    {
        regionConfigs.Clear();

        // 方法1：按类型搜索
        var guids = AssetDatabase.FindAssets("t:RegionConfig");
        Debug.Log($"[MapGenerator] FindAssets t:RegionConfig 找到 {guids.Length} 个GUID");

        foreach (var guid in guids)
        {
            var path = AssetDatabase.GUIDToAssetPath(guid);
            var cfg = AssetDatabase.LoadAssetAtPath<RegionConfig>(path);
            if (cfg != null)
            {
                regionConfigs.Add(cfg);
                Debug.Log($"[MapGenerator]   加载成功: {cfg.regionName} ({cfg.regionId}) @ {path}");
            }
            else
            {
                Debug.LogWarning($"[MapGenerator]   加载失败: {path} (类型不匹配?)");
            }
        }

        // 方法2：如果方法1没找到，按文件名搜索
        if (regionConfigs.Count == 0)
        {
            Debug.Log("[MapGenerator] 类型搜索无结果，尝试按文件名搜索...");
            var nameGuids = AssetDatabase.FindAssets("Region_ l:RegionConfig");
            foreach (var guid in nameGuids)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (path.EndsWith(".asset"))
                {
                    var cfg = AssetDatabase.LoadAssetAtPath<RegionConfig>(path);
                    if (cfg != null)
                    {
                        regionConfigs.Add(cfg);
                        Debug.Log($"[MapGenerator]   文件名搜索加载: {cfg.regionName} @ {path}");
                    }
                }
            }
        }

        // 方法3：还是没找到，直接搜索所有.asset文件手动过滤
        if (regionConfigs.Count == 0)
        {
            Debug.Log("[MapGenerator] 文件名搜索也无结果，尝试全量搜索.asset...");
            var allAssets = AssetDatabase.FindAssets("Region_");
            foreach (var guid in allAssets)
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (!path.EndsWith(".asset")) continue;
                var obj = AssetDatabase.LoadMainAssetAtPath(path);
                if (obj is RegionConfig cfg)
                {
                    regionConfigs.Add(cfg);
                    Debug.Log($"[MapGenerator]   全量搜索加载: {cfg.regionName} @ {path}");
                }
                else
                {
                    Debug.LogWarning($"[MapGenerator]   跳过(类型={obj?.GetType().Name}): {path}");
                }
            }
        }

        // 按危险等级排序（Hub先，神殿最后）
        regionConfigs = regionConfigs.OrderBy(c => c.dangerLevel).ToList();

        if (regionConfigs.Count > 0 && selectedRegionIndex < 0)
            selectedRegionIndex = 0;

        Debug.Log($"[MapGenerator] 最终加载了 {regionConfigs.Count} 个区域配置");

        if (regionConfigs.Count == 0)
        {
            Debug.LogError("[MapGenerator] 未找到任何RegionConfig！请确认：\n" +
                "1. 已运行 Tools > Glory Chronicle > Create Default Regions\n" +
                "2. Assets/ScriptableObjects/Regions/ 文件夹中有 .asset 文件\n" +
                "3. RegionConfig.cs 无编译错误");
        }
    }

    GameObject GetOrCreateWorldRoot()
    {
        if (worldRoot != null) return worldRoot;

        worldRoot = GameObject.Find(parentName);
        if (worldRoot == null)
        {
            worldRoot = new GameObject(parentName);
            Undo.RegisterCreatedObjectUndo(worldRoot, "Create World Root");
        }
        return worldRoot;
    }

    void GenerateAllRegions()
    {
        if (regionConfigs.Count == 0)
        {
            EditorUtility.DisplayDialog("提示", "没有加载任何区域配置", "OK");
            return;
        }

        if (!EditorUtility.DisplayDialog("确认生成",
            $"即将生成 {regionConfigs.Count} 个区域，\n这可能需要几秒钟。\n\n是否继续？",
            "生成", "取消"))
            return;

        float progress = 0f;
        foreach (var cfg in regionConfigs)
        {
            if (EditorUtility.DisplayCancelableProgressBar("生成地图", $"正在生成: {cfg.regionName}", progress))
                break;

            GenerateRegion(cfg);
            progress += 1f / regionConfigs.Count;
        }

        EditorUtility.ClearProgressBar();
        Debug.Log($"[MapGenerator] 地图生成完成！共 {totalGeneratedCount} 个物体");
    }

    void GenerateRegion(RegionConfig cfg)
    {
        if (cfg == null) return;

        var root = GetOrCreateWorldRoot();

        // 清除旧的同名区域
        ClearRegion(cfg.regionId);

        // 创建区域根物体
        var regionObj = new GameObject($"Region_{cfg.regionId}");
        regionObj.transform.parent = root.transform;
        regionObj.transform.position = cfg.center;
        Undo.RegisterCreatedObjectUndo(regionObj, $"Create Region {cfg.regionName}");

        generatedRegions[cfg.regionId] = regionObj;
        generatedObjects[cfg.regionId] = new List<GameObject>();

        // 使用种子初始化随机数
        var rng = cfg.seed >= 0 ? new System.Random(cfg.seed) : new System.Random();

        // 1. 生成地面
        GenerateGround(cfg, regionObj);

        // 2. 生成各类环境物体
        GenerateCategoryObjects(cfg, cfg.structures, cfg.structureDensity, rng, regionObj);
        GenerateCategoryObjects(cfg, cfg.props, cfg.propDensity, rng, regionObj);
        GenerateCategoryObjects(cfg, cfg.natureObjects, cfg.natureDensity, rng, regionObj);
        GenerateCategoryObjects(cfg, cfg.decorations, cfg.decorationDensity, rng, regionObj);

        // 3. 生成区域间的路径
        GeneratePaths(cfg, regionObj, rng);

        // 4. 标记Static
        if (setStaticFlags)
        {
            SetStaticRecursive(regionObj);
        }

        Debug.Log($"[MapGenerator] 区域 '{cfg.regionName}' 生成完成，{generatedObjects[cfg.regionId].Count} 个物体");
    }

    void GenerateGround(RegionConfig cfg, GameObject regionObj)
    {
        // 创建地面
        var groundObj = GameObject.CreatePrimitive(PrimitiveType.Quad);
        groundObj.name = "Ground";
        groundObj.transform.parent = regionObj.transform;
        groundObj.transform.localPosition = new Vector3(0, cfg.groundY, 0);
        groundObj.transform.localRotation = Quaternion.Euler(90, 0, 0); // Quad默认朝Z，旋转朝上
        groundObj.transform.localScale = new Vector3(cfg.radius * 2, cfg.radius * 2, 1);

        // 赋予材质
        if (cfg.groundMaterial != null)
        {
            var renderer = groundObj.GetComponent<Renderer>();
            renderer.sharedMaterial = cfg.groundMaterial;
        }

        // 地面碰撞体（Quad自带Collider，设为Trigger不需要）
        var col = groundObj.GetComponent<Collider>();
        if (col != null) col.isTrigger = true;

        Undo.RegisterCreatedObjectUndo(groundObj, "Create Ground");

        if (!generatedObjects.ContainsKey(cfg.regionId))
            generatedObjects[cfg.regionId] = new List<GameObject>();
        generatedObjects[cfg.regionId].Add(groundObj);
    }

    void GenerateCategoryObjects(RegionConfig cfg, List<PrefabEntry> entries, float density, System.Random rng, GameObject regionObj)
    {
        if (entries == null || entries.Count == 0) return;

        foreach (var entry in entries)
        {
            if (entry.prefab == null) continue;

            // 根据密度决定数量
            int count = GetCountFromDensity(entry, density, cfg.radius, rng);

            for (int i = 0; i < count; i++)
            {
                var pos = GetPlacementPosition(cfg, entry, rng);
                var rot = GetPlacementRotation(entry, rng);
                var scale = GetPlacementScale(entry, rng);

                var obj = PrefabUtility.InstantiatePrefab(entry.prefab, regionObj.transform) as GameObject;
                if (obj == null) continue;

                obj.transform.localPosition = pos;
                // 保留Prefab原有旋转（GLB导入通常有X=-90修正），在此基础上叠加随机Y旋转
                obj.transform.localRotation = rot * obj.transform.localRotation;
                obj.transform.localScale = Vector3.Scale(obj.transform.localScale, scale * globalScaleMultiplier);

                obj.name = $"{entry.prefab.name}_{i}";

                // 添加碰撞体
                if (addCollidersAuto && entry.needsCollider)
                {
                    AddColliderIfNeeded(obj);
                }

                Undo.RegisterCreatedObjectUndo(obj, $"Place {entry.prefab.name}");
                generatedObjects[cfg.regionId].Add(obj);
                totalGeneratedCount++;
            }
        }
    }

    int GetCountFromDensity(PrefabEntry entry, float categoryDensity, float regionRadius, System.Random rng)
    {
        // 基础数量从prefab entry的min/max取
        int baseCount = rng.Next(entry.minCount, entry.maxCount + 1);

        // 根据区域面积和密度缩放
        float areaFactor = (regionRadius * regionRadius) / 225f; // 以半径15为基准
        float densityFactor = categoryDensity;

        int finalCount = Mathf.RoundToInt(baseCount * areaFactor * densityFactor);
        return Mathf.Max(1, finalCount);
    }

    Vector3 GetPlacementPosition(RegionConfig cfg, PrefabEntry entry, System.Random rng)
    {
        float minDist = entry.minDistanceFromCenter;
        float maxDist = entry.maxDistanceFromCenter > 0 ? entry.maxDistanceFromCenter : cfg.radius;

        Vector3 pos;

        switch (entry.placementMode)
        {
            case PlacementMode.Center:
                // 中心附近
                pos = new Vector3(
                    (float)(rng.NextDouble() - 0.5) * minDist * 2,
                    0,
                    (float)(rng.NextDouble() - 0.5) * minDist * 2
                );
                break;

            case PlacementMode.Edge:
                // 边缘
                float angle = (float)rng.NextDouble() * 360f;
                float edgeDist = maxDist * (0.8f + (float)rng.NextDouble() * 0.2f);
                pos = new Vector3(
                    Mathf.Cos(angle * Mathf.Deg2Rad) * edgeDist,
                    0,
                    Mathf.Sin(angle * Mathf.Deg2Rad) * edgeDist
                );
                break;

            case PlacementMode.Ring:
                // 环形
                float ringAngle = (float)rng.NextDouble() * 360f;
                float ringDist = (minDist + maxDist) / 2f + (float)(rng.NextDouble() - 0.5) * (maxDist - minDist) * 0.3f;
                pos = new Vector3(
                    Mathf.Cos(ringAngle * Mathf.Deg2Rad) * ringDist,
                    0,
                    Mathf.Sin(ringAngle * Mathf.Deg2Rad) * ringDist
                );
                break;

            case PlacementMode.Cluster:
                // 集群：先选一个中心点，然后围绕它
                float clusterCenterAngle = (float)rng.NextDouble() * 360f;
                float clusterCenterDist = Mathf.Lerp(minDist, maxDist, (float)rng.NextDouble());
                var clusterCenter = new Vector3(
                    Mathf.Cos(clusterCenterAngle * Mathf.Deg2Rad) * clusterCenterDist,
                    0,
                    Mathf.Sin(clusterCenterAngle * Mathf.Deg2Rad) * clusterCenterDist
                );
                pos = clusterCenter + new Vector3(
                    (float)(rng.NextDouble() - 0.5) * entry.clusterRadius * 2,
                    0,
                    (float)(rng.NextDouble() - 0.5) * entry.clusterRadius * 2
                );
                break;

            case PlacementMode.Path:
                // 沿路径（简化为沿某方向线段）
                float t = (float)rng.NextDouble();
                pos = Vector3.Lerp(Vector3.zero, cfg.center.normalized * maxDist, t);
                pos += new Vector3((float)(rng.NextDouble() - 0.5) * 2f, 0, (float)(rng.NextDouble() - 0.5) * 2f);
                break;

            default: // Scatter
                // 随机散布在圆内
                float scatterAngle = (float)rng.NextDouble() * 360f;
                float scatterDist = Mathf.Lerp(minDist, maxDist, (float)rng.NextDouble());
                // 使用平方根分布让点更均匀
                scatterDist = Mathf.Sqrt((float)rng.NextDouble()) * (maxDist - minDist) + minDist;
                pos = new Vector3(
                    Mathf.Cos(scatterAngle * Mathf.Deg2Rad) * scatterDist,
                    0,
                    Mathf.Sin(scatterAngle * Mathf.Deg2Rad) * scatterDist
                );
                break;
        }

        return pos;
    }

    Quaternion GetPlacementRotation(PrefabEntry entry, System.Random rng)
    {
        if (entry.randomRotation)
        {
            float yRot = (float)rng.NextDouble() * 360f;
            return Quaternion.Euler(0, yRot, 0);
        }
        return Quaternion.identity;
    }

    Vector3 GetPlacementScale(PrefabEntry entry, System.Random rng)
    {
        float s = Mathf.Lerp(entry.minScale, entry.maxScale, (float)rng.NextDouble());
        return new Vector3(s, s, s);
    }

    void AddColliderIfNeeded(GameObject obj)
    {
        // 已有碰撞体则跳过
        if (obj.GetComponent<Collider>() != null) return;

        // 有MeshRenderer则添加MeshCollider
        if (obj.GetComponent<MeshRenderer>() != null)
        {
            var meshCol = obj.AddComponent<MeshCollider>();
            meshCol.convex = false;
            return;
        }

        // 有子物体的MeshRenderer
        var childRenderers = obj.GetComponentsInChildren<MeshRenderer>();
        if (childRenderers.Length > 0)
        {
            foreach (var r in childRenderers)
            {
                if (r.gameObject.GetComponent<Collider>() == null)
                {
                    var meshCol = r.gameObject.AddComponent<MeshCollider>();
                    meshCol.convex = false;
                }
            }
            return;
        }

        // 兜底：BoxCollider
        var boxCol = obj.AddComponent<BoxCollider>();
        // 尝试适配大小
        var renderers = obj.GetComponentsInChildren<Renderer>();
        if (renderers.Length > 0)
        {
            var bounds = renderers[0].bounds;
            foreach (var r in renderers)
                bounds.Encapsulate(r.bounds);
            boxCol.size = bounds.size;
            boxCol.center = obj.transform.InverseTransformPoint(bounds.center);
        }
    }

    void SetStaticRecursive(GameObject obj)
    {
        // 不对有Rigidbody或动态组件的物体设Static
        if (obj.GetComponent<Rigidbody>() != null) return;
        if (obj.GetComponent<Animator>() != null) return;

        obj.isStatic = true;

        foreach (Transform child in obj.transform)
        {
            SetStaticRecursive(child.gameObject);
        }
    }

    // ========== 路径生成 ==========

    void GeneratePaths(RegionConfig cfg, GameObject regionObj, System.Random rng)
    {
        if (cfg.connectedRegions == null || cfg.connectedRegions.Count == 0) return;

        // 找到连接的区域配置
        foreach (var connectedId in cfg.connectedRegions)
        {
            var connectedCfg = regionConfigs.FirstOrDefault(c => c.regionId == connectedId);
            if (connectedCfg == null) continue;

            // 避免重复生成（两个区域互相连接只生成一次）
            if (string.Compare(cfg.regionId, connectedId) > 0) continue;

            GeneratePathBetween(cfg, connectedCfg, rng);
        }
    }

    void GeneratePathBetween(RegionConfig from, RegionConfig to, System.Random rng)
    {
        var root = GetOrCreateWorldRoot();

        // 路径物体
        var pathObj = new GameObject($"Path_{from.regionId}_to_{to.regionId}");
        pathObj.transform.parent = root.transform;
        Undo.RegisterCreatedObjectUndo(pathObj, $"Create Path {from.regionId}-{to.regionId}");

        // 计算路径方向
        Vector3 dir = (to.center - from.center).normalized;
        float distance = Vector3.Distance(from.center, to.center);

        // 放置路径地面片
        int segments = Mathf.CeilToInt(distance / 8f);
        for (int i = 0; i < segments; i++)
        {
            float t = (i + 0.5f) / segments;
            Vector3 segPos = Vector3.Lerp(from.center, to.center, t);

            var segObj = GameObject.CreatePrimitive(PrimitiveType.Quad);
            segObj.name = $"PathSeg_{i}";
            segObj.transform.parent = pathObj.transform;
            segObj.transform.position = new Vector3(segPos.x, 0.01f, segPos.z); // 略高于地面
            segObj.transform.rotation = Quaternion.LookRotation(dir) * Quaternion.Euler(90, 0, 0);
            segObj.transform.localScale = new Vector3(from.pathWidth, 8f / segments * distance / segments, 1f);

            // 使用较暗的材质
            var renderer = segObj.GetComponent<Renderer>();
            renderer.sharedMaterial = from.groundMaterial ?? to.groundMaterial;

            var col = segObj.GetComponent<Collider>();
            if (col != null) Object.DestroyImmediate(col); // 路径不需要碰撞
        }
    }

    // ========== 预览 ==========

    void DrawRegionPreview()
    {
        // 在Scene视图中画区域范围预览
        foreach (var cfg in regionConfigs)
        {
            if (cfg == null) continue;
            var colorIdx = Mathf.Min((int)cfg.regionType, regionColors.Length - 1);
            Debug.DrawLine(
                cfg.center + Vector3.forward * cfg.radius,
                cfg.center - Vector3.forward * cfg.radius,
                regionColors[colorIdx],
                5f
            );
            Debug.DrawLine(
                cfg.center + Vector3.right * cfg.radius,
                cfg.center - Vector3.right * cfg.radius,
                regionColors[colorIdx],
                5f
            );
        }
        SceneView.RepaintAll();
    }

    // ========== 清除 ==========

    void ClearRegion(string regionId)
    {
        if (generatedRegions.TryGetValue(regionId, out var regionObj))
        {
            if (regionObj != null)
            {
                Undo.DestroyObjectImmediate(regionObj);
            }
            generatedRegions.Remove(regionId);
        }

        if (generatedObjects.TryGetValue(regionId, out var objs))
        {
            totalGeneratedCount -= objs.Count;
            generatedObjects.Remove(regionId);
        }
    }

    void ClearAllRegions()
    {
        if (!EditorUtility.DisplayDialog("确认清空", "确定要清空所有已生成的地图物体吗？\n此操作可撤销（Ctrl+Z）。", "清空", "取消"))
            return;

        var root = GameObject.Find(parentName);
        if (root != null)
        {
            Undo.DestroyObjectImmediate(root);
        }

        generatedRegions.Clear();
        generatedObjects.Clear();
        totalGeneratedCount = 0;
        worldRoot = null;

        Debug.Log("[MapGenerator] 地图已清空");
    }

    void GenerateAllGrounds()
    {
        foreach (var cfg in regionConfigs)
        {
            if (cfg == null) continue;
            var root = GetOrCreateWorldRoot();

            var groundObj = GameObject.CreatePrimitive(PrimitiveType.Quad);
            groundObj.name = $"Ground_{cfg.regionId}";
            groundObj.transform.parent = root.transform;
            groundObj.transform.position = new Vector3(cfg.center.x, cfg.groundY, cfg.center.z);
            groundObj.transform.rotation = Quaternion.Euler(90, 0, 0);
            groundObj.transform.localScale = new Vector3(cfg.radius * 2, cfg.radius * 2, 1);

            if (cfg.groundMaterial != null)
            {
                groundObj.GetComponent<Renderer>().sharedMaterial = cfg.groundMaterial;
            }

            var col = groundObj.GetComponent<Collider>();
            if (col != null) Object.DestroyImmediate(col);

            Undo.RegisterCreatedObjectUndo(groundObj, $"Create Ground {cfg.regionName}");
        }

        Debug.Log("[MapGenerator] 所有地面已生成");
    }

    // ========== 工具 ==========

    Texture2D MakeTex(int w, int h, Color col)
    {
        var pix = new Color[w * h];
        for (int i = 0; i < pix.Length; i++)
            pix[i] = col;
        var tex = new Texture2D(w, h);
        tex.SetPixels(pix);
        tex.Apply();
        return tex;
    }
}