## 矿工亡魂 - Alpha v0.6
## 幽影矿井普通小怪，矿工亡灵
## 行为：巡逻→发现玩家→追击→攻击
extends Node2D

signal enemy_died(pos: Vector2)
signal enemy_hit_player(damage: float, knockback: Vector2)

# === 属性 ===
@export var max_hp: float = 60.0
@export var move_speed: float = 80.0
@export var chase_speed: float = 150.0
@export var attack_range: float = 50.0
@export var detect_range: float = 200.0
@export var patrol_range: float = 100.0

# === 状态 ===
enum State { PATROL, CHASE, ATTACK, HURT, DYING }
var current_state: State = State.PATROL
var hp: float = 60.0
var pos: Vector2 = Vector2(300, 309)
var vel: Vector2 = Vector2.ZERO
var facing: float = -1.0
var state_timer: float = 0.0
var attack_cooldown: float = 0.0

# 巡逻
var patrol_center: float = 300.0
var patrol_dir: float = 1.0

# 攻击判定帧
enum AttackPhase { TELEGRAPH, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.TELEGRAPH
var attack_hit_dealt: bool = false

# 受击
var hurt_timer: float = 0.0
var invincible_timer: float = 0.0

# 视觉
var sprite: AnimatedSprite2D
var current_anim: String = "idle"

func _ready() -> void:
        hp = max_hp
        patrol_center = pos.x

func setup(anim_sprite: AnimatedSprite2D) -> void:
        sprite = anim_sprite
        _build_animations()

func _build_animations() -> void:
        if not sprite:
                return
        var sf = SpriteFrames.new()
        
        var anims = {
                "idle": {"path": "mine_wraith_idle_sheet.png", "frames": 4, "speed": 6.0, "loop": true},
                "walk": {"path": "mine_wraith_walk_sheet.png", "frames": 4, "speed": 7.0, "loop": true},
                "attack": {"path": "mine_wraith_attack_sheet.png", "frames": 4, "speed": 10.0, "loop": false},
                "hurt": {"path": "mine_wraith_hurt_sheet.png", "frames": 2, "speed": 8.0, "loop": false},
                "death": {"path": "mine_wraith_death_sheet.png", "frames": 4, "speed": 5.0, "loop": false},
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
                        atlas.region = Rect2(i * 48, 0, 48, 64)
                        atlas.filter_clip = false
                        sf.add_frame(anim_name, atlas)
        
        # 回退
        if not sf.has_animation("idle"):
                sf.add_animation("idle")
                var fb = load("res://assets/sprites/enemy/mine_wraith_idle_64.png")
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
                        state_timer = 1.0
                        play_anim("death")
                state_timer -= delta
                if state_timer <= 0:
                        enemy_died.emit(pos)
                return
        
        # 无敌帧
        if invincible_timer > 0:
                invincible_timer -= delta
        
        # 受击恢复
        if current_state == State.HURT:
                hurt_timer -= delta
                if hurt_timer <= 0:
                        current_state = State.PATROL
                _update_visuals(ground_y)
                _apply_physics(delta, ground_y)
                return
        
        # 攻击冷却
        if attack_cooldown > 0:
                attack_cooldown -= delta
        
        state_timer -= delta
        var dist_to_player = abs(pos.x - player_pos.x)
        
        match current_state:
                State.PATROL:
                        _process_patrol(delta, dist_to_player, player_pos)
                State.CHASE:
                        _process_chase(delta, dist_to_player, player_pos)
                State.ATTACK:
                        _process_attack(delta, player_pos)
        
        _apply_physics(delta, ground_y)
        _update_visuals(ground_y)

func _apply_physics(delta: float, ground_y: float) -> void:
        if pos.y < ground_y:
                vel.y += 980.0 * delta
        pos += vel * delta
        if pos.y > ground_y:
                pos.y = ground_y
                vel.y = 0

func change_state(new_state: State) -> void:
        current_state = new_state
        state_timer = 0.0
        attack_hit_dealt = false
        attack_phase = AttackPhase.TELEGRAPH
        
        match new_state:
                State.PATROL:
                        play_anim("walk")
                        state_timer = randf_range(1.0, 3.0)
                State.CHASE:
                        play_anim("walk")
                State.ATTACK:
                        play_anim("idle")  # 预警姿态
                        state_timer = 0.6
                State.HURT:
                        play_anim("hurt")
                        hurt_timer = 0.3
                        invincible_timer = 0.4

func _process_patrol(delta: float, dist: float, player_pos: Vector2) -> void:
        # 巡逻：在patrol_center附近来回走
        vel.x = patrol_dir * move_speed * 0.5
        facing = patrol_dir
        
        # 到巡逻边界换方向
        if pos.x > patrol_center + patrol_range:
                patrol_dir = -1.0
        elif pos.x < patrol_center - patrol_range:
                patrol_dir = 1.0
        
        # 发现玩家
        if dist < detect_range:
                change_state(State.CHASE)

func _process_chase(delta: float, dist: float, player_pos: Vector2) -> void:
        var dir = 1.0 if player_pos.x > pos.x else -1.0
        vel.x = dir * chase_speed
        facing = dir
        
        if dist < attack_range and attack_cooldown <= 0:
                vel.x = 0
                change_state(State.ATTACK)
        elif dist > detect_range * 1.5:
                vel.x = lerp(vel.x, 0.0, 0.1)
                change_state(State.PATROL)

func _process_attack(delta: float, player_pos: Vector2) -> void:
        # 预警→判定→恢复
        if attack_phase == AttackPhase.TELEGRAPH:
                # 蓄力阶段，轻微抖动
                vel.x = sin(state_timer * 20) * 1.0
                if state_timer <= 0.3:
                        attack_phase = AttackPhase.ACTIVE
                        play_anim("attack")
        elif attack_phase == AttackPhase.ACTIVE:
                # 判定帧，发出伤害信号
                if not attack_hit_dealt:
                        attack_hit_dealt = true
                        var dmg: float = 10.0
                        var kb: Vector2 = Vector2(4 * facing, -2)
                        enemy_hit_player.emit(dmg, kb)
                vel.x = lerp(vel.x, 0.0, 0.2)
                if state_timer <= 0:
                        attack_phase = AttackPhase.RECOVERY
        elif attack_phase == AttackPhase.RECOVERY:
                vel.x = lerp(vel.x, 0.0, 0.15)
        
        if state_timer <= 0:
                attack_cooldown = randf_range(1.5, 2.5)
                change_state(State.PATROL)

func take_damage(dmg: float) -> void:
        if hp <= 0 or invincible_timer > 0:
                return
        hp = max(0, hp - dmg)
        
        if hp <= 0:
                return  # process()会处理死亡
        
        # 受击打断
        change_state(State.HURT)
        play_anim("hurt")

func get_attack_damage() -> float:
        return 10.0

func is_in_attack_active() -> bool:
        return current_state == State.ATTACK and attack_phase == AttackPhase.ACTIVE

func _update_visuals(ground_y: float) -> void:
        if sprite:
                sprite.position = pos + Vector2(-24, -64)
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
