## 打击感特效系统 - Alpha v0.5
## 管理Hitstop顿帧、ScreenShake震屏、粒子特效
extends Node2D

signal hitstop_started(duration: float)
signal hitstop_ended

# === Hitstop 顿帧 ===
var hitstop_active: bool = false
var hitstop_timer: float = 0.0
var hitstop_entities: Array = []  # 顿帧期间冻结的实体列表

# === Screen Shake 震屏 ===
var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var shake_offset: Vector2 = Vector2.ZERO
var camera_node: Node2D = null

# === 粒子特效 ===
var particles: Array = []  # 活跃粒子列表
# 粒子结构: {node, life, max_life, vel, gravity, fade, type}

# === 全局时间缩放 ===
var time_scale: float = 1.0
var slowmo_timer: float = 0.0
var slowmo_target: float = 1.0

func _ready() -> void:
        pass

func process(delta: float) -> void:
        # 处理Hitstop
        if hitstop_active:
                hitstop_timer -= delta
                if hitstop_timer <= 0:
                        hitstop_active = false
                        hitstop_timer = 0
                        hitstop_ended.emit()
                return  # 顿帧期间不处理其他效果

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

# === Hitstop API ===
func start_hitstop(duration: float = 0.08) -> void:
        """触发顿帧效果 - 攻击命中时双方短暂停顿"""
        hitstop_active = true
        hitstop_timer = duration
        hitstop_started.emit(duration)

func is_paused() -> bool:
        """当前是否在顿帧中"""
        return hitstop_active

# === Screen Shake API ===
func start_shake(intensity: float = 3.0, decay: float = 5.0) -> void:
        """触发震屏效果"""
        shake_intensity = intensity
        shake_decay = decay

func get_shake_offset() -> Vector2:
        """获取当前震屏偏移量，供场景脚本应用"""
        return shake_offset

# === Slow Motion API ===
func start_slowmo(duration: float = 0.3, target_scale: float = 0.3) -> void:
        """触发慢动作效果"""
        slowmo_timer = duration
        slowmo_target = target_scale
        time_scale = target_scale

# === 粒子特效 API ===
func spawn_hit_spark(pos: Vector2, color: Color = Color(1, 0.9, 0.5)) -> void:
        """命中火花 - 攻击命中时"""
        var count: int = 6
        for i in range(count):
                var angle: float = randf() * TAU
                var speed: float = randf_range(80, 200)
                var p = ColorRect.new()
                p.size = Vector2(3, 3)
                p.position = pos
                p.color = color
                add_child(p)
                particles.append({
                        "node": p,
                        "life": randf_range(0.15, 0.3),
                        "max_life": 0.3,
                        "vel": Vector2(cos(angle) * speed, sin(angle) * speed),
                        "gravity": 300.0,
                        "fade": true,
                        "type": "spark"
                })

func spawn_parry_spark(pos: Vector2, is_perfect: bool = false) -> void:
        """格挡火花"""
        var color: Color = Color(0.5, 0.9, 1.0) if is_perfect else Color(0.7, 0.8, 1.0)
        var count: int = 10 if is_perfect else 5
        for i in range(count):
                var angle: float = randf() * TAU
                var speed: float = randf_range(100, 280) if is_perfect else randf_range(60, 150)
                var p = ColorRect.new()
                p.size = Vector2(3, 3) if is_perfect else Vector2(2, 2)
                p.position = pos
                p.color = color
                add_child(p)
                particles.append({
                        "node": p,
                        "life": randf_range(0.2, 0.4),
                        "max_life": 0.4,
                        "vel": Vector2(cos(angle) * speed, sin(angle) * speed),
                        "gravity": 100.0,
                        "fade": true,
                        "type": "spark"
                })

func spawn_rage_burst(pos: Vector2) -> void:
        """怒气爆发特效"""
        var colors: Array = [Color(1, 0.5, 0.1), Color(1, 0.8, 0.2), Color(1, 0.3, 0.05)]
        for i in range(15):
                var angle: float = randf() * TAU
                var speed: float = randf_range(60, 220)
                var p = ColorRect.new()
                p.size = Vector2(randf_range(2, 5), randf_range(2, 5))
                p.position = pos
                p.color = colors[i % 3]
                add_child(p)
                particles.append({
                        "node": p,
                        "life": randf_range(0.3, 0.6),
                        "max_life": 0.6,
                        "vel": Vector2(cos(angle) * speed, sin(angle) * speed),
                        "gravity": -50.0,  # 向上飘
                        "fade": true,
                        "type": "rage"
                })

func spawn_boss_enrage_aura(pos: Vector2) -> void:
        """Boss狂暴火焰特效"""
        var colors: Array = [Color(1, 0.2, 0.05), Color(0.8, 0.1, 0.3), Color(1, 0.5, 0.1)]
        for i in range(20):
                var angle: float = -PI/2 + randf_range(-0.8, 0.8)  # 向上
                var speed: float = randf_range(40, 120)
                var p = ColorRect.new()
                p.size = Vector2(randf_range(2, 4), randf_range(2, 4))
                p.position = pos + Vector2(randf_range(-30, 30), 0)
                p.color = colors[i % 3]
                add_child(p)
                particles.append({
                        "node": p,
                        "life": randf_range(0.4, 0.8),
                        "max_life": 0.8,
                        "vel": Vector2(cos(angle) * speed, sin(angle) * speed),
                        "gravity": -30.0,
                        "fade": true,
                        "type": "fire"
                })

func spawn_earth_shatter(pos: Vector2, facing: float = 1.0) -> void:
        """裂地斩岩石碎片特效"""
        for i in range(12):
                var angle: float = -PI/2 + randf_range(-1.2, 1.2)
                var speed: float = randf_range(100, 300)
                var p = ColorRect.new()
                p.size = Vector2(randf_range(3, 6), randf_range(3, 6))
                p.position = pos + Vector2(randf_range(-20, 20) * facing, 0)
                p.color = Color(0.5, 0.4, 0.3) if randf() > 0.3 else Color(0.6, 0.5, 0.3)
                add_child(p)
                particles.append({
                        "node": p,
                        "life": randf_range(0.3, 0.7),
                        "max_life": 0.7,
                        "vel": Vector2(cos(angle) * speed * facing, sin(angle) * speed - 100),
                        "gravity": 400.0,
                        "fade": true,
                        "type": "rock"
                })

func spawn_blood_splatter(pos: Vector2, direction: float = 1.0) -> void:
        """受击血液飞溅"""
        for i in range(4):
                var angle: float = randf_range(-0.5, 0.5) + (0 if direction > 0 else PI)
                var speed: float = randf_range(50, 120)
                var p = ColorRect.new()
                p.size = Vector2(2, 2)
                p.position = pos
                p.color = Color(0.8, 0.1, 0.05, 0.9)
                add_child(p)
                particles.append({
                        "node": p,
                        "life": randf_range(0.2, 0.5),
                        "max_life": 0.5,
                        "vel": Vector2(cos(angle) * speed, sin(angle) * speed - 30),
                        "gravity": 200.0,
                        "fade": true,
                        "type": "blood"
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
                # 火焰类型缩小
                if p["type"] == "fire" or p["type"] == "rage":
                        var s: float = max(0.5, p["life"] / p["max_life"])
                        p["node"].scale = Vector2(s, s)
        
        # 从后往前删除，避免索引偏移
        to_remove.reverse()
        for i in to_remove:
                particles.remove_at(i)
