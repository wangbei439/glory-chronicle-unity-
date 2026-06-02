using UnityEngine;
using UnityEditor;
using UnityEngine.Networking;
using System.Collections.Generic;
using System.Text;
using System.IO;

public class AIAssistantWindow : EditorWindow
{
    [MenuItem("Tools/AI\u52a9\u624b")]
    public static void ShowWindow()
    {
        var window = GetWindow<AIAssistantWindow>("AI\u52a9\u624b");
        window.minSize = new Vector2(400, 500);
    }

    private string apiUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions";
    private string apiKey = "";
    private string model = "qwen-plus";

    private string userInput = "";
    private List<Message> chatHistory = new List<Message>();
    private Vector2 scrollPos;
    private bool isWaiting = false;
    private string systemPrompt = "";
    private bool includeProjectContext = true;

    // 气泡样式（只初始化一次）
    private GUIStyle userBubbleStyle;
    private GUIStyle aiBubbleStyle;
    private GUIStyle userLabelStyle;
    private GUIStyle aiLabelStyle;
    private GUIStyle nameStyle;
    private bool stylesInitialized = false;

    [System.Serializable]
    public class Message
    {
        public string role;
        public string content;
    }

    [System.Serializable]
    public class ChatRequest
    {
        public string model;
        public List<Message> messages;
        public int max_tokens;
        public float temperature;
    }

    [System.Serializable]
    public class ChatResponse
    {
        public List<Choice> choices;
    }

    [System.Serializable]
    public class Choice
    {
        public int index;
        public Message message;
    }

    void InitStyles()
    {
        if (stylesInitialized) return;

        // 用户气泡：深蓝底白字
        userBubbleStyle = new GUIStyle("box");
        userBubbleStyle.normal.background = MakeTex(2, 2, new Color(0.15f, 0.3f, 0.55f, 1f));
        userBubbleStyle.padding = new RectOffset(12, 12, 8, 8);
        userBubbleStyle.margin = new RectOffset(40, 8, 4, 4);

        // AI气泡：深灰底浅字
        aiBubbleStyle = new GUIStyle("box");
        aiBubbleStyle.normal.background = MakeTex(2, 2, new Color(0.22f, 0.22f, 0.26f, 1f));
        aiBubbleStyle.padding = new RectOffset(12, 12, 8, 8);
        aiBubbleStyle.margin = new RectOffset(8, 40, 4, 4);

        // 用户文字样式
        userLabelStyle = new GUIStyle();
        userLabelStyle.wordWrap = true;
        userLabelStyle.fontSize = 13;
        userLabelStyle.normal.textColor = new Color(0.92f, 0.94f, 1f);

        // AI文字样式
        aiLabelStyle = new GUIStyle();
        aiLabelStyle.wordWrap = true;
        aiLabelStyle.fontSize = 13;
        aiLabelStyle.normal.textColor = new Color(0.85f, 0.9f, 0.85f);

        // 名字标签
        nameStyle = new GUIStyle(EditorStyles.boldLabel);
        nameStyle.fontSize = 11;

        stylesInitialized = true;
    }

    Texture2D MakeTex(int w, int h, Color col)
    {
        Color[] pix = new Color[w * h];
        for (int i = 0; i < pix.Length; i++) pix[i] = col;
        Texture2D tex = new Texture2D(w, h);
        tex.SetPixels(pix);
        tex.Apply();
        return tex;
    }

    void OnEnable()
    {
        systemPrompt = BuildSystemPrompt();
    }

    string BuildSystemPrompt()
    {
        StringBuilder sb = new StringBuilder();
        sb.AppendLine("\u4f60\u662fUnity\u6e38\u620f\u5f00\u53d1\u7684AI\u52a9\u624b\u3002\u4f60\u4e86\u89e3\u5f53\u524d\u9879\u76ee\u7684\u5b8c\u6574\u7ed3\u6784\u3002");
        sb.AppendLine();
        sb.AppendLine("=== \u9879\u76ee\u4fe1\u606f ===");
        sb.AppendLine("\u9879\u76ee\u540d\uff1a\u4ee3\u53f7\uff1a\u4f20\u8bf4 (Glory Chronicle)");
        sb.AppendLine("\u5f15\u64ce\uff1aUnity 2022.3.58 LTS + URP");
        sb.AppendLine("\u7c7b\u578b\uff1a2.5D \u4fef\u89c6\u89d2\u52a8\u4f5cRPG");
        sb.AppendLine();
        sb.AppendLine("=== \u9879\u76ee\u6587\u4ef6\u5939\u7ed3\u6784 ===");

        string scriptsPath = Application.dataPath + "/Scripts";
        if (Directory.Exists(scriptsPath))
            sb.AppendLine(GetDirectoryTree(scriptsPath, "  "));

        sb.AppendLine();
        sb.AppendLine("=== \u5173\u952e\u811a\u672c\u5185\u5bb9 ===");

        if (Directory.Exists(scriptsPath))
        {
            string[] csFiles = Directory.GetFiles(scriptsPath, "*.cs", SearchOption.AllDirectories);
            foreach (string file in csFiles)
            {
                string relativePath = file.Replace(Application.dataPath, "Assets");
                sb.AppendLine($"--- {relativePath} ---");
                string[] lines = File.ReadAllLines(file);
                int lineCount = Mathf.Min(lines.Length, 100);
                for (int i = 0; i < lineCount; i++)
                    sb.AppendLine(lines[i]);
                if (lines.Length > 100)
                    sb.AppendLine($"... (\u7701\u7565 {lines.Length - 100} \u884c)");
                sb.AppendLine();
            }
        }

        sb.AppendLine("=== \u89c4\u5219 ===");
        sb.AppendLine("1. \u56de\u7b54\u65f6\u53c2\u8003\u4e0a\u9762\u7684\u9879\u76ee\u7ed3\u6784\uff0c\u4e0d\u8981\u5efa\u8bae\u5df2\u5b58\u5728\u7684\u529f\u80fd");
        sb.AppendLine("2. \u751f\u6210\u4ee3\u7801\u65f6\u7528C#\uff0c\u517c\u5bb9Unity 2022.3");
        sb.AppendLine("3. \u5982\u679c\u7528\u6237\u8d34\u62a5\u9519\uff0c\u6839\u636e\u5df2\u77e5\u811a\u672c\u5185\u5bb9\u5206\u6790\u539f\u56e0");
        sb.AppendLine("4. \u7528\u4e2d\u6587\u56de\u590d");
        sb.AppendLine("5. \u6bcf\u4e2a\u64cd\u4f5c\u6b65\u9aa4\u5fc5\u987b\u5199\u6e05\u695a\u5177\u4f53\u70b9\u54ea\u91cc\uff0c\u683c\u5f0f\u5982\uff1a");
        sb.AppendLine("   - \u83dc\u5355\u680f\u64cd\u4f5c\uff1a\u201c\u70b9\u51fb\u83dc\u5355\u680f Window \u2192 AI \u2192 Muse Chat\u201d");
        sb.AppendLine("   - Inspector\u64cd\u4f5c\uff1a\u201c\u5728Inspector\u4e2d\u627e\u5230 Move Speed \u5b57\u6bb5\uff0c\u6539\u4e3a6\u201d");
        sb.AppendLine("   - Hierarchy\u64cd\u4f5c\uff1a\u201c\u5728Hierarchy\u4e2d\u53f3\u952e Player \u2192 Create Empty\u201d");
        sb.AppendLine("   - Project\u64cd\u4f5c\uff1a\u201c\u5728Project\u7a97\u53e3 Assets/Scripts \u4e0b\u53f3\u952e \u2192 Create \u2192 C# Script\u201d");
        sb.AppendLine("   - \u62d6\u62fd\u8d4b\u503c\uff1a\u201c\u628aProject\u91cc\u7684 xxx.prefab \u62d6\u5230 Spawn Zone \u7684 Enemy Prefab \u69fd\u4f4d\u201d");
        sb.AppendLine("6. \u7528\u6237\u95ee\u201c\u600e\u4e48\u505a\u201d\u7c7b\u95ee\u9898\uff0c\u5148\u7ed9\u5177\u4f53\u64cd\u4f5c\u6b65\u9aa4\uff0c\u518d\u7ed9\u4ee3\u7801");
        sb.AppendLine("7. \u7528\u6237\u95ee\u62a5\u9519\uff0c\u5148\u544a\u8bc9\u4ed6\u5728\u54ea\u91cc\u770b\u9519\u8bef\u4fe1\u606f\uff0c\u518d\u7ed9\u89e3\u51b3\u65b9\u6848");

        return sb.ToString();
    }

    string GetDirectoryTree(string path, string indent)
    {
        StringBuilder sb = new StringBuilder();
        DirectoryInfo dir = new DirectoryInfo(path);
        foreach (var d in dir.GetDirectories())
        {
            sb.AppendLine($"{indent}[{d.Name}/]");
            sb.Append(GetDirectoryTree(d.FullName, indent + "  "));
        }
        foreach (var f in dir.GetFiles("*.cs"))
            sb.AppendLine($"{indent}{f.Name}");
        return sb.ToString();
    }

    void OnGUI()
    {
        InitStyles();

        // === Enter键发送 ===
        if (Event.current.type == EventType.KeyDown
            && Event.current.keyCode == KeyCode.Return
        && (Event.current.modifiers & EventModifiers.Shift) == 0
            && GUI.GetNameOfFocusedControl() == "ChatInput")
        {
            SendToAI();
            Event.current.Use();
        }

        // === 配置区 ===
        EditorGUILayout.Space(5);
        EditorGUILayout.LabelField("API \u914d\u7f6e", EditorStyles.boldLabel);

        EditorGUI.BeginChangeCheck();
        apiUrl = EditorGUILayout.TextField("API URL", apiUrl);
        apiKey = EditorGUILayout.PasswordField("API Key", apiKey);
        model = EditorGUILayout.TextField("\u6a21\u578b", model);
        includeProjectContext = EditorGUILayout.Toggle("\u5305\u542b\u9879\u76ee\u4e0a\u4e0b\u6587", includeProjectContext);
        if (EditorGUI.EndChangeCheck())
            systemPrompt = BuildSystemPrompt();

        EditorGUILayout.Space(3);
        if (GUILayout.Button("\u5237\u65b0\u9879\u76ee\u4e0a\u4e0b\u6587", GUILayout.Height(22)))
        {
            systemPrompt = BuildSystemPrompt();
            Debug.Log("\u9879\u76ee\u4e0a\u4e0b\u6587\u5df2\u5237\u65b0");
        }

        EditorGUILayout.Space(5);

        // === 对话区 ===
        EditorGUILayout.LabelField("\u5bf9\u8bdd  (Enter\u53d1\u9001 / Shift+Enter\u6362\u884c)", EditorStyles.boldLabel);

        scrollPos = EditorGUILayout.BeginScrollView(scrollPos, GUILayout.ExpandHeight(true));

        foreach (var msg in chatHistory)
        {
            bool isUser = msg.role == "user";
            GUIStyle bubble = isUser ? userBubbleStyle : aiBubbleStyle;
            GUIStyle text = isUser ? userLabelStyle : aiLabelStyle;
            string name = isUser ? "\u4f60" : "AI";
            Color nameColor = isUser ? new Color(0.5f, 0.75f, 1f) : new Color(0.5f, 1f, 0.6f);

            EditorGUILayout.BeginVertical(bubble);

            // 名字
            Color oldColor = nameStyle.normal.textColor;
            nameStyle.normal.textColor = nameColor;
            EditorGUILayout.LabelField(name, nameStyle);
            nameStyle.normal.textColor = oldColor;

            // 内容
            string displayText = msg.content;
            if (displayText.Length > 3000)
                displayText = displayText.Substring(0, 3000) + "\n... (\u592a\u957f\u5df2\u622a\u65ad)";

            EditorGUILayout.LabelField(displayText, text, GUILayout.ExpandHeight(false));

            // AI回复的操作按钮
            if (msg.role == "assistant" && msg.content.Contains("```"))
            {
                EditorGUILayout.Space(4);
                EditorGUILayout.BeginHorizontal();
                if (GUILayout.Button("\u590d\u5236\u4ee3\u7801", GUILayout.Height(22)))
                {
                    string code = ExtractCode(msg.content);
                    GUIUtility.systemCopyBuffer = code;
                    Debug.Log("\u4ee3\u7801\u5df2\u590d\u5236");
                }
                if (GUILayout.Button("\u521b\u5efa\u811a\u672c\u6587\u4ef6", GUILayout.Height(22)))
                {
                    CreateScriptFromCode(msg.content);
                }
                EditorGUILayout.EndHorizontal();
            }

            EditorGUILayout.EndVertical();
            EditorGUILayout.Space(2);
        }

        if (isWaiting)
            EditorGUILayout.LabelField("AI\u6b63\u5728\u601d\u8003...", EditorStyles.centeredGreyMiniLabel);

        EditorGUILayout.EndScrollView();

        // === 输入区 ===
        EditorGUILayout.Space(5);
        EditorGUILayout.BeginHorizontal();

        GUI.SetNextControlName("ChatInput");
        userInput = EditorGUILayout.TextArea(userInput, GUILayout.Height(50), GUILayout.ExpandWidth(true));

        EditorGUILayout.BeginVertical();
        GUI.enabled = !isWaiting;
        if (GUILayout.Button("\u53d1\u9001", GUILayout.Height(28), GUILayout.Width(50)))
            SendToAI();
        if (GUILayout.Button("\u6e05\u7a7a", GUILayout.Height(22), GUILayout.Width(50)))
            chatHistory.Clear();
        GUI.enabled = true;
        EditorGUILayout.EndVertical();

        EditorGUILayout.EndHorizontal();

        // === 快捷按钮 ===
        EditorGUILayout.Space(3);
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("\u5206\u6790\u62a5\u9519")) userInput = "\u5e2e\u6211\u5206\u6790\u8fd9\u4e2a\u62a5\u9519\uff1a\n\uff08\u7c98\u8d34\u62a5\u9519\u4fe1\u606f\uff09";
        if (GUILayout.Button("\u751f\u6210\u811a\u672c")) userInput = "\u5e2e\u6211\u751f\u6210\u4e00\u4e2a\u811a\u672c\uff1a\n\uff08\u63cf\u8ff0\u529f\u80fd\uff09";
        if (GUILayout.Button("\u89e3\u91ca\u4ee3\u7801")) userInput = "\u5e2e\u6211\u89e3\u91ca\u8fd9\u4e2a\u811a\u672c\u7684\u903b\u8f91\uff1a\n\uff08\u811a\u672c\u540d\u6216\u7c98\u8d34\u4ee3\u7801\uff09";
        EditorGUILayout.EndHorizontal();
    }

    void SendToAI()
    {
        if (string.IsNullOrEmpty(userInput.Trim())) return;
        if (string.IsNullOrEmpty(apiKey))
        {
            Debug.LogWarning("\u8bf7\u5148\u586b\u5199 API Key\uff01");
            return;
        }

        chatHistory.Add(new Message { role = "user", content = userInput });

        List<Message> messages = new List<Message>();
        if (includeProjectContext)
            messages.Add(new Message { role = "system", content = systemPrompt });
        else
            messages.Add(new Message { role = "system", content = "\u4f60\u662fUnity\u6e38\u620f\u5f00\u53d1AI\u52a9\u624b\uff0c\u7528\u4e2d\u6587\u56de\u7b54\uff0c\u7b80\u6d01\u76f4\u63a5\u3002" });

        int startIdx = Mathf.Max(0, chatHistory.Count - 20);
        for (int i = startIdx; i < chatHistory.Count; i++)
            messages.Add(chatHistory[i]);

        ChatRequest req = new ChatRequest
        {
            model = model,
            messages = messages,
            max_tokens = 2000,
            temperature = 0.7f
        };

        string json = Newtonsoft.Json.JsonConvert.SerializeObject(req);
        isWaiting = true;
        Repaint();

        UnityWebRequest request = new UnityWebRequest(apiUrl, "POST");
        byte[] bodyRaw = Encoding.UTF8.GetBytes(json);
        request.uploadHandler = new UploadHandlerRaw(bodyRaw);
        request.downloadHandler = new DownloadHandlerBuffer();
        request.SetRequestHeader("Content-Type", "application/json");
        request.SetRequestHeader("Authorization", "Bearer " + apiKey);

        var op = request.SendWebRequest();
        op.completed += (asyncOp) =>
        {
            isWaiting = false;
            if (request.result == UnityWebRequest.Result.Success)
            {
                try
                {
                    ChatResponse res = Newtonsoft.Json.JsonConvert.DeserializeObject<ChatResponse>(request.downloadHandler.text);
                    if (res.choices != null && res.choices.Count > 0)
                        chatHistory.Add(new Message { role = "assistant", content = res.choices[0].message.content });
                }
                catch (System.Exception e)
                {
                    chatHistory.Add(new Message { role = "assistant", content = "\u89e3\u6790\u5931\u8d25: " + e.Message });
                }
            }
            else
            {
                chatHistory.Add(new Message { role = "assistant", content = "\u8bf7\u6c42\u5931\u8d25: " + request.error });
                Debug.LogError("AI\u8bf7\u6c42\u5931\u8d25: " + request.error + "\n" + request.downloadHandler?.text);
            }
            request.Dispose();
            Repaint();
        };

        userInput = "";
        Repaint();
    }

    string ExtractCode(string content)
    {
        int start = content.IndexOf("```csharp");
        if (start < 0) start = content.IndexOf("```cs");
        if (start < 0) start = content.IndexOf("```");
        if (start < 0) return content;
        start = content.IndexOf('\n', start) + 1;
        int end = content.IndexOf("```", start);
        if (end < 0) return content.Substring(start);
        return content.Substring(start, end - start).Trim();
    }

    void CreateScriptFromCode(string content)
    {
        string code = ExtractCode(content);
        if (string.IsNullOrEmpty(code)) return;

        string className = "NewScript";
        foreach (string line in code.Split('\n'))
        {
            string trimmed = line.Trim();
            if (trimmed.Contains("class "))
            {
                int ci = trimmed.IndexOf("class ") + 6;
                int end2 = trimmed.IndexOfAny(new char[] { ':', '{', ' ' }, ci);
                if (end2 > ci)
                {
                    className = trimmed.Substring(ci, end2 - ci).Trim();
                    break;
                }
            }
        }

        string path = EditorUtility.SaveFilePanel("\u4fdd\u5b58\u811a\u672c", Application.dataPath + "/Scripts", className + ".cs", "cs");
        if (!string.IsNullOrEmpty(path))
        {
            if (path.StartsWith(Application.dataPath))
            {
                File.WriteAllText(path, code);
                AssetDatabase.Refresh();
                Debug.Log("\u811a\u672c\u5df2\u521b\u5efa: " + path);
            }
            else
                Debug.LogWarning("\u8bf7\u4fdd\u5b58\u5230 Assets \u76ee\u5f55\u4e0b");
        }
    }
}