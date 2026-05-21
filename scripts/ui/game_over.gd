## GameOver 死亡画面 - Beta v0.19
## 覆盖层：显示战斗统计、重试/返回主菜单
## 键盘操作：R重试 / Q返回主菜单
extends CanvasLayer

signal retry_pressed
signal quit_pressed

var is_open: bool = false
var frame_count: int = 0

# 视觉元素
var overlay: ColorRect
var title_shadow: Label
var title_label: Label
var stats_labels: Array = []
var retry_btn: Label
var retry_bg: ColorRect
var quit_btn: Label
var quit_bg: ColorRect
var selected_option: int = 0  # 0=重试, 1=退出
var skull_sprite: TextureRect

# 统计数据
var stats: Dictionary = {}

# 输入冷却
var _input_cooldown: float = 0.0
const INPUT_COOLDOWN_TIME: float = 0.18

func _ready() -> void:
	layer = 10
	build()

func build() -> void:
	# === 全屏半透明遮罩 ===
	overlay = ColorRect.new()
	overlay.size = Vector2(640, 360)
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.visible = false
	overlay.z_index = 500
	add_child(overlay)

	# === 中央面板背景 ===
	var panel_bg = ColorRect.new()
	panel_bg.size = Vector2(320, 240)
	panel_bg.position = Vector2(160, 60)
	panel_bg.color = Color(0.06, 0.04, 0.08, 0.95)
	panel_bg.visible = false
	panel_bg.z_index = 501
	add_child(panel_bg)

	# 面板边框（暗红色调）
	var panel_border = ColorRect.new()
	panel_border.size = Vector2(324, 244)
	panel_border.position = Vector2(158, 58)
	panel_border.color = Color(0.6, 0.12, 0.08, 0.8)
	panel_border.visible = false
	panel_border.z_index = 500
	add_child(panel_border)

	# 面板内侧高光
	var panel_inner = ColorRect.new()
	panel_inner.size = Vector2(318, 238)
	panel_inner.position = Vector2(161, 61)
	panel_inner.color = Color(0.15, 0.06, 0.04, 0.3)
	panel_inner.visible = false
	panel_inner.z_index = 501
	add_child(panel_inner)

	# 顶部装饰线
	var top_line = ColorRect.new()
	top_line.size = Vector2(280, 2)
	top_line.position = Vector2(180, 76)
	top_line.color = Color(0.7, 0.15, 0.1, 0.6)
	top_line.visible = false
	top_line.z_index = 502
	add_child(top_line)

	# === 骷髅头标记 ===
	skull_sprite = TextureRect.new()
	skull_sprite.size = Vector2(32, 32)
	skull_sprite.position = Vector2(304, 68)
	skull_sprite.z_index = 502
	skull_sprite.visible = false
	add_child(skull_sprite)

	# === 标题阴影 ===
	title_shadow = Label.new()
	title_shadow.text = "YOU DIED"
	title_shadow.position = Vector2(233, 84)
	title_shadow.add_theme_font_size_override("font_size", 28)
	title_shadow.add_theme_color_override("font_color", Color(0, 0, 0, 0.6))
	title_shadow.visible = false
	title_shadow.z_index = 502
	add_child(title_shadow)

	# === 标题 ===
	title_label = Label.new()
	title_label.text = "YOU DIED"
	title_label.position = Vector2(230, 82)
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.85, 0.12, 0.08, 1.0))
	title_label.visible = false
	title_label.z_index = 502
	add_child(title_label)

	# 副标题
	var subtitle = Label.new()
	subtitle.text = "魂归深渊"
	subtitle.position = Vector2(272, 114)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.35, 0.3, 0.7))
	subtitle.visible = false
	subtitle.z_index = 502
	add_child(subtitle)

	# === 战斗统计区域 ===
	var stats_title = Label.new()
	stats_title.text = "── 战斗统计 ──"
	stats_title.position = Vector2(236, 132)
	stats_title.add_theme_font_size_override("font_size", 8)
	stats_title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5, 0.6))
	stats_title.visible = false
	stats_title.z_index = 502
	add_child(stats_title)

	# 统计条目（6行）
	var stat_names = ["存活时间", "击杀数", "最大连击", "总伤害", "获得矿石", "使用药水"]
	for i in range(6):
		var name_label = Label.new()
		name_label.text = stat_names[i] + ":"
		name_label.position = Vector2(185, 150 + i * 16)
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55, 0.8))
		name_label.visible = false
		name_label.z_index = 502
		add_child(name_label)

		var value_label = Label.new()
		value_label.text = "--"
		value_label.position = Vector2(340, 150 + i * 16)
		value_label.add_theme_font_size_override("font_size", 8)
		value_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 0.9))
		value_label.visible = false
		value_label.z_index = 502
		add_child(value_label)

		stats_labels.append({"name": name_label, "value": value_label})

	# === 底部分隔线 ===
	var bottom_line = ColorRect.new()
	bottom_line.size = Vector2(280, 1)
	bottom_line.position = Vector2(180, 252)
	bottom_line.color = Color(0.5, 0.15, 0.1, 0.4)
	bottom_line.visible = false
	bottom_line.z_index = 502
	add_child(bottom_line)

	# === 重试按钮 ===
	retry_bg = ColorRect.new()
	retry_bg.size = Vector2(130, 26)
	retry_bg.position = Vector2(175, 262)
	retry_bg.color = Color(0.92, 0.78, 0.32, 0.2)
	retry_bg.visible = false
	retry_bg.z_index = 502
	add_child(retry_bg)

	retry_btn = Label.new()
	retry_btn.text = "[R] 重新挑战"
	retry_btn.position = Vector2(196, 267)
	retry_btn.add_theme_font_size_override("font_size", 10)
	retry_btn.add_theme_color_override("font_color", Color(1, 0.92, 0.5, 1.0))
	retry_btn.visible = false
	retry_btn.z_index = 502
	add_child(retry_btn)

	# === 退出按钮 ===
	quit_bg = ColorRect.new()
	quit_bg.size = Vector2(130, 26)
	quit_bg.position = Vector2(335, 262)
	quit_bg.color = Color(0.4, 0.35, 0.3, 0.0)
	quit_bg.visible = false
	quit_bg.z_index = 502
	add_child(quit_bg)

	quit_btn = Label.new()
	quit_btn.text = "[Q] 返回主菜单"
	quit_btn.position = Vector2(346, 267)
	quit_btn.add_theme_font_size_override("font_size", 10)
	quit_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.7))
	quit_btn.visible = false
	quit_btn.z_index = 502
	add_child(quit_btn)

func open(data: Dictionary = {}) -> void:
	"""显示GameOver画面，data中包含战斗统计"""
	stats = data
	is_open = true
	selected_option = 0

	# 更新统计数据
	var values = [
		_format_time(data.get("play_time", 0.0)),
		str(data.get("total_kills", 0)),
		str(data.get("max_combo", 0)) + " HIT",
		str(int(data.get("total_damage", 0))),
		str(data.get("ore_fragments", 0)),
		str(data.get("potions_used", 0)),
	]
	for i in range(min(stats_labels.size(), values.size())):
		stats_labels[i]["value"].text = values[i]

	# 显示所有元素
	_show_all_children()

	# 淡入遮罩
	overlay.color = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.75, 0.5)

	_update_selection()

func close() -> void:
	is_open = false
	_hide_all_children()
	overlay.visible = false

func process_input(delta: float) -> void:
	frame_count += 1
	_input_cooldown = max(0, _input_cooldown - delta)

	# 标题闪烁
	if title_label:
		var pulse = 0.8 + 0.2 * sin(frame_count * 0.06)
		title_label.add_theme_color_override("font_color", Color(0.85 * pulse, 0.12, 0.08, 1.0))

	# 选择切换
	if Input.is_action_just_pressed("menu_up") or Input.is_action_just_pressed("menu_down"):
		if _input_cooldown <= 0:
			selected_option = 1 - selected_option
			_input_cooldown = INPUT_COOLDOWN_TIME
			_update_selection()

	# 确认
	if Input.is_action_just_pressed("menu_confirm") or Input.is_action_just_pressed("menu_retry"):
		if _input_cooldown <= 0:
			_input_cooldown = INPUT_COOLDOWN_TIME
			if selected_option == 0:
				close()
				retry_pressed.emit()
			else:
				close()
				quit_pressed.emit()

	# Q键退出
	if Input.is_action_just_pressed("menu_back"):
		if _input_cooldown <= 0:
			_input_cooldown = INPUT_COOLDOWN_TIME
			close()
			quit_pressed.emit()

func _update_selection() -> void:
	if selected_option == 0:
		retry_bg.color = Color(0.92, 0.78, 0.32, 0.2)
		retry_btn.add_theme_color_override("font_color", Color(1, 0.92, 0.5, 1.0))
		quit_bg.color = Color(0.4, 0.35, 0.3, 0.0)
		quit_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.7))
	else:
		retry_bg.color = Color(0.4, 0.35, 0.3, 0.0)
		retry_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.7))
		quit_bg.color = Color(0.5, 0.3, 0.25, 0.2)
		quit_btn.add_theme_color_override("font_color", Color(1, 0.7, 0.6, 1.0))

func _format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return str(mins) + ":" + str(secs).lpad(2, "0")

func _show_all_children() -> void:
	for child in get_children():
		if child is ColorRect or child is Label or child is TextureRect:
			child.visible = true

func _hide_all_children() -> void:
	for child in get_children():
		if child is ColorRect or child is Label or child is TextureRect:
			child.visible = false
