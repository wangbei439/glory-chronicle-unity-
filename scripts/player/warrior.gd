## 战士玩家控制器 - Alpha v0.5
## 处理输入、移动、连招、格挡、怒气
## 新增：攻击判定帧(startup/active/recovery)、战吼增伤、完美格挡回血、裂地斩AOE
extends Node2D

signal attack_hit(target: Node2D, damage: float, knockback: Vector2)
signal parry_success(is_perfect: bool)
signal rage_changed(value: float)
signal health_changed(value: float)
signal died

# === 属性 ===
@export var max_hp: float = 100.0
@export var max_rage: float = 100.0
@export var move_speed: float = 280.0
@export var jump_force: float = -450.0
@export var gravity: float = 980.0

# === 状态 ===
var hp: float = 100.0
var rage: float = 0.0
var pos: Vector2 = Vector2(125, 309)
var vel: Vector2 = Vector2.ZERO
var facing: float = 1.0
var is_attacking: bool = false
var attack_frame: int = 0
var attack_duration: int = 20
var attack_name: String = ""
var is_guarding: bool = false
var is_perfect_parry_window: bool = false
var parry_window_timer: float = 0.0
var is_hurt: bool = false
var hurt_timer: float = 0.0
var invincible_timer: float = 0.0

# === 攻击判定帧 ===
# 每个攻击有三个阶段：startup(前摇) / active(判定) / recovery(后摇)
# 只有active帧才能造成伤害
enum AttackPhase { STARTUP, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.STARTUP
var attack_startup_frames: int = 4   # 前摇帧数
var attack_active_frames: int = 6    # 判定帧数
var attack_hit_dealt: bool = false   # 本次攻击是否已命中

# === 连招 ===
var combo_sequence: Array = []
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_tree: Dictionary = {}

# === 技能效果 ===
var war_cry_buff: bool = false       # 战吼增伤状态
var war_cry_timer: float = 0.0      # 战吼剩余时间
var war_cry_damage_mult: float = 1.15  # 战吼增伤倍率
var hit_count: int = 0               # 连击计数

# === 视觉 ===
var sprite: AnimatedSprite2D
var parry_indicator: ColorRect
var current_anim: String = "idle"

func _ready() -> void:
	_build_combo_tree()

func _build_combo_tree() -> void:
	# 连招定义：name, mult(伤害倍率), rage(怒气获取), dur(总帧数), startup(前摇), active(判定), kb(击退)
	combo_tree["L"] = {"name": "横斩", "mult": 1.0, "rage": 5, "dur": 20, "startup": 4, "active": 6, "kb": Vector2(3, -1)}
	combo_tree["L,L"] = {"name": "逆斩", "mult": 1.2, "rage": 5, "dur": 18, "startup": 3, "active": 5, "kb": Vector2(3, -1)}
	combo_tree["L,L,L"] = {"name": "回旋斩", "mult": 1.8, "rage": 10, "dur": 25, "startup": 5, "active": 8, "kb": Vector2(5, -2)}
	combo_tree["L,L,H"] = {"name": "上挑", "mult": 1.5, "rage": 8, "dur": 25, "startup": 4, "active": 6, "kb": Vector2(2, -6)}
	combo_tree["L,L,DH"] = {"name": "下砸", "mult": 2.0, "rage": 10, "dur": 30, "startup": 6, "active": 8, "kb": Vector2(0, 8)}
	combo_tree["L,H"] = {"name": "冲刺斩", "mult": 1.3, "rage": 7, "dur": 18, "startup": 2, "active": 6, "kb": Vector2(8, -1)}
	combo_tree["H"] = {"name": "重击", "mult": 2.5, "rage": 8, "dur": 28, "startup": 8, "active": 6, "kb": Vector2(6, -2)}
	combo_tree["H,L"] = {"name": "追击斩", "mult": 1.5, "rage": 6, "dur": 15, "startup": 2, "active": 5, "kb": Vector2(4, -1)}

func setup_sprite(animated_sprite: AnimatedSprite2D) -> void:
	sprite = animated_sprite
	_build_animations()

func _build_animations() -> void:
	if not sprite:
		return
	var sf = SpriteFrames.new()
	
	var anims = {
		"idle": {"path": "warrior_idle_sheet.png", "frames": 4, "speed": 8.0, "loop": true},
		"run": {"path": "warrior_run_sheet.png", "frames": 4, "speed": 10.0, "loop": true},
		"attack": {"path": "warrior_attack_sheet.png", "frames": 4, "speed": 10.0, "loop": false},
		"guard": {"path": "warrior_guard_sheet.png", "frames": 2, "speed": 6.0, "loop": true},
		"jump": {"path": "warrior_jump_sheet.png", "frames": 2, "speed": 4.0, "loop": false},
		"hurt": {"path": "warrior_hurt_sheet.png", "frames": 2, "speed": 8.0, "loop": false},
		"war_cry": {"path": "warrior_war_cry_sheet.png", "frames": 2, "speed": 6.0, "loop": false},
		"earth_shatter": {"path": "warrior_earth_shatter_sheet.png", "frames": 2, "speed": 6.0, "loop": false},
	}
	
	for anim_name: String in anims:
		var info: Dictionary = anims[anim_name]
		var tex = load("res://assets/sprites/player/" + info["path"])
		if not tex:
			continue
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, info["speed"])
		sf.set_animation_loop(anim_name, info["loop"])
		var count: int = info["frames"]
		for i in range(count):
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * 64, 0, 64, 64)
			atlas.filter_clip = true
			sf.add_frame(anim_name, atlas)
	
	# 回退
	if not sf.has_animation("idle"):
		sf.add_animation("idle")
		var fb = load("res://assets/sprites/player/warrior_idle_64.png")
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

func process(delta: float, ground_y: float) -> void:
	# 战吼buff计时
	if war_cry_buff:
		war_cry_timer -= delta
		if war_cry_timer <= 0:
			war_cry_buff = false
			war_cry_damage_mult = 1.0
	
	# 无敌帧
	if invincible_timer > 0:
		invincible_timer -= delta
	
	# 受击恢复
	if is_hurt:
		hurt_timer -= delta
		if hurt_timer <= 0:
			is_hurt = false
	
	# 连招超时
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_sequence.clear()
			combo_count = 0
			hit_count = 0
	
	# 格挡窗口
	if is_perfect_parry_window:
		parry_window_timer -= delta
		if parry_window_timer <= 0:
			is_perfect_parry_window = false
			if parry_indicator:
				parry_indicator.visible = false
	
	# 受击中不能操作
	if is_hurt:
		vel.x = lerp(vel.x, 0.0, 0.1)
		_apply_physics(delta, ground_y)
		return
	
	# 攻击中 - 判定帧系统
	if is_attacking:
		attack_frame += 1
		
		# 判定当前攻击阶段
		var active_end: int = attack_startup_frames + attack_active_frames
		if attack_frame <= attack_startup_frames:
			attack_phase = AttackPhase.STARTUP
		elif attack_frame <= active_end:
			attack_phase = AttackPhase.ACTIVE
		else:
			attack_phase = AttackPhase.RECOVERY
		
		# 攻击期间移动减速
		if attack_phase == AttackPhase.STARTUP:
			vel.x = lerp(vel.x, 0.0, 0.15)  # 前摇几乎不动
		elif attack_phase == AttackPhase.ACTIVE:
			# 判定帧可以微移（冲刺斩有位移）
			if attack_name == "冲刺斩":
				vel.x = facing * 180  # 冲刺斩向前冲刺
			else:
				vel.x = lerp(vel.x, 0.0, 0.08)
		else:
			vel.x = lerp(vel.x, 0.0, 0.12)  # 后摇减速
		
		# 攻击结束
		if attack_frame >= attack_duration:
			is_attacking = false
			attack_frame = 0
			attack_name = ""
			attack_hit_dealt = false
			attack_phase = AttackPhase.STARTUP
			play_anim("idle")
	
	# 格挡
	if is_guarding:
		vel.x = 0
		play_anim("guard")
		_apply_physics(delta, ground_y)
		return
	
	# 移动
	var is_moving = false
	if Input.is_action_pressed("move_right"):
		vel.x = move_speed
		facing = 1.0
		is_moving = true
	elif Input.is_action_pressed("move_left"):
		vel.x = -move_speed
		facing = -1.0
		is_moving = true
	else:
		vel.x = lerp(vel.x, 0.0, 0.2)
	
	# 动画
	if not is_attacking:
		if pos.y < ground_y - 3:
			play_anim("jump")
		elif is_moving:
			play_anim("run")
		else:
			play_anim("idle")
	
	# 跳跃
	if Input.is_action_just_pressed("jump") and pos.y >= ground_y - 3:
		vel.y = jump_force
	
	# 攻击
	if Input.is_action_just_pressed("attack"):
		do_attack("L")
	elif Input.is_action_just_pressed("heavy_attack"):
		do_attack("H")
	
	# 格挡
	if Input.is_action_just_pressed("guard"):
		is_guarding = true
		is_perfect_parry_window = true
		parry_window_timer = 0.1  # 6帧完美窗口
		if parry_indicator:
			parry_indicator.visible = true
			parry_indicator.color = Color(0.5, 0.8, 1.0, 0.5)
	
	if Input.is_action_just_released("guard"):
		is_guarding = false
		is_perfect_parry_window = false
		if parry_indicator:
			parry_indicator.visible = false
	
	# 技能 - 战吼（50怒气）：增伤15%持续8秒 + 回复10HP
	if Input.is_action_just_pressed("skill_1") and rage >= 50:
		rage -= 50
		war_cry_buff = true
		war_cry_timer = 8.0
		war_cry_damage_mult = 1.15
		hp = min(max_hp, hp + 10)  # 回复10HP
		health_changed.emit(hp)
		play_anim("war_cry")
		rage_changed.emit(rage)
	
	# 技能 - 裂地斩（100怒气）：大范围AOE伤害
	if Input.is_action_just_pressed("ultimate") and rage >= 100:
		rage = 0
		play_anim("earth_shatter")
		rage_changed.emit(rage)
	
	_apply_physics(delta, ground_y)

func _apply_physics(delta: float, ground_y: float) -> void:
	if pos.y < ground_y:
		vel.y += gravity * delta
	pos += vel * delta
	if pos.y > ground_y:
		pos.y = ground_y
		vel.y = 0

func do_attack(input_key: String) -> void:
	# 只能在后摇阶段输入下一个连招（或非攻击时）
	if is_attacking and attack_phase != AttackPhase.RECOVERY:
		return
	
	# 后摇取消 - 进入下一招
	if is_attacking and attack_phase == AttackPhase.RECOVERY:
		is_attacking = false
		attack_frame = 0
		attack_hit_dealt = false
	
	combo_sequence.append(input_key)
	combo_timer = 1.0
	
	var key = ",".join(combo_sequence)
	var combo_data = null
	if combo_tree.has(key):
		combo_data = combo_tree[key]
	else:
		combo_sequence = [input_key]
		key = input_key
		if combo_tree.has(key):
			combo_data = combo_tree[key]
	
	if combo_data == null:
		combo_sequence.clear()
		return
	
	attack_name = combo_data["name"]
	attack_duration = combo_data["dur"]
	attack_startup_frames = combo_data.get("startup", 4)
	attack_active_frames = combo_data.get("active", 6)
	is_attacking = true
	attack_frame = 0
	attack_phase = AttackPhase.STARTUP
	attack_hit_dealt = false
	combo_count += 1
	hit_count += 1
	play_anim("attack")

func get_attack_damage() -> float:
	"""获取当前攻击的伤害值（含战吼增伤）"""
	var key = ",".join(combo_sequence) if combo_sequence.size() > 0 else ""
	var info = combo_tree.get(key, {})
	var base_mult: float = info.get("mult", 1.0) if info else 1.0
	var dmg: float = 10.0 * base_mult
	
	# 完美判定加成
	var is_perfect: bool = is_perfect_parry_window or randf() < 0.2
	if is_perfect:
		dmg *= 1.3
	
	# 战吼增伤
	if war_cry_buff:
		dmg *= war_cry_damage_mult
	
	# 连击加成（每10连击+5%伤害，上限+30%）
	var combo_bonus: float = 1.0 + min(0.3, hit_count * 0.05)
	if hit_count >= 10:
		combo_bonus = 1.3
	dmg *= combo_bonus
	
	return dmg

func is_in_active_frames() -> bool:
	"""当前是否在攻击判定帧"""
	return is_attacking and attack_phase == AttackPhase.ACTIVE and not attack_hit_dealt

func mark_hit_dealt() -> void:
	"""标记本次攻击已命中"""
	attack_hit_dealt = true

func take_damage(dmg: float, knockback: Vector2) -> void:
	if invincible_timer > 0:
		return
	
	# 格挡判定
	if is_guarding:
		if is_perfect_parry_window:
			# 完美格挡：0伤害 + 反击窗口 + 回复5HP
			parry_success.emit(true)
			hp = min(max_hp, hp + 5)  # 完美格挡回血
			health_changed.emit(hp)
			dmg = 0
			knockback = Vector2.ZERO
		else:
			# 普通格挡：50%减伤
			dmg *= 0.5
			knockback *= 0.3
			parry_success.emit(false)
	
	hp = max(0, hp - dmg)
	health_changed.emit(hp)
	
	if dmg > 0:
		is_hurt = true
		hurt_timer = 0.3
		invincible_timer = 0.5
		vel = knockback * 50
		play_anim("hurt")
		hit_count = 0  # 受击重置连击计数
		
		if hp <= 0:
			died.emit()

func get_attack_info() -> Dictionary:
	var key = ",".join(combo_sequence) if combo_sequence.size() > 0 else ""
	var info = combo_tree.get(key, {})
	return {
		"name": attack_name,
		"is_attacking": is_attacking,
		"combo_count": combo_count,
		"damage_mult": info.get("mult", 1.0) if info else 1.0,
		"is_active_frame": attack_phase == AttackPhase.ACTIVE,
		"hit_count": hit_count,
		"war_cry_active": war_cry_buff,
	}
