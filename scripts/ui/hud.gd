## HUD 系统 - Alpha v0.5
## 显示玩家HP/怒气、Boss HP、连招、技能状态、伤害数字
## 新增：预警指示器、连击计数、战吼buff显示
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

# === Alpha v0.5 新增 ===
var hit_count_label: Label       # 连击计数
var war_cry_indicator: ColorRect # 战吼buff指示
var telegraph_indicator: Label   # Boss攻击预警
var telegraph_bg: ColorRect      # 预警背景

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
	
	# 战吼buff指示器
	war_cry_indicator = ColorRect.new()
	war_cry_indicator.size = Vector2(40, 6)
	war_cry_indicator.position = Vector2(10, 49)
	war_cry_indicator.color = Color(1, 0.7, 0.2, 0.0)  # 默认隐藏
	add_child(war_cry_indicator)

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
	
	# 连击计数
	hit_count_label = Label.new()
	hit_count_label.position = Vector2(550, 50)
	hit_count_label.add_theme_font_size_override("font_size", 18)
	hit_count_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 0.9))
	hit_count_label.visible = false
	add_child(hit_count_label)
	
	# 完美判定
	perfect_label = Label.new()
	perfect_label.position = Vector2(250, 140)
	perfect_label.add_theme_font_size_override("font_size", 20)
	perfect_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	perfect_label.visible = false
	add_child(perfect_label)
	
	# Boss攻击预警指示器
	telegraph_bg = ColorRect.new()
	telegraph_bg.size = Vector2(30, 16)
	telegraph_bg.position = Vector2(0, 0)
	telegraph_bg.color = Color(1, 0.2, 0.1, 0.0)
	telegraph_bg.visible = false
	add_child(telegraph_bg)
	
	telegraph_indicator = Label.new()
	telegraph_indicator.position = Vector2(0, 0)
	telegraph_indicator.add_theme_font_size_override("font_size", 12)
	telegraph_indicator.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	telegraph_indicator.visible = false
	add_child(telegraph_indicator)

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

func update_hit_count(count: int) -> void:
	"""更新连击计数显示"""
	if hit_count_label:
		if count >= 2:
			hit_count_label.visible = true
			hit_count_label.text = str(count) + " HIT"
			# 根据连击数变色
			if count >= 20:
				hit_count_label.add_theme_color_override("font_color", Color(1, 0.2, 0.1, 1))
			elif count >= 10:
				hit_count_label.add_theme_color_override("font_color", Color(1, 0.6, 0.1, 1))
			elif count >= 5:
				hit_count_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
			else:
				hit_count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		else:
			hit_count_label.visible = false

func show_telegraph(attack_type: String, boss_pos: Vector2, facing: float, warning_level: int) -> void:
	"""显示Boss攻击预警"""
	if not telegraph_indicator or not telegraph_bg:
		return
	telegraph_indicator.visible = true
	telegraph_bg.visible = true
	
	# 预警位置：Boss头顶
	var indicator_pos: Vector2 = boss_pos + Vector2(-15 + (-20 * facing), -55)
	telegraph_indicator.position = indicator_pos
	telegraph_bg.position = indicator_pos + Vector2(-2, -1)
	
	# 根据攻击类型设置文字
	telegraph_indicator.text = attack_type
	
	# 根据危险等级设置颜色
	if warning_level >= 2:
		telegraph_indicator.add_theme_color_override("font_color", Color(1, 0.2, 0.1, 1))
		telegraph_bg.color = Color(1, 0.1, 0.05, 0.6)
	else:
		telegraph_indicator.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
		telegraph_bg.color = Color(0.8, 0.6, 0.1, 0.4)

func hide_telegraph() -> void:
	"""隐藏预警"""
	if telegraph_indicator:
		telegraph_indicator.visible = false
	if telegraph_bg:
		telegraph_bg.visible = false

func show_war_cry_buff(active: bool, timer: float = 0) -> void:
	"""显示战吼buff状态"""
	if war_cry_indicator:
		if active:
			war_cry_indicator.color = Color(1, 0.7, 0.2, 0.8)
			# buff剩余比例
			var ratio = timer / 8.0
			war_cry_indicator.size.x = 40 * ratio
		else:
			war_cry_indicator.color = Color(1, 0.7, 0.2, 0.0)

func spawn_damage_number(pos: Vector2, damage: float, is_crit: bool = false) -> void:
	var dmg_label = Label.new()
	dmg_label.text = str(int(damage))
	dmg_label.position = pos + Vector2(randf_range(-10, 10), -20)
	dmg_label.add_theme_font_size_override("font_size", 14 if is_crit else 10)
	if is_crit:
		dmg_label.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
	else:
		dmg_label.add_theme_color_override("font_color", Color(1, 1, 1))
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
