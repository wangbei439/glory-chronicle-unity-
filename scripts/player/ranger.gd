## 游侠玩家控制器 - v0.21
## 处理输入、移动、连招、闪避、连击点
## 攻击判定帧(startup/active/recovery)、影步增伤、完美闪避+1CP、刃风暴AOE
## v0.21: 装备叠加系统(武器附着+护甲色调)、量化精灵
extends Node2D

signal attack_hit(target: Node2D, damage: float, knockback: Vector2)
signal dodge_success(is_perfect: bool)
signal combo_points_changed(points: int)
signal health_changed(value: float)
signal died
signal attack_started(attack_type: String, combo_step: int)

# === 属性 ===
@export var max_hp: float = 80.0
@export var max_rage: float = 100.0
@export var move_speed: float = 320.0
@export var jump_force: float = -480.0
@export var gravity: float = 980.0

# === 连击点系统 (替代怒气) ===
var combo_points: int = 0
var combo_decay_timer: float = 0.0  # 命中后重置为4.0，倒计时到0扣1点

# === 状态 ===
var hp: float = 80.0
var pos: Vector2 = Vector2(125, 309)
var vel: Vector2 = Vector2.ZERO
var facing: float = 1.0
var is_attacking: bool = false
var attack_frame: int = 0
var attack_duration: int = 20
var attack_name: String = ""
var is_hurt: bool = false
var hurt_timer: float = 0.0
var invincible_timer: float = 0.0

# === 兼容层 (关卡脚本可同时操作战士/游侠) ===
var rage: float:
        get:
                return combo_points * 20.0
        set(value):
                combo_points = int(value / 20.0)
                combo_points_changed.emit(combo_points)

var is_guarding: bool:
        get:
                return is_dodging

var war_cry_buff: bool:
        get:
                return shadow_step_buff

var war_cry_timer: float:
        get:
                return shadow_step_timer

var war_cry_damage_mult: float:
        get:
                return shadow_step_damage_mult

# === 闪避 (替代格挡) ===
var is_dodging: bool = false
var dodge_timer: float = 0.0       # 0.35s无敌时间
var dodge_cooldown: float = 0.0    # 0.6s冷却
var is_perfect_dodge_window: bool = false  # 完美闪避窗口
var perfect_dodge_window_timer: float = 0.0

# === 影步 (替代战吼, 2CP) ===
var shadow_step_buff: bool = false
var shadow_step_timer: float = 0.0
var shadow_step_damage_mult: float = 1.4
var is_invisible: bool = false
var invisible_timer: float = 0.0

# === 刃风暴 (替代裂地斩, 5CP) ===
var blade_storm_active: bool = false
var blade_storm_timer: float = 0.0      # 1.5s持续时间
var blade_storm_hit_timer: float = 0.0   # 每0.2s命中一次

# === 攻击判定帧 ===
enum AttackPhase { STARTUP, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.STARTUP
var attack_startup_frames: int = 2
var attack_active_frames: int = 4
var attack_hit_dealt: bool = false
var is_heavy_attack: bool = false
var is_combo_finisher: bool = false
var current_combo_step: int = 0

# === 输入缓冲 ===
var buffered_input: String = ""
var buffer_timer: float = 0.0
var BUFFER_WINDOW: float = 0.25

# === 连招 ===
var combo_sequence: Array = []
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_tree: Dictionary = {}
var hit_count: int = 0

# === 视觉 ===
var sprite: AnimatedSprite2D
var dodge_indicator: ColorRect
var parry_indicator: ColorRect:
        get:
                return dodge_indicator
        set(value):
                dodge_indicator = value
var current_anim: String = "idle"

# === v0.21: 装备叠加系统 ===
var weapon_sprite: Sprite2D

const WEAPON_ICONS: Dictionary = {
        "": "",
        "iron_sword": "res://assets/sprites/equipment/iron_sword.png",
        "crystal_blade": "res://assets/sprites/equipment/crystal_blade.png",
        "berserker_axe": "res://assets/sprites/equipment/berserker_axe.png",
        "lava_greatsword": "res://assets/sprites/equipment/lava_greatsword.png",
        "shadow_twin_blades": "res://assets/sprites/equipment/shadow_twin_blades.png",
        "wraith_pick": "res://assets/sprites/equipment/iron_sword.png",
        "beetle_carapace_sword": "res://assets/sprites/equipment/crystal_blade.png",
        "arcane_codex": "res://assets/sprites/equipment/crystal_blade.png",
}

const ARMOR_TINTS: Dictionary = {
        "": Color(1, 1, 1, 0),
        "leather_vest": Color(0.85, 0.7, 0.5, 0.15),
        "iron_plate": Color(0.7, 0.75, 0.8, 0.25),
        "crystal_mail": Color(0.6, 0.8, 1.0, 0.2),
        "beetle_bulwark": Color(0.7, 0.55, 0.3, 0.25),
        "vein_holy_garb": Color(1.0, 0.85, 0.5, 0.2),
}

func _ready() -> void:
        _build_combo_tree()

func _build_combo_tree() -> void:
        # 连招定义：name, mult(伤害倍率), rage(连击点获取), dur(总帧数), startup(前摇), active(判定), kb(击退)
        combo_tree["L"] = {"name": "快斩", "mult": 1.0, "rage": 0, "dur": 12, "startup": 2, "active": 4, "kb": Vector2(2, -1)}
        combo_tree["L,L"] = {"name": "连斩", "mult": 1.2, "rage": 0, "dur": 10, "startup": 1, "active": 4, "kb": Vector2(3, -1)}
        combo_tree["L,L,L"] = {"name": "三连斩", "mult": 1.6, "rage": 0, "dur": 14, "startup": 2, "active": 5, "kb": Vector2(4, -2)}
        combo_tree["L,L,H"] = {"name": "回旋斩", "mult": 1.8, "rage": 0, "dur": 20, "startup": 3, "active": 6, "kb": Vector2(2, -3)}
        combo_tree["L,H"] = {"name": "穿刺", "mult": 1.3, "rage": 0, "dur": 14, "startup": 2, "active": 5, "kb": Vector2(6, 0)}
        combo_tree["H"] = {"name": "重刺", "mult": 2.2, "rage": 0, "dur": 22, "startup": 5, "active": 5, "kb": Vector2(5, -1)}
        combo_tree["H,L"] = {"name": "追击刺", "mult": 1.5, "rage": 0, "dur": 10, "startup": 1, "active": 4, "kb": Vector2(7, 0)}

func setup_sprite(animated_sprite: AnimatedSprite2D) -> void:
        sprite = animated_sprite
        _build_animations()
        _setup_equipment_layers()

func _setup_equipment_layers() -> void:
        if not sprite:
                return
        weapon_sprite = Sprite2D.new()
        weapon_sprite.name = "WeaponOverlay"
        weapon_sprite.z_index = 1
        weapon_sprite.offset = Vector2(12, -18)
        weapon_sprite.scale = Vector2(1.0, 1.0)
        sprite.add_child(weapon_sprite)
        update_equipment_visuals()

func update_equipment_visuals() -> void:
        if not sprite:
                return
        var weapon_id: String = GameState.equipped_weapon
        if weapon_sprite:
                var icon_path: String = WEAPON_ICONS.get(weapon_id, "")
                if icon_path != "":
                        var tex = load(icon_path)
                        if tex:
                                weapon_sprite.texture = tex
                                weapon_sprite.visible = true
                        else:
                                weapon_sprite.visible = false
                else:
                        weapon_sprite.texture = null
                        weapon_sprite.visible = false
        var armor_id: String = GameState.equipped_armor
        var armor_tint: Color = ARMOR_TINTS.get(armor_id, Color(1, 1, 1, 0))
        if armor_tint.a > 0:
                sprite.modulate = Color(1, 1, 1, 1).lerp(armor_tint, armor_tint.a)
        else:
                sprite.modulate = Color(1, 1, 1, 1)

func _build_animations() -> void:
        if not sprite:
                return
        var sf: SpriteFrames = SpriteFrames.new()

        # v0.20: 48x64现代像素风精灵
        var anims: Dictionary = {
                "idle": {"path": "ranger_idle_sheet.png", "frames": 4, "speed": 8.0, "loop": true},
                "run": {"path": "ranger_run_sheet.png", "frames": 6, "speed": 10.0, "loop": true},
                "attack": {"path": "ranger_attack_sheet.png", "frames": 5, "speed": 10.0, "loop": false},
                "dodge": {"path": "ranger_dodge_sheet.png", "frames": 4, "speed": 6.0, "loop": false},
                "jump": {"path": "ranger_jump_sheet.png", "frames": 4, "speed": 4.0, "loop": false},
                "hurt": {"path": "ranger_hurt_sheet.png", "frames": 3, "speed": 8.0, "loop": false},
                "shadow_step": {"path": "ranger_shadow_step_sheet.png", "frames": 5, "speed": 6.0, "loop": false},
                "blade_storm": {"path": "ranger_blade_storm_sheet.png", "frames": 6, "speed": 6.0, "loop": true},
        }

        for anim_name: String in anims:
                var info: Dictionary = anims[anim_name]
                var tex: Texture2D = load("res://assets/sprites/player/" + info["path"])
                if not tex:
                        continue
                sf.add_animation(anim_name)
                sf.set_animation_speed(anim_name, info["speed"])
                sf.set_animation_loop(anim_name, info["loop"])
                var count: int = info["frames"]
                for i: int in range(count):
                        var atlas: AtlasTexture = AtlasTexture.new()
                        atlas.atlas = tex
                        atlas.region = Rect2(i * 48, 0, 48, 64)  # v0.20: 48px帧宽
                        atlas.filter_clip = false
                        sf.add_frame(anim_name, atlas)

        # 回退
        if not sf.has_animation("idle"):
                sf.add_animation("idle")
                var fb: Texture2D = load("res://assets/sprites/player/ranger_idle_64.png")
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

func process(delta: float, ground_y: float) -> void:
        # === 连击点衰减 ===
        if combo_points > 0:
                if combo_decay_timer > 0.0:
                        combo_decay_timer -= delta
                        if combo_decay_timer <= 0.0:
                                combo_points = max(0, combo_points - 1)
                                combo_points_changed.emit(combo_points)
                                # 如果还有点，重置计时器继续衰减
                                if combo_points > 0:
                                        combo_decay_timer = 4.0

        # === 影步buff计时 ===
        if shadow_step_buff:
                shadow_step_timer -= delta
                if shadow_step_timer <= 0.0:
                        shadow_step_buff = false
                        shadow_step_damage_mult = 1.0

        # === 隐身计时 ===
        if is_invisible:
                invisible_timer -= delta
                if invisible_timer <= 0.0:
                        is_invisible = false
                        if sprite:
                                sprite.modulate.a = 1.0

        # === 闪避冷却 ===
        if dodge_cooldown > 0.0:
                dodge_cooldown -= delta

        # === 闪避状态 ===
        if is_dodging:
                dodge_timer -= delta
                if dodge_timer <= 0.0:
                        is_dodging = false
                        dodge_cooldown = 0.6
                        if sprite:
                                sprite.modulate.a = 1.0
                        play_anim("idle")

        # === 刃风暴状态 ===
        if blade_storm_active:
                blade_storm_timer -= delta
                blade_storm_hit_timer -= delta
                # 刃风暴期间不可操作，原地旋转
                vel.x = lerp(vel.x, 0.0, 0.1)
                if blade_storm_hit_timer <= 0.0:
                        blade_storm_hit_timer = 0.2
                        # 刃风暴每0.2s造成8点伤害 (由外部调用blade_storm_deal_damage)
                if blade_storm_timer <= 0.0:
                        blade_storm_active = false
                        blade_storm_timer = 0.0
                        blade_storm_hit_timer = 0.0
                        if sprite:
                                sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
                        play_anim("idle")
                _apply_physics(delta, ground_y)
                return

        # === 无敌帧 ===
        if invincible_timer > 0.0:
                invincible_timer -= delta

        # === 受击恢复 ===
        if is_hurt:
                hurt_timer -= delta
                if hurt_timer <= 0.0:
                        is_hurt = false

        # 输入缓冲计时
        if buffer_timer > 0.0:
                buffer_timer -= delta
                if buffer_timer <= 0.0:
                        buffered_input = ""
        
        # === 连招超时 ===
        if combo_timer > 0.0:
                combo_timer -= delta
                if combo_timer <= 0.0:
                        combo_sequence.clear()
                        combo_count = 0
                        hit_count = 0

        # === 完美闪避窗口 ===
        if is_perfect_dodge_window:
                perfect_dodge_window_timer -= delta
                if perfect_dodge_window_timer <= 0.0:
                        is_perfect_dodge_window = false
                        if dodge_indicator:
                                dodge_indicator.visible = false

        # === 受击中不能操作 ===
        if is_hurt:
                vel.x = lerp(vel.x, 0.0, 0.1)
                _apply_physics(delta, ground_y)
                return

        # === 闪避中不能操作（但可以移动） ===
        if is_dodging:
                # 闪避默认向面朝反方向移动
                _apply_physics(delta, ground_y)
                return

        # === 攻击中 - 判定帧系统 ===
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

                # 攻击期间移动
                if attack_phase == AttackPhase.STARTUP:
                        vel.x = lerp(vel.x, 0.0, 0.15)
                elif attack_phase == AttackPhase.ACTIVE:
                        # 穿刺和追击刺有位移
                        if attack_name == "穿刺" or attack_name == "追击刺":
                                vel.x = facing * 200.0
                        else:
                                vel.x = lerp(vel.x, 0.0, 0.08)
                else:
                        vel.x = lerp(vel.x, 0.0, 0.12)

                # 后摇期间检查输入缓冲 → 自动衔接下一招
                if attack_phase == AttackPhase.RECOVERY and buffered_input != "":
                        var input: String = buffered_input
                        buffered_input = ""
                        buffer_timer = 0.0
                        do_attack(input)
                        return
                
                # 攻击结束
                if attack_frame >= attack_duration:
                        is_attacking = false
                        attack_frame = 0
                        attack_name = ""
                        attack_hit_dealt = false
                        attack_phase = AttackPhase.STARTUP
                        current_combo_step = 0
                        play_anim("idle")

        # === 移动 ===
        var is_moving: bool = false
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

        # === 动画 ===
        if not is_attacking:
                if pos.y < ground_y - 3:
                        play_anim("jump")
                elif is_moving:
                        play_anim("run")
                else:
                        play_anim("idle")

        # === 跳跃 ===
        if Input.is_action_just_pressed("jump") and pos.y >= ground_y - 3:
                vel.y = jump_force

        # === 攻击 - 带输入缓冲 ===
        if Input.is_action_just_pressed("attack"):
                if is_attacking and attack_phase != AttackPhase.RECOVERY:
                        buffered_input = "L"
                        buffer_timer = BUFFER_WINDOW
                else:
                        do_attack("L")
        elif Input.is_action_just_pressed("heavy_attack"):
                if is_attacking and attack_phase != AttackPhase.RECOVERY:
                        buffered_input = "H"
                        buffer_timer = BUFFER_WINDOW
                else:
                        do_attack("H")

        # === 闪避 (L键) ===
        if Input.is_action_just_pressed("guard") and dodge_cooldown <= 0.0 and not is_dodging:
                is_dodging = true
                dodge_timer = 0.35
                is_perfect_dodge_window = true
                perfect_dodge_window_timer = 0.1
                invincible_timer = 0.35
                # 闪避向面朝反方向移动
                vel.x = -facing * 400.0
                vel.y = -100.0
                if sprite:
                        sprite.modulate.a = 0.5
                if dodge_indicator:
                        dodge_indicator.visible = true
                        dodge_indicator.color = Color(0.6, 0.3, 1.0, 0.5)  # 紫色
                play_anim("dodge")

        # === 技能 - 影步 (U键, 2CP): 传送100px + 40%增伤2s + 0.5s隐身 ===
        if Input.is_action_just_pressed("skill_1") and combo_points >= 2:
                combo_points -= 2
                combo_points_changed.emit(combo_points)
                shadow_step_buff = true
                shadow_step_timer = 2.0
                shadow_step_damage_mult = 1.4
                # 传送
                pos.x += facing * 100.0
                # 隐身
                is_invisible = true
                invisible_timer = 0.5
                if sprite:
                        sprite.modulate = Color(0.6, 0.3, 1.0, 0.3)  # 紫色半透明
                play_anim("shadow_step")

        # === 技能 - 刃风暴 (I键, 5CP): 1.5s旋转AOE, 每0.2s8伤害, 无敌 ===
        if Input.is_action_just_pressed("ultimate") and combo_points >= 5:
                combo_points = 0
                combo_points_changed.emit(combo_points)
                blade_storm_active = true
                blade_storm_timer = 1.5
                blade_storm_hit_timer = 0.2
                invincible_timer = 1.5
                if sprite:
                        sprite.modulate = Color(0.8, 0.5, 1.0, 0.9)  # 紫色特效
                play_anim("blade_storm")

        _apply_physics(delta, ground_y)

func _apply_physics(delta: float, ground_y: float) -> void:
        if pos.y < ground_y:
                vel.y += gravity * delta
        pos += vel * delta
        if pos.y > ground_y:
                pos.y = ground_y
                vel.y = 0.0

func do_attack(input_key: String) -> void:
        if is_attacking and attack_phase != AttackPhase.RECOVERY:
                buffered_input = input_key
                buffer_timer = BUFFER_WINDOW
                return

        if is_attacking and attack_phase == AttackPhase.RECOVERY:
                is_attacking = false
                attack_frame = 0
                attack_hit_dealt = false

        combo_sequence.append(input_key)
        combo_timer = 1.0

        var key: String = ",".join(combo_sequence)
        var combo_data: Variant = null
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
        attack_startup_frames = combo_data.get("startup", 2)
        attack_active_frames = combo_data.get("active", 4)
        is_attacking = true
        attack_frame = 0
        attack_phase = AttackPhase.STARTUP
        attack_hit_dealt = false
        combo_count += 1
        hit_count += 1

        is_heavy_attack = input_key == "H" or combo_data.get("mult", 1.0) >= 1.8
        is_combo_finisher = combo_sequence.size() >= 3 or (combo_sequence.size() >= 2 and input_key == "H")
        current_combo_step = combo_sequence.size()

        var attack_type: String = "light"
        if is_combo_finisher:
                attack_type = "finisher"
        elif is_heavy_attack:
                attack_type = "heavy"
        attack_started.emit(attack_type, current_combo_step)

        play_anim("attack", true)

        buffered_input = ""
        buffer_timer = 0.0

func get_attack_damage() -> float:
        # 获取当前攻击的伤害值（含影步增伤）
        var key: String = ",".join(combo_sequence) if combo_sequence.size() > 0 else ""
        var info: Dictionary = combo_tree.get(key, {})
        var base_mult: float = info.get("mult", 1.0) if info.size() > 0 else 1.0
        var dmg: float = 10.0 * base_mult

        # 影步增伤
        if shadow_step_buff:
                dmg *= shadow_step_damage_mult

        # 连击加成（每10连击+5%伤害，上限+30%）
        var combo_bonus: float = 1.0 + min(0.3, float(hit_count) * 0.005)
        if hit_count >= 10:
                combo_bonus = 1.3
        dmg *= combo_bonus

        return dmg

func is_in_active_frames() -> bool:
        # 当前是否在攻击判定帧
        return is_attacking and attack_phase == AttackPhase.ACTIVE and not attack_hit_dealt

func mark_hit_dealt() -> void:
        # 标记本次攻击已命中，获得1连击点
        attack_hit_dealt = true
        if combo_points < 5:
                combo_points += 1
                combo_points_changed.emit(combo_points)
        combo_decay_timer = 4.0  # 命中后重置衰减计时器

func take_damage(dmg: float, knockback: Vector2) -> void:
        if invincible_timer > 0.0:
                return

        # 刃风暴期间无敌
        if blade_storm_active:
                return

        # 闪避判定
        if is_dodging:
                if is_perfect_dodge_window:
                        # 完美闪避：0伤害 + 获得1连击点
                        dodge_success.emit(true)
                        if combo_points < 5:
                                combo_points += 1
                                combo_points_changed.emit(combo_points)
                        combo_decay_timer = 4.0
                        dmg = 0.0
                        knockback = Vector2.ZERO
                else:
                        # 普通闪避仍有无敌帧（invincible_timer已设置）
                        dodge_success.emit(false)
                        return

        hp = max(0.0, hp - dmg)
        health_changed.emit(hp)

        if dmg > 0.0:
                is_hurt = true
                hurt_timer = 0.3
                invincible_timer = 0.5
                vel = knockback * 50.0
                play_anim("hurt")
                hit_count = 0

                if hp <= 0.0:
                        died.emit()

func get_attack_info() -> Dictionary:
        var key: String = ",".join(combo_sequence) if combo_sequence.size() > 0 else ""
        var info: Dictionary = combo_tree.get(key, {})
        return {
                "name": attack_name,
                "is_attacking": is_attacking,
                "combo_count": combo_count,
                "damage_mult": info.get("mult", 1.0) if info.size() > 0 else 1.0,
                "is_active_frame": attack_phase == AttackPhase.ACTIVE,
                "hit_count": hit_count,
                "war_cry_active": shadow_step_buff,
                "blade_storm_active": blade_storm_active,
                "combo_points": combo_points,
        }
