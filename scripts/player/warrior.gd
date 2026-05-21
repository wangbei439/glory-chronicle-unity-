## 战士玩家控制器 - v0.21
## 处理输入、移动、连招、格挡、怒气
## 攻击判定帧(startup/active/recovery)、战吼增伤、完美格挡回血、裂地斩AOE
## v0.21: 装备叠加系统(武器附着+护甲色调)、量化精灵、装备图标集成
extends Node2D

signal attack_hit(target: Node2D, damage: float, knockback: Vector2)
signal parry_success(is_perfect: bool)
signal rage_changed(value: float)
signal health_changed(value: float)
signal died
signal slash_trail(trail_type: String, position: Vector2, facing: float)  # "light" / "heavy" / "finisher" / "light2" / "light3"
signal attack_started(attack_type: String, combo_step: int)  # 新增：攻击开始信号，携带类型和连击步骤

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
var is_heavy_attack: bool = false     # 当前攻击是否为重击
var is_combo_finisher: bool = false   # 当前攻击是否为连招终结技

# === 输入缓冲 ===
var buffered_input: String = ""       # 缓冲的攻击输入("L"/"H")
var buffer_timer: float = 0.0         # 缓冲计时器
var BUFFER_WINDOW: float = 0.25       # 缓冲窗口(秒)
var current_combo_step: int = 0       # 当前连击步骤(1-3)用于视觉区分

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

# === v0.21: 装备叠加系统 ===
var weapon_sprite: Sprite2D          # 武器附着精灵
var armor_tint: Color = Color(1, 1, 1, 0)  # 护甲色调叠加

# 武器附着点配置 - 根据动画和帧数调整武器位置/旋转
# 格式: anim_name -> [{frame_index: {"pos": Vector2, "rot": float}}]
const WEAPON_ANCHORS: Dictionary = {
        "idle": [
                {"pos": Vector2(14, -20), "rot": 15.0},
                {"pos": Vector2(14, -20), "rot": 15.0},
                {"pos": Vector2(14, -20), "rot": 15.0},
                {"pos": Vector2(14, -20), "rot": 15.0},
        ],
        "run": [
                {"pos": Vector2(14, -18), "rot": 20.0},
                {"pos": Vector2(16, -20), "rot": 10.0},
                {"pos": Vector2(14, -18), "rot": 20.0},
                {"pos": Vector2(12, -20), "rot": 25.0},
                {"pos": Vector2(14, -18), "rot": 20.0},
                {"pos": Vector2(16, -20), "rot": 10.0},
        ],
        "attack_1": [
                {"pos": Vector2(10, -30), "rot": -60.0},
                {"pos": Vector2(10, -35), "rot": -30.0},
                {"pos": Vector2(18, -25), "rot": 45.0},
                {"pos": Vector2(20, -15), "rot": 60.0},
                {"pos": Vector2(14, -20), "rot": 15.0},
        ],
        "heavy_attack": [
                {"pos": Vector2(10, -35), "rot": -80.0},
                {"pos": Vector2(10, -38), "rot": -90.0},
                {"pos": Vector2(10, -35), "rot": -80.0},
                {"pos": Vector2(18, -25), "rot": 90.0},
                {"pos": Vector2(20, -10), "rot": 70.0},
                {"pos": Vector2(14, -20), "rot": 15.0},
        ],
        "guard": [
                {"pos": Vector2(10, -22), "rot": -45.0},
                {"pos": Vector2(10, -22), "rot": -45.0},
                {"pos": Vector2(10, -22), "rot": -45.0},
        ],
        "jump": [
                {"pos": Vector2(14, -22), "rot": 30.0},
                {"pos": Vector2(14, -22), "rot": 30.0},
                {"pos": Vector2(14, -22), "rot": 30.0},
                {"pos": Vector2(14, -22), "rot": 30.0},
        ],
        "hurt": [
                {"pos": Vector2(10, -15), "rot": 45.0},
                {"pos": Vector2(8, -12), "rot": 60.0},
                {"pos": Vector2(14, -20), "rot": 15.0},
        ],
}

# 护甲色调配置 - 不同护甲给角色不同的颜色叠加
const ARMOR_TINTS: Dictionary = {
        "": Color(1, 1, 1, 0),            # 无护甲
        "leather_vest": Color(0.85, 0.7, 0.5, 0.15),   # 皮甲 - 棕色调
        "iron_plate": Color(0.7, 0.75, 0.8, 0.25),     # 铁甲 - 金属蓝灰色
        "crystal_mail": Color(0.6, 0.8, 1.0, 0.2),    # 水晶甲 - 冰蓝色
        "beetle_bulwark": Color(0.7, 0.55, 0.3, 0.25), # 甲壳盾 - 琥珀色
        "vein_holy_garb": Color(1.0, 0.85, 0.5, 0.2),  # 圣衣 - 金色
}

# 武器图标路径配置
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
        _setup_equipment_layers()

func _setup_equipment_layers() -> void:
        ## v0.21: 创建武器附着精灵和护甲色调
        if not sprite:
                return
        
        # 创建武器Sprite2D（叠加在角色精灵上方）
        weapon_sprite = Sprite2D.new()
        weapon_sprite.name = "WeaponOverlay"
        weapon_sprite.z_index = 1  # 在角色上方
        weapon_sprite.texture = null  # 初始无武器
        weapon_sprite.offset = Vector2(14, -20)  # 默认手部位置
        weapon_sprite.scale = Vector2(1.2, 1.2)  # 略放大以清晰可见
        sprite.add_child(weapon_sprite)
        
        # 初始化护甲色调
        update_equipment_visuals()

func update_equipment_visuals() -> void:
        ## v0.21: 根据当前装备更新视觉（武器+护甲色调）
        if not sprite:
                return
        
        # 更新武器图标
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
        
        # 更新护甲色调
        var armor_id: String = GameState.equipped_armor
        armor_tint = ARMOR_TINTS.get(armor_id, Color(1, 1, 1, 0))
        if armor_tint.a > 0:
                # 用modulate叠加护甲色调
                sprite.modulate = Color(1, 1, 1, 1).lerp(armor_tint, armor_tint.a)
        else:
                sprite.modulate = Color(1, 1, 1, 1)

func _update_weapon_anchor() -> void:
        ## v0.21: 根据当前动画帧更新武器位置/旋转
        if not weapon_sprite or not weapon_sprite.visible:
                return
        if not sprite or not sprite.sprite_frames:
                return
        
        var anim_name: String = current_anim
        var frame_idx: int = sprite.frame
        
        # 查找武器锚点配置
        var anchors: Array = WEAPON_ANCHORS.get(anim_name, [])
        if anchors.size() == 0:
                # 未配置的动画使用默认位置
                weapon_sprite.offset = Vector2(14, -20)
                weapon_sprite.rotation_degrees = 15.0 * facing
                return
        
        # 获取当前帧的锚点
        var idx: int = mini(frame_idx, anchors.size() - 1)
        var anchor: Dictionary = anchors[idx]
        
        # 应用位置（考虑朝向翻转）
        var pos: Vector2 = anchor.get("pos", Vector2(14, -20))
        var rot: float = anchor.get("rot", 15.0)
        
        weapon_sprite.offset = Vector2(pos.x * facing, pos.y)
        weapon_sprite.rotation_degrees = rot * facing
        # 朝向左时翻转武器
        weapon_sprite.flip_h = (facing < 0)

func _build_animations() -> void:
        if not sprite:
                return
        var sf = SpriteFrames.new()
        
        # v0.20: 48x64现代像素风精灵，帧数与生成器匹配
        var anims = {
                "idle": {"path": "warrior_idle_sheet.png", "frames": 4, "speed": 8.0, "loop": true},
                "run": {"path": "warrior_run_sheet.png", "frames": 6, "speed": 10.0, "loop": true},
                "attack_1": {"path": "warrior_attack_sheet.png", "frames": 5, "speed": 12.0, "loop": false},
                "attack_2": {"path": "warrior_attack2_sheet.png", "frames": 5, "speed": 11.0, "loop": false},
                "attack_3": {"path": "warrior_attack3_sheet.png", "frames": 6, "speed": 10.0, "loop": false},
                "heavy_attack": {"path": "warrior_heavy_attack_sheet.png", "frames": 6, "speed": 7.0, "loop": false},
                "combo_finisher": {"path": "warrior_combo_finisher_sheet.png", "frames": 6, "speed": 9.0, "loop": false},
                "guard": {"path": "warrior_guard_sheet.png", "frames": 3, "speed": 6.0, "loop": true},
                "jump": {"path": "warrior_jump_sheet.png", "frames": 4, "speed": 5.0, "loop": false},
                "hurt": {"path": "warrior_hurt_sheet.png", "frames": 3, "speed": 8.0, "loop": false},
                "war_cry": {"path": "warrior_war_cry_sheet.png", "frames": 5, "speed": 6.0, "loop": false},
                "earth_shatter": {"path": "warrior_earth_shatter_sheet.png", "frames": 6, "speed": 7.0, "loop": false},
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
                        var frame_w: int = 48  # v0.20: 统一48px宽度
                        atlas.region = Rect2(i * frame_w, 0, frame_w, 64)
                        atlas.filter_clip = false
                        sf.add_frame(anim_name, atlas)
        
        # 回退
        if not sf.has_animation("idle"):
                sf.add_animation("idle")
                var fb = load("res://assets/sprites/player/warrior_idle_64.png")
                if fb:
                        sf.add_frame("idle", fb)
        
        # attack_2/attack_3回退到attack_1的精灵
        if not sf.has_animation("attack_2") and sf.has_animation("attack_1"):
                sf.add_animation("attack_2")
                for i in range(sf.get_frame_count("attack_1")):
                        sf.add_frame("attack_2", sf.get_frame_texture("attack_1", i))
        if not sf.has_animation("attack_3") and sf.has_animation("attack_1"):
                sf.add_animation("attack_3")
                for i in range(sf.get_frame_count("attack_1")):
                        sf.add_frame("attack_3", sf.get_frame_texture("attack_1", i))
        
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
        # v0.21: 更新武器附着点
        _update_weapon_anchor()
        
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
        
        # 输入缓冲计时
        if buffer_timer > 0:
                buffer_timer -= delta
                if buffer_timer <= 0:
                        buffered_input = ""
        
        # 连招超时
        if combo_timer > 0:
                combo_timer -= delta
                if combo_timer <= 0:
                        combo_sequence.clear()
                        combo_count = 0
                        hit_count = 0
                        current_combo_step = 0
        
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
                        # 判定帧发射挥砍拖影信号
                        if not attack_hit_dealt:
                                if is_combo_finisher:
                                        slash_trail.emit("finisher", pos, facing)
                                elif is_heavy_attack:
                                        slash_trail.emit("heavy", pos, facing)
                                else:
                                        slash_trail.emit("light", pos, facing)
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
                
                # 后摇期间检查输入缓冲 → 自动衔接下一招
                if attack_phase == AttackPhase.RECOVERY and buffered_input != "":
                        var input: String = buffered_input
                        buffered_input = ""
                        buffer_timer = 0
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
        
        # 攻击 - 带输入缓冲
        if Input.is_action_just_pressed("attack"):
                if is_attacking and attack_phase != AttackPhase.RECOVERY:
                        # 攻击中（非后摇）→ 缓冲输入
                        buffered_input = "L"
                        buffer_timer = BUFFER_WINDOW
                else:
                        do_attack("L")
        elif Input.is_action_just_pressed("heavy_attack"):
                if is_attacking and attack_phase != AttackPhase.RECOVERY:
                        # 攻击中（非后摇）→ 缓冲输入
                        buffered_input = "H"
                        buffer_timer = BUFFER_WINDOW
                else:
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
                # 非后摇阶段 → 缓冲输入
                buffered_input = input_key
                buffer_timer = BUFFER_WINDOW
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
        
        # 判断攻击类型：重击 vs 轻击
        is_heavy_attack = input_key == "H" or combo_data.get("mult", 1.0) >= 1.8
        # 判断连招终结技：3段以上连招 或 2段+重击
        is_combo_finisher = combo_sequence.size() >= 3 or (combo_sequence.size() >= 2 and input_key == "H")
        # 记录当前连击步骤
        current_combo_step = combo_sequence.size()
        
        # 发射攻击开始信号（用于关卡脚本添加视觉特效）
        var attack_type: String = "light"
        if is_combo_finisher:
                attack_type = "finisher"
        elif is_heavy_attack:
                attack_type = "heavy"
        attack_started.emit(attack_type, current_combo_step)
        
        # 根据攻击类型和连击段数播放不同动画（强制重播）
        if is_combo_finisher:
                play_anim("combo_finisher", true)
        elif is_heavy_attack:
                play_anim("heavy_attack", true)
        else:
                # 轻攻击根据连击段数使用不同动画，让连招有视觉区别
                var combo_step: int = combo_sequence.size()
                match combo_step:
                        1:
                                play_anim("attack_1", true)
                        2:
                                play_anim("attack_2", true)
                        3:
                                play_anim("attack_3", true)
                        _:
                                play_anim("attack_1", true)
        
        # 清除缓冲（已执行）
        buffered_input = ""
        buffer_timer = 0

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
        
        # 连击加成（每连击+3%伤害，上限+30%）
        var combo_bonus: float = 1.0 + min(0.3, hit_count * 0.03)
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
                "is_heavy": is_heavy_attack,
                "is_combo_finisher": is_combo_finisher,
        }
