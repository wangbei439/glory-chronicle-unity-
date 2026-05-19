## HUD 系统
## 显示玩家HP/怒气、Boss HP、连招、技能状态、伤害数字
extends Node2D

# 玩家HUD
var hp_fill: ColorRect
var rage_fill: ColorRect
var skill_label_1: Label
var skill_label_2: Label

# Boss HUD
var boss_hp_bg: ColorRect
var boss_hp_fill: ColorRect
var boss_name_label: Label
var boss_phase_label: Label

# 战斗信息
var combo_label: Label
var perfect_label: Label
var hit_effects: Array = []

var frame_count: int = 0

func build(player_pos_y: float = 309) -> void:
	_build_player_hud()
	_build_boss_hud()
	_build_combat_hud()

func _build_player_hud() -> void:
	# HP背景
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(125, 8)
	hp_bg.position = Vector2(10, 10)
	hp_bg.color = Color(0.2, 0.15, 0.15, 0.85)
	add_child(hp_bg)
	
	hp_fill = ColorRect.new()
	hp_fill.size = Vector2(124, 7)
	hp_fill.position = Vector2(10, 10)
	hp_fill.color = Color(0.85, 0.15, 0.1, 1.0)
	add_child(hp_fill)
	
	# 怒气背景
	var rage_bg = ColorRect.new()
	rage_bg.size = Vector2(125, 8)
	rage_bg.position = Vector2(10, 21)
	rage_bg.color = Color(0.15, 0.15, 0.2, 0.85)
	add_child(rage_bg)
	
	rage_fill = ColorRect.new()
	rage_fill.size = Vector2(0, 7)
	rage_fill.position = Vector2(10, 21)
	rage_fill.color = Color(0.9, 0.6, 0.1, 1.0)
	add_child(rage_fill)
	
	# 怒气50标记
	var mark50 = ColorRect.new()
	mark50.size = Vector2(1, 7)
	mark50.position = Vector2(72, 21)
	mark50.color = Color(1, 1, 1, 0.3)
	add_child(mark50)
	
	# 技能
	skill_label_1 = Label.new()
	skill_label_1.text = "[U]战吼 50怒气"
	skill_label_1.position = Vector2(10, 32)
	skill_label_1.add_theme_font_size_override("font_size", 7)
	skill_label_1.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	add_child(skill_label_1)
	
	skill_label_2 = Label.new()
	skill_label_2.text = "[I]裂地斩 100怒气"
	skill_label_2.position = Vector2(10, 40)
	skill_label_2.add_theme_font_size_override("font_size", 7)
	skill_label_2.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	add_child(skill_label_2)

func _build_boss_hud() -> void:
	# Boss HP条（屏幕顶部居中）
	boss_hp_bg = ColorRect.new()
	boss_hp_bg.size = Vector2(300, 10)
	boss_hp_bg.position = Vector2(170, 22)
	boss_hp_bg.color = Color(0.2, 0.15, 0.15, 0.9)
	boss_hp_bg.visible = false
	add_child(boss_hp_bg)
	
	boss_hp_fill = ColorRect.new()
	boss_hp_fill.size = Vector2(298, 8)
	boss_hp_fill.position = Vector2(171, 23)
	boss_hp_fill.color = Color(0.7, 0.2, 0.1, 1.0)
	boss_hp_fill.visible = false
	add_child(boss_hp_fill)
	
	# Boss名字
	boss_name_label = Label.new()
	boss_name_label.text = "矿脉甲虫"
	boss_name_label.position = Vector2(270, 12)
	boss_name_label.add_theme_font_size_override("font_size", 8)
	boss_name_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.5, 0.9))
	boss_name_label.visible = false
	add_child(boss_name_label)
	
	# Boss阶段
	boss_phase_label = Label.new()
	boss_phase_label.text = ""
	boss_phase_label.position = Vector2(420, 12)
	boss_phase_label.add_theme_font_size_override("font_size", 7)
	boss_phase_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2, 0.8))
	boss_phase_label.visible = false
	add_child(boss_phase_label)

func _build_combat_hud() -> void:
	# 连招名
	combo_label = Label.new()
	combo_label.position = Vector2(280, 270)
	combo_label.add_theme_font_size_override("font_size", 16)
	combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(combo_label)
	
	# 完美判定
	perfect_label = Label.new()
	perfect_label.position = Vector2(250, 140)
	perfect_label.add_theme_font_size_override("font_size", 20)
	perfect_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	perfect_label.visible = false
	add_child(perfect_label)

func update_player_hp(current: float, maximum: float) -> void:
	if hp_fill:
		hp_fill.size.x = 124 * (current / maximum)
		if current < maximum * 0.3:
			hp_fill.color = Color(1, 0.2, 0.1, 1) if int(frame_count / 6) % 2 == 0 else Color(0.8, 0.1, 0.05, 1)
		else:
			hp_fill.color = Color(0.85, 0.15, 0.1, 1.0)

func update_rage(current: float, maximum: float) -> void:
	if rage_fill:
		rage_fill.size.x = 124 * (current / maximum)
		if current >= 100:
			rage_fill.color = Color(1, 0.85, 0.2, 1) if int(frame_count / 6) % 2 == 0 else Color(0.9, 0.5, 0.1, 1)
		elif current >= 50:
			rage_fill.color = Color(0.95, 0.65, 0.1, 1)
		else:
			rage_fill.color = Color(0.9, 0.6, 0.1, 1)
	
	if skill_label_1:
		skill_label_1.add_theme_color_override("font_color",
			Color(0.3, 1, 0.3, 1) if current >= 50 else Color(0.5, 0.5, 0.5, 0.5))
	if skill_label_2:
		skill_label_2.add_theme_color_override("font_color",
			Color(1, 0.3, 0.2, 1) if current >= 100 else Color(0.5, 0.5, 0.5, 0.5))

func show_boss_hp(boss_name: String) -> void:
	if boss_hp_bg: boss_hp_bg.visible = true
	if boss_hp_fill: boss_hp_fill.visible = true
	if boss_name_label:
		boss_name_label.text = boss_name
		boss_name_label.visible = true
	if boss_phase_label: boss_phase_label.visible = true

func update_boss_hp(current: float, maximum: float) -> void:
	if boss_hp_fill:
		boss_hp_fill.size.x = 298 * (current / maximum)
		# HP低时变色
		var ratio = current / maximum
		if ratio < 0.3:
			boss_hp_fill.color = Color(1, 0.1, 0.05, 1)
		elif ratio < 0.5:
			boss_hp_fill.color = Color(0.9, 0.3, 0.1, 1)
		else:
			boss_hp_fill.color = Color(0.7, 0.2, 0.1, 1.0)

func update_boss_phase(phase: int) -> void:
	if boss_phase_label:
		if phase == 2:
			boss_phase_label.text = "狂暴!"
			boss_phase_label.add_theme_color_override("font_color", Color(1, 0.3, 0.1, 1))

func show_combo(name: String, is_perfect: bool) -> void:
	if combo_label:
		combo_label.text = name
		if is_perfect:
			combo_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
		else:
			combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func clear_combo() -> void:
	if combo_label:
		combo_label.text = ""

func show_perfect(text: String, color: Color) -> void:
	if perfect_label:
		perfect_label.text = text
		perfect_label.visible = true
		perfect_label.add_theme_color_override("font_color", color)
		var tween = create_tween()
		tween.tween_property(perfect_label, "modulate:a", 0, 0.8)
		tween.tween_callback(func(): perfect_label.visible = false; perfect_label.modulate.a = 1)

func spawn_damage_number(pos: Vector2, damage: float, is_crit: bool = false) -> void:
	var dmg_label = Label.new()
	dmg_label.text = str(int(damage))
	dmg_label.position = pos + Vector2(randf_range(-10, 10), -20)
	dmg_label.add_theme_font_size_override("font_size", 14 if is_crit else 10)
	dmg_label.add_theme_color_override("font_color", Color(1, 0.3, 0.1) if is_crit else Color(1, 1, 1))
	add_child(dmg_label)
	hit_effects.append({"node": dmg_label, "life": 0.8, "vel": Vector2(randf_range(-15, 15), -40)})

func process_effects(delta: float) -> void:
	frame_count += 1
	var to_remove: Array = []
	for i in range(hit_effects.size()):
		var e: Dictionary = hit_effects[i]
		e["life"] -= delta
		e["node"].position += e["vel"] * delta
		e["vel"].y += 80 * delta
		var mod: Color = e["node"].modulate
		mod.a = max(0, e["life"] / 0.8)
		e["node"].modulate = mod
		if e["life"] <= 0:
			e["node"].queue_free()
			to_remove.append(i)
	for i in to_remove:
		hit_effects.remove_at(i)
