## 主菜单/标题画面 - Beta v0.13
## 游戏入口：标题动画、菜单选项、职业选择、存档信息、背景粒子
## v0.13: 新增职业选择界面（战士/游侠）
extends Node2D

# 菜单选项
var menu_items: Array = []
var selected_index: int = 0
var frame_count: int = 0

# 视觉元素
var title_label: Label
var subtitle_label: Label
var version_label: Label
var cursor: ColorRect
var bg_particles: Array = []
var save_info_label: Label = null

# 职业选择
var class_select_active: bool = false
var class_select_index: int = 0  # 0=战士, 1=游侠
var class_nodes: Array = []  # 职业选择界面的节点
var warrior_desc: Label
var ranger_desc: Label
var warrior_stats: Label
var ranger_stats: Label
var class_cursor: ColorRect

# 场景路径
const SCENES = {
        "training": "res://scenes/levels/training_ground.tscn",
        "mine": "res://scenes/levels/mine_level.tscn",
        "boss": "res://scenes/levels/boss_arena.tscn",
        "lava": "res://scenes/levels/lava_level.tscn",
        "lava_boss": "res://scenes/levels/lava_boss.tscn",
}

# 淡入淡出
var fade_overlay: ColorRect
var is_transitioning: bool = false
var fade_alpha: float = 0.0
var target_scene: String = ""

func _ready() -> void:
        _build_scene()

func _build_scene() -> void:
        # === 背景 ===
        var bg = ColorRect.new()
        bg.size = Vector2(640, 360)
        bg.color = Color(0.03, 0.03, 0.08, 1.0)
        add_child(bg)

        # 背景装饰粒子（飘浮的矿石光点）
        for i in range(30):
                var p = ColorRect.new()
                p.size = Vector2(randf_range(1, 3), randf_range(1, 3))
                p.position = Vector2(randf() * 640, randf() * 360)
                var colors = [Color(0.4, 0.6, 0.8, 0.4), Color(0.6, 0.4, 0.8, 0.3), Color(0.8, 0.7, 0.3, 0.3)]
                p.color = colors[i % 3]
                add_child(p)
                bg_particles.append({
                        "node": p,
                        "vel": Vector2(randf_range(-8, 8), randf_range(-15, -5)),
                        "base_y": p.position.y,
                        "phase": randf() * TAU,
                })

        # 地面装饰
        var ground = ColorRect.new()
        ground.position = Vector2(0, 320)
        ground.size = Vector2(640, 40)
        ground.color = Color(0.08, 0.07, 0.12, 1.0)
        add_child(ground)

        # 地面裂缝装饰
        for x in [50, 180, 320, 450, 580]:
                var crack = ColorRect.new()
                crack.position = Vector2(x, 319)
                crack.size = Vector2(randf_range(5, 15), 2)
                crack.color = Color(0.15, 0.12, 0.2, 0.6)
                add_child(crack)

        # 装饰性柱子
        for x_pos in [80, 560]:
                var pillar = ColorRect.new()
                pillar.position = Vector2(x_pos, 180)
                pillar.size = Vector2(20, 140)
                pillar.color = Color(0.1, 0.09, 0.15, 0.8)
                add_child(pillar)
                var cap = ColorRect.new()
                cap.position = Vector2(x_pos - 5, 175)
                cap.size = Vector2(30, 8)
                cap.color = Color(0.15, 0.12, 0.2, 0.9)
                add_child(cap)

        # === 游戏标题 ===
        title_label = Label.new()
        title_label.text = "代号：传说"
        title_label.position = Vector2(170, 60)
        title_label.add_theme_font_size_override("font_size", 36)
        title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1.0))
        add_child(title_label)

        # 副标题
        subtitle_label = Label.new()
        subtitle_label.text = "CODE: LEGEND"
        subtitle_label.position = Vector2(215, 105)
        subtitle_label.add_theme_font_size_override("font_size", 12)
        subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 0.7))
        add_child(subtitle_label)

        # 装饰线
        var line = ColorRect.new()
        line.position = Vector2(200, 125)
        line.size = Vector2(240, 1)
        line.color = Color(0.5, 0.4, 0.3, 0.4)
        add_child(line)

        # === 菜单选项 ===
        var menu_data = []
        if SaveSystem.has_save:
                menu_data.append({"text": "继续游戏", "scene": "continue"})
        menu_data.append({"text": "开始冒险", "scene": "mine"})
        menu_data.append({"text": "失落地脉", "scene": "lava"})
        menu_data.append({"text": "训练场", "scene": "training"})
        menu_data.append({"text": "Boss挑战(甲虫)", "scene": "boss"})
        menu_data.append({"text": "Boss挑战(熔岩龟)", "scene": "lava_boss"})

        var start_y: float = 160
        for i in range(menu_data.size()):
                var item = Label.new()
                item.text = menu_data[i]["text"]
                item.position = Vector2(260, start_y + i * 35)
                item.add_theme_font_size_override("font_size", 14)
                item.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))
                add_child(item)
                menu_items.append({"label": item, "scene": menu_data[i]["scene"]})

        # 选中光标
        cursor = ColorRect.new()
        cursor.size = Vector2(8, 8)
        cursor.position = Vector2(245, start_y + selected_index * 35 + 5)
        cursor.color = Color(0.9, 0.75, 0.3, 1.0)
        add_child(cursor)

        # === 底部信息 ===
        version_label = Label.new()
        version_label.text = "Beta v0.13"
        version_label.position = Vector2(560, 345)
        version_label.add_theme_font_size_override("font_size", 7)
        version_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.5))
        add_child(version_label)

        # === 存档信息 ===
        if SaveSystem.has_save:
                var info: Dictionary = SaveSystem.get_save_info()
                save_info_label = Label.new()
                var save_text: String = "存档: " + str(info.get("play_time", "")) + " | 击杀:" + str(info.get("total_kills", 0)) + " | 矿石:" + str(info.get("ore_fragments", 0))
                var mat_text: String = str(info.get("materials", ""))
                if mat_text != "":
                        save_text += " | " + mat_text
                save_info_label.text = save_text
                save_info_label.position = Vector2(180, 330)
                save_info_label.add_theme_font_size_override("font_size", 7)
                save_info_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35, 0.6))
                add_child(save_info_label)

        var controls = Label.new()
        controls.text = "W/S:选择  Enter/J:确认  Esc:退出"
        controls.position = Vector2(200, 300)
        controls.add_theme_font_size_override("font_size", 8)
        controls.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 0.6))
        add_child(controls)

        # 版权
        var copyright_label = Label.new()
        copyright_label.text = "Powered by Godot 4.6"
        copyright_label.position = Vector2(510, 345)
        copyright_label.add_theme_font_size_override("font_size", 7)
        copyright_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35, 0.4))
        add_child(copyright_label)

        # === 淡入淡出遮罩 ===
        fade_overlay = ColorRect.new()
        fade_overlay.size = Vector2(640, 360)
        fade_overlay.color = Color(0, 0, 0, 0)
        add_child(fade_overlay)

        # 初始淡入效果
        fade_alpha = 1.0
        fade_overlay.color = Color(0, 0, 0, 1)

        # === 职业选择界面（默认隐藏）===
        _build_class_select()

func _build_class_select() -> void:
        # 全屏半透明遮罩
        var overlay = ColorRect.new()
        overlay.size = Vector2(640, 360)
        overlay.color = Color(0, 0, 0, 0.85)
        overlay.visible = false
        add_child(overlay)
        class_nodes.append(overlay)

        # 标题
        var cs_title = Label.new()
        cs_title.text = "选 择 职 业"
        cs_title.position = Vector2(240, 30)
        cs_title.add_theme_font_size_override("font_size", 20)
        cs_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
        cs_title.visible = false
        add_child(cs_title)
        class_nodes.append(cs_title)

        # === 战士面板 ===
        var w_panel = ColorRect.new()
        w_panel.size = Vector2(260, 220)
        w_panel.position = Vector2(40, 70)
        w_panel.color = Color(0.12, 0.1, 0.08, 0.9)
        w_panel.visible = false
        add_child(w_panel)
        class_nodes.append(w_panel)

        var w_border = ColorRect.new()
        w_border.size = Vector2(264, 224)
        w_border.position = Vector2(38, 68)
        w_border.color = Color(0.8, 0.65, 0.3, 0.8)
        w_border.visible = false
        add_child(w_border)
        class_nodes.append(w_border)

        var w_name = Label.new()
        w_name.text = "战  士"
        w_name.position = Vector2(120, 80)
        w_name.add_theme_font_size_override("font_size", 18)
        w_name.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
        w_name.visible = false
        add_child(w_name)
        class_nodes.append(w_name)

        var w_icon = ColorRect.new()
        w_icon.size = Vector2(40, 40)
        w_icon.position = Vector2(150, 105)
        w_icon.color = Color(0.8, 0.65, 0.3, 0.6)
        w_icon.visible = false
        add_child(w_icon)
        class_nodes.append(w_icon)

        warrior_desc = Label.new()
        warrior_desc.text = "近战重装战士，以怒气驱动强力技能"
        warrior_desc.position = Vector2(55, 150)
        warrior_desc.add_theme_font_size_override("font_size", 8)
        warrior_desc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
        warrior_desc.visible = false
        add_child(warrior_desc)
        class_nodes.append(warrior_desc)

        warrior_stats = Label.new()
        warrior_stats.text = "HP:100  ATK:高  DEF:高  SPD:中\n怒气系统(0-100): 命中+怒气\n格挡: L键 完美格挡=0伤害+回血\n战吼: U键(50怒气) +15%伤害8秒\n裂地斩: I键(100怒气) AOE"
        warrior_stats.position = Vector2(55, 165)
        warrior_stats.add_theme_font_size_override("font_size", 7)
        warrior_stats.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
        warrior_stats.visible = false
        add_child(warrior_stats)
        class_nodes.append(warrior_stats)

        # === 游侠面板 ===
        var r_panel = ColorRect.new()
        r_panel.size = Vector2(260, 220)
        r_panel.position = Vector2(340, 70)
        r_panel.color = Color(0.08, 0.12, 0.1, 0.9)
        r_panel.visible = false
        add_child(r_panel)
        class_nodes.append(r_panel)

        var r_border = ColorRect.new()
        r_border.size = Vector2(264, 224)
        r_border.position = Vector2(338, 68)
        r_border.color = Color(0.3, 0.7, 0.5, 0.8)
        r_border.visible = false
        add_child(r_border)
        class_nodes.append(r_border)

        var r_name = Label.new()
        r_name.text = "游  侠"
        r_name.position = Vector2(420, 80)
        r_name.add_theme_font_size_override("font_size", 18)
        r_name.add_theme_color_override("font_color", Color(0.4, 0.85, 0.6))
        r_name.visible = false
        add_child(r_name)
        class_nodes.append(r_name)

        var r_icon = ColorRect.new()
        r_icon.size = Vector2(40, 40)
        r_icon.position = Vector2(450, 105)
        r_icon.color = Color(0.3, 0.7, 0.5, 0.6)
        r_icon.visible = false
        add_child(r_icon)
        class_nodes.append(r_icon)

        ranger_desc = Label.new()
        ranger_desc.text = "敏捷暗影刺客，以连击点释放致命技能"
        ranger_desc.position = Vector2(355, 150)
        ranger_desc.add_theme_font_size_override("font_size", 8)
        ranger_desc.add_theme_color_override("font_color", Color(0.65, 0.8, 0.7))
        ranger_desc.visible = false
        add_child(ranger_desc)
        class_nodes.append(ranger_desc)

        ranger_stats = Label.new()
        ranger_stats.text = "HP:80  ATK:中  DEF:低  SPD:快\n连击点(0-5): 命中+1点 4秒-1点\n闪避: L键 0.35秒无敌 完美闪避+1CP\n影步: U键(2CP) 传送+40%伤害2秒\n刃风暴: I键(5CP) 旋转AOE"
        ranger_stats.position = Vector2(355, 165)
        ranger_stats.add_theme_font_size_override("font_size", 7)
        ranger_stats.add_theme_color_override("font_color", Color(0.5, 0.65, 0.55))
        ranger_stats.visible = false
        add_child(ranger_stats)
        class_nodes.append(ranger_stats)

        # 光标
        class_cursor = ColorRect.new()
        class_cursor.size = Vector2(12, 12)
        class_cursor.position = Vector2(140, 92)
        class_cursor.color = Color(0.9, 0.75, 0.3, 1.0)
        class_cursor.visible = false
        add_child(class_cursor)
        class_nodes.append(class_cursor)

        # 操作提示
        var cs_hint = Label.new()
        cs_hint.text = "A/D:选择职业  Enter/J:确认  Esc:返回"
        cs_hint.position = Vector2(200, 310)
        cs_hint.add_theme_font_size_override("font_size", 8)
        cs_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
        cs_hint.visible = false
        add_child(cs_hint)
        class_nodes.append(cs_hint)

        # NEW标签
        var new_label = Label.new()
        new_label.text = "NEW!"
        new_label.position = Vector2(480, 78)
        new_label.add_theme_font_size_override("font_size", 10)
        new_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 1.0))
        new_label.visible = false
        add_child(new_label)
        class_nodes.append(new_label)

func _physics_process(delta: float) -> void:
        frame_count += 1

        if is_transitioning:
                fade_alpha = min(1.0, fade_alpha + delta * 2.0)
                fade_overlay.color = Color(0, 0, 0, fade_alpha)
                if fade_alpha >= 1.0:
                        get_tree().change_scene_to_file(target_scene)
                return

        # 淡入
        if fade_alpha > 0:
                fade_alpha = max(0, fade_alpha - delta * 1.5)
                fade_overlay.color = Color(0, 0, 0, fade_alpha)

        # 更新背景粒子
        for p in bg_particles:
                var node: ColorRect = p["node"]
                p["phase"] += delta * 0.5
                node.position.x += p["vel"].x * delta
                node.position.y = p["base_y"] + sin(p["phase"]) * 15
                if node.position.x < -10:
                        node.position.x = 650
                elif node.position.x > 650:
                        node.position.x = -10

        # 标题闪烁效果
        if title_label:
                var glow = 0.85 + 0.15 * sin(frame_count * 0.03)
                title_label.add_theme_color_override("font_color", Color(0.9 * glow, 0.75 * glow, 0.3 * glow, 1.0))

        # === 职业选择界面 ===
        if class_select_active:
                _process_class_select()
                return

        # === 主菜单输入 ===
        if Input.is_action_just_pressed("move_left") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
                selected_index = (selected_index - 1) % menu_items.size()
                if selected_index < 0:
                        selected_index = menu_items.size() - 1
                _update_cursor()

        if Input.is_action_just_pressed("move_right") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
                selected_index = (selected_index + 1) % menu_items.size()
                _update_cursor()

        # 确认选择
        if Input.is_key_pressed(KEY_ENTER) or Input.is_action_just_pressed("attack"):
                _confirm_selection()

        # 退出
        if Input.is_key_pressed(KEY_ESCAPE):
                get_tree().quit()

func _process_class_select() -> void:
        # A/D选择职业
        if Input.is_action_just_pressed("move_left"):
                class_select_index = 0
                _update_class_cursor()
        if Input.is_action_just_pressed("move_right"):
                class_select_index = 1
                _update_class_cursor()

        # W/S也可以选择
        if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
                class_select_index = 0
                _update_class_cursor()
        if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
                class_select_index = 1
                _update_class_cursor()

        # 确认
        if Input.is_key_pressed(KEY_ENTER) or Input.is_action_just_pressed("attack"):
                _confirm_class_selection()

        # 返回
        if Input.is_key_pressed(KEY_ESCAPE):
                _close_class_select()

func _update_class_cursor() -> void:
        if class_cursor:
                if class_select_index == 0:
                        class_cursor.position = Vector2(140, 92)
                        class_cursor.color = Color(0.9, 0.75, 0.3, 1.0)
                else:
                        class_cursor.position = Vector2(440, 92)
                        class_cursor.color = Color(0.3, 0.85, 0.5, 1.0)

        # 高亮选中面板的边框
        # 战士面板边框索引=3, 游侠面板边框索引=9
        if class_select_index == 0:
                if class_nodes.size() > 3:
                        class_nodes[3].color = Color(0.9, 0.75, 0.3, 1.0)
                if class_nodes.size() > 9:
                        class_nodes[9].color = Color(0.3, 0.7, 0.5, 0.4)
        else:
                if class_nodes.size() > 3:
                        class_nodes[3].color = Color(0.8, 0.65, 0.3, 0.4)
                if class_nodes.size() > 9:
                        class_nodes[9].color = Color(0.3, 0.85, 0.5, 1.0)

func _confirm_class_selection() -> void:
        if class_select_index == 0:
                GameState.selected_class = "warrior"
        else:
                GameState.selected_class = "ranger"
        _close_class_select()
        # 继续进入关卡
        _goto_selected_scene()

func _close_class_select() -> void:
        class_select_active = false
        for node in class_nodes:
                if is_instance_valid(node):
                        node.visible = false

func _show_class_select() -> void:
        class_select_active = true
        class_select_index = 0 if GameState.selected_class == "warrior" else 1
        for node in class_nodes:
                if is_instance_valid(node):
                        node.visible = true
        _update_class_cursor()

func _update_cursor() -> void:
        if cursor:
                cursor.position.y = 160 + selected_index * 35 + 5
        for i in range(menu_items.size()):
                var label: Label = menu_items[i]["label"]
                if i == selected_index:
                        label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1.0))
                else:
                        label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))

func _confirm_selection() -> void:
        if is_transitioning:
                return
        var scene_key: String = menu_items[selected_index]["scene"]

        # 继续游戏：加载存档后进入上次关卡
        if scene_key == "continue":
                SaveSystem.load_game()
                var last_level: String = GameState.current_level
                if last_level == "" or not SCENES.has(last_level):
                        last_level = "mine"
                target_scene = SCENES[last_level]
                is_transitioning = true
                return

        # 新游戏 - 显示职业选择
        if scene_key == "mine":
                if SaveSystem.has_save:
                        SaveSystem.new_game()
                # 显示职业选择界面
                _show_class_select()
                return

        # 其他关卡 - 也需要职业选择（如果是新游戏）
        if not SaveSystem.has_save and GameState.selected_class == "":
                _show_class_select()
                return

        _goto_selected_scene()

func _goto_selected_scene() -> void:
        var scene_key: String = menu_items[selected_index]["scene"]
        if scene_key == "continue":
                scene_key = GameState.current_level
                if scene_key == "" or not SCENES.has(scene_key):
                        scene_key = "mine"

        if SCENES.has(scene_key):
                target_scene = SCENES[scene_key]
                is_transitioning = true

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img:
                img.save_png("/home/z/my-project/download/" + filename)
                print("Screenshot saved: " + filename)
