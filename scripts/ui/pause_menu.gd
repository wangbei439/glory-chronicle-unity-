## 暂停菜单 - Beta v0.22
## 覆盖层：暂停游戏、恢复/设置/退出
## 键盘操作：W/S选择, Enter确认, Esc恢复
## v0.22: 使用CanvasLayer固定在屏幕中央，不随相机移动
extends CanvasLayer

signal resume_pressed
signal settings_pressed
signal quit_pressed

var is_open: bool = false
var frame_count: int = 0
var selected_index: int = 0

# 菜单选项
var menu_items: Array = []
var menu_bgs: Array = []
var menu_borders: Array = []

# 视觉元素
var overlay: ColorRect
var title_label: Label
var title_shadow: Label

# 容器节点 - 所有UI元素放在这个Node2D下
var container: Node2D

# 输入冷却
var _input_cooldown: float = 0.0
const INPUT_COOLDOWN_TIME: float = 0.15

func _ready() -> void:
        layer = 10  # 在默认层之上
        build()

func build() -> void:
        # 所有UI元素放在container下，确保在CanvasLayer中正确渲染
        container = Node2D.new()
        add_child(container)

        # === 全屏半透明遮罩 ===
        overlay = ColorRect.new()
        overlay.size = Vector2(640, 360)
        overlay.color = Color(0, 0, 0, 0.0)
        overlay.visible = false
        container.add_child(overlay)

        # === 中央面板背景 ===
        var panel_bg = ColorRect.new()
        panel_bg.size = Vector2(240, 200)
        panel_bg.position = Vector2(200, 80)
        panel_bg.color = Color(0.05, 0.05, 0.10, 0.95)
        panel_bg.visible = false
        container.add_child(panel_bg)

        # 面板边框
        var panel_border = ColorRect.new()
        panel_border.size = Vector2(244, 204)
        panel_border.position = Vector2(198, 78)
        panel_border.color = Color(0.5, 0.45, 0.35, 0.7)
        panel_border.visible = false
        container.add_child(panel_border)

        # 内侧高光
        var panel_inner = ColorRect.new()
        panel_inner.size = Vector2(238, 198)
        panel_inner.position = Vector2(201, 81)
        panel_inner.color = Color(0.08, 0.08, 0.12, 0.3)
        panel_inner.visible = false
        container.add_child(panel_inner)

        # 顶部装饰线
        var top_line = ColorRect.new()
        top_line.size = Vector2(200, 2)
        top_line.position = Vector2(220, 96)
        top_line.color = Color(0.7, 0.6, 0.35, 0.5)
        top_line.visible = false
        container.add_child(top_line)

        # === 标题阴影 ===
        title_shadow = Label.new()
        title_shadow.text = "PAUSED"
        title_shadow.position = Vector2(268, 100)
        title_shadow.add_theme_font_size_override("font_size", 22)
        title_shadow.add_theme_color_override("font_color", Color(0, 0, 0, 0.5))
        title_shadow.visible = false
        container.add_child(title_shadow)

        # === 标题 ===
        title_label = Label.new()
        title_label.text = "PAUSED"
        title_label.position = Vector2(265, 98)
        title_label.add_theme_font_size_override("font_size", 22)
        title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
        title_label.visible = false
        container.add_child(title_label)

        # 副标题
        var subtitle = Label.new()
        subtitle.text = "游戏暂停"
        subtitle.position = Vector2(280, 125)
        subtitle.add_theme_font_size_override("font_size", 8)
        subtitle.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 0.5))
        subtitle.visible = false
        container.add_child(subtitle)

        # === 菜单选项 ===
        var options = [
                {"text": "继续游戏", "action": "resume"},
                {"text": "游戏设置", "action": "settings"},
                {"text": "返回主菜单", "action": "quit"},
        ]

        var start_y: float = 145
        for i in range(options.size()):
                # 按钮边框
                var border = ColorRect.new()
                border.size = Vector2(180, 28)
                border.position = Vector2(228, start_y + i * 38 - 4)
                border.color = Color(0, 0, 0, 0)
                border.visible = false
                container.add_child(border)
                menu_borders.append(border)

                # 按钮背景
                var bg = ColorRect.new()
                bg.size = Vector2(178, 26)
                bg.position = Vector2(229, start_y + i * 38 - 3)
                bg.color = Color(0, 0, 0, 0)
                bg.visible = false
                container.add_child(bg)
                menu_bgs.append(bg)

                # 文字阴影
                var item_shadow = Label.new()
                item_shadow.text = options[i]["text"]
                item_shadow.position = Vector2(294, start_y + i * 38 + 2)
                item_shadow.add_theme_font_size_override("font_size", 12)
                item_shadow.add_theme_color_override("font_color", Color(0, 0, 0, 0.4))
                item_shadow.visible = false
                container.add_child(item_shadow)

                # 文字
                var item = Label.new()
                item.text = options[i]["text"]
                item.position = Vector2(291, start_y + i * 38)
                item.add_theme_font_size_override("font_size", 12)
                item.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))
                item.visible = false
                container.add_child(item)

                menu_items.append({"label": item, "action": options[i]["action"]})

        # 底部提示
        var hint = Label.new()
        hint.text = "W/S:选择  Enter:确认  Esc:恢复"
        hint.position = Vector2(218, 265)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 0.5))
        hint.visible = false
        container.add_child(hint)

func open() -> void:
        is_open = true
        selected_index = 0
        _input_cooldown = 0.2
        _show_all_children()

        # 淡入遮罩
        overlay.color = Color(0, 0, 0, 0)
        var tween = create_tween()
        tween.tween_property(overlay, "color:a", 0.6, 0.3)

        _update_selection()

func close() -> void:
        is_open = false
        _hide_all_children()
        overlay.visible = false

func process_input(delta: float) -> void:
        frame_count += 1
        _input_cooldown = max(0, _input_cooldown - delta)

        # Esc恢复
        if Input.is_action_just_pressed("menu_quit"):
                close()
                resume_pressed.emit()
                return

        # 上下选择
        if Input.is_action_just_pressed("menu_up"):
                if _input_cooldown <= 0:
                        selected_index = (selected_index - 1) % menu_items.size()
                        if selected_index < 0:
                                selected_index = menu_items.size() - 1
                        _input_cooldown = INPUT_COOLDOWN_TIME
                        _update_selection()

        if Input.is_action_just_pressed("menu_down"):
                if _input_cooldown <= 0:
                        selected_index = (selected_index + 1) % menu_items.size()
                        _input_cooldown = INPUT_COOLDOWN_TIME
                        _update_selection()

        # 确认
        if Input.is_action_just_pressed("menu_confirm"):
                if _input_cooldown <= 0:
                        _confirm()

        # 标题闪烁
        if title_label:
                var glow = 0.85 + 0.15 * sin(frame_count * 0.04)
                title_label.add_theme_color_override("font_color", Color(0.9 * glow, 0.85 * glow, 0.7, 1.0))

func _update_selection() -> void:
        for i in range(menu_items.size()):
                var label: Label = menu_items[i]["label"]
                var bg: ColorRect = menu_bgs[i]
                var border: ColorRect = menu_borders[i]
                if i == selected_index:
                        label.add_theme_color_override("font_color", Color(1, 0.92, 0.5, 1.0))
                        bg.color = Color(0.92, 0.78, 0.32, 0.12)
                        border.color = Color(0.92, 0.78, 0.32, 0.35)
                else:
                        label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))
                        bg.color = Color(0, 0, 0, 0)
                        border.color = Color(0, 0, 0, 0)

func _confirm() -> void:
        var action: String = menu_items[selected_index]["action"]
        close()
        match action:
                "resume":
                        resume_pressed.emit()
                "settings":
                        settings_pressed.emit()
                "quit":
                        quit_pressed.emit()

func _show_all_children() -> void:
        for child in container.get_children():
                if child is ColorRect or child is Label or child is TextureRect:
                        child.visible = true

func _hide_all_children() -> void:
        for child in container.get_children():
                if child is ColorRect or child is Label or child is TextureRect:
                        child.visible = false
