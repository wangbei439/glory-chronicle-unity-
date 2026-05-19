## 矿脉甲虫 Boss AI
## 行为状态机：IDLE → CHASE → ATTACK → SPECIAL → STUNNED → ENRAGED
extends Node2D

signal boss_health_changed(hp: float, max_hp: float)
signal boss_died
signal boss_phase_changed(phase: int)

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

# 视觉
var sprite: AnimatedSprite2D
var current_anim: String = "idle"
var hp_bar_bg: ColorRect
var hp_bar_fill: ColorRect
var name_label: Label

# 攻击模式
var attack_patterns: Array = []
var current_pattern: int = 0

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
        
        # 硬直恢复
        if is_stunned:
                stun_timer -= delta
                if stun_timer <= 0:
                        is_stunned = false
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
        match new_state:
                State.IDLE:
                        play_anim("idle")
                        state_timer = randf_range(0.5, 1.5)
                State.CHASE:
                        play_anim("walk")
                State.ATTACK:
                        play_anim("attack")
                        state_timer = 0.5
                State.HEAVY_ATTACK:
                        play_anim("attack")
                        state_timer = 0.8
                State.CHARGE:
                        play_anim("charge")
                        is_charging = true
                        state_timer = 1.5
                State.SPECIAL:
                        play_anim("attack")
                        state_timer = 1.0
                State.STUNNED:
                        play_anim("stunned")

func _process_idle(delta: float, dist: float, player_pos: Vector2) -> void:
        vel.x = lerp(vel.x, 0.0, 0.15)
        if state_timer <= 0:
                if dist < attack_range and attack_cooldown <= 0:
                        # 攻击
                        if phase == 2 and randf() < 0.3:
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
        vel.x = lerp(vel.x, 0.0, 0.2)
        if state_timer <= 0:
                attack_cooldown = randf_range(1.0, 2.0) if phase == 1 else randf_range(0.5, 1.2)
                change_state(State.IDLE)

func _process_heavy_attack(delta: float, player_pos: Vector2) -> void:
        # 蓄力阶段
        if state_timer > 0.4:
                # 蓄力抖动
                vel.x = sin(state_timer * 30) * 2
        else:
                # 释放
                vel.x = facing * 300
        if state_timer <= 0:
                attack_cooldown = 2.5
                change_state(State.IDLE)

func _process_charge(delta: float, player_pos: Vector2, ground_y: float) -> void:
        if is_charging:
                # 冲向玩家
                var dir = 1.0 if player_pos.x > pos.x else -1.0
                facing = dir
                vel.x = dir * chase_speed * 2.5
                state_timer -= delta
                if state_timer <= 0:
                        is_charging = false
                        # 冲锋结束，短暂时停
                        vel.x = 0
                        state_timer = 0.5
        else:
                vel.x = lerp(vel.x, 0.0, 0.1)
                if state_timer <= 0:
                        attack_cooldown = 3.0
                        change_state(State.IDLE)

func _process_special(delta: float, player_pos: Vector2) -> void:
        # 跳砸攻击
        if state_timer > 0.5:
                vel.y = -400
                vel.x = facing * 50
        elif state_timer > 0:
                vel.y = 500
                vel.x = 0
        if state_timer <= 0:
                attack_cooldown = 4.0
                change_state(State.IDLE)

func take_damage(dmg: float) -> void:
        if hp <= 0:
                return
        hp = max(0, hp - dmg)
        boss_health_changed.emit(hp, max_hp)
        
        # 轻微受击但不打断
        play_anim("hurt")
        
        # 一定概率被打断
        if randf() < 0.15 and current_state != State.CHARGE:
                is_stunned = true
                stun_timer = 0.5
                change_state(State.STUNNED)

func get_attack_damage() -> float:
        match current_state:
                State.ATTACK:
                        return 15.0 if phase == 1 else 20.0
                State.HEAVY_ATTACK:
                        return 30.0 if phase == 1 else 40.0
                State.CHARGE:
                        return 25.0
                State.SPECIAL:
                        return 35.0
                _:
                        return 0.0

func get_attack_knockback() -> Vector2:
        var base_kb = Vector2(5, -3)
        match current_state:
                State.HEAVY_ATTACK:
                        base_kb = Vector2(10, -5)
                State.CHARGE:
                        base_kb = Vector2(15, -3)
                State.SPECIAL:
                        base_kb = Vector2(3, -10)
        return base_kb * Vector2(facing, 1)

func is_in_attack_state() -> bool:
        return current_state == State.ATTACK or current_state == State.HEAVY_ATTACK or current_state == State.CHARGE or current_state == State.SPECIAL

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
                # 硬直闪烁
                if is_stunned:
                        if int(Time.get_ticks_msec() / 100) % 2 == 0:
                                sprite.modulate = Color(1.5, 1.5, 2.0)
                        else:
                                sprite.modulate = Color(1, 1, 1)
