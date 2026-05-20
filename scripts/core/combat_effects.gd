## 打击感特效系统 - Beta v0.14 美术升级版
## 管理Hitstop顿帧、ScreenShake震屏、粒子特效
## v0.14: 圆形粒子 + 发光效果 + 拖尾 + 环境粒子
extends Node2D

signal hitstop_started(duration: float)
signal hitstop_ended

# === Hitstop 顿帧 ===
var hitstop_active: bool = false
var hitstop_timer: float = 0.0

# === Screen Shake 震屏 ===
var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var shake_offset: Vector2 = Vector2.ZERO
var camera_node: Node2D = null

# === 粒子特效 ===
var particles: Array = []

# === 全局时间缩放 ===
var time_scale: float = 1.0
var slowmo_timer: float = 0.0
var slowmo_target: float = 1.0

# === 环境粒子 ===
var ambient_particles: Array = []
var ambient_type: String = ""  # "dust", "embers", "crystals"

# === 闪光效果 ===
var flash_overlay: ColorRect
var flash_timer: float = 0.0

func _ready() -> void:
	# 创建闪光覆盖层
	flash_overlay = ColorRect.new()
	flash_overlay.size = Vector2(640, 360)
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_overlay.z_index = 100
	add_child(flash_overlay)

func process(delta: float) -> void:
	# 处理Hitstop
	if hitstop_active:
		hitstop_timer -= delta
		if hitstop_timer <= 0:
			hitstop_active = false
			hitstop_timer = 0
			hitstop_ended.emit()
		return
	
	# 处理慢动作
	if slowmo_timer > 0:
		slowmo_timer -= delta
		if slowmo_timer <= 0:
			time_scale = 1.0
		else:
			time_scale = lerp(time_scale, slowmo_target, 0.2)
	
	# 处理震屏
	if shake_intensity > 0:
		shake_intensity = max(0, shake_intensity - shake_decay * delta)
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		shake_offset = Vector2.ZERO
	
	# 处理粒子
	_process_particles(delta)
	
	# 处理闪光
	if flash_timer > 0:
		flash_timer -= delta
		flash_overlay.color = Color(1, 1, 1, max(0, flash_timer * 3))
	
	# 处理环境粒子
	_process_ambient(delta)

# === Hitstop API ===
func start_hitstop(duration: float = 0.08) -> void:
	hitstop_active = true
	hitstop_timer = duration
	hitstop_started.emit(duration)

func is_paused() -> bool:
	return hitstop_active

# === Screen Shake API ===
func start_shake(intensity: float = 3.0, decay: float = 5.0) -> void:
	shake_intensity = intensity
	shake_decay = decay

func get_shake_offset() -> Vector2:
	return shake_offset

# === Slow Motion API ===
func start_slowmo(duration: float = 0.3, target_scale: float = 0.3) -> void:
	slowmo_timer = duration
	slowmo_target = target_scale
	time_scale = target_scale

# === Screen Flash API ===
func start_flash(duration: float = 0.15, color: Color = Color(1, 1, 1)) -> void:
	flash_timer = duration
	flash_overlay.color = Color(color.r, color.g, color.b, 0.3)

# === 环境粒子API ===
func setup_ambient(type: String, count: int = 12) -> void:
	ambient_type = type
	ambient_particles.clear()
	for i in range(count):
		var p = _create_ambient_particle(type)
		add_child(p["node"])
		ambient_particles.append(p)

func _create_ambient_particle(type: String) -> Dictionary:
	var p = ColorRect.new()
	match type:
		"dust":
			p.size = Vector2(randf_range(1, 2), randf_range(1, 2))
			p.color = Color(0.5, 0.45, 0.4, randf_range(0.15, 0.35))
		"embers":
			p.size = Vector2(randf_range(1, 3), randf_range(1, 3))
			var colors = [Color(1, 0.5, 0.1, 0.5), Color(1, 0.7, 0.2, 0.4), Color(0.8, 0.2, 0.05, 0.3)]
			p.color = colors[randi() % 3]
		"crystals":
			p.size = Vector2(randf_range(1, 2), randf_range(1, 2))
			var colors = [Color(0.4, 0.7, 1.0, 0.3), Color(0.6, 0.4, 1.0, 0.25), Color(0.3, 0.8, 0.6, 0.2)]
			p.color = colors[randi() % 3]
		_:
			p.size = Vector2(1, 1)
			p.color = Color(0.5, 0.5, 0.5, 0.2)
	
	p.position = Vector2(randf() * 640, randf() * 360)
	return {
		"node": p,
		"vel": Vector2(randf_range(-5, 5), randf_range(-10, -2)),
		"phase": randf() * TAU,
		"base_y": p.position.y,
	}

func _process_ambient(delta: float) -> void:
	for ap in ambient_particles:
		var node: ColorRect = ap["node"]
		ap["phase"] += delta * 0.8
		node.position.x += ap["vel"].x * delta
		node.position.y = ap["base_y"] + sin(ap["phase"]) * 12
		if node.position.x < -10:
			node.position.x = 650
		elif node.position.x > 650:
			node.position.x = -10

# === 粒子特效 API ===

func spawn_hit_spark(pos: Vector2, color: Color = Color(1, 0.9, 0.5)) -> void:
	"""命中火花 - 圆形粒子+发光"""
	var count: int = 8
	for i in range(count):
		var angle: float = randf() * TAU
		var speed: float = randf_range(80, 220)
		var size: float = randf_range(2, 4)
		var p = ColorRect.new()
		p.size = Vector2(size, size)
		p.position = pos
		# 圆形粒子（用颜色深浅模拟）
		if i < 3:
			p.color = Color(1, 1, 0.9, 1.0)  # 白热核心
		else:
			p.color = color
		add_child(p)
		particles.append({
			"node": p,
			"life": randf_range(0.15, 0.35),
			"max_life": 0.35,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed),
			"gravity": 250.0,
			"fade": true,
			"type": "spark",
			"trail": [],
		})
	
	# 发光核心
	var glow = ColorRect.new()
	glow.size = Vector2(8, 8)
	glow.position = pos - Vector2(4, 4)
	glow.color = Color(color.r, color.g, color.b, 0.6)
	add_child(glow)
	particles.append({
		"node": glow,
		"life": 0.12,
		"max_life": 0.12,
		"vel": Vector2.ZERO,
		"gravity": 0.0,
		"fade": true,
		"type": "glow",
		"trail": [],
	})

func spawn_parry_spark(pos: Vector2, is_perfect: bool = false) -> void:
	"""格挡火花 - 更华丽的圆形粒子"""
	var color: Color = Color(0.5, 0.9, 1.0) if is_perfect else Color(0.7, 0.8, 1.0)
	var count: int = 12 if is_perfect else 6
	for i in range(count):
		var angle: float = randf() * TAU
		var speed: float = randf_range(100, 300) if is_perfect else randf_range(60, 160)
		var size: float = randf_range(2, 4) if is_perfect else randf_range(2, 3)
		var p = ColorRect.new()
		p.size = Vector2(size, size)
		p.position = pos
		if i < 2:
			p.color = Color(1, 1, 1, 1.0)  # 白热核心
		else:
			p.color = color
		add_child(p)
		particles.append({
			"node": p,
			"life": randf_range(0.2, 0.45),
			"max_life": 0.45,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed),
			"gravity": 80.0,
			"fade": true,
			"type": "spark",
			"trail": [],
		})
	
	# 完美格挡大发光
	if is_perfect:
		var glow = ColorRect.new()
		glow.size = Vector2(16, 16)
		glow.position = pos - Vector2(8, 8)
		glow.color = Color(0.7, 0.95, 1.0, 0.5)
		add_child(glow)
		particles.append({
			"node": glow,
			"life": 0.2,
			"max_life": 0.2,
			"vel": Vector2.ZERO,
			"gravity": 0.0,
			"fade": true,
			"type": "glow",
			"trail": [],
		})
		start_flash(0.08, Color(0.5, 0.8, 1.0))

func spawn_rage_burst(pos: Vector2) -> void:
	"""怒气爆发特效 - 火焰圆粒子"""
	var colors: Array = [Color(1, 0.5, 0.1), Color(1, 0.8, 0.2), Color(1, 0.3, 0.05), Color(1, 1, 0.8)]
	for i in range(18):
		var angle: float = randf() * TAU
		var speed: float = randf_range(60, 250)
		var size: float = randf_range(2, 5)
		var p = ColorRect.new()
		p.size = Vector2(size, size)
		p.position = pos
		p.color = colors[i % 4]
		add_child(p)
		particles.append({
			"node": p,
			"life": randf_range(0.3, 0.7),
			"max_life": 0.7,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed),
			"gravity": -60.0,
			"fade": true,
			"type": "rage",
			"trail": [],
		})
	
	# 中心发光
	var glow = ColorRect.new()
	glow.size = Vector2(20, 20)
	glow.position = pos - Vector2(10, 10)
	glow.color = Color(1, 0.7, 0.2, 0.4)
	add_child(glow)
	particles.append({
		"node": glow,
		"life": 0.3,
		"max_life": 0.3,
		"vel": Vector2.ZERO,
		"gravity": 0.0,
		"fade": true,
		"type": "glow",
		"trail": [],
	})

func spawn_boss_enrage_aura(pos: Vector2) -> void:
	"""Boss狂暴火焰特效"""
	var colors: Array = [Color(1, 0.2, 0.05), Color(0.8, 0.1, 0.3), Color(1, 0.5, 0.1), Color(1, 0.9, 0.3)]
	for i in range(24):
		var angle: float = -PI/2 + randf_range(-0.8, 0.8)
		var speed: float = randf_range(40, 140)
		var size: float = randf_range(2, 5)
		var p = ColorRect.new()
		p.size = Vector2(size, size)
		p.position = pos + Vector2(randf_range(-30, 30), 0)
		p.color = colors[i % 4]
		add_child(p)
		particles.append({
			"node": p,
			"life": randf_range(0.4, 0.9),
			"max_life": 0.9,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed),
			"gravity": -40.0,
			"fade": true,
			"type": "fire",
			"trail": [],
		})
	start_flash(0.1, Color(1, 0.3, 0.1))

func spawn_earth_shatter(pos: Vector2, facing: float = 1.0) -> void:
	"""裂地斩岩石碎片特效"""
	var colors: Array = [Color(0.5, 0.4, 0.3), Color(0.6, 0.5, 0.3), Color(0.7, 0.6, 0.35), Color(1, 0.6, 0.2)]
	for i in range(16):
		var angle: float = -PI/2 + randf_range(-1.2, 1.2)
		var speed: float = randf_range(100, 350)
		var size: float = randf_range(3, 7)
		var p = ColorRect.new()
		p.size = Vector2(size, size)
		p.position = pos + Vector2(randf_range(-20, 20) * facing, 0)
		p.color = colors[i % 4]
		add_child(p)
		particles.append({
			"node": p,
			"life": randf_range(0.3, 0.8),
			"max_life": 0.8,
			"vel": Vector2(cos(angle) * speed * facing, sin(angle) * speed - 120),
			"gravity": 400.0,
			"fade": true,
			"type": "rock",
			"trail": [],
		})
	
	# 地面冲击波
	var shockwave = ColorRect.new()
	shockwave.size = Vector2(60, 4)
	shockwave.position = pos - Vector2(30, 0)
	shockwave.color = Color(1, 0.8, 0.3, 0.6)
	add_child(shockwave)
	particles.append({
		"node": shockwave,
		"life": 0.25,
		"max_life": 0.25,
		"vel": Vector2.ZERO,
		"gravity": 0.0,
		"fade": true,
		"type": "glow",
		"trail": [],
	})
	start_flash(0.12, Color(1, 0.6, 0.2))
	start_shake(6.0, 4.0)

func spawn_blood_splatter(pos: Vector2, direction: float = 1.0) -> void:
	"""受击血液飞溅"""
	var colors: Array = [Color(0.8, 0.1, 0.05, 0.9), Color(0.6, 0.05, 0.02, 0.8), Color(0.9, 0.15, 0.08, 0.85)]
	for i in range(6):
		var angle: float = randf_range(-0.5, 0.5) + (0 if direction > 0 else PI)
		var speed: float = randf_range(50, 140)
		var size: float = randf_range(1, 3)
		var p = ColorRect.new()
		p.size = Vector2(size, size)
		p.position = pos
		p.color = colors[i % 3]
		add_child(p)
		particles.append({
			"node": p,
			"life": randf_range(0.2, 0.6),
			"max_life": 0.6,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 40),
			"gravity": 200.0,
			"fade": true,
			"type": "blood",
			"trail": [],
		})

func spawn_dodge_trail(pos: Vector2, facing: float) -> void:
	"""闪避/移动拖尾效果"""
	for i in range(4):
		var trail = ColorRect.new()
		trail.size = Vector2(12, 24)
		trail.position = pos + Vector2(-6 + i * (-8 * facing), -32)
		trail.color = Color(0.5, 0.7, 1.0, 0.2 - i * 0.04)
		add_child(trail)
		particles.append({
			"node": trail,
			"life": 0.15 + i * 0.05,
			"max_life": 0.3,
			"vel": Vector2.ZERO,
			"gravity": 0.0,
			"fade": true,
			"type": "trail",
			"trail": [],
		})

func _process_particles(delta: float) -> void:
	var to_remove: Array = []
	for i in range(particles.size()):
		var p: Dictionary = particles[i]
		p["life"] -= delta
		if p["life"] <= 0:
			p["node"].queue_free()
			to_remove.append(i)
			continue
		# 更新位置
		var vel: Vector2 = p["vel"]
		p["node"].position += vel * delta
		# 重力
		p["vel"] = Vector2(vel.x, vel.y + p["gravity"] * delta)
		# 淡出
		if p["fade"]:
			var ratio: float = p["life"] / p["max_life"]
			var mod: Color = p["node"].modulate
			mod.a = ratio
			p["node"].modulate = mod
		# 类型特殊处理
		var ptype: String = p["type"]
		if ptype == "fire" or ptype == "rage":
			var s: float = max(0.3, p["life"] / p["max_life"])
			p["node"].scale = Vector2(s, s)
		elif ptype == "spark":
			# 火花减速
			p["vel"] = Vector2(vel.x * 0.98, vel.y)
		elif ptype == "rock":
			# 岩石旋转效果（通过缩放模拟）
			var t: float = p["life"] / p["max_life"]
			var wobble: float = 1.0 + 0.2 * sin(t * 20)
			p["node"].scale = Vector2(wobble, 1.0 / wobble)
	
	# 从后往前删除
	to_remove.reverse()
	for i in to_remove:
		particles.remove_at(i)
