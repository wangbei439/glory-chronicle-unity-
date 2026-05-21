## 洞穴蝙蝠 - Alpha v0.8
## 幽影矿井飞行敌人，上下飘动
## 行为：悬浮→发现玩家→俯冲攻击→返回悬浮
extends Node2D

signal enemy_died(pos: Vector2)
signal enemy_hit_player(damage: float, knockback: Vector2)

# === 属性 ===
@export var max_hp: float = 30.0
@export var fly_speed: float = 100.0
@export var dive_speed: float = 250.0
@export var detect_range: float = 180.0
@export var patrol_range: float = 80.0

# === 状态 ===
enum State { HOVER, CHASE, DIVE, RETREAT, HURT, DYING }
var current_state: State = State.HOVER
var hp: float = 30.0
var pos: Vector2 = Vector2(300, 200)
var vel: Vector2 = Vector2.ZERO
var facing: float = -1.0
var state_timer: float = 0.0
var attack_cooldown: float = 0.0

# 悬浮参数
var hover_center: Vector2 = Vector2(300, 200)
var hover_phase: float = 0.0
var hover_amplitude: float = 20.0

# 俯冲参数
var dive_target: Vector2 = Vector2.ZERO
var has_dealt_damage: bool = false

# 受击
var hurt_timer: float = 0.0
var invincible_timer: float = 0.0

# 视觉
var sprite: AnimatedSprite2D
var current_anim: String = "idle"

func _ready() -> void:
        hp = max_hp
        hover_center = pos

func setup(anim_sprite: AnimatedSprite2D) -> void:
        sprite = anim_sprite
        _build_animations()

func _build_animations() -> void:
        if not sprite:
                return
        var sf = SpriteFrames.new()

        var anims = {
                "idle": {"path": "cave_bat_idle_sheet.png", "frames": 4, "speed": 10.0, "loop": true},
                "fly": {"path": "cave_bat_fly_sheet.png", "frames": 4, "speed": 12.0, "loop": true},
                "dive": {"path": "cave_bat_dive_sheet.png", "frames": 2, "speed": 8.0, "loop": false},
                "hurt": {"path": "cave_bat_hurt_sheet.png", "frames": 2, "speed": 8.0, "loop": false},
                "death": {"path": "cave_bat_death_sheet.png", "frames": 4, "speed": 5.0, "loop": false},
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
                        atlas.region = Rect2(i * 32, 0, 32, 32)
                        atlas.filter_clip = false
                        sf.add_frame(anim_name, atlas)

        # 回退
        if not sf.has_animation("idle"):
                sf.add_animation("idle")
                var fb = load("res://assets/sprites/enemy/cave_bat_idle_64.png")
                if fb:
                        sf.add_frame("idle", fb)

        sprite.sprite_frames = sf
        sprite.play("idle")

func play_anim(anim_name: String, force: bool = false) -> void:
        if current_anim == anim_name and not force:
                return
        current_anim = anim_name
        if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
                if force:
                        sprite.stop()
                sprite.play(anim_name)

func process(delta: float, player_pos: Vector2, ground_y: float) -> void:
        if hp <= 0:
                if current_state != State.DYING:
                        current_state = State.DYING
                        state_timer = 0.8
                        play_anim("death")
                state_timer -= delta
                # 死亡时下坠
                vel.y += 400 * delta
                pos += vel * delta
                if pos.y > ground_y:
                        pos.y = ground_y
                        vel = Vector2.ZERO
                if state_timer <= 0:
                        enemy_died.emit(pos)
                _update_visuals()
                return

        # 无敌帧
        if invincible_timer > 0:
                invincible_timer -= delta

        # 受击恢复
        if current_state == State.HURT:
                hurt_timer -= delta
                if hurt_timer <= 0:
                        current_state = State.HOVER
                        # 被打后飞远一点
                        var dir: float = 1.0 if pos.x > player_pos.x else -1.0
                        vel.x = dir * 60
                _update_visuals()
                pos += vel * delta
                return

        # 攻击冷却
        if attack_cooldown > 0:
                attack_cooldown -= delta

        state_timer -= delta
        var dist_to_player: float = Vector2(pos.x - player_pos.x, pos.y - player_pos.y).length()

        match current_state:
                State.HOVER:
                        _process_hover(delta, dist_to_player, player_pos)
                State.CHASE:
                        _process_chase(delta, dist_to_player, player_pos)
                State.DIVE:
                        _process_dive(delta, player_pos, ground_y)
                State.RETREAT:
                        _process_retreat(delta)

        pos += vel * delta
        _update_visuals()

func change_state(new_state: State) -> void:
        current_state = new_state
        state_timer = 0.0
        has_dealt_damage = false

        match new_state:
                State.HOVER:
                        hover_center = pos
                        hover_phase = 0.0
                        play_anim("idle")
                        state_timer = randf_range(1.0, 2.5)
                State.CHASE:
                        play_anim("fly")
                State.DIVE:
                        play_anim("dive")
                        state_timer = 0.8
                State.RETREAT:
                        play_anim("fly")
                        state_timer = 1.0
                        # 向上飞远离玩家
                        vel = Vector2(0, -dive_speed * 0.6)
                State.HURT:
                        play_anim("hurt")
                        hurt_timer = 0.25
                        invincible_timer = 0.3

func _process_hover(delta: float, dist: float, player_pos: Vector2) -> void:
        # 上下飘动 + 微横向移动
        hover_phase += delta * 3
        vel.y = sin(hover_phase) * hover_amplitude
        vel.x = sin(hover_phase * 0.7) * 15

        # 保持在巡逻范围内
        if pos.x > hover_center.x + patrol_range:
                vel.x = -20
        elif pos.x < hover_center.x - patrol_range:
                vel.x = 20

        # 发现玩家
        if dist < detect_range:
                change_state(State.CHASE)

func _process_chase(delta: float, dist: float, player_pos: Vector2) -> void:
        # 飞向玩家上方
        var target: Vector2 = player_pos + Vector2(0, -60)
        var dir_x: float = 1.0 if target.x > pos.x else -1.0
        var dir_y: float = 1.0 if target.y > pos.y else -1.0

        vel.x = dir_x * fly_speed
        vel.y = dir_y * fly_speed * 0.6
        facing = dir_x

        # 靠近后俯冲
        var dist_to_target: float = abs(pos.x - player_pos.x)
        if dist_to_target < 50 and pos.y < player_pos.y - 30 and attack_cooldown <= 0:
                dive_target = player_pos
                change_state(State.DIVE)

        # 玩家离开范围
        if dist > detect_range * 1.5:
                change_state(State.HOVER)

func _process_dive(delta: float, player_pos: Vector2, ground_y: float) -> void:
        # 俯冲攻击：快速向下冲刺
        var dir_x: float = 1.0 if dive_target.x > pos.x else -1.0
        vel.x = dir_x * dive_speed * 0.5
        vel.y = dive_speed  # 向下冲刺

        facing = dir_x

        # 判定是否命中玩家
        if not has_dealt_damage:
                var dist: float = abs(pos.x - player_pos.x)
                var dist_y: float = abs(pos.y - player_pos.y)
                if dist < 40 and dist_y < 35:
                        has_dealt_damage = true
                        var dmg: float = 8.0
                        var kb: Vector2 = Vector2(3 * facing, -3)
                        enemy_hit_player.emit(dmg, kb)

        # 俯冲到底部或超时
        if pos.y >= ground_y - 20 or state_timer <= 0:
                change_state(State.RETREAT)

func _process_retreat(delta: float) -> void:
        # 向上飞回
        vel.y = -dive_speed * 0.5
        vel.x = lerp(vel.x, 0.0, 0.05)

        if state_timer <= 0:
                attack_cooldown = randf_range(2.0, 3.5)
                hover_center = pos
                change_state(State.HOVER)

func take_damage(dmg: float) -> void:
        if hp <= 0 or invincible_timer > 0:
                return
        hp = max(0, hp - dmg)

        if hp <= 0:
                return  # process()会处理死亡

        # 蝙蝠血薄，每次受击都打断
        change_state(State.HURT)
        # 被击退
        vel = Vector2(-facing * 80, -60)

func get_attack_damage() -> float:
        return 8.0

func is_in_attack_active() -> bool:
        return current_state == State.DIVE

func _update_visuals() -> void:
        if sprite:
                sprite.position = pos + Vector2(-16, -32)  # 32x32居中
                sprite.flip_h = (facing < 0)
                # 受击闪烁
                if current_state == State.HURT:
                        if int(Time.get_ticks_msec() / 80) % 2 == 0:
                                sprite.modulate = Color(2, 1.5, 1.5)
                        else:
                                sprite.modulate = Color(1, 1, 1)
                elif invincible_timer > 0:
                        sprite.modulate = Color(1, 1, 1, 0.6)
                else:
                        sprite.modulate = Color(1, 1, 1)
