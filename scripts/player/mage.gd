## 法师玩家控制器 - v0.21
## 冰火双系法术+魔力系统+魔法护盾+闪现+暴风雪
## 攻击判定帧(startup/active/recovery)、魔力自动恢复、完美护盾反弹
## v0.21: 装备叠加系统(武器附着+护甲色调)、量化精灵
extends Node2D

signal attack_hit(target: Node2D, damage: float, knockback: Vector2)
signal shield_success(is_perfect: bool)
signal mana_changed(value: float)
signal health_changed(value: float)
signal died

# === 属性 ===
@export var max_hp: float = 70.0
@export var max_rage: float = 100.0
@export var move_speed: float = 240.0
@export var jump_force: float = -420.0
@export var gravity: float = 980.0
@export var mana_regen: float = 8.0  # 每秒魔力恢复

# === 魔力系统 (替代怒气) ===
var mana: float = 100.0
var is_shielding: bool = false
var shield_mana_drain: float = 15.0  # 护盾每秒消耗魔力
var is_perfect_shield_window: bool = false
var perfect_shield_timer: float = 0.0

# === 闪现 (替代战吼, 30魔力) ===
var blink_buff: bool = false
var blink_timer: float = 0.0
var blink_speed_mult: float = 1.3
var blink_spell_amp: float = 1.2
var blink_spell_amp_timer: float = 0.0

# === 暴风雪 (替代裂地斩, 80魔力) ===
var blizzard_active: bool = false
var blizzard_timer: float = 0.0
var blizzard_hit_timer: float = 0.0

# === 状态 ===
var hp: float = 70.0
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

# === 兼容层 (关卡脚本可同时操作战士/游侠/法师) ===
var rage: float:
        get:
                return mana
        set(value):
                mana = value
                mana_changed.emit(mana)

var is_guarding: bool:
        get:
                return is_shielding

var war_cry_buff: bool:
        get:
                return blink_buff

var war_cry_timer: float:
        get:
                return blink_timer

var war_cry_damage_mult: float:
        get:
                return blink_spell_amp

# === 攻击判定帧 ===
enum AttackPhase { STARTUP, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.STARTUP
var attack_startup_frames: int = 3
var attack_active_frames: int = 5
var attack_hit_dealt: bool = false

# === 连招 ===
var combo_sequence: Array = []
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_tree: Dictionary = {}
var hit_count: int = 0

# === 魔法弹射物 ===
var projectiles: Array = []  # 存储活化的法术弹

# === 视觉 ===
var sprite: AnimatedSprite2D
var shield_indicator: ColorRect
var parry_indicator: ColorRect:
        get:
                return shield_indicator
        set(value):
                shield_indicator = value
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
        # 连招定义：name, mult(伤害倍率), mana_cost(魔力消耗), dur(总帧数), startup(前摇), active(判定), kb(击退), element(元素)
        combo_tree["L"] = {"name": "火弹", "mult": 0.8, "mana_cost": 8, "dur": 18, "startup": 3, "active": 4, "kb": Vector2(2, -1), "element": "fire"}
        combo_tree["L,L"] = {"name": "烈焰", "mult": 1.3, "mana_cost": 12, "dur": 16, "startup": 2, "active": 5, "kb": Vector2(3, -1), "element": "fire"}
        combo_tree["L,L,L"] = {"name": "炎爆", "mult": 2.2, "mana_cost": 22, "dur": 24, "startup": 5, "active": 6, "kb": Vector2(5, -2), "element": "fire"}
        combo_tree["L,H"] = {"name": "冰刺", "mult": 1.5, "mana_cost": 18, "dur": 20, "startup": 3, "active": 5, "kb": Vector2(1, -3), "element": "ice"}
        combo_tree["H"] = {"name": "寒霜", "mult": 1.8, "mana_cost": 20, "dur": 22, "startup": 4, "active": 5, "kb": Vector2(1, -2), "element": "ice"}
        combo_tree["H,L"] = {"name": "雷击", "mult": 2.0, "mana_cost": 25, "dur": 18, "startup": 2, "active": 5, "kb": Vector2(4, 0), "element": "lightning"}
        combo_tree["H,H"] = {"name": "雷暴", "mult": 2.8, "mana_cost": 35, "dur": 28, "startup": 6, "active": 6, "kb": Vector2(6, -2), "element": "lightning"}

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
        weapon_sprite.offset = Vector2(14, -24)
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
                "idle": {"path": "mage_idle_sheet.png", "frames": 4, "speed": 8.0, "loop": true},
                "run": {"path": "mage_run_sheet.png", "frames": 6, "speed": 9.0, "loop": true},
                "cast": {"path": "mage_cast_sheet.png", "frames": 5, "speed": 10.0, "loop": false},
                "shield": {"path": "mage_shield_sheet.png", "frames": 4, "speed": 6.0, "loop": true},
                "jump": {"path": "mage_jump_sheet.png", "frames": 4, "speed": 4.0, "loop": false},
                "hurt": {"path": "mage_hurt_sheet.png", "frames": 3, "speed": 8.0, "loop": false},
                "blink": {"path": "mage_blink_sheet.png", "frames": 4, "speed": 8.0, "loop": false},
                "blizzard": {"path": "mage_blizzard_sheet.png", "frames": 6, "speed": 6.0, "loop": true},
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
                sf.add_frame("idle", load("res://assets/sprites/player/mage_idle_64.png"))

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
        # === 魔力自动恢复 ===
        if mana < 100.0 and not is_shielding:
                mana = min(100.0, mana + mana_regen * delta)
                mana_changed.emit(mana)

        # === 闪现buff计时 ===
        if blink_buff:
                blink_timer -= delta
                if blink_timer <= 0.0:
                        blink_buff = false
                        blink_speed_mult = 1.0

        if blink_spell_amp_timer > 0.0:
                blink_spell_amp_timer -= delta
                if blink_spell_amp_timer <= 0.0:
                        blink_spell_amp = 1.0

        # === 暴风雪状态 ===
        if blizzard_active:
                blizzard_timer -= delta
                blizzard_hit_timer -= delta
                vel.x = lerp(vel.x, 0.0, 0.1)
                if blizzard_hit_timer <= 0.0:
                        blizzard_hit_timer = 0.3
                if blizzard_timer <= 0.0:
                        blizzard_active = false
                        blizzard_timer = 0.0
                        blizzard_hit_timer = 0.0
                        if sprite:
                                sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
                        play_anim("idle")
                _apply_physics(delta, ground_y)
                return

        # === 魔法护盾消耗 ===
        if is_shielding:
                mana -= shield_mana_drain * delta
                if mana <= 0.0:
                        mana = 0.0
                        is_shielding = false
                        is_perfect_shield_window = false
                        if shield_indicator:
                                shield_indicator.visible = false
                        play_anim("idle")
                mana_changed.emit(mana)

        # === 无敌帧 ===
        if invincible_timer > 0.0:
                invincible_timer -= delta

        # === 受击恢复 ===
        if is_hurt:
                hurt_timer -= delta
                if hurt_timer <= 0.0:
                        is_hurt = false

        # === 连招超时 ===
        if combo_timer > 0.0:
                combo_timer -= delta
                if combo_timer <= 0.0:
                        combo_sequence.clear()
                        combo_count = 0
                        hit_count = 0

        # === 完美护盾窗口 ===
        if is_perfect_shield_window:
                perfect_shield_timer -= delta
                if perfect_shield_timer <= 0.0:
                        is_perfect_shield_window = false

        # === 受击中不能操作 ===
        if is_hurt:
                vel.x = lerp(vel.x, 0.0, 0.1)
                _apply_physics(delta, ground_y)
                return

        # === 护盾中不能攻击但可缓慢移动 ===
        if is_shielding:
                vel.x = lerp(vel.x, 0.0, 0.3)
                play_anim("shield")
                _apply_physics(delta, ground_y)
                return

        # === 攻击中 - 判定帧系统 ===
        if is_attacking:
                attack_frame += 1

                var active_end: int = attack_startup_frames + attack_active_frames
                if attack_frame <= attack_startup_frames:
                        attack_phase = AttackPhase.STARTUP
                elif attack_frame <= active_end:
                        attack_phase = AttackPhase.ACTIVE
                else:
                        attack_phase = AttackPhase.RECOVERY

                # 法师施法时几乎不移动
                if attack_phase == AttackPhase.STARTUP:
                        vel.x = lerp(vel.x, 0.0, 0.2)
                elif attack_phase == AttackPhase.ACTIVE:
                        vel.x = lerp(vel.x, 0.0, 0.15)
                else:
                        vel.x = lerp(vel.x, 0.0, 0.12)

                # 攻击结束
                if attack_frame >= attack_duration:
                        is_attacking = false
                        attack_frame = 0
                        attack_name = ""
                        attack_hit_dealt = false
                        attack_phase = AttackPhase.STARTUP
                        play_anim("idle")

        # === 移动 ===
        var is_moving: bool = false
        var current_speed: float = move_speed * blink_speed_mult
        if Input.is_action_pressed("move_right"):
                vel.x = current_speed
                facing = 1.0
                is_moving = true
        elif Input.is_action_pressed("move_left"):
                vel.x = -current_speed
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

        # === 攻击 ===
        if Input.is_action_just_pressed("attack"):
                do_attack("L")
        elif Input.is_action_just_pressed("heavy_attack"):
                do_attack("H")

        # === 魔法护盾 (L键) ===
        if Input.is_action_just_pressed("guard") and mana >= 5.0:
                is_shielding = true
                is_perfect_shield_window = true
                perfect_shield_timer = 0.1  # 完美护盾窗口
                if shield_indicator:
                        shield_indicator.visible = true
                        shield_indicator.color = Color(0.3, 0.6, 1.0, 0.5)  # 蓝色魔法盾

        if Input.is_action_just_released("guard"):
                is_shielding = false
                is_perfect_shield_window = false
                if shield_indicator:
                        shield_indicator.visible = false

        # === 技能 - 闪现 (U键, 30魔力): 传送120px + 1.5s加速 + 1s法术增幅 ===
        if Input.is_action_just_pressed("skill_1") and mana >= 30.0:
                mana -= 30.0
                blink_buff = true
                blink_timer = 1.5
                blink_speed_mult = 1.3
                blink_spell_amp = 1.2
                blink_spell_amp_timer = 1.0
                # 闪现传送
                pos.x += facing * 120.0
                invincible_timer = 0.2  # 闪现短暂无敌
                mana_changed.emit(mana)
                if sprite:
                        sprite.modulate = Color(0.3, 0.6, 1.0, 0.5)  # 蓝色闪光
                play_anim("blink")

        # === 技能 - 暴风雪 (I键, 80魔力): 2.0s冰冻AOE, 每0.3s15伤害 ===
        if Input.is_action_just_pressed("ultimate") and mana >= 80.0:
                mana -= 80.0
                blizzard_active = true
                blizzard_timer = 2.0
                blizzard_hit_timer = 0.3
                invincible_timer = 0.5  # 开始0.5s无敌
                mana_changed.emit(mana)
                if sprite:
                        sprite.modulate = Color(0.5, 0.8, 1.0, 0.9)  # 冰蓝色特效
                play_anim("blizzard")

        _apply_physics(delta, ground_y)

func _apply_physics(delta: float, ground_y: float) -> void:
        if pos.y < ground_y:
                vel.y += gravity * delta
        pos += vel * delta
        if pos.y > ground_y:
                pos.y = ground_y
                vel.y = 0.0

func do_attack(input_key: String) -> void:
        # 只能在后摇阶段输入下一个连招（或非攻击时）
        if is_attacking and attack_phase != AttackPhase.RECOVERY:
                return

        # 先预检查魔力是否足够
        combo_sequence.append(input_key)
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

        # 检查魔力消耗
        var mana_cost: int = combo_data.get("mana_cost", 0)
        if mana < mana_cost:
                # 魔力不足，回到第一个连招
                combo_sequence = [input_key]
                key = input_key
                if combo_tree.has(key):
                        combo_data = combo_tree[key]
                        mana_cost = combo_data.get("mana_cost", 0)
                        if mana < mana_cost:
                                combo_sequence.clear()
                                return
                else:
                        combo_sequence.clear()
                        return

        # 消耗魔力
        mana -= mana_cost
        mana_changed.emit(mana)

        # 后摇取消
        if is_attacking and attack_phase == AttackPhase.RECOVERY:
                is_attacking = false
                attack_frame = 0
                attack_hit_dealt = false

        combo_timer = 1.2

        attack_name = combo_data["name"]
        attack_duration = combo_data["dur"]
        attack_startup_frames = combo_data.get("startup", 3)
        attack_active_frames = combo_data.get("active", 5)
        is_attacking = true
        attack_frame = 0
        attack_phase = AttackPhase.STARTUP
        attack_hit_dealt = false
        combo_count += 1
        hit_count += 1
        play_anim("cast")

func get_attack_damage() -> float:
        var key: String = ",".join(combo_sequence) if combo_sequence.size() > 0 else ""
        var info: Dictionary = combo_tree.get(key, {})
        var base_mult: float = info.get("mult", 1.0) if info.size() > 0 else 1.0
        var dmg: float = 10.0 * base_mult

        # 闪现法术增幅
        if blink_spell_amp > 1.0:
                dmg *= blink_spell_amp

        # 连击加成
        var combo_bonus: float = 1.0 + min(0.3, float(hit_count) * 0.005)
        if hit_count >= 10:
                combo_bonus = 1.3
        dmg *= combo_bonus

        return dmg

func is_in_active_frames() -> bool:
        return is_attacking and attack_phase == AttackPhase.ACTIVE and not attack_hit_dealt

func mark_hit_dealt() -> void:
        attack_hit_dealt = true

func take_damage(dmg: float, knockback: Vector2) -> void:
        if invincible_timer > 0.0:
                return

        # 暴风雪期间有减伤
        if blizzard_active:
                dmg *= 0.5

        # 魔法护盾判定
        if is_shielding:
                if is_perfect_shield_window:
                        # 完美护盾：0伤害 + 反弹20伤害 + 回复10魔力
                        shield_success.emit(true)
                        mana = min(100.0, mana + 10.0)
                        mana_changed.emit(mana)
                        dmg = 0.0
                        knockback = Vector2.ZERO
                        # 反弹伤害（由外部调用reflect_damage处理）
                else:
                        # 普通护盾：用魔力抵消伤害，1魔力=抵消1.5伤害
                        var mana_to_consume: float = dmg / 1.5
                        if mana >= mana_to_consume:
                                mana -= mana_to_consume
                                mana_changed.emit(mana)
                                dmg *= 0.2  # 只受20%伤害
                                knockback *= 0.2
                        else:
                                # 魔力不足，部分抵消
                                var absorbed: float = mana * 1.5
                                mana = 0.0
                                mana_changed.emit(mana)
                                dmg -= absorbed
                                dmg = max(0.0, dmg)
                                knockback *= 0.5
                        shield_success.emit(false)

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
                "war_cry_active": blink_buff,
                "blizzard_active": blizzard_active,
                "element": info.get("element", "fire") if info.size() > 0 else "fire",
        }
