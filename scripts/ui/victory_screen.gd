## Boss胜利画面 - Beta v0.18
## 覆盖层：击败Boss后显示战利品、奖励、评级
## 键盘操作：Enter/J继续
extends CanvasLayer

signal continue_pressed

var is_open: bool = false
var frame_count: int = 0

# 视觉元素
var overlay: ColorRect
var title_shadow: Label
var title_label: Label
var boss_name_label: Label
var boss_name_shadow: Label
var loot_labels: Array = []
var rating_label: Label
var rating_shadow: Label
var continue_btn: Label
var continue_bg: ColorRect
var particles: Array = []

# 战斗数据
var victory_data: Dictionary = {}

# 输入冷却
var _input_cooldown: float = 0.5

func _ready() -> void:
	layer = 10
	build()

func build() -> void:
	# === 全屏半透明遮罩 ===
	overlay = ColorRect.new()
	overlay.size = Vector2(640, 360)
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.visible = false
	overlay.z_index = 500
	add_child(overlay)

	# === 中央面板背景 ===
	var panel_bg = ColorRect.new()
	panel_bg.size = Vector2(360, 280)
	panel_bg.position = Vector2(140, 40)
	panel_bg.color = Color(0.04, 0.05, 0.08, 0.95)
	panel_bg.visible = false
	panel_bg.z_index = 501
	add_child(panel_bg)

	# 面板边框（金色）
	var panel_border = ColorRect.new()
	panel_border.size = Vector2(364, 284)
	panel_border.position = Vector2(138, 38)
	panel_border.color = Color(0.7, 0.55, 0.2, 0.8)
	panel_border.visible = false
	panel_border.z_index = 500
	add_child(panel_border)

	# 面板内侧渐变
	var panel_inner = ColorRect.new()
	panel_inner.size = Vector2(358, 278)
	panel_inner.position = Vector2(141, 41)
	panel_inner.color = Color(0.12, 0.1, 0.04, 0.3)
	panel_inner.visible = false
	panel_inner.z_index = 501
	add_child(panel_inner)

	# 顶部装饰线
	var top_line = ColorRect.new()
	top_line.size = Vector2(320, 2)
	top_line.position = Vector2(160, 56)
	top_line.color = Color(0.92, 0.78, 0.32, 0.5)
	top_line.visible = false
	top_line.z_index = 502
	add_child(top_line)

	# === 标题阴影 ===
	title_shadow = Label.new()
	title_shadow.text = "VICTORY"
	title_shadow.position = Vector2(218, 62)
	title_shadow.add_theme_font_size_override("font_size", 30)
	title_shadow.add_theme_color_override("font_color", Color(0, 0, 0, 0.5))
	title_shadow.visible = false
	title_shadow.z_index = 502
	add_child(title_shadow)

	# === 标题 ===
	title_label = Label.new()
	title_label.text = "VICTORY"
	title_label.position = Vector2(215, 60)
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3, 1.0))
	title_label.visible = false
	title_label.z_index = 502
	add_child(title_label)

	# 副标题
	var subtitle = Label.new()
	subtitle.text = "传说继续"
	subtitle.position = Vector2(276, 94)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.7, 0.45, 0.6))
	subtitle.visible = false
	subtitle.z_index = 502
	add_child(subtitle)

	# === Boss名称 ===
	boss_name_shadow = Label.new()
	boss_name_shadow.text = ""
	boss_name_shadow.position = Vector2(241, 112)
	boss_name_shadow.add_theme_font_size_override("font_size", 14)
	boss_name_shadow.add_theme_color_override("font_color", Color(0, 0, 0, 0.4))
	boss_name_shadow.visible = false
	boss_name_shadow.z_index = 502
	add_child(boss_name_shadow)

	boss_name_label = Label.new()
	boss_name_label.text = ""
	boss_name_label.position = Vector2(238, 110)
	boss_name_label.add_theme_font_size_override("font_size", 14)
	boss_name_label.add_theme_color_override("font_color", Color(0.9, 0.65, 0.2, 1.0))
	boss_name_label.visible = false
	boss_name_label.z_index = 502
	add_child(boss_name_label)

	# Boss击败标记
	var defeated = Label.new()
	defeated.text = "已击败"
	defeated.position = Vector2(360, 112)
	defeated.add_theme_font_size_override("font_size", 8)
	defeated.add_theme_color_override("font_color", Color(0.6, 0.5, 0.35, 0.7))
	defeated.visible = false
	defeated.z_index = 502
	add_child(defeated)

	# 分隔线
	var div_line = ColorRect.new()
	div_line.size = Vector2(300, 1)
	div_line.position = Vector2(170, 132)
	div_line.color = Color(0.7, 0.55, 0.2, 0.3)
	div_line.visible = false
	div_line.z_index = 502
	add_child(div_line)

	# === 战利品区域 ===
	var loot_title = Label.new()
	loot_title.text = "── 战利品 ──"
	loot_title.position = Vector2(258, 138)
	loot_title.add_theme_font_size_override("font_size", 9)
	loot_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.45, 0.7))
	loot_title.visible = false
	loot_title.z_index = 502
	add_child(loot_title)

	# 战利品条目（5行）
	var loot_names = ["矿石碎片", "Boss素材", "经验值", "击杀数", "战斗时间"]
	for i in range(5):
		var name_label = Label.new()
		name_label.text = loot_names[i] + ":"
		name_label.position = Vector2(170, 156 + i * 16)
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55, 0.8))
		name_label.visible = false
		name_label.z_index = 502
		add_child(name_label)

		var value_label = Label.new()
		value_label.text = "--"
		value_label.position = Vector2(390, 156 + i * 16)
		value_label.add_theme_font_size_override("font_size", 8)
		value_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 0.9))
		value_label.visible = false
		value_label.z_index = 502
		add_child(value_label)

		loot_labels.append({"name": name_label, "value": value_label})

	# === 评级 ===
	rating_shadow = Label.new()
	rating_shadow.text = ""
	rating_shadow.position = Vector2(272, 240)
	rating_shadow.add_theme_font_size_override("font_size", 24)
	rating_shadow.add_theme_color_override("font_color", Color(0, 0, 0, 0.4))
	rating_shadow.visible = false
	rating_shadow.z_index = 502
	add_child(rating_shadow)

	rating_label = Label.new()
	rating_label.text = ""
	rating_label.position = Vector2(270, 238)
	rating_label.add_theme_font_size_override("font_size", 24)
	rating_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1.0))
	rating_label.visible = false
	rating_label.z_index = 502
	add_child(rating_label)

	# 评级说明
	var rating_desc = Label.new()
	rating_desc.text = "战斗评级"
	rating_desc.position = Vector2(283, 265)
	rating_desc.add_theme_font_size_override("font_size", 7)
	rating_desc.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35, 0.5))
	rating_desc.visible = false
	rating_desc.z_index = 502
	add_child(rating_desc)

	# === 继续按钮 ===
	continue_bg = ColorRect.new()
	continue_bg.size = Vector2(160, 28)
	continue_bg.position = Vector2(240, 286)
	continue_bg.color = Color(0.92, 0.78, 0.32, 0.15)
	continue_bg.visible = false
	continue_bg.z_index = 502
	add_child(continue_bg)

	continue_btn = Label.new()
	continue_btn.text = "[Enter] 继续"
	continue_btn.position = Vector2(266, 291)
	continue_btn.add_theme_font_size_override("font_size", 10)
	continue_btn.add_theme_color_override("font_color", Color(1, 0.92, 0.5, 1.0))
	continue_btn.visible = false
	continue_btn.z_index = 502
	add_child(continue_btn)

	# === 庆祝粒子 ===
	for i in range(20):
		var p = ColorRect.new()
		p.size = Vector2(randf_range(2, 4), randf_range(2, 4))
		p.position = Vector2(320, 180)
		var colors = [
			Color(0.95, 0.85, 0.3, 0.8),
			Color(1.0, 0.7, 0.2, 0.7),
			Color(0.9, 0.6, 0.1, 0.6),
			Color(1.0, 0.9, 0.5, 0.5),
		]
		p.color = colors[i % 4]
		p.visible = false
		p.z_index = 503
		add_child(p)
		particles.append({
			"node": p,
			"vel": Vector2(randf_range(-120, 120), randf_range(-180, -60)),
			"life": randf_range(1.0, 2.5),
			"max_life": 2.5,
		})

func open(data: Dictionary = {}) -> void:
	victory_data = data
	is_open = true
	_input_cooldown = 0.8  # 初始延迟防止误触

	# 更新Boss名称
	var boss_name: String = data.get("boss_name", "未知Boss")
	if boss_name_label:
		boss_name_label.text = boss_name
	if boss_name_shadow:
		boss_name_shadow.text = boss_name

	# 更新战利品
	var loot_values = [
		str(data.get("ore", 0)),
		data.get("material_name", "无") + " x" + str(data.get("material_count", 0)),
		str(data.get("exp", 0)),
		str(data.get("kills", 0)),
		_format_time(data.get("time", 0.0)),
	]
	for i in range(min(loot_labels.size(), loot_values.size())):
		loot_labels[i]["value"].text = loot_values[i]

	# 计算评级
	var rating: String = _calculate_rating(data)
	if rating_label:
		rating_label.text = rating
	if rating_shadow:
		rating_shadow.text = rating
	_set_rating_color(rating)

	_show_all_children()

	# 淡入遮罩
	overlay.color = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.7, 0.6)

	# 重置粒子
	for p in particles:
		p["node"].position = Vector2(320 + randf_range(-40, 40), 180 + randf_range(-20, 20))
		p["vel"] = Vector2(randf_range(-120, 120), randf_range(-180, -60))
		p["life"] = randf_range(1.0, 2.5)

func close() -> void:
	is_open = false
	_hide_all_children()
	overlay.visible = false

func process_input(delta: float) -> void:
	frame_count += 1
	_input_cooldown = max(0, _input_cooldown - delta)

	# 标题金色闪烁
	if title_label:
		var glow = 0.88 + 0.12 * sin(frame_count * 0.05)
		title_label.add_theme_color_override("font_color", Color(0.95 * glow, 0.85 * glow, 0.3, 1.0))

	# 继续按钮闪烁
	if continue_btn:
		var alpha = 0.7 + 0.3 * sin(frame_count * 0.08)
		continue_btn.add_theme_color_override("font_color", Color(1, 0.92, 0.5, alpha))

	# 更新粒子
	for p in particles:
		var node: ColorRect = p["node"]
		if not node.visible:
			continue
		p["life"] -= delta
		node.position += p["vel"] * delta
		p["vel"].y += 100 * delta  # 重力
		var alpha_val: float = max(0, p["life"] / p["max_life"])
		node.modulate = Color(1, 1, 1, alpha_val)
		if p["life"] <= 0:
			# 重生粒子
			node.position = Vector2(320 + randf_range(-40, 40), 180 + randf_range(-20, 20))
			p["vel"] = Vector2(randf_range(-120, 120), randf_range(-180, -60))
			p["life"] = randf_range(1.0, 2.5)

	# 确认继续
	if _input_cooldown <= 0:
		if Input.is_action_just_pressed("menu_confirm") or Input.is_action_just_pressed("attack"):
			close()
			continue_pressed.emit()

func _calculate_rating(data: Dictionary) -> String:
	"""基于战斗表现计算评级"""
	var damage_taken: float = data.get("damage_taken", 100.0)
	var time: float = data.get("time", 120.0)
	var max_combo: int = data.get("max_combo", 0)

	var score: float = 0.0
	# 受伤越少越好（0伤=50分，满伤=0分）
	score += max(0, 50.0 * (1.0 - damage_taken / 100.0))
	# 时间越短越好（<30s=30分，>120s=0分）
	score += max(0, 30.0 * (1.0 - time / 120.0))
	# 连击加分
	score += min(20.0, float(max_combo) * 2.0)

	if score >= 85: return "S"
	if score >= 65: return "A"
	if score >= 45: return "B"
	if score >= 25: return "C"
	return "D"

func _set_rating_color(rating: String) -> void:
	if not rating_label:
		return
	match rating:
		"S":
			rating_label.add_theme_color_override("font_color", Color(1, 0.85, 0.15, 1.0))
		"A":
			rating_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3, 1.0))
		"B":
			rating_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.5, 1.0))
		"C":
			rating_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 1.0))
		"D":
			rating_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5, 1.0))

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
