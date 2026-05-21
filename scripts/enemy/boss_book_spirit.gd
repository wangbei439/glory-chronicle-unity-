## 堕落书灵 Boss AI - Beta v0.11
## 禁忌书库关底Boss，灵异区域守护者
## 行为状态机：IDLE → CHASE → BOOK_SLAM → PAGE_STORM → SPELL_BEAM → BOOK_TORNADO → STUNNED
## 双阶段：普通(100%-50%) + 狂怒(50%以下)
## 特色：书页风暴(远程AOE)、魔光射线(横屏激光)、旋书追踪(追踪弹)
extends Node2D

signal boss_health_changed(hp: float, max_hp: float)
signal boss_died
signal boss_phase_changed(phase: int)
signal boss_telegraph(attack_type: String, direction: float, duration: float)
signal boss_attack_active(is_active: bool)
signal boss_page_spawn(pos: Vector2, vel: Vector2)  # 书页弹生成信号
signal boss_beam_active(pos: Vector2, facing: float, duration: float)  # 魔光射线信号
signal boss_tornado_spawn(pos: Vector2, target_pos: Vector2)  # 旋书追踪信号

# === 属性 ===
@export var max_hp: float = 600.0
@export var move_speed: float = 80.0
@export var chase_speed: float = 120.0
@export var attack_range: float = 80.0
@export var detect_range: float = 300.0

# === 状态 ===
enum State { IDLE, CHASE, BOOK_SLAM, PAGE_STORM, SPELL_BEAM, BOOK_TORNADO, STUNNED, DYING }
var current_state: State = State.IDLE
var hp: float = 600.0
var pos: Vector2 = Vector2(450, 309)
var vel: Vector2 = Vector2.ZERO
var facing: float = -1.0
var state_timer: float = 0.0
var attack_cooldown: float = 0.0
var phase: int = 1  # 1=普通, 2=狂怒(HP<50%)
var is_stunned: bool = false
var stun_timer: float = 0.0

# === 飘浮 ===
var float_offset: float = -20.0  # 空中飘浮偏移
var float_bob_timer: float = 0.0  # 上下浮动计时

# === 攻击判定帧 ===
enum AttackPhase { TELEGRAPH, STARTUP, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.TELEGRAPH
var attack_hit_count: int = 0
var attack_max_hits: int = 1
var attack_hit_timer: float = 0.0

# === 霸体 ===
var super_armor: bool = false
var poise: float = 100.0
var max_poise: float = 100.0
var poise_regen_rate: float = 12.0  # 书灵韧性回复中

# === 书页风暴 ===
var page_storm_count: int = 0  # 已发射的书页数
var page_storm_max: int = 3    # 本次风暴总页数

# === 魔光射线 ===
var beam_timer: float = 0.0    # 射线持续时间
var beam_telegraph_dur: float = 0.8  # 射线预警时间
var beam_active_dur: float = 0.6     # 射线激活时间

# === 旋书追踪 ===
var tornado_count: int = 0     # 已生成的追踪书数
var tornado_max: int = 2       # 本次追踪书总数
var tornado_track_duration: float = 2.0  # 追踪持续时间

# === 视觉 ===
var sprite: AnimatedSprite2D
var current_anim: String = "idle"
var arc_glow_intensity: float = 0.0  # 魔力光环强度

# 攻击模式
var consecutive_attacks: int = 0
var last_attack_type: String = ""

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
                "idle": {"path": "boss_book_spirit_idle_sheet.png", "frames": 4, "speed": 5.0, "loop": true},
                "walk": {"path": "boss_book_spirit_walk_sheet.png", "frames": 4, "speed": 6.0, "loop": true},
                "attack": {"path": "boss_book_spirit_attack_sheet.png", "frames": 4, "speed": 8.0, "loop": false},
                "page_storm": {"path": "boss_book_spirit_page_storm_sheet.png", "frames": 2, "speed": 6.0, "loop": false},
                "spell_beam": {"path": "boss_book_spirit_spell_beam_sheet.png", "frames": 2, "speed": 14.0, "loop": true},
                "book_tornado": {"path": "boss_book_spirit_book_tornado_sheet.png", "frames": 2, "speed": 6.0, "loop": false},
                "stunned": {"path": "boss_book_spirit_stunned_sheet.png", "frames": 2, "speed": 3.0, "loop": true},
                "hurt": {"path": "boss_book_spirit_hurt_sheet.png", "frames": 2, "speed": 8.0, "loop": false},
                "death": {"path": "boss_book_spirit_death_sheet.png", "frames": 4, "speed": 3.0, "loop": false},
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
                        atlas.region = Rect2(i * 128, 0, 128, 64)
                        atlas.filter_clip = false
                        sf.add_frame(anim_name, atlas)

        # 回退
        if not sf.has_animation("idle"):
                sf.add_animation("idle")
                var fb = load("res://assets/sprites/enemy/boss_book_spirit_idle_128.png")
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
                        state_timer = 2.5
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

        # 阶段检测 - 50%触发狂怒
        if phase == 1 and hp < max_hp * 0.5:
                phase = 2
                boss_phase_changed.emit(2)
                poise = min(max_poise, poise + 30)
                super_armor = true

        # 状态机
        state_timer -= delta
        var dist_to_player = abs(pos.x - player_pos.x)

        match current_state:
                State.IDLE:
                        _process_idle(delta, dist_to_player, player_pos)
                State.CHASE:
                        _process_chase(delta, dist_to_player, player_pos)
                State.BOOK_SLAM:
                        _process_book_slam(delta, player_pos)
                State.PAGE_STORM:
                        _process_page_storm(delta, player_pos)
                State.SPELL_BEAM:
                        _process_spell_beam(delta, player_pos)
                State.BOOK_TORNADO:
                        _process_book_tornado(delta, player_pos)

        # 物理 - 书灵飘浮，不受重力
        float_bob_timer += delta
        var bob_y: float = sin(float_bob_timer * 2.5) * 5.0  # 轻微上下浮动
        pos += vel * delta
        # 飘浮：保持在地面以上float_offset + bob偏移
        var float_y: float = ground_y + float_offset + bob_y
        pos.y = float_y
        vel.y = 0  # 不受重力影响

        _update_visuals(ground_y)

func change_state(new_state: State) -> void:
        current_state = new_state
        state_timer = 0.0
        attack_phase = AttackPhase.TELEGRAPH
        attack_hit_count = 0

        match new_state:
                State.IDLE:
                        play_anim("idle")
                        state_timer = randf_range(0.8, 2.0)
                        super_armor = false
                        consecutive_attacks = 0
                State.CHASE:
                        play_anim("walk")
                        super_armor = false
                State.BOOK_SLAM:
                        _start_telegraph("slam", 0.4)
                        state_timer = 1.0
                        attack_max_hits = 1
                State.PAGE_STORM:
                        _start_telegraph("page", 0.5)
                        state_timer = 1.8
                        page_storm_count = 0
                        page_storm_max = 5 if phase == 2 else 3
                State.SPELL_BEAM:
                        _start_telegraph("beam", beam_telegraph_dur)
                        state_timer = beam_telegraph_dur + beam_active_dur + 0.3
                        super_armor = true
                State.BOOK_TORNADO:
                        _start_telegraph("tornado", 0.6)
                        state_timer = 2.5
                        tornado_count = 0
                        tornado_max = 3 if phase == 2 else 2
                        super_armor = true
                State.STUNNED:
                        play_anim("stunned")
                        super_armor = false

func _start_telegraph(attack_type: String, duration: float) -> void:
        attack_phase = AttackPhase.TELEGRAPH
        boss_telegraph.emit(attack_type, facing, duration)

func _process_idle(delta: float, dist: float, player_pos: Vector2) -> void:
        vel.x = lerp(vel.x, 0.0, 0.12)
        if state_timer <= 0:
                if dist < attack_range and attack_cooldown <= 0:
                        consecutive_attacks += 1
                        _choose_attack(dist, player_pos)
                elif dist < detect_range:
                        change_state(State.CHASE)
                else:
                        state_timer = randf_range(0.8, 2.0)

func _choose_attack(dist: float, player_pos: Vector2) -> void:
        """选择攻击模式 - 堕落书灵特色AI"""
        var choices: Array = []

        # 近距离：书页重击
        if dist < 100:
                choices.append("book_slam")
        # 中距离：书页风暴或书页重击
        if dist >= 60 and dist < 250:
                choices.append("page_storm")
                choices.append("book_slam")
        # 远距离：书页风暴或Phase2特殊
        if dist >= 200:
                choices.append("page_storm")
                if phase == 2:
                        choices.append("spell_beam")
                        choices.append("book_tornado")

        # Phase 2近距离也有概率出特殊攻击
        if phase == 2 and dist < 150:
                choices.append("spell_beam")
                if consecutive_attacks >= 2:
                        choices.append("book_tornado")

        # 避免重复同类型攻击
        if choices.size() == 0:
                choices.append("book_slam")

        var choice: String = choices[randi() % choices.size()]

        # 连续攻击3次后强制使用强力技能
        if consecutive_attacks >= 3 and last_attack_type != "book_tornado":
                if phase == 2:
                        choice = "book_tornado"
                else:
                        choice = "page_storm"

        # 狂怒阶段增加特殊攻击概率
        if phase == 2 and randf() < 0.3:
                if choice == "book_slam":
                        choice = "spell_beam"
                elif choice == "page_storm":
                        choice = "book_tornado"

        last_attack_type = choice
        match choice:
                "book_slam":
                        change_state(State.BOOK_SLAM)
                "page_storm":
                        change_state(State.PAGE_STORM)
                "spell_beam":
                        change_state(State.SPELL_BEAM)
                "book_tornado":
                        change_state(State.BOOK_TORNADO)

func _process_chase(delta: float, dist: float, player_pos: Vector2) -> void:
        var spd = chase_speed if phase == 2 else move_speed
        var dir = 1.0 if player_pos.x > pos.x else -1.0
        vel.x = dir * spd
        facing = dir

        if dist < attack_range and attack_cooldown <= 0:
                vel.x = 0
                consecutive_attacks += 1
                _choose_attack(dist, player_pos)
        elif dist > detect_range * 1.5:
                vel.x = lerp(vel.x, 0.0, 0.1)
                change_state(State.IDLE)

func _process_book_slam(delta: float, player_pos: Vector2) -> void:
        """书页重击 - 近距离猛击"""
        if attack_phase == AttackPhase.TELEGRAPH:
                # 蓄力：书本微后仰
                vel.x = sin(state_timer * 20) * 1.0
                play_anim("idle")
                if state_timer <= 0.6:
                        attack_phase = AttackPhase.STARTUP
        elif attack_phase == AttackPhase.STARTUP:
                if state_timer <= 0.3:
                        attack_phase = AttackPhase.ACTIVE
                        play_anim("attack")
                        boss_attack_active.emit(true)
                        # 重击前冲
                        vel.x = facing * 220
        elif attack_phase == AttackPhase.ACTIVE:
                vel.x = lerp(vel.x, 0.0, 0.15)
                if state_timer <= 0.1:
                        attack_phase = AttackPhase.RECOVERY
                        boss_attack_active.emit(false)
        elif attack_phase == AttackPhase.RECOVERY:
                vel.x = lerp(vel.x, 0.0, 0.15)

        if state_timer <= 0:
                attack_cooldown = randf_range(1.0, 1.8) if phase == 1 else randf_range(0.6, 1.2)
                change_state(State.IDLE)

func _process_page_storm(delta: float, player_pos: Vector2) -> void:
        """书页风暴 - 远程AOE，发射多枚书页弹"""
        if attack_phase == AttackPhase.TELEGRAPH:
                # 蓄力：书本环绕发光
                vel.x = 0
                play_anim("idle")
                arc_glow_intensity = min(1.0, arc_glow_intensity + delta * 3)
                if state_timer <= 0.9:
                        attack_phase = AttackPhase.STARTUP
                        play_anim("page_storm")
        elif attack_phase == AttackPhase.STARTUP:
                # 蓄力展开
                if state_timer <= 0.5 and page_storm_count < page_storm_max:
                        attack_phase = AttackPhase.ACTIVE
        elif attack_phase == AttackPhase.ACTIVE:
                # 发射书页弹
                attack_hit_timer += delta
                if attack_hit_timer >= 0.25 and page_storm_count < page_storm_max:
                        attack_hit_timer = 0.0
                        page_storm_count += 1
                        # 书页弹：朝玩家方向散射
                        var dir_x: float = 1.0 if player_pos.x > pos.x else -1.0
                        var spread_angle: float = randf_range(-0.4, 0.4)  # 扇形散射
                        var page_speed: float = 250.0 if phase == 1 else 320.0
                        var page_vel: Vector2 = Vector2(
                                dir_x * page_speed * cos(spread_angle),
                                page_speed * sin(spread_angle) - 80.0
                        )
                        boss_page_spawn.emit(pos + Vector2(facing * 30, -25), page_vel)
                        boss_attack_active.emit(true)

                        if page_storm_count >= page_storm_max:
                                attack_phase = AttackPhase.RECOVERY
                                boss_attack_active.emit(false)
                                arc_glow_intensity = 0.0
                        else:
                                # 多发间隔
                                attack_phase = AttackPhase.STARTUP
                                state_timer = max(state_timer, 0.3)
        elif attack_phase == AttackPhase.RECOVERY:
                vel.x = lerp(vel.x, 0.0, 0.12)

        if state_timer <= 0:
                attack_cooldown = randf_range(2.0, 3.0) if phase == 1 else randf_range(1.2, 2.0)
                arc_glow_intensity = 0.0
                change_state(State.IDLE)

func _process_spell_beam(delta: float, player_pos: Vector2) -> void:
        """魔光射线 - Phase2横屏激光"""
        if attack_phase == AttackPhase.TELEGRAPH:
                # 长时间蓄力，魔力光环剧烈增强
                vel.x = 0
                play_anim("idle")
                arc_glow_intensity = min(1.0, arc_glow_intensity + delta * 2.5)
                if state_timer <= beam_active_dur + 0.3:
                        attack_phase = AttackPhase.STARTUP
                        play_anim("spell_beam")
        elif attack_phase == AttackPhase.STARTUP:
                # 预警完成，准备射线
                if state_timer <= beam_active_dur + 0.1:
                        attack_phase = AttackPhase.ACTIVE
                        boss_attack_active.emit(true)
                        beam_timer = beam_active_dur
                        # 发出射线信号
                        boss_beam_active.emit(pos + Vector2(facing * 40, -15), facing, beam_active_dur)
        elif attack_phase == AttackPhase.ACTIVE:
                # 射线持续
                vel.x = 0
                beam_timer -= delta
                if beam_timer <= 0:
                        attack_phase = AttackPhase.RECOVERY
                        boss_attack_active.emit(false)
                        arc_glow_intensity = 0.0
        elif attack_phase == AttackPhase.RECOVERY:
                vel.x = lerp(vel.x, 0.0, 0.15)
                # 射线后短暂硬直（弱点窗口！）
                if state_timer <= 0:
                        is_stunned = true
                        stun_timer = 1.0  # 1.0秒硬直
                        change_state(State.STUNNED)
                        return

        if state_timer <= 0 and attack_phase != AttackPhase.RECOVERY:
                attack_cooldown = 4.0
                super_armor = false
                arc_glow_intensity = 0.0
                change_state(State.IDLE)

func _process_book_tornado(delta: float, player_pos: Vector2) -> void:
        """旋书追踪 - Phase2追踪弹，生成追踪玩家的魔法书"""
        if attack_phase == AttackPhase.TELEGRAPH:
                # 蓄力：魔力漩涡
                vel.x = 0
                play_anim("idle")
                arc_glow_intensity = min(1.0, arc_glow_intensity + delta * 2)
                if state_timer <= 1.5:
                        attack_phase = AttackPhase.STARTUP
                        play_anim("book_tornado")
        elif attack_phase == AttackPhase.STARTUP:
                # 蓄力展开
                if state_timer <= 1.0 and tornado_count < tornado_max:
                        attack_phase = AttackPhase.ACTIVE
        elif attack_phase == AttackPhase.ACTIVE:
                # 生成追踪书
                attack_hit_timer += delta
                if attack_hit_timer >= 0.4 and tornado_count < tornado_max:
                        attack_hit_timer = 0.0
                        tornado_count += 1
                        # 追踪书：从书灵位置生成，追踪玩家
                        var spawn_offset: Vector2 = Vector2(randf_range(-30, 30), -40)
                        boss_tornado_spawn.emit(pos + spawn_offset, player_pos)
                        boss_attack_active.emit(true)

                        if tornado_count >= tornado_max:
                                attack_phase = AttackPhase.RECOVERY
                                boss_attack_active.emit(false)
                                arc_glow_intensity = 0.0
                        else:
                                # 多本间隔
                                attack_phase = AttackPhase.STARTUP
                                state_timer = max(state_timer, 0.5)
        elif attack_phase == AttackPhase.RECOVERY:
                vel.x = lerp(vel.x, 0.0, 0.15)

        if state_timer <= 0:
                attack_cooldown = 5.0
                super_armor = false
                arc_glow_intensity = 0.0
                change_state(State.IDLE)

func take_damage(dmg: float) -> void:
        if hp <= 0:
                return
        hp = max(0, hp - dmg)
        boss_health_changed.emit(hp, max_hp)
        play_anim("hurt")

        # 韧性减少
        var poise_damage: float = dmg * 1.5
        poise = max(0, poise - poise_damage)

        # 韧性归零时破霸体
        if poise <= 0 and super_armor:
                super_armor = false
                is_stunned = true
                stun_timer = 1.0  # 书灵破霸体硬直1.0秒
                change_state(State.STUNNED)
                return

        # 非霸体时被打断概率低
        if not super_armor and randf() < 0.1 and current_state != State.BOOK_TORNADO:
                is_stunned = true
                stun_timer = 0.5
                change_state(State.STUNNED)

func get_attack_damage() -> float:
        match current_state:
                State.BOOK_SLAM:
                        return 18.0 if phase == 1 else 25.0
                State.PAGE_STORM:
                        return 12.0 if phase == 1 else 18.0
                State.SPELL_BEAM:
                        return 22.0  # Phase2固定
                State.BOOK_TORNADO:
                        return 15.0  # 单发伤害，但追踪
                _:
                        return 0.0

func get_attack_knockback() -> Vector2:
        var base_kb = Vector2(5, -3)
        match current_state:
                State.BOOK_SLAM:
                        base_kb = Vector2(6, -3)
                State.PAGE_STORM:
                        base_kb = Vector2(3, -2)  # 书页击退小
                State.SPELL_BEAM:
                        base_kb = Vector2(8, -1)  # 射线强横向击退
                State.BOOK_TORNADO:
                        base_kb = Vector2(4, -4)  # 追踪书向上击飞
        return base_kb * Vector2(facing, 1)

func is_in_attack_state() -> bool:
        return current_state == State.BOOK_SLAM or current_state == State.PAGE_STORM or current_state == State.SPELL_BEAM or current_state == State.BOOK_TORNADO

func is_attack_active() -> bool:
        return attack_phase == AttackPhase.ACTIVE

func get_telegraph_info() -> Dictionary:
        var info = {"type": "", "warning_level": 0}
        if attack_phase == AttackPhase.TELEGRAPH or attack_phase == AttackPhase.STARTUP:
                match current_state:
                        State.BOOK_SLAM:
                                info = {"type": "!", "warning_level": 1}
                        State.PAGE_STORM:
                                info = {"type": "◇◇", "warning_level": 2}  # 紫色双菱形=远程AOE
                        State.SPELL_BEAM:
                                info = {"type": "━━━", "warning_level": 2}  # 横线=横屏激光
                        State.BOOK_TORNADO:
                                info = {"type": "↯↯", "warning_level": 2}  # 闪电标记=追踪
        return info

func _update_visuals(ground_y: float) -> void:
        if sprite:
                sprite.position = pos + Vector2(-64, -64)  # 128x64居中
                sprite.flip_h = (facing < 0)
                # 狂怒阶段闪烁 - 紫色幽光
                if phase == 2 and hp > 0:
                        if int(Time.get_ticks_msec() / 150) % 2 == 0:
                                sprite.modulate = Color(0.7, 0.5, 1.4)
                        else:
                                sprite.modulate = Color(0.9, 0.8, 1.1)
                # 霸体发光 - 魔力护盾
                elif super_armor:
                        sprite.modulate = Color(0.8, 0.7, 1.3)
                # 硬直闪烁
                elif is_stunned:
                        if int(Time.get_ticks_msec() / 100) % 2 == 0:
                                sprite.modulate = Color(1.5, 1.5, 2.0)
                        else:
                                sprite.modulate = Color(1, 1, 1)
                # 魔力蓄力发光
                elif arc_glow_intensity > 0:
                        var glow: float = arc_glow_intensity
                        sprite.modulate = Color(1.0 + glow * 0.3, 1.0 - glow * 0.2, 1.0 + glow * 0.5)
                else:
                        sprite.modulate = Color(1, 1, 1)
