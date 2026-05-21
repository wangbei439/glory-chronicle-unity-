## 远古熔岩龟 Boss AI - Beta v0.11
## 失落地脉关底Boss，元素区域守护者
## 行为状态机：IDLE → CHASE → BITE → LAVA_SPIT → SHELL_SPIN → LAVA_RAIN → STUNNED
## 双阶段：普通(100%-40%) + 熔岩暴怒(40%以下)
## 特色：熔岩喷吐(远程)、龟壳旋转(霸体+冲撞)、熔岩雨(AOE)
extends Node2D

signal boss_health_changed(hp: float, max_hp: float)
signal boss_died
signal boss_phase_changed(phase: int)
signal boss_telegraph(attack_type: String, direction: float, duration: float)
signal boss_attack_active(is_active: bool)
signal boss_lava_spawn(pos: Vector2, vel: Vector2)  # 熔岩弹生成信号

# === 属性 ===
@export var max_hp: float = 700.0
@export var move_speed: float = 60.0
@export var chase_speed: float = 100.0
@export var attack_range: float = 80.0
@export var detect_range: float = 300.0

# === 状态 ===
enum State { IDLE, CHASE, BITE, LAVA_SPIT, SHELL_SPIN, LAVA_RAIN, STUNNED, DYING }
var current_state: State = State.IDLE
var hp: float = 700.0
var pos: Vector2 = Vector2(450, 309)
var vel: Vector2 = Vector2.ZERO
var facing: float = -1.0
var state_timer: float = 0.0
var attack_cooldown: float = 0.0
var phase: int = 1  # 1=普通, 2=熔岩暴怒(HP<40%)
var is_stunned: bool = false
var stun_timer: float = 0.0

# === 攻击判定帧 ===
enum AttackPhase { TELEGRAPH, STARTUP, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.TELEGRAPH
var attack_hit_count: int = 0
var attack_max_hits: int = 1
var attack_hit_timer: float = 0.0

# === 霸体 ===
var super_armor: bool = false
var poise: float = 120.0
var max_poise: float = 120.0
var poise_regen_rate: float = 15.0  # 熔岩龟韧性回复慢

# === 龟壳旋转 ===
var is_spinning: bool = false
var spin_timer: float = 0.0

# === 熔岩弹 ===
var lava_spit_count: int = 0  # 已喷出的熔岩弹数
var lava_spit_max: int = 1    # 本次喷吐总数

# === 视觉 ===
var sprite: AnimatedSprite2D
var current_anim: String = "idle"
var shell_glow_intensity: float = 0.0  # 壳上熔岩发光强度

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
                "idle": {"path": "boss_lava_turtle_idle_sheet.png", "frames": 4, "speed": 5.0, "loop": true},
                "walk": {"path": "boss_lava_turtle_walk_sheet.png", "frames": 4, "speed": 6.0, "loop": true},
                "attack": {"path": "boss_lava_turtle_attack_sheet.png", "frames": 4, "speed": 8.0, "loop": false},
                "shell_spin": {"path": "boss_lava_turtle_shell_spin_sheet.png", "frames": 2, "speed": 14.0, "loop": true},
                "lava_spit": {"path": "boss_lava_turtle_lava_spit_sheet.png", "frames": 2, "speed": 6.0, "loop": false},
                "stunned": {"path": "boss_lava_turtle_stunned_sheet.png", "frames": 2, "speed": 3.0, "loop": true},
                "hurt": {"path": "boss_lava_turtle_hurt_sheet.png", "frames": 2, "speed": 8.0, "loop": false},
                "death": {"path": "boss_lava_turtle_death_sheet.png", "frames": 4, "speed": 3.0, "loop": false},
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
                var fb = load("res://assets/sprites/enemy/boss_lava_turtle_idle_128.png")
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

        # 阶段检测 - 40%触发熔岩暴怒
        if phase == 1 and hp < max_hp * 0.4:
                phase = 2
                boss_phase_changed.emit(2)
                poise = min(max_poise, poise + 40)
                super_armor = true

        # 状态机
        state_timer -= delta
        var dist_to_player = abs(pos.x - player_pos.x)

        match current_state:
                State.IDLE:
                        _process_idle(delta, dist_to_player, player_pos)
                State.CHASE:
                        _process_chase(delta, dist_to_player, player_pos)
                State.BITE:
                        _process_bite(delta, player_pos)
                State.LAVA_SPIT:
                        _process_lava_spit(delta, player_pos)
                State.SHELL_SPIN:
                        _process_shell_spin(delta, player_pos, ground_y)
                State.LAVA_RAIN:
                        _process_lava_rain(delta, player_pos)

        # 物理
        if not is_spinning:
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
                State.BITE:
                        _start_telegraph("bite", 0.4)
                        state_timer = 1.0
                        attack_max_hits = 1
                State.LAVA_SPIT:
                        _start_telegraph("lava", 0.5)
                        state_timer = 1.5
                        lava_spit_count = 0
                        lava_spit_max = 2 if phase == 2 else 1
                State.SHELL_SPIN:
                        _start_telegraph("spin", 0.3)
                        is_spinning = true
                        spin_timer = 2.0 if phase == 1 else 2.8
                        state_timer = spin_timer + 0.3
                        super_armor = true
                State.LAVA_RAIN:
                        _start_telegraph("rain", 0.8)
                        state_timer = 2.5
                        attack_max_hits = 3 if phase == 2 else 2
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
        """选择攻击模式 - 熔岩龟特色AI"""
        var choices: Array = []

        # 近距离：撕咬或龟壳旋转
        if dist < 100:
                choices.append("bite")
                if phase == 2 or consecutive_attacks >= 2:
                        choices.append("shell_spin")
        # 中距离：熔岩喷吐
        if dist >= 60 and dist < 250:
                choices.append("lava_spit")
                choices.append("bite")
        # 远距离：熔岩喷吐或熔岩雨
        if dist >= 200:
                choices.append("lava_spit")
                if phase == 2:
                        choices.append("lava_rain")

        # 避免重复同类型攻击
        if choices.size() == 0:
                choices.append("bite")

        var choice: String = choices[randi() % choices.size()]

        # 连续攻击3次后强制龟壳旋转
        if consecutive_attacks >= 3 and last_attack_type != "shell_spin":
                choice = "shell_spin"

        # 熔岩暴怒阶段增加特殊攻击概率
        if phase == 2 and randf() < 0.3:
                if choice == "bite":
                        choice = "shell_spin"
                elif choice == "lava_spit":
                        choice = "lava_rain"

        last_attack_type = choice
        match choice:
                "bite":
                        change_state(State.BITE)
                "lava_spit":
                        change_state(State.LAVA_SPIT)
                "shell_spin":
                        change_state(State.SHELL_SPIN)
                "lava_rain":
                        change_state(State.LAVA_RAIN)

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

func _process_bite(delta: float, player_pos: Vector2) -> void:
        """撕咬攻击 - 近距离快攻"""
        if attack_phase == AttackPhase.TELEGRAPH:
                # 蓄力：头部微后仰
                vel.x = sin(state_timer * 20) * 1.0
                play_anim("idle")
                if state_timer <= 0.6:
                        attack_phase = AttackPhase.STARTUP
        elif attack_phase == AttackPhase.STARTUP:
                if state_timer <= 0.3:
                        attack_phase = AttackPhase.ACTIVE
                        play_anim("attack")
                        boss_attack_active.emit(true)
                        # 咬击前冲
                        vel.x = facing * 250
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

func _process_lava_spit(delta: float, player_pos: Vector2) -> void:
        """熔岩喷吐 - 远程抛物线攻击"""
        if attack_phase == AttackPhase.TELEGRAPH:
                # 蓄力：抬头
                vel.x = 0
                play_anim("idle")
                if state_timer <= 0.8:
                        attack_phase = AttackPhase.STARTUP
                        play_anim("lava_spit")
        elif attack_phase == AttackPhase.STARTUP:
                # 张嘴蓄力
                if state_timer <= 0.5 and lava_spit_count < lava_spit_max:
                        attack_phase = AttackPhase.ACTIVE
        elif attack_phase == AttackPhase.ACTIVE:
                # 喷出熔岩弹
                if lava_spit_count < lava_spit_max:
                        lava_spit_count += 1
                        # 熔岩弹：朝玩家方向抛射
                        var dir_x: float = 1.0 if player_pos.x > pos.x else -1.0
                        var lava_vel: Vector2 = Vector2(dir_x * 200, -250)  # 抛物线
                        boss_lava_spawn.emit(pos + Vector2(facing * 40, -35), lava_vel)
                        boss_attack_active.emit(true)

                        if lava_spit_count >= lava_spit_max:
                                attack_phase = AttackPhase.RECOVERY
                                boss_attack_active.emit(false)
                        else:
                                # 多发间隔
                                attack_phase = AttackPhase.STARTUP
                                state_timer = max(state_timer, 0.5)
        elif attack_phase == AttackPhase.RECOVERY:
                vel.x = lerp(vel.x, 0.0, 0.12)

        if state_timer <= 0:
                attack_cooldown = randf_range(2.0, 3.0) if phase == 1 else randf_range(1.2, 2.0)
                change_state(State.IDLE)

func _process_shell_spin(delta: float, player_pos: Vector2, ground_y: float) -> void:
        """龟壳旋转 - 霸体冲撞"""
        if attack_phase == AttackPhase.TELEGRAPH:
                play_anim("idle")
                if state_timer <= spin_timer:
                        attack_phase = AttackPhase.ACTIVE
                        play_anim("shell_spin")
                        boss_attack_active.emit(true)
        elif attack_phase == AttackPhase.ACTIVE:
                # 旋转冲向玩家
                var dir = 1.0 if player_pos.x > pos.x else -1.0
                facing = dir
                var spin_speed: float = 300.0 if phase == 1 else 400.0
                vel.x = dir * spin_speed
                vel.y = 0  # 旋转时不掉落

                # 震屏效果由关卡脚本处理
                spin_timer -= delta
                if spin_timer <= 0:
                        attack_phase = AttackPhase.RECOVERY
                        boss_attack_active.emit(false)
                        is_spinning = false
                        vel.x = 0
        elif attack_phase == AttackPhase.RECOVERY:
                vel.x = lerp(vel.x, 0.0, 0.1)
                # 旋转后短暂眩晕（弱点窗口！）
                if state_timer <= 0:
                        is_stunned = true
                        stun_timer = 1.2  # 1.2秒眩晕
                        change_state(State.STUNNED)
                        return

        if state_timer <= 0 and attack_phase != AttackPhase.RECOVERY:
                is_spinning = false
                attack_cooldown = 3.5
                super_armor = false
                change_state(State.IDLE)

func _process_lava_rain(delta: float, player_pos: Vector2) -> void:
        """熔岩雨 - 狂暴专属AOE，从天降下多枚熔岩弹"""
        if attack_phase == AttackPhase.TELEGRAPH:
                # 长时间蓄力，壳剧烈发光
                vel.x = 0
                play_anim("idle")
                shell_glow_intensity = min(1.0, shell_glow_intensity + delta * 2)
                if state_timer <= 1.2:
                        attack_phase = AttackPhase.ACTIVE
                        play_anim("lava_spit")
        elif attack_phase == AttackPhase.ACTIVE:
                # 连续喷出熔岩弹（向空中高抛）
                attack_hit_timer += delta
                if attack_hit_timer >= 0.5 and attack_hit_count < attack_max_hits:
                        attack_hit_timer = 0.0
                        attack_hit_count += 1
                        # 熔岩弹向空中抛射，由关卡脚本处理落点
                        for j in range(2):
                                var offset_x: float = randf_range(-150, 150)
                                var lava_vel: Vector2 = Vector2(offset_x * 0.8, -400)  # 高抛
                                var spawn_pos: Vector2 = pos + Vector2(0, -40)
                                boss_lava_spawn.emit(spawn_pos, lava_vel)
                        boss_attack_active.emit(true)

                if attack_hit_count >= attack_max_hits:
                        attack_phase = AttackPhase.RECOVERY
                        boss_attack_active.emit(false)
                        shell_glow_intensity = 0.0
        elif attack_phase == AttackPhase.RECOVERY:
                vel.x = lerp(vel.x, 0.0, 0.15)

        if state_timer <= 0:
                attack_cooldown = 5.0
                super_armor = false
                shell_glow_intensity = 0.0
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
                is_spinning = false
                is_stunned = true
                stun_timer = 1.5  # 熔岩龟破霸体硬直更长
                change_state(State.STUNNED)
                return

        # 非霸体时被打断概率低（熔岩龟本身就是tank）
        if not super_armor and randf() < 0.1 and current_state != State.SHELL_SPIN:
                is_stunned = true
                stun_timer = 0.5
                change_state(State.STUNNED)

func get_attack_damage() -> float:
        match current_state:
                State.BITE:
                        return 20.0 if phase == 1 else 30.0
                State.SHELL_SPIN:
                        return 25.0 if phase == 1 else 35.0
                State.LAVA_RAIN:
                        return 15.0  # 单发伤害低但数量多
                _:
                        return 0.0

func get_attack_knockback() -> Vector2:
        var base_kb = Vector2(5, -3)
        match current_state:
                State.BITE:
                        base_kb = Vector2(6, -2)
                State.SHELL_SPIN:
                        base_kb = Vector2(12, -4)  # 旋转击退大
                State.LAVA_RAIN:
                        base_kb = Vector2(3, -5)  # 向下击飞
        return base_kb * Vector2(facing, 1)

func is_in_attack_state() -> bool:
        return current_state == State.BITE or current_state == State.SHELL_SPIN or current_state == State.LAVA_RAIN

func is_attack_active() -> bool:
        return attack_phase == AttackPhase.ACTIVE

func get_telegraph_info() -> Dictionary:
        var info = {"type": "", "warning_level": 0}
        if attack_phase == AttackPhase.TELEGRAPH or attack_phase == AttackPhase.STARTUP:
                match current_state:
                        State.BITE:
                                info = {"type": "!", "warning_level": 1}
                        State.LAVA_SPIT:
                                info = {"type": "◆", "warning_level": 2}  # 橙色菱形=远程
                        State.SHELL_SPIN:
                                info = {"type": "↻↻", "warning_level": 2}  # 旋转标记
                        State.LAVA_RAIN:
                                info = {"type": "▼▼▼", "warning_level": 2}  # 红色向下
        return info

func _update_visuals(ground_y: float) -> void:
        if sprite:
                sprite.position = pos + Vector2(-64, -64)  # 128x64居中
                sprite.flip_h = (facing < 0)
                # 熔岩暴怒闪烁
                if phase == 2 and hp > 0:
                        if int(Time.get_ticks_msec() / 150) % 2 == 0:
                                sprite.modulate = Color(1.4, 0.7, 0.5)
                        else:
                                sprite.modulate = Color(1.1, 0.9, 0.8)
                # 霸体发光
                elif super_armor:
                        sprite.modulate = Color(1.3, 1.0, 0.7)
                # 硬直闪烁
                elif is_stunned:
                        if int(Time.get_ticks_msec() / 100) % 2 == 0:
                                sprite.modulate = Color(1.5, 1.5, 2.0)
                        else:
                                sprite.modulate = Color(1, 1, 1)
                # 熔岩雨蓄力发光
                elif shell_glow_intensity > 0:
                        var glow: float = shell_glow_intensity
                        sprite.modulate = Color(1.0 + glow * 0.5, 1.0 - glow * 0.3, 1.0 - glow * 0.5)
                else:
                        sprite.modulate = Color(1, 1, 1)
