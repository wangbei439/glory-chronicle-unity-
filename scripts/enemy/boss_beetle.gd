## 矿脉甲虫 Boss AI - Alpha v0.5
## 行为状态机：IDLE → CHASE → ATTACK → HEAVY_ATTACK → CHARGE → SPECIAL → STUNNED → ENRAGED
## 新增：攻击预警(telegraph)、霸体(super armor)、多段攻击、增强狂暴模式
extends Node2D

signal boss_health_changed(hp: float, max_hp: float)
signal boss_died
signal boss_phase_changed(phase: int)
signal boss_telegraph(attack_type: String, direction: float, duration: float)  # 预警信号
signal boss_attack_active(is_active: bool)  # 攻击判定帧信号

# === 属性 ===
@export var max_hp: float = 500.0
@export var move_speed: float = 120.0
@export var chase_speed: float = 180.0
@export var attack_range: float = 70.0
@export var detect_range: float = 250.0

# === 状态 ===
enum State { IDLE, CHASE, ATTACK, HEAVY_ATTACK, CHARGE, SPECIAL, STUNNED, DYING }
var current_state: State = State.IDLE
var hp: float = 500.0
var pos: Vector2 = Vector2(450, 309)
var vel: Vector2 = Vector2.ZERO
var facing: float = -1.0
var state_timer: float = 0.0
var attack_cooldown: float = 0.0
var phase: int = 1  # 1=普通, 2=狂暴(HP<50%)
var is_stunned: bool = false
var stun_timer: float = 0.0
var charge_target: Vector2 = Vector2.ZERO
var is_charging: bool = false

# === 攻击判定帧 ===
enum AttackPhase { TELEGRAPH, STARTUP, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.TELEGRAPH
var attack_hit_count: int = 0   # 多段攻击计数
var attack_max_hits: int = 1    # 本次攻击最大命中次数
var attack_hit_interval: float = 0.0  # 多段攻击间隔
var attack_hit_timer: float = 0.0

# === 霸体 ===
var super_armor: bool = false  # 霸体状态 - 不被打断
var poise: float = 100.0       # 韧性值 - 受攻击减少，归零时破霸体
var max_poise: float = 100.0
var poise_regen_rate: float = 20.0  # 韧性回复速率

# === 视觉 ===
var sprite: AnimatedSprite2D
var current_anim: String = "idle"
var telegraph_indicator: ColorRect  # 预警指示器
var telegraph_label: Label          # 预警文字

# 攻击模式
var attack_patterns: Array = []
var current_pattern: int = 0
var consecutive_attacks: int = 0  # 连续攻击计数

func _ready() -> void:
	hp = max_hp

func setup(anim_sprite: AnimatedSprite2D) -> void:
	sprite = anim_sprite
	_build_animations()

func _build_animations() -> void:
	if not sprite:
		return
	var sf = SpriteFrames.new()
	
	var anims = {
		"idle": {"path": "boss_beetle_idle_sheet.png", "frames": 4, "speed": 6.0, "loop": true},
		"walk": {"path": "boss_beetle_walk_sheet.png", "frames": 4, "speed": 8.0, "loop": true},
		"attack": {"path": "boss_beetle_attack_sheet.png", "frames": 4, "speed": 10.0, "loop": false},
		"charge": {"path": "boss_beetle_charge_sheet.png", "frames": 2, "speed": 12.0, "loop": true},
		"stunned": {"path": "boss_beetle_stunned_sheet.png", "frames": 2, "speed": 4.0, "loop": true},
		"hurt": {"path": "boss_beetle_hurt_sheet.png", "frames": 2, "speed": 8.0, "loop": false},
		"death": {"path": "boss_beetle_death_sheet.png", "frames": 4, "speed": 4.0, "loop": false},
	}
	
	for anim_name: String in anims:
		var info: Dictionary = anims[anim_name]
		var tex = load("res://assets/sprites/enemy/" + info["path"])
		if not tex:
			continue
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, info["speed"])
		sf.set_animation_loop(anim_name, info["loop"])
		var count: int = info["frames"]
		for i in range(count):
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * 96, 0, 96, 64)
			atlas.filter_clip = true
			sf.add_frame(anim_name, atlas)
	
	# 回退
	if not sf.has_animation("idle"):
		sf.add_animation("idle")
		var fb = load("res://assets/sprites/enemy/boss_beetle_idle_64.png")
		if fb:
			sf.add_frame("idle", fb)
	
	sprite.sprite_frames = sf
	sprite.play("idle")

func play_anim(anim_name: String) -> void:
	if current_anim == anim_name:
		return
	current_anim = anim_name
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func process(delta: float, player_pos: Vector2, ground_y: float) -> void:
	if hp <= 0:
		if current_state != State.DYING:
			current_state = State.DYING
			state_timer = 2.0
			play_anim("death")
		state_timer -= delta
		if state_timer <= 0:
			boss_died.emit()
		return
	
	# 韧性回复
	if not super_armor and poise < max_poise:
		poise = min(max_poise, poise + poise_regen_rate * delta)
	
	# 硬直恢复
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			super_armor = false
			change_state(State.IDLE)
		_update_visuals(ground_y)
		return
	
	# 攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# 阶段检测
	if phase == 1 and hp < max_hp * 0.5:
		phase = 2
		boss_phase_changed.emit(2)
		# 狂暴转换：回复30点韧性
		poise = min(max_poise, poise + 30)
		super_armor = true  # 狂暴开始有霸体
	
	# 状态机
	state_timer -= delta
	var dist_to_player = abs(pos.x - player_pos.x)
	
	match current_state:
		State.IDLE:
			_process_idle(delta, dist_to_player, player_pos)
		State.CHASE:
			_process_chase(delta, dist_to_player, player_pos)
		State.ATTACK:
			_process_attack(delta, player_pos)
		State.HEAVY_ATTACK:
			_process_heavy_attack(delta, player_pos)
		State.CHARGE:
			_process_charge(delta, player_pos, ground_y)
		State.SPECIAL:
			_process_special(delta, player_pos)
	
	# 物理
	if pos.y < ground_y:
		vel.y += 980.0 * delta
	pos += vel * delta
	if pos.y > ground_y:
		pos.y = ground_y
		vel.y = 0
	
	_update_visuals(ground_y)

func change_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	attack_phase = AttackPhase.TELEGRAPH
	attack_hit_count = 0
	
	match new_state:
		State.IDLE:
			play_anim("idle")
			state_timer = randf_range(0.5, 1.5)
			super_armor = false
			consecutive_attacks = 0
		State.CHASE:
			play_anim("walk")
			super_armor = false
		State.ATTACK:
			# 普通攻击：短暂预警 → 攻击
			_start_telegraph("bite", 0.3)
			state_timer = 0.8
			attack_max_hits = 1
			attack_hit_interval = 0
		State.HEAVY_ATTACK:
			# 重击：较长预警 → 二连击
			_start_telegraph("heavy", 0.5)
			state_timer = 1.2
			attack_max_hits = 2
			attack_hit_interval = 0.3
			attack_hit_timer = 0
			super_armor = true  # 重击有霸体
		State.CHARGE:
			_start_telegraph("charge", 0.4)
			is_charging = true
			state_timer = 1.5
			super_armor = true  # 冲锋有霸体
		State.SPECIAL:
			_start_telegraph("jump", 0.6)
			state_timer = 1.2
			attack_max_hits = 1
			super_armor = true
		State.STUNNED:
			play_anim("stunned")
			super_armor = false

func _start_telegraph(attack_type: String, duration: float) -> void:
	"""发送攻击预警信号"""
	attack_phase = AttackPhase.TELEGRAPH
	boss_telegraph.emit(attack_type, facing, duration)

func _process_idle(delta: float, dist: float, player_pos: Vector2) -> void:
	vel.x = lerp(vel.x, 0.0, 0.15)
	if state_timer <= 0:
		if dist < attack_range and attack_cooldown <= 0:
			# 选择攻击类型
			consecutive_attacks += 1
			if phase == 2 and randf() < 0.35:
				if consecutive_attacks >= 3:
					change_state(State.SPECIAL)  # 连续3次后跳砸
				else:
					change_state(State.HEAVY_ATTACK)
			else:
				change_state(State.ATTACK)
		elif dist < detect_range:
			change_state(State.CHASE)
		else:
			state_timer = randf_range(0.5, 1.5)

func _process_chase(delta: float, dist: float, player_pos: Vector2) -> void:
	var spd = chase_speed if phase == 2 else move_speed
	var dir = 1.0 if player_pos.x > pos.x else -1.0
	vel.x = dir * spd
	facing = dir
	
	if dist < attack_range and attack_cooldown <= 0:
		vel.x = 0
		change_state(State.ATTACK)
	elif dist > detect_range * 1.5:
		vel.x = lerp(vel.x, 0.0, 0.1)
		change_state(State.IDLE)
	elif phase == 2 and dist < 180 and randf() < 0.01:
		# 狂暴阶段随机冲锋
		change_state(State.CHARGE)

func _process_attack(delta: float, player_pos: Vector2) -> void:
	# 预警阶段
	if attack_phase == AttackPhase.TELEGRAPH:
		if state_timer > 0.5:
			# 预警中：蓄力抖动
			vel.x = sin(state_timer * 25) * 1.5
			play_anim("idle")
			attack_phase = AttackPhase.STARTUP
	# 启动阶段
	elif attack_phase == AttackPhase.STARTUP:
		if state_timer <= 0.5 and state_timer > 0.2:
			attack_phase = AttackPhase.ACTIVE
			play_anim("attack")
			boss_attack_active.emit(true)
	# 判定阶段
	elif attack_phase == AttackPhase.ACTIVE:
		vel.x = lerp(vel.x, 0.0, 0.2)
		attack_hit_timer += delta
		if state_timer <= 0.2:
			attack_phase = AttackPhase.RECOVERY
			boss_attack_active.emit(false)
	# 恢复阶段
	elif attack_phase == AttackPhase.RECOVERY:
		vel.x = lerp(vel.x, 0.0, 0.15)
	
	if state_timer <= 0:
		attack_cooldown = randf_range(1.0, 2.0) if phase == 1 else randf_range(0.5, 1.2)
		super_armor = false
		change_state(State.IDLE)

func _process_heavy_attack(delta: float, player_pos: Vector2) -> void:
	# 预警阶段
	if attack_phase == AttackPhase.TELEGRAPH:
		if state_timer > 0.7:
			# 蓄力抖动（更明显）
			vel.x = sin(state_timer * 30) * 3
			play_anim("idle")
			attack_phase = AttackPhase.STARTUP
	# 启动阶段：蓄力
	elif attack_phase == AttackPhase.STARTUP:
		if state_timer <= 0.7 and state_timer > 0.4:
			# 蓄力下压
			vel.x = 0
		elif state_timer <= 0.4:
			attack_phase = AttackPhase.ACTIVE
			play_anim("attack")
			boss_attack_active.emit(true)
	# 判定阶段：二连击
	elif attack_phase == AttackPhase.ACTIVE:
		attack_hit_timer += delta
		if attack_hit_timer >= attack_hit_interval and attack_hit_count < attack_max_hits:
			attack_hit_timer = 0
			attack_hit_count += 1
			# 第二击前冲
			if attack_hit_count == 2:
				vel.x = facing * 350
			else:
				vel.x = facing * 200
		if state_timer <= 0.3:
			attack_phase = AttackPhase.RECOVERY
			boss_attack_active.emit(false)
	# 恢复
	elif attack_phase == AttackPhase.RECOVERY:
		vel.x = lerp(vel.x, 0.0, 0.12)
	
	if state_timer <= 0:
		attack_cooldown = 2.5
		super_armor = false
		change_state(State.IDLE)

func _process_charge(delta: float, player_pos: Vector2, ground_y: float) -> void:
	# 预警
	if attack_phase == AttackPhase.TELEGRAPH:
		attack_phase = AttackPhase.STARTUP
	# 冲锋
	if is_charging:
		var dir = 1.0 if player_pos.x > pos.x else -1.0
		facing = dir
		vel.x = dir * chase_speed * 2.5
		attack_phase = AttackPhase.ACTIVE
		boss_attack_active.emit(true)
		state_timer -= delta
		if state_timer <= 0:
			is_charging = false
			attack_phase = AttackPhase.RECOVERY
			boss_attack_active.emit(false)
			# 冲锋结束，短暂时停
			vel.x = 0
			state_timer = 0.8
	else:
		vel.x = lerp(vel.x, 0.0, 0.1)
		if state_timer <= 0:
			attack_cooldown = 3.0
			super_armor = false
			change_state(State.IDLE)

func _process_special(delta: float, player_pos: Vector2) -> void:
	# 预警
	if attack_phase == AttackPhase.TELEGRAPH:
		attack_phase = AttackPhase.STARTUP
	# 跳砸攻击
	if state_timer > 0.6:
		vel.y = -450
		vel.x = facing * 60
		play_anim("idle")
	elif state_timer > 0.2:
		vel.y = 550
		vel.x = 0
		attack_phase = AttackPhase.ACTIVE
		play_anim("attack")
		boss_attack_active.emit(true)
	else:
		attack_phase = AttackPhase.RECOVERY
		boss_attack_active.emit(false)
	
	if state_timer <= 0:
		attack_cooldown = 4.0
		super_armor = false
		change_state(State.IDLE)

func take_damage(dmg: float) -> void:
	if hp <= 0:
		return
	hp = max(0, hp - dmg)
	boss_health_changed.emit(hp, max_hp)
	
	# 轻微受击反馈
	play_anim("hurt")
	
	# 韧性减少（重击减更多）
	var poise_damage: float = dmg * 2.0  # 伤害越高韧性损失越大
	poise = max(0, poise - poise_damage)
	
	# 韧性归零时破霸体
	if poise <= 0 and super_armor:
		super_armor = false
		is_stunned = true
		stun_timer = 1.0  # 破霸体后长硬直
		change_state(State.STUNNED)
		return
	
	# 非霸体时一定概率被打断
	if not super_armor and randf() < 0.2 and current_state != State.CHARGE:
		is_stunned = true
		stun_timer = 0.4
		change_state(State.STUNNED)

func get_attack_damage() -> float:
	match current_state:
		State.ATTACK:
			return 15.0 if phase == 1 else 20.0
		State.HEAVY_ATTACK:
			# 二连击第二击伤害更高
			if attack_hit_count >= 2:
				return (30.0 if phase == 1 else 45.0)
			return 20.0 if phase == 1 else 30.0
		State.CHARGE:
			return 25.0
		State.SPECIAL:
			return 35.0 if phase == 1 else 45.0
		_:
			return 0.0

func get_attack_knockback() -> Vector2:
	var base_kb = Vector2(5, -3)
	match current_state:
		State.HEAVY_ATTACK:
			# 第二击击退更大
			if attack_hit_count >= 2:
				base_kb = Vector2(14, -6)
			else:
				base_kb = Vector2(8, -3)
		State.CHARGE:
			base_kb = Vector2(15, -3)
		State.SPECIAL:
			base_kb = Vector2(3, -10)
	return base_kb * Vector2(facing, 1)

func is_in_attack_state() -> bool:
	return current_state == State.ATTACK or current_state == State.HEAVY_ATTACK or current_state == State.CHARGE or current_state == State.SPECIAL

func is_attack_active() -> bool:
	"""当前是否在攻击判定帧"""
	return attack_phase == AttackPhase.ACTIVE

func get_telegraph_info() -> Dictionary:
	"""获取当前预警信息"""
	var info = {"type": "", "warning_level": 0}  # warning_level: 0=无, 1=黄, 2=红
	if attack_phase == AttackPhase.TELEGRAPH or attack_phase == AttackPhase.STARTUP:
		match current_state:
			State.ATTACK:
				info = {"type": "!", "warning_level": 1}  # 黄色感叹号
			State.HEAVY_ATTACK:
				info = {"type": "!!", "warning_level": 2}  # 红色双感叹号
			State.CHARGE:
				info = {"type": "→→", "warning_level": 2}  # 红色箭头
			State.SPECIAL:
				info = {"type": "▼▼", "warning_level": 2}  # 红色向下
	return info

func _update_visuals(ground_y: float) -> void:
	if sprite:
		sprite.position = pos + Vector2(0, -32)
		sprite.flip_h = (facing < 0)
		# 狂暴闪烁
		if phase == 2 and hp > 0:
			if int(Time.get_ticks_msec() / 200) % 2 == 0:
				sprite.modulate = Color(1.3, 0.8, 0.7)
			else:
				sprite.modulate = Color(1, 1, 1)
		# 霸体效果 - 发光边框
		elif super_armor:
			sprite.modulate = Color(1.2, 1.1, 0.8)
		# 硬直闪烁
		elif is_stunned:
			if int(Time.get_ticks_msec() / 100) % 2 == 0:
				sprite.modulate = Color(1.5, 1.5, 2.0)
			else:
				sprite.modulate = Color(1, 1, 1)
		else:
			sprite.modulate = Color(1, 1, 1)
