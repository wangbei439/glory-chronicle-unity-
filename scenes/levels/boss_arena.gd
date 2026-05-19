## 幽影矿井 Boss 战 - Alpha v0.5
## 矿脉甲虫 vs 战士 完整战斗
## 新增：Hitstop/震屏/粒子/判定帧/预警/裂地斩AOE/场景切换
extends Node2D

const GROUND_Y: float = 309.0

# 子系统
var warrior: Node2D
var boss: Node2D
var hud: Node2D
var effects: Node2D  # 打击感特效系统

# 视觉节点
var player_sprite: AnimatedSprite2D
var boss_sprite: AnimatedSprite2D
var parry_indicator: ColorRect
var camera_offset: Vector2 = Vector2.ZERO  # 震屏偏移

# 战斗状态
var battle_active: bool = false
var battle_intro: bool = true
var intro_timer: float = 0.0
var frame_count: int = 0
var player_hit_applied: bool = false
var boss_hit_applied: bool = false

# 地震斩
var earth_shatter_active: bool = false
var earth_shatter_timer: float = 0.0
var earth_shatter_dealt: bool = false

# 场景切换
var current_scene: String = "boss_arena"
var scene_switch_cooldown: float = 0.0

func _ready() -> void:
	_build_scene()

func _build_scene() -> void:
	# 背景
	var bg_tex = load("res://assets/sprites/background/dungeon_mine_640x360.png")
	if bg_tex:
		var bg = TextureRect.new()
		bg.texture = bg_tex
		bg.size = Vector2(640, 360)
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(bg)
	else:
		var bg2 = ColorRect.new()
		bg2.size = Vector2(640, 360)
		bg2.color = Color(0.06, 0.06, 0.14, 1.0)
		add_child(bg2)
	
	# 地面
	var ground_top = ColorRect.new()
	ground_top.position = Vector2(0, 329)
	ground_top.size = Vector2(640, 2)
	ground_top.color = Color(0.35, 0.4, 0.45, 0.8)
	add_child(ground_top)
	var ground = ColorRect.new()
	ground.position = Vector2(0, 330)
	ground.size = Vector2(640, 30)
	ground.color = Color(0.15, 0.17, 0.2, 0.6)
	add_child(ground)
	
	# === 打击感特效系统 ===
	var effects_script = load("res://scripts/core/combat_effects.gd")
	effects = Node2D.new()
	effects.set_script(effects_script)
	add_child(effects)
	
	# === 战士 ===
	var warrior_script = load("res://scripts/player/warrior.gd")
	warrior = Node2D.new()
	warrior.set_script(warrior_script)
	add_child(warrior)
	
	player_sprite = AnimatedSprite2D.new()
	add_child(player_sprite)
	warrior.setup_sprite(player_sprite)
	warrior.pos = Vector2(150, GROUND_Y)
	
	parry_indicator = ColorRect.new()
	parry_indicator.size = Vector2(20, 20)
	parry_indicator.color = Color(0.5, 0.8, 1.0, 0.4)
	parry_indicator.visible = false
	add_child(parry_indicator)
	warrior.parry_indicator = parry_indicator
	
	# === 矿脉甲虫 Boss ===
	var boss_script = load("res://scripts/enemy/boss_beetle.gd")
	boss = Node2D.new()
	boss.set_script(boss_script)
	add_child(boss)
	
	boss_sprite = AnimatedSprite2D.new()
	add_child(boss_sprite)
	boss.setup(boss_sprite)
	boss.pos = Vector2(480, GROUND_Y)
	boss.facing = -1.0
	
	# === HUD ===
	var hud_script = load("res://scripts/ui/hud.gd")
	hud = Node2D.new()
	hud.set_script(hud_script)
	add_child(hud)
	hud.build()
	
	# 连接信号
	warrior.attack_hit.connect(_on_player_attack)
	warrior.rage_changed.connect(func(v): hud.update_rage(v, 100))
	warrior.health_changed.connect(func(v): hud.update_player_hp(v, 100))
	warrior.parry_success.connect(_on_parry_success)
	warrior.died.connect(_on_player_died)
	boss.boss_health_changed.connect(func(h, m): hud.update_boss_hp(h, m))
	boss.boss_phase_changed.connect(_on_boss_phase_changed)
	boss.boss_died.connect(_on_boss_died)
	boss.boss_telegraph.connect(_on_boss_telegraph)
	boss.boss_attack_active.connect(_on_boss_attack_active)
	
	# 版本号
	var ver = Label.new()
	ver.text = "v0.5"
	ver.position = Vector2(600, 350)
	ver.add_theme_font_size_override("font_size", 7)
	ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
	add_child(ver)
	
	# 场景切换提示
	var switch_hint = Label.new()
	switch_hint.text = "[R]切换训练场"
	switch_hint.position = Vector2(520, 350)
	switch_hint.add_theme_font_size_override("font_size", 7)
	switch_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
	add_child(switch_hint)

func _physics_process(delta: float) -> void:
	frame_count += 1
	
	# 场景切换冷却
	if scene_switch_cooldown > 0:
		scene_switch_cooldown -= delta
	
	# Hitstop：顿帧期间只处理特效
	if effects.hitstop_active:
		effects.process(delta)
		return
	
	# 应用震屏偏移
	camera_offset = effects.get_shake_offset()
	
	if battle_intro:
		_process_intro(delta)
		return
	
	if not battle_active:
		return
	
	# 处理特效系统
	effects.process(delta)
	
	# 处理战士
	warrior.process(delta, GROUND_Y)
	
	# 处理Boss
	boss.process(delta, warrior.pos, GROUND_Y)
	
	# 碰撞检测（使用判定帧）
	_check_combat_collisions()
	
	# 裂地斩AOE
	_process_earth_shatter(delta)
	
	# 更新视觉
	_update_visuals()
	
	# 更新HUD
	_update_hud()
	
	# 连招超时
	if warrior.combo_timer <= 0 and not warrior.is_attacking:
		hud.clear_combo()
	
	# 攻击状态显示
	if warrior.is_attacking and warrior.attack_name != "":
		var info = warrior.get_attack_info()
		hud.show_combo(warrior.attack_name, info.get("war_cry_active", false))
	
	# 预警显示
	_update_telegraph()
	
	# 战吼buff显示
	hud.show_war_cry_buff(warrior.war_cry_buff, warrior.war_cry_timer)
	
	# Boss狂暴时定期火焰特效
	if boss.phase == 2 and boss.hp > 0 and frame_count % 30 == 0:
		effects.spawn_boss_enrage_aura(boss.pos)
	
	# 场景切换
	if Input.is_action_just_pressed("skill_1") and scene_switch_cooldown <= 0:
		# 暂时用U键也做场景切换（方便测试）
		pass  # 保持U键为战吼功能
	
	# 自动演示
	_run_demo()
	
	# 截图
	if frame_count == 150:
		_take_screenshot("legend_v05_battle.png")
	if frame_count > 500:
		_take_screenshot("legend_v05_combat.png")
		get_tree().quit()

func _process_intro(delta: float) -> void:
	intro_timer += delta
	boss_sprite.play("idle")
	boss_sprite.position = boss.pos + Vector2(0, -32) + camera_offset
	boss_sprite.flip_h = (boss.facing < 0)
	
	player_sprite.play("idle")
	player_sprite.position = warrior.pos + Vector2(0, -32) + camera_offset
	
	hud.show_boss_hp("矿脉甲虫")
	hud.update_boss_hp(boss.hp, boss.max_hp)
	hud.update_player_hp(warrior.hp, warrior.max_hp)
	
	if intro_timer > 2.0:
		battle_intro = false
		battle_active = true
		hud.show_perfect("FIGHT!", Color(1, 0.3, 0.1))

func _check_combat_collisions() -> void:
	var dist = abs(warrior.pos.x - boss.pos.x)
	
	# === 玩家攻击Boss ===
	# 只有在攻击判定帧才能造成伤害
	if warrior.is_in_active_frames() and not boss_hit_applied:
		if dist < 80:
			var dmg: float = warrior.get_attack_damage()
			boss.take_damage(dmg)
			warrior.mark_hit_dealt()
			boss_hit_applied = true
			
			# 打击感特效
			var hit_pos: Vector2 = (warrior.pos + boss.pos) / 2 + Vector2(0, -20)
			var is_heavy: bool = dmg >= 20
			
			# 命中火花
			effects.spawn_hit_spark(hit_pos, Color(1, 0.9, 0.5) if not is_heavy else Color(1, 0.5, 0.2))
			
			# 血液飞溅
			effects.spawn_blood_splatter(hit_pos, warrior.facing)
			
			# Hitstop顿帧（重击更长）
			if is_heavy:
				effects.start_hitstop(0.1)
			else:
				effects.start_hitstop(0.06)
			
			# 震屏（重击更强烈）
			if is_heavy:
				effects.start_shake(4.0, 8.0)
			else:
				effects.start_shake(1.5, 6.0)
			
			# 伤害数字
			hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, is_heavy)
			
			# 怒气获取
			var combo_info = warrior.get_attack_info()
			var rage_gain: float = 5.0 * combo_info.get("damage_mult", 1.0)
			if warrior.war_cry_buff:
				rage_gain *= 1.2
			warrior.rage = min(warrior.max_rage, warrior.rage + rage_gain)
	
	if not warrior.is_attacking or warrior.attack_phase != 2:  # 不在判定帧
		if warrior.attack_phase == 3:  # RECOVERY
			boss_hit_applied = false
	
	# === Boss攻击玩家 ===
	# 只有Boss在判定帧才能伤害玩家
	if boss.is_in_attack_state() and boss.is_attack_active() and not player_hit_applied:
		if dist < 85:
			var dmg: float = boss.get_attack_damage()
			var kb: Vector2 = boss.get_attack_knockback()
			warrior.take_damage(dmg, kb)
			if dmg > 0:
				hud.spawn_damage_number(warrior.pos + Vector2(0, -40), dmg, dmg >= 25)
				
				# 打击感
				var hit_pos: Vector2 = (warrior.pos + boss.pos) / 2 + Vector2(0, -20)
				effects.spawn_hit_spark(hit_pos, Color(1, 0.3, 0.2))
				effects.spawn_blood_splatter(hit_pos, boss.facing)
				
				# Boss重击 → 长顿帧+强震屏
				if dmg >= 25:
					effects.start_hitstop(0.12)
					effects.start_shake(6.0, 10.0)
				else:
					effects.start_hitstop(0.05)
					effects.start_shake(2.0, 7.0)
				
				player_hit_applied = true
	
	if not boss.is_attack_active():
		player_hit_applied = false

func _process_earth_shatter(delta: float) -> void:
	"""处理裂地斩AOE"""
	# 检测是否使用裂地斩
	if warrior.current_anim == "earth_shatter" and not earth_shatter_active:
		earth_shatter_active = true
		earth_shatter_timer = 0.5
		earth_shatter_dealt = false
		# 怒气爆发特效
		effects.spawn_rage_burst(warrior.pos)
		effects.start_shake(5.0, 8.0)
		hud.show_perfect("EARTH SHATTER!", Color(1, 0.3, 0.1))
	
	if earth_shatter_active:
		earth_shatter_timer -= delta
		# 在判定帧造成AOE伤害
		if earth_shatter_timer <= 0.3 and not earth_shatter_dealt:
			earth_shatter_dealt = true
			var dist = abs(warrior.pos.x - boss.pos.x)
			if dist < 120:  # 裂地斩大范围
				var dmg: float = 60.0  # 终极技高伤害
				if warrior.war_cry_buff:
					dmg *= warrior.war_cry_damage_mult
				boss.take_damage(dmg)
				hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, true)
				effects.spawn_earth_shatter(warrior.pos, warrior.facing)
				effects.start_hitstop(0.15)
				effects.start_shake(8.0, 12.0)
			else:
				effects.spawn_earth_shatter(warrior.pos, warrior.facing)
		
		if earth_shatter_timer <= 0:
			earth_shatter_active = false
	
	# 战吼特效
	if warrior.current_anim == "war_cry" and frame_count % 8 == 0:
		effects.spawn_rage_burst(warrior.pos + Vector2(0, -30))

func _on_player_attack(_target: Node2D, _damage: float, _knockback: Vector2) -> void:
	pass

func _on_parry_success(is_perfect: bool) -> void:
	if is_perfect:
		hud.show_perfect("PERFECT PARRY!", Color(0.5, 0.8, 1.0))
		# 完美格挡特效
		var parry_pos: Vector2 = warrior.pos + Vector2(15 * warrior.facing, -25)
		effects.spawn_parry_spark(parry_pos, true)
		effects.start_hitstop(0.08)
		effects.start_shake(2.0, 6.0)
		# 怒气回复
		warrior.rage = min(warrior.max_rage, warrior.rage + 15)
		hud.update_rage(warrior.rage, warrior.max_rage)
	else:
		hud.show_perfect("PARRY!", Color(0.7, 0.9, 1.0))
		var parry_pos: Vector2 = warrior.pos + Vector2(15 * warrior.facing, -25)
		effects.spawn_parry_spark(parry_pos, false)
		effects.start_hitstop(0.04)

func _on_boss_phase_changed(phase: int) -> void:
	hud.update_boss_phase(phase)
	# 狂暴特效
	effects.start_slowmo(0.5, 0.3)
	effects.spawn_boss_enrage_aura(boss.pos)
	hud.show_perfect("ENRAGED!", Color(1, 0.2, 0.1))

func _on_boss_died() -> void:
	battle_active = false
	hud.show_perfect("VICTORY!", Color(1, 0.9, 0.2))
	effects.start_slowmo(1.0, 0.2)
	effects.start_shake(10.0, 3.0)
	# 胜利粒子爆发
	for i in range(3):
		effects.spawn_rage_burst(boss.pos + Vector2(randf_range(-30, 30), randf_range(-40, 0)))
	_take_screenshot("legend_v05_victory.png")

func _on_boss_telegraph(attack_type: String, direction: float, duration: float) -> void:
	"""Boss攻击预警信号"""
	# 预警将在 _update_telegraph 中根据Boss状态更新
	pass

func _on_boss_attack_active(is_active: bool) -> void:
	"""Boss攻击判定帧变化"""
	if not is_active:
		hud.hide_telegraph()

func _on_player_died() -> void:
	battle_active = false
	hud.show_perfect("DEFEATED...", Color(0.5, 0.5, 0.5))
	effects.start_slowmo(0.5, 0.3)

func _update_telegraph() -> void:
	"""更新Boss预警显示"""
	var info: Dictionary = boss.get_telegraph_info()
	var warning_level: int = info.get("warning_level", 0)
	if warning_level > 0:
		hud.show_telegraph(info["type"], boss.pos, boss.facing, warning_level)
	else:
		hud.hide_telegraph()

func _update_hud() -> void:
	"""更新HUD状态"""
	hud.update_player_hp(warrior.hp, warrior.max_hp)
	hud.update_rage(warrior.rage, warrior.max_rage)
	hud.update_hit_count(warrior.hit_count)

func _update_visuals() -> void:
	# 震屏偏移
	var shake = camera_offset
	
	# 战士
	player_sprite.position = warrior.pos + Vector2(0, -32) + shake
	player_sprite.flip_h = (warrior.facing < 0)
	
	# 无敌闪烁
	if warrior.invincible_timer > 0:
		player_sprite.visible = int(frame_count / 3) % 2 == 0
	else:
		player_sprite.visible = true
	
	# 战吼buff视觉效果
	if warrior.war_cry_buff:
		if int(frame_count / 4) % 3 == 0:
			player_sprite.modulate = Color(1.2, 1.0, 0.7)
		else:
			player_sprite.modulate = Color(1, 1, 1)
	
	# 格挡指示器
	if warrior.is_guarding and warrior.is_perfect_parry_window:
		parry_indicator.visible = true
		parry_indicator.position = warrior.pos + Vector2(-10 * warrior.facing, -42) + shake
		parry_indicator.color = Color(0.5, 0.8, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
	else:
		parry_indicator.visible = false
	
	# Boss (96x64 精灵, 中心偏移16)
	boss_sprite.position = boss.pos + Vector2(-16, -32) + shake
	boss_sprite.flip_h = (boss.facing < 0)

func _take_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("/home/z/my-project/download/" + filename)
		print("Screenshot saved: " + filename)

# === 自动演示 ===
func _run_demo() -> void:
	match frame_count:
		150:
			warrior.vel.x = 220
			warrior.facing = 1.0
		180:
			warrior.do_attack("L")
		210:
			warrior.do_attack("L")
		240:
			warrior.do_attack("L")
		270:
			warrior.vel.x = 0
		300:
			warrior.do_attack("H")
		330:
			warrior.do_attack("L")
		360:
			warrior.do_attack("H")
		390:
			warrior.rage = 100
			hud.show_perfect("RAGE FULL!", Color(1, 0.7, 0.1))
			effects.spawn_rage_burst(warrior.pos)
		410:
			warrior.vel.x = 0
