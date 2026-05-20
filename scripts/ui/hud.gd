## HUD 系统 - Beta v0.14 美术升级版
## 显示玩家HP/怒气/连击点、Boss HP、连招、技能状态、伤害数字
## v0.14: 全面美术升级 - 像素风条框+图标+阴影+粒子效果
extends Node2D

# 玩家HUD
var hp_fill: ColorRect
var hp_fill_bg: ColorRect
var hp_label: Label
var rage_fill: ColorRect
var rage_fill_bg: ColorRect
var rage_label: Label
var skill_label_1: Label
var skill_label_2: Label
var hp_icon: TextureRect
var rage_icon: TextureRect

# v0.13: 游侠连击点数指示器
var combo_dots: Array = []
var is_ranger_mode: bool = false

# Boss HUD
var boss_hp_fill: ColorRect
var boss_hp_bg: ColorRect
var boss_name_label: Label
var boss_phase_label: Label

# 战斗信息
var combo_label: Label
var perfect_label: Label
var hit_effects: Array = []

# === 新增视觉元素 ===
var player_shadow: TextureRect
var skill_icon_1: TextureRect
var skill_icon_2: TextureRect
var skill_1_ready: ColorRect
var skill_2_ready: ColorRect

var hit_count_label: Label
var war_cry_indicator: ColorRect
var telegraph_indicator: Label
var telegraph_bg: ColorRect

var frame_count: int = 0

# 环境粒子
var ambient_particles: Array = []

func build(player_pos_y: float = 309) -> void:
	is_ranger_mode = GameState.is_ranger()
	_build_player_hud()
	_build_boss_hud()
	_build_combat_hud()
	_build_ambient_effects()

func _build_player_hud() -> void:
	# === HP条框 (使用精灵纹理) ===
	var hp_frame_tex = load("res://assets/sprites/ui/hp_bar_frame.png")
	if hp_frame_tex:
		var hp_frame = TextureRect.new()
		hp_frame.texture = hp_frame_tex
		hp_frame.size = Vector2(130, 12)
		hp_frame.position = Vector2(8, 8)
		add_child(hp_frame)
	else:
		var hp_bg = ColorRect.new()
		hp_bg.size = Vector2(130, 12)
		hp_bg.position = Vector2(8, 8)
		hp_bg.color = Color(0.15, 0.12, 0.18, 0.92)
		add_child(hp_bg)
	
	# HP填充背景
	hp_fill_bg = ColorRect.new()
	hp_fill_bg.size = Vector2(126, 8)
	hp_fill_bg.position = Vector2(10, 10)
	hp_fill_bg.color = Color(0.3, 0.1, 0.08, 0.9)
	add_child(hp_fill_bg)
	
	# HP填充
	hp_fill = ColorRect.new()
	hp_fill.size = Vector2(126, 8)
	hp_fill.position = Vector2(10, 10)
	hp_fill.color = Color(0.85, 0.2, 0.12, 1.0)
	add_child(hp_fill)
	
	# HP渐变覆盖（顶部亮）
	var hp_shine = ColorRect.new()
	hp_shine.size = Vector2(126, 3)
	hp_shine.position = Vector2(10, 10)
	hp_shine.color = Color(1.0, 0.4, 0.3, 0.3)
	add_child(hp_shine)
	
	# HP文字
	hp_label = Label.new()
	hp_label.text = "HP"
	hp_label.position = Vector2(12, 9)
	hp_label.add_theme_font_size_override("font_size", 7)
	hp_label.add_theme_color_override("font_color", Color(1, 0.9, 0.85, 0.9))
	add_child(hp_label)
	
	# === 怒气条框 ===
	var rage_frame_tex = load("res://assets/sprites/ui/rage_bar_frame.png")
	if rage_frame_tex:
		var rage_frame = TextureRect.new()
		rage_frame.texture = rage_frame_tex
		rage_frame.size = Vector2(130, 10)
		rage_frame.position = Vector2(8, 22)
		add_child(rage_frame)
	else:
		var rage_bg = ColorRect.new()
		rage_bg.size = Vector2(130, 10)
		rage_bg.position = Vector2(8, 22)
		rage_bg.color = Color(0.15, 0.12, 0.18, 0.92)
		add_child(rage_bg)
	
	# 怒气填充背景
	rage_fill_bg = ColorRect.new()
	rage_fill_bg.size = Vector2(126, 6)
	rage_fill_bg.position = Vector2(10, 24)
	rage_fill_bg.color = Color(0.2, 0.12, 0.05, 0.9)
	add_child(rage_fill_bg)
	
	# 怒气填充
	rage_fill = ColorRect.new()
	rage_fill.size = Vector2(0, 6)
	rage_fill.position = Vector2(10, 24)
	rage_fill.color = Color(0.95, 0.6, 0.1, 1.0)
	add_child(rage_fill)
	
	# 怒气渐变
	var rage_shine = ColorRect.new()
	rage_shine.size = Vector2(126, 2)
	rage_shine.position = Vector2(10, 24)
	rage_shine.color = Color(1.0, 0.8, 0.3, 0.25)
	add_child(rage_shine)
	
	# 怒气文字
	rage_label = Label.new()
	rage_label.text = "RAGE"
	rage_label.position = Vector2(12, 23)
	rage_label.add_theme_font_size_override("font_size", 6)
	rage_label.add_theme_color_override("font_color", Color(1, 0.85, 0.5, 0.8))
	add_child(rage_label)
	
	# === 技能图标 + 标签 ===
	var icon_atk = load("res://assets/sprites/ui/skill_icon_attack.png")
	var icon_rage = load("res://assets/sprites/ui/skill_icon_rage.png")
	
	# 技能1图标
	if icon_atk:
		skill_icon_1 = TextureRect.new()
		skill_icon_1.texture = icon_atk
		skill_icon_1.size = Vector2(16, 16)
		skill_icon_1.position = Vector2(8, 35)
		add_child(skill_icon_1)
	else:
		var icon1 = ColorRect.new()
		icon1.size = Vector2(16, 16)
		icon1.position = Vector2(8, 35)
		icon1.color = Color(0.5, 0.2, 0.15, 0.8)
		add_child(icon1)
	
	# 技能1就绪指示
	skill_1_ready = ColorRect.new()
	skill_1_ready.size = Vector2(16, 16)
	skill_1_ready.position = Vector2(8, 35)
	skill_1_ready.color = Color(0.3, 1.0, 0.3, 0.0)
	add_child(skill_1_ready)
	
	skill_label_1 = Label.new()
	skill_label_1.text = "[U]战吼 50怒气"
	skill_label_1.position = Vector2(26, 38)
	skill_label_1.add_theme_font_size_override("font_size", 7)
	skill_label_1.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.7))
	add_child(skill_label_1)
	
	# 技能2图标
	if icon_rage:
		skill_icon_2 = TextureRect.new()
		skill_icon_2.texture = icon_rage
		skill_icon_2.size = Vector2(16, 16)
		skill_icon_2.position = Vector2(8, 53)
		add_child(skill_icon_2)
	else:
		var icon2 = ColorRect.new()
		icon2.size = Vector2(16, 16)
		icon2.position = Vector2(8, 53)
		icon2.color = Color(0.4, 0.3, 0.1, 0.8)
		add_child(icon2)
	
	skill_2_ready = ColorRect.new()
	skill_2_ready.size = Vector2(16, 16)
	skill_2_ready.position = Vector2(8, 53)
	skill_2_ready.color = Color(1, 0.3, 0.2, 0.0)
	add_child(skill_2_ready)
	
	skill_label_2 = Label.new()
	skill_label_2.text = "[I]裂地斩 100怒气"
	skill_label_2.position = Vector2(26, 56)
	skill_label_2.add_theme_font_size_override("font_size", 7)
	skill_label_2.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.7))
	add_child(skill_label_2)
	
	# 战吼buff/影步指示器
	war_cry_indicator = ColorRect.new()
	war_cry_indicator.size = Vector2(40, 4)
	war_cry_indicator.position = Vector2(8, 71)
	if is_ranger_mode:
		war_cry_indicator.color = Color(0.6, 0.3, 1.0, 0.0)
	else:
		war_cry_indicator.color = Color(1, 0.7, 0.2, 0.0)
	add_child(war_cry_indicator)
	
	# v0.13: 游侠连击点数指示器
	if is_ranger_mode:
		for i in range(5):
			var dot = ColorRect.new()
			dot.size = Vector2(8, 8)
			dot.position = Vector2(8 + i * 18, 71)
			dot.color = Color(0.25, 0.12, 0.35, 0.5)
			add_child(dot)
			# 内部点亮
			var dot_inner = ColorRect.new()
			dot_inner.size = Vector2(6, 6)
			dot_inner.position = Vector2(9 + i * 18, 72)
			dot_inner.color = Color(0.3, 0.15, 0.4, 0.3)
			add_child(dot_inner)
			combo_dots.append({"outer": dot, "inner": dot_inner})
		if rage_fill:
			rage_fill.visible = false
		if rage_fill_bg:
			rage_fill_bg.visible = false
		if rage_label:
			rage_label.visible = false
		if skill_label_1:
			skill_label_1.text = "[U]影步 2CP"
		if skill_label_2:
			skill_label_2.text = "[I]刃风暴 5CP"

func _build_boss_hud() -> void:
	# Boss HP条框
	var boss_frame_tex = load("res://assets/sprites/ui/boss_hp_frame.png")
	if boss_frame_tex:
		var boss_frame = TextureRect.new()
		boss_frame.texture = boss_frame_tex
		boss_frame.size = Vector2(304, 14)
		boss_frame.position = Vector2(168, 18)
		boss_frame.visible = false
		add_child(boss_frame)
	else:
		boss_hp_bg = ColorRect.new()
		boss_hp_bg.size = Vector2(300, 10)
		boss_hp_bg.position = Vector2(170, 20)
		boss_hp_bg.color = Color(0.2, 0.15, 0.15, 0.9)
		boss_hp_bg.visible = false
		add_child(boss_hp_bg)
	
	# Boss HP填充
	boss_hp_fill = ColorRect.new()
	boss_hp_fill.size = Vector2(298, 10)
	boss_hp_fill.position = Vector2(171, 20)
	boss_hp_fill.color = Color(0.7, 0.2, 0.1, 1.0)
	boss_hp_fill.visible = false
	add_child(boss_hp_fill)
	
	# Boss HP渐变
	var boss_shine = ColorRect.new()
	boss_shine.size = Vector2(298, 3)
	boss_shine.position = Vector2(171, 20)
	boss_shine.color = Color(1.0, 0.4, 0.3, 0.3)
	boss_shine.visible = false
	add_child(boss_shine)
	
	# Boss名字
	boss_name_label = Label.new()
	boss_name_label.text = "矿脉甲虫"
	boss_name_label.position = Vector2(270, 10)
	boss_name_label.add_theme_font_size_override("font_size", 8)
	boss_name_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.45, 0.95))
	boss_name_label.visible = false
	add_child(boss_name_label)
	
	# Boss阶段
	boss_phase_label = Label.new()
	boss_phase_label.text = ""
	boss_phase_label.position = Vector2(420, 10)
	boss_phase_label.add_theme_font_size_override("font_size", 7)
	boss_phase_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2, 0.8))
	boss_phase_label.visible = false
	add_child(boss_phase_label)

func _build_combat_hud() -> void:
	# 连招名（带阴影效果）
	var combo_shadow = Label.new()
	combo_shadow.position = Vector2(282, 272)
	combo_shadow.add_theme_font_size_override("font_size", 16)
	combo_shadow.add_theme_color_override("font_color", Color(0, 0, 0, 0.5))
	add_child(combo_shadow)
	
	combo_label = Label.new()
	combo_label.position = Vector2(280, 270)
	combo_label.add_theme_font_size_override("font_size", 16)
	combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(combo_label)
	
	# 连击计数（带背景框）
	var hit_bg = ColorRect.new()
	hit_bg.size = Vector2(70, 24)
	hit_bg.position = Vector2(548, 44)
	hit_bg.color = Color(0, 0, 0, 0.4)
	add_child(hit_bg)
	
	hit_count_label = Label.new()
	hit_count_label.position = Vector2(553, 48)
	hit_count_label.add_theme_font_size_override("font_size", 16)
	hit_count_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 0.9))
	hit_count_label.visible = false
	add_child(hit_count_label)
	
	# 完美判定（带发光效果）
	var perfect_glow = Label.new()
	perfect_glow.position = Vector2(247, 137)
	perfect_glow.add_theme_font_size_override("font_size", 22)
	perfect_glow.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 0.3))
	add_child(perfect_glow)
	
	perfect_label = Label.new()
	perfect_label.position = Vector2(250, 140)
	perfect_label.add_theme_font_size_override("font_size", 20)
	perfect_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	perfect_label.visible = false
	add_child(perfect_label)
	
	# Boss攻击预警
	telegraph_bg = ColorRect.new()
	telegraph_bg.size = Vector2(34, 18)
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

func _build_ambient_effects() -> void:
	"""构建HUD环境粒子效果"""
	# 微尘粒子（装饰性）
	for i in range(8):
		var p = ColorRect.new()
		p.size = Vector2(1, 1)
		p.position = Vector2(randf() * 640, randf() * 360)
		p.color = Color(0.5, 0.5, 0.6, randf_range(0.1, 0.3))
		p.visible = false  # 只在特定场景显示
		add_child(p)
		ambient_particles.append({
			"node": p,
			"vel": Vector2(randf_range(-3, 3), randf_range(-8, -2)),
			"phase": randf() * TAU,
		})

func update_player_hp(current: float, maximum: float) -> void:
	if hp_fill:
		hp_fill.size.x = 126 * (current / maximum)
		if current < maximum * 0.3:
			hp_fill.color = Color(1, 0.2, 0.1, 1) if int(frame_count / 6) % 2 == 0 else Color(0.8, 0.1, 0.05, 1)
		elif current < maximum * 0.5:
			hp_fill.color = Color(0.9, 0.35, 0.1, 1)
		else:
			hp_fill.color = Color(0.85, 0.2, 0.12, 1.0)
	if hp_label:
		hp_label.text = str(int(current)) + "/" + str(int(maximum))

func update_rage(current: float, maximum: float) -> void:
	if is_ranger_mode:
		var cp: int = int(current / 20.0)
		update_combo_points(cp)
		return
	if rage_fill:
		rage_fill.size.x = 126 * (current / maximum)
		if current >= 100:
			rage_fill.color = Color(1, 0.85, 0.2, 1) if int(frame_count / 6) % 2 == 0 else Color(0.9, 0.5, 0.1, 1)
		elif current >= 50:
			rage_fill.color = Color(0.95, 0.65, 0.1, 1)
		else:
			rage_fill.color = Color(0.9, 0.6, 0.1, 1.0)
	if rage_label:
		rage_label.text = str(int(current)) + "/" + str(int(maximum))
	
	# 技能就绪指示
	if skill_label_1:
		if is_ranger_mode:
			skill_label_1.add_theme_color_override("font_color",
				Color(0.6, 0.3, 1.0, 1) if current >= 40 else Color(0.5, 0.5, 0.5, 0.5))
		else:
			skill_label_1.add_theme_color_override("font_color",
				Color(0.3, 1, 0.3, 1) if current >= 50 else Color(0.5, 0.5, 0.5, 0.5))
	if skill_1_ready:
		if current >= (40 if is_ranger_mode else 50):
			skill_1_ready.color = Color(0.3, 1.0, 0.3, 0.15)
		else:
			skill_1_ready.color = Color(0, 0, 0, 0)
	
	if skill_label_2:
		if is_ranger_mode:
			skill_label_2.add_theme_color_override("font_color",
				Color(1, 0.3, 0.8, 1) if current >= 100 else Color(0.5, 0.5, 0.5, 0.5))
		else:
			skill_label_2.add_theme_color_override("font_color",
				Color(1, 0.3, 0.2, 1) if current >= 100 else Color(0.5, 0.5, 0.5, 0.5))
	if skill_2_ready:
		if current >= 100:
			skill_2_ready.color = Color(1, 0.3, 0.2, 0.15)
		else:
			skill_2_ready.color = Color(0, 0, 0, 0)

func update_combo_points(points: int) -> void:
	for i in range(combo_dots.size()):
		var dot_data: Dictionary = combo_dots[i]
		var outer: ColorRect = dot_data["outer"]
		var inner: ColorRect = dot_data["inner"]
		if i < points:
			if i >= 4:
				outer.color = Color(1.0, 0.3, 0.8, 1.0) if int(frame_count / 6) % 2 == 0 else Color(0.8, 0.2, 0.6, 1.0)
				inner.color = Color(1.0, 0.5, 0.9, 1.0)
			elif i >= 2:
				outer.color = Color(0.6, 0.3, 1.0, 1.0)
				inner.color = Color(0.7, 0.5, 1.0, 1.0)
			else:
				outer.color = Color(0.4, 0.6, 1.0, 1.0)
				inner.color = Color(0.5, 0.7, 1.0, 1.0)
		else:
			outer.color = Color(0.25, 0.12, 0.35, 0.5)
			inner.color = Color(0.3, 0.15, 0.4, 0.3)

func show_boss_hp(boss_name: String) -> void:
	if boss_hp_fill: boss_hp_fill.visible = true
	if boss_hp_bg: boss_hp_bg.visible = true
	if boss_name_label:
		boss_name_label.text = boss_name
		boss_name_label.visible = true
	if boss_phase_label: boss_phase_label.visible = true

func update_boss_hp(current: float, maximum: float) -> void:
	if boss_hp_fill:
		boss_hp_fill.size.x = 298 * (current / maximum)
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
	if hit_count_label:
		if count >= 2:
			hit_count_label.visible = true
			hit_count_label.text = str(count) + " HIT"
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
	if not telegraph_indicator or not telegraph_bg:
		return
	telegraph_indicator.visible = true
	telegraph_bg.visible = true
	
	var indicator_pos: Vector2 = boss_pos + Vector2(-15 + (-20 * facing), -55)
	telegraph_indicator.position = indicator_pos
	telegraph_bg.position = indicator_pos + Vector2(-2, -1)
	
	telegraph_indicator.text = attack_type
	
	if warning_level >= 2:
		telegraph_indicator.add_theme_color_override("font_color", Color(1, 0.2, 0.1, 1))
		telegraph_bg.color = Color(1, 0.1, 0.05, 0.6)
	else:
		telegraph_indicator.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
		telegraph_bg.color = Color(0.8, 0.6, 0.1, 0.4)

func hide_telegraph() -> void:
	if telegraph_indicator:
		telegraph_indicator.visible = false
	if telegraph_bg:
		telegraph_bg.visible = false

func show_war_cry_buff(active: bool, timer: float = 0) -> void:
	if war_cry_indicator:
		if active:
			if is_ranger_mode:
				war_cry_indicator.color = Color(0.6, 0.3, 1.0, 0.8)
				var ratio: float = timer / 2.0
				war_cry_indicator.size.x = 40 * ratio
			else:
				war_cry_indicator.color = Color(1, 0.7, 0.2, 0.8)
				var ratio: float = timer / 8.0
				war_cry_indicator.size.x = 40 * ratio
		else:
			if is_ranger_mode:
				war_cry_indicator.color = Color(0.6, 0.3, 1.0, 0.0)
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
