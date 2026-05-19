## 主菜单/标题画面 - Alpha v0.9
## 游戏入口：标题动画、菜单选项、存档信息、背景粒子
## v0.9新增：继续游戏选项、存档信息显示
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

# 场景路径
const SCENES = {
        "training": "res://scenes/levels/training_ground.tscn",
        "mine": "res://scenes/levels/mine_level.tscn",
        "boss": "res://scenes/levels/boss_arena.tscn",
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
                # 柱顶
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
        menu_data.append({"text": "训练场", "scene": "training"})
        menu_data.append({"text": "Boss挑战", "scene": "boss"})

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
        version_label.text = "Alpha v0.9"
        version_label.position = Vector2(560, 345)
        version_label.add_theme_font_size_override("font_size", 7)
        version_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.5))
        add_child(version_label)

        # === 存档信息 ===
        if SaveSystem.has_save:
                var info: Dictionary = SaveSystem.get_save_info()
                save_info_label = Label.new()
                var save_text: String = "存档: " + str(info.get("play_time", "")) + " | 击杀:" + str(info.get("total_kills", 0)) + " | 矿石:" + str(info.get("ore_fragments", 0))
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

        # 自动截图（第180帧时截图，用于验证渲染）
        if frame_count == 180:
                _take_screenshot("legend_v07_title.png")

        # 更新背景粒子
        for p in bg_particles:
                var node: ColorRect = p["node"]
                p["phase"] += delta * 0.5
                node.position.x += p["vel"].x * delta
                node.position.y = p["base_y"] + sin(p["phase"]) * 15
                # 边界循环
                if node.position.x < -10:
                        node.position.x = 650
                elif node.position.x > 650:
                        node.position.x = -10

        # 标题闪烁效果
        if title_label:
                var glow = 0.85 + 0.15 * sin(frame_count * 0.03)
                title_label.add_theme_color_override("font_color", Color(0.9 * glow, 0.75 * glow, 0.3 * glow, 1.0))

        # 菜单输入
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

func _update_cursor() -> void:
        if cursor:
                cursor.position.y = 160 + selected_index * 35 + 5
        # 更新选项颜色
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

        # 新游戏
        if scene_key == "mine" and SaveSystem.has_save:
                # 有存档时开始新游戏会重置进度
                SaveSystem.new_game()

        if SCENES.has(scene_key):
                target_scene = SCENES[scene_key]
                is_transitioning = true

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img:
                img.save_png("/home/z/my-project/download/" + filename)
                print("Screenshot saved: " + filename)
