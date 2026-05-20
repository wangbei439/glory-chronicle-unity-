## 物品栏UI - Beta v0.10
## 显示收集的物品和数量，Shift+Tab切换
## v0.10: 修复物品计数追踪，增加装备栏位显示
extends Node2D

# === UI状态 ===
var is_open: bool = false
var panel_nodes: Array = []

# === 外部引用 ===
var drop_system: Node2D = null

# === 物品数据 ===
var item_labels: Dictionary = {}

# === 装备栏 ===
var equipment_label: Label = null

func _ready() -> void:
        pass

func set_drop_system(ds: Node2D) -> void:
        drop_system = ds

func build() -> void:
        """构建物品栏UI面板"""
        # 边框（纹理面板框架）
        var border_frame_tex = load("res://assets/sprites/ui/panel_frame_280x200.png")
        var border: TextureRect = null
        if border_frame_tex:
                border = TextureRect.new()
                border.texture = border_frame_tex
                border.size = Vector2(264, 204)
                border.position = Vector2(188, 78)
                border.stretch_mode = TextureRect.STRETCH_SCALE
                border.visible = false
                add_child(border)
        else:
                var border_fallback = ColorRect.new()
                border_fallback.size = Vector2(264, 204)
                border_fallback.position = Vector2(188, 78)
                border_fallback.color = Color(0.4, 0.35, 0.3, 0.8)
                border_fallback.visible = false
                add_child(border_fallback)
        panel_nodes.append(border if border else get_child(get_child_count() - 1))

        # 背景
        var panel_bg = ColorRect.new()
        panel_bg.size = Vector2(260, 200)
        panel_bg.position = Vector2(190, 80)
        panel_bg.color = Color(0.05, 0.05, 0.1, 0.92)
        panel_bg.visible = false
        add_child(panel_bg)
        panel_nodes.append(panel_bg)

        # 标题
        var title = Label.new()
        title.text = "物 品 栏"
        title.position = Vector2(270, 84)
        title.add_theme_font_size_override("font_size", 12)
        title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
        title.visible = false
        add_child(title)
        panel_nodes.append(title)

        # 物品列表
        var items_data = [
                {"key": "health_potion", "name": "生命药水", "color": Color(0.2, 0.9, 0.3), "desc": "+20HP"},
                {"key": "rage_crystal", "name": "怒气水晶", "color": Color(0.9, 0.4, 0.1), "desc": "+20怒"},
                {"key": "ore_fragment", "name": "矿石碎片", "color": Color(0.7, 0.6, 0.9), "desc": "技能货币"},
        ]

        var start_y: float = 108
        for i in range(items_data.size()):
                var info = items_data[i]

                # 行分隔线
                if i > 0:
                        var sep_line = ColorRect.new()
                        sep_line.size = Vector2(220, 1)
                        sep_line.position = Vector2(210, start_y + i * 28 - 5)
                        sep_line.color = Color(0.25, 0.25, 0.3, 0.3)
                        sep_line.visible = false
                        add_child(sep_line)
                        panel_nodes.append(sep_line)

                # 物品图标（稍大 14x14）
                var icon = ColorRect.new()
                icon.size = Vector2(14, 14)
                icon.position = Vector2(206, start_y + i * 28 - 1)
                icon.color = info["color"]
                icon.visible = false
                add_child(icon)
                panel_nodes.append(icon)

                # 物品名称
                var name_label = Label.new()
                name_label.text = info["name"]
                name_label.position = Vector2(224, start_y + i * 28 - 2)
                name_label.add_theme_font_size_override("font_size", 9)
                name_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
                name_label.visible = false
                add_child(name_label)
                panel_nodes.append(name_label)

                # 物品描述
                var desc_label = Label.new()
                desc_label.text = info["desc"]
                desc_label.position = Vector2(300, start_y + i * 28 - 2)
                desc_label.add_theme_font_size_override("font_size", 7)
                desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
                desc_label.visible = false
                add_child(desc_label)
                panel_nodes.append(desc_label)

                # 物品数量
                var count_label = Label.new()
                count_label.text = "x0"
                count_label.position = Vector2(380, start_y + i * 28 - 2)
                count_label.add_theme_font_size_override("font_size", 9)
                count_label.add_theme_color_override("font_color", info["color"])
                count_label.visible = false
                add_child(count_label)
                panel_nodes.append(count_label)

                item_labels[info["key"]] = count_label

        # 装备栏分隔线
        var sep = ColorRect.new()
        sep.size = Vector2(230, 1)
        sep.position = Vector2(205, start_y + items_data.size() * 28 + 2)
        sep.color = Color(0.3, 0.3, 0.3, 0.5)
        sep.visible = false
        add_child(sep)
        panel_nodes.append(sep)

        # 装备栏标题
        var equip_title = Label.new()
        equip_title.text = "装 备"
        equip_title.position = Vector2(270, start_y + items_data.size() * 28 + 8)
        equip_title.add_theme_font_size_override("font_size", 10)
        equip_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
        equip_title.visible = false
        add_child(equip_title)
        panel_nodes.append(equip_title)

        # 装备栏内容（从GameState读取当前装备）
        equipment_label = Label.new()
        equipment_label.text = "无装备"
        equipment_label.position = Vector2(210, start_y + items_data.size() * 28 + 24)
        equipment_label.add_theme_font_size_override("font_size", 8)
        equipment_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
        equipment_label.visible = false
        add_child(equipment_label)
        panel_nodes.append(equipment_label)

        # 操作提示
        var hint = Label.new()
        hint.text = "Shift+Tab:关闭"
        hint.position = Vector2(250, 268)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
        hint.visible = false
        add_child(hint)
        panel_nodes.append(hint)

func toggle() -> void:
        is_open = not is_open
        for node in panel_nodes:
                if is_instance_valid(node):
                        node.visible = is_open
        if is_open:
                _update_display()

func close() -> void:
        is_open = false
        for node in panel_nodes:
                if is_instance_valid(node):
                        node.visible = false

func process_input() -> void:
        if not is_open:
                return
        if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_TAB):
                close()

func _update_display() -> void:
        """更新物品数量显示"""
        if drop_system:
                if item_labels.has("ore_fragment"):
                        item_labels["ore_fragment"].text = "x" + str(drop_system.get_ore_count())
                if item_labels.has("health_potion"):
                        item_labels["health_potion"].text = "x" + str(drop_system.get_potion_count())
                if item_labels.has("rage_crystal"):
                        item_labels["rage_crystal"].text = "x" + str(drop_system.get_crystal_count())

        # 更新装备显示
        if equipment_label:
                var equip_text: String = ""
                if GameState.equipped_weapon != "":
                        equip_text += "武器: " + GameState.equipped_weapon + "  "
                if GameState.equipped_armor != "":
                        equip_text += "护甲: " + GameState.equipped_armor
                if equip_text == "":
                        equip_text = "无装备"
                equipment_label.text = equip_text
