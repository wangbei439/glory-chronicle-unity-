## 幽影矿井 Boss 战 - Alpha v0.7
## 矿脉甲虫 vs 战士 完整战斗
## v0.7新增：摄像机跟随、音效系统、关卡过渡、Esc返回主菜单
extends Node2D

const GROUND_Y: float = 309.0

# === 自动演示模式（服务器截图用，玩家下载后默认关闭）===
@export var auto_demo: bool = false
@export var auto_quit_frame: int = 0  # 0=不自动退出

# 子系统
var warrior: Node2D
var boss: Node2D
var hud: Node2D
var effects: Node2D
var camera: Node2D
var audio: Node2D

# 视觉节点
var player_sprite: AnimatedSprite2D
var boss_sprite: AnimatedSprite2D
var parry_indicator: ColorRect
var camera_offset: Vector2 = Vector2.ZERO

# 战斗状态
var battle_active: bool = false
var battle_intro: bool = true
var intro_timer: float = 0.0
var frame_count: int = 0
var player_hit_applied: bool = false
var boss_hit_applied: bool = false

# 地震斩
var earth_shatter_active: bool = false
var earth_shatter_timer: float = 0.0
var earth_shatter_dealt: bool = false

# 死亡/重生
var player_dead: bool = false
var respawn_timer: float = 0.0
var boss_victory: bool = false

# 跳跃音效
var was_on_ground: bool = true

func _ready() -> void:
        _build_scene()

func _build_scene() -> void:
        # 背景
        var bg_tex = load("res://assets/sprites/background/dungeon_mine_640x360.png")
        if bg_tex:
                var bg = TextureRect.new()
                bg.texture = bg_tex
                bg.size = Vector2(640, 360)
                bg.stretch_mode = TextureRect.STRETCH_SCALE
                add_child(bg)
        else:
                var bg2 = ColorRect.new()
                bg2.size = Vector2(640, 360)
                bg2.color = Color(0.06, 0.06, 0.14, 1.0)
                add_child(bg2)

        # 地面
        var ground_top = ColorRect.new()
        ground_top.position = Vector2(0, 329)
        ground_top.size = Vector2(640, 2)
        ground_top.color = Color(0.35, 0.4, 0.45, 0.8)
        add_child(ground_top)
        var ground = ColorRect.new()
        ground.position = Vector2(0, 330)
        ground.size = Vector2(640, 30)
        ground.color = Color(0.15, 0.17, 0.2, 0.6)
        add_child(ground)

        # === 摄像机控制器 ===
        var camera_script = load("res://scripts/core/camera_controller.gd")
        camera = Node2D.new()
        camera.set_script(camera_script)
        add_child(camera)
        camera.setup(Vector2(640, 360), Vector2.ZERO, Vector2(640, 360))
        camera.set_position_immediate(Vector2(320, 180))
        camera.activate()

        # === 音效系统 ===
        var audio_script = load("res://scripts/audio/audio_manager.gd")
        audio = Node2D.new()
        audio.set_script(audio_script)
        add_child(audio)

        # === 打击感特效系统 ===
        var effects_script = load("res://scripts/core/combat_effects.gd")
        effects = Node2D.new()
        effects.set_script(effects_script)
        add_child(effects)

        # === 战士 ===
        var warrior_script = load("res://scripts/player/warrior.gd")
        warrior = Node2D.new()
        warrior.set_script(warrior_script)
        add_child(warrior)

        player_sprite = AnimatedSprite2D.new()
        add_child(player_sprite)
        warrior.setup_sprite(player_sprite)
        warrior.pos = Vector2(150, GROUND_Y)

        # 从全局状态恢复
        var state = GameState.get_player_state()
        warrior.hp = state["hp"]
        warrior.rage = state["rage"]
        warrior.hit_count = state["hit_count"]

        parry_indicator = ColorRect.new()
        parry_indicator.size = Vector2(20, 20)
        parry_indicator.color = Color(0.5, 0.8, 1.0, 0.4)
        parry_indicator.visible = false
        add_child(parry_indicator)
        warrior.parry_indicator = parry_indicator

        # === 矿脉甲虫 Boss ===
        var boss_script = load("res://scripts/enemy/boss_beetle.gd")
        boss = Node2D.new()
        boss.set_script(boss_script)
        add_child(boss)

        boss_sprite = AnimatedSprite2D.new()
        add_child(boss_sprite)
        boss.setup(boss_sprite)
        boss.pos = Vector2(480, GROUND_Y)
        boss.facing = -1.0

        # === HUD ===
        var hud_script = load("res://scripts/ui/hud.gd")
        hud = Node2D.new()
        hud.set_script(hud_script)
        add_child(hud)
        hud.build()

        # 连接信号
        warrior.attack_hit.connect(_on_player_attack)
        warrior.rage_changed.connect(func(v): hud.update_rage(v, 100))
        warrior.health_changed.connect(func(v): hud.update_player_hp(v, 100))
        warrior.parry_success.connect(_on_parry_success)
        warrior.died.connect(_on_player_died)
        boss.boss_health_changed.connect(func(h, m): hud.update_boss_hp(h, m))
        boss.boss_phase_changed.connect(_on_boss_phase_changed)
        boss.boss_died.connect(_on_boss_died)
        boss.boss_telegraph.connect(_on_boss_telegraph)
        boss.boss_attack_active.connect(_on_boss_attack_active)

        # 版本号
        var ver = Label.new()
        ver.text = "v0.7"
        ver.position = Vector2(600, 350)
        ver.add_theme_font_size_override("font_size", 7)
        ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
        add_child(ver)

        # 操作提示
        var hint = Label.new()
        hint.text = "A/D:移动 W/Space:跳跃 J:轻攻 K:重攻 L:格挡 U:战吼 I:裂地斩 R:重来 Esc:主菜单"
        hint.position = Vector2(90, 350)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.7))
        add_child(hint)

        # 关卡标题
        var level_title = Label.new()
        level_title.text = "幽影矿井 - Boss战"
        level_title.position = Vector2(230, 5)
        level_title.add_theme_font_size_override("font_size", 10)
        level_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2, 0.8))
        add_child(level_title)

func _physics_process(delta: float) -> void:
        frame_count += 1

        # Esc返回主菜单
        if Input.is_key_pressed(KEY_ESCAPE):
                GameState.save_player_state(warrior.hp, warrior.rage, warrior.hit_count)
                GameState.go_to_title()
                return

        # Hitstop：顿帧期间只处理特效
        if effects.hitstop_active:
                effects.process(delta)
                return

        # 应用震屏偏移
        camera_offset = effects.get_shake_offset()
        camera.apply_shake(camera_offset)

        if battle_intro:
                _process_intro(delta)
                camera.follow(warrior.pos, warrior.facing, delta)
                return

        # === 死亡/重生 ===
        if player_dead:
                respawn_timer -= delta
                if respawn_timer <= 0:
                        if Input.is_key_pressed(KEY_R):
                                _respawn_player()
                effects.process(delta)
                camera.follow(warrior.pos, warrior.facing, delta)
                return

        # === Boss胜利 ===
        if boss_victory:
                effects.process(delta)
                camera.follow(warrior.pos, warrior.facing, delta)
                if Input.is_key_pressed(KEY_R):
                        _restart_battle()
                return

        if not battle_active:
                return

        # 处理特效系统
        effects.process(delta)

        # 处理战士
        warrior.process(delta, GROUND_Y)

        # 跳跃/落地音效
        var on_ground: bool = warrior.pos.y >= GROUND_Y - 3
        if not was_on_ground and on_ground:
                audio.play("land")
        was_on_ground = on_ground

        # 处理Boss
        boss.process(delta, warrior.pos, GROUND_Y)

        # 碰撞检测
        _check_combat_collisions()

        # 裂地斩AOE
        _process_earth_shatter(delta)

        # 更新视觉
        _update_visuals()

        # 更新HUD
        _update_hud()

        # 更新摄像机
        camera.follow(warrior.pos, warrior.facing, delta)

        # 保存全局状态
        GameState.save_player_state(warrior.hp, warrior.rage, warrior.hit_count)

        # 连招超时
        if warrior.combo_timer <= 0 and not warrior.is_attacking:
                hud.clear_combo()

        # 攻击状态显示
        if warrior.is_attacking and warrior.attack_name != "":
                var info = warrior.get_attack_info()
                hud.show_combo(warrior.attack_name, info.get("war_cry_active", false))

        # 预警显示
        _update_telegraph()

        # 战吼buff显示
        hud.show_war_cry_buff(warrior.war_cry_buff, warrior.war_cry_timer)

        # Boss狂暴时定期火焰特效
        if boss.phase == 2 and boss.hp > 0 and frame_count % 30 == 0:
                effects.spawn_boss_enrage_aura(boss.pos)
                audio.play("boss_enrage", 0.5)

        # HUD特效更新
        hud.process_effects(delta)

        # === 自动演示模式（仅服务器截图用）===
        if auto_demo:
                _run_demo()

        # === 自动退出（仅服务器用）===
        if auto_quit_frame > 0 and frame_count >= auto_quit_frame:
                _take_screenshot("legend_auto_quit.png")
                get_tree().quit()

func _process_intro(delta: float) -> void:
        intro_timer += delta
        boss_sprite.play("idle")
        boss_sprite.position = boss.pos + Vector2(0, -32) + camera_offset
        boss_sprite.flip_h = (boss.facing < 0)

        player_sprite.play("idle")
        player_sprite.position = warrior.pos + Vector2(0, -32) + camera_offset

        hud.show_boss_hp("矿脉甲虫")
        hud.update_boss_hp(boss.hp, boss.max_hp)
        hud.update_player_hp(warrior.hp, warrior.max_hp)

        if intro_timer > 2.0:
                battle_intro = false
                battle_active = true
                hud.show_perfect("FIGHT!", Color(1, 0.3, 0.1))
                audio.play("war_cry", 0.7)

func _check_combat_collisions() -> void:
        var dist = abs(warrior.pos.x - boss.pos.x)

        # === 玩家攻击Boss ===
        if warrior.is_in_active_frames() and not boss_hit_applied:
                if dist < 80:
                        var dmg: float = warrior.get_attack_damage()
                        boss.take_damage(dmg)
                        warrior.mark_hit_dealt()
                        boss_hit_applied = true

                        var hit_pos: Vector2 = (warrior.pos + boss.pos) / 2 + Vector2(0, -20)
                        var is_heavy: bool = dmg >= 20

                        effects.spawn_hit_spark(hit_pos, Color(1, 0.9, 0.5) if not is_heavy else Color(1, 0.5, 0.2))
                        effects.spawn_blood_splatter(hit_pos, warrior.facing)

                        # 音效
                        if is_heavy:
                                effects.start_hitstop(0.1)
                                effects.start_shake(4.0, 8.0)
                                audio.play("hit_heavy")
                        else:
                                effects.start_hitstop(0.06)
                                effects.start_shake(1.5, 6.0)
                                audio.play("hit_light")

                        hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, is_heavy)

                        var combo_info = warrior.get_attack_info()
                        var rage_gain: float = 5.0 * combo_info.get("damage_mult", 1.0)
                        if warrior.war_cry_buff:
                                rage_gain *= 1.2
                        warrior.rage = min(warrior.max_rage, warrior.rage + rage_gain)

        if not warrior.is_attacking or warrior.attack_phase != 1:  # 1 = ACTIVE
                if warrior.attack_phase == 2:  # 2 = RECOVERY
                        boss_hit_applied = false

        # === Boss攻击玩家 ===
        if boss.is_in_attack_state() and boss.is_attack_active() and not player_hit_applied:
                if dist < 85:
                        var dmg: float = boss.get_attack_damage()
                        var kb: Vector2 = boss.get_attack_knockback()
                        warrior.take_damage(dmg, kb)
                        if dmg > 0:
                                hud.spawn_damage_number(warrior.pos + Vector2(0, -40), dmg, dmg >= 25)

                                var hit_pos: Vector2 = (warrior.pos + boss.pos) / 2 + Vector2(0, -20)
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.3, 0.2))
                                effects.spawn_blood_splatter(hit_pos, boss.facing)

                                if dmg >= 25:
                                        effects.start_hitstop(0.12)
                                        effects.start_shake(6.0, 10.0)
                                        audio.play("hit_boss")
                                else:
                                        effects.start_hitstop(0.05)
                                        effects.start_shake(2.0, 7.0)
                                        audio.play("hurt")

                                player_hit_applied = true

        if not boss.is_attack_active():
                player_hit_applied = false

func _process_earth_shatter(delta: float) -> void:
        if warrior.current_anim == "earth_shatter" and not earth_shatter_active:
                earth_shatter_active = true
                earth_shatter_timer = 0.5
                earth_shatter_dealt = false
                effects.spawn_rage_burst(warrior.pos)
                effects.start_shake(5.0, 8.0)
                audio.play("earth_shatter")
                hud.show_perfect("EARTH SHATTER!", Color(1, 0.3, 0.1))

        if earth_shatter_active:
                earth_shatter_timer -= delta
                if earth_shatter_timer <= 0.3 and not earth_shatter_dealt:
                        earth_shatter_dealt = true
                        var dist = abs(warrior.pos.x - boss.pos.x)
                        if dist < 120:
                                var dmg: float = 60.0
                                if warrior.war_cry_buff:
                                        dmg *= warrior.war_cry_damage_mult
                                boss.take_damage(dmg)
                                hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, true)
                                effects.spawn_earth_shatter(warrior.pos, warrior.facing)
                                effects.start_hitstop(0.15)
                                effects.start_shake(8.0, 12.0)
                                audio.play("hit_boss")
                        else:
                                effects.spawn_earth_shatter(warrior.pos, warrior.facing)

                if earth_shatter_timer <= 0:
                        earth_shatter_active = false

        if warrior.current_anim == "war_cry" and frame_count % 8 == 0:
                effects.spawn_rage_burst(warrior.pos + Vector2(0, -30))

func _on_player_attack(_target: Node2D, _damage: float, _knockback: Vector2) -> void:
        pass

func _on_parry_success(is_perfect: bool) -> void:
        if is_perfect:
                hud.show_perfect("PERFECT PARRY!", Color(0.5, 0.8, 1.0))
                var parry_pos: Vector2 = warrior.pos + Vector2(15 * warrior.facing, -25)
                effects.spawn_parry_spark(parry_pos, true)
                effects.start_hitstop(0.08)
                effects.start_shake(2.0, 6.0)
                warrior.rage = min(warrior.max_rage, warrior.rage + 15)
                hud.update_rage(warrior.rage, warrior.max_rage)
                audio.play("parry_perfect")
        else:
                hud.show_perfect("PARRY!", Color(0.7, 0.9, 1.0))
                var parry_pos: Vector2 = warrior.pos + Vector2(15 * warrior.facing, -25)
                effects.spawn_parry_spark(parry_pos, false)
                effects.start_hitstop(0.04)
                audio.play("parry")

func _on_boss_phase_changed(phase: int) -> void:
        hud.update_boss_phase(phase)
        effects.start_slowmo(0.5, 0.3)
        effects.spawn_boss_enrage_aura(boss.pos)
        hud.show_perfect("ENRAGED!", Color(1, 0.2, 0.1))
        audio.play("boss_enrage")

func _on_boss_died() -> void:
        battle_active = false
        boss_victory = true
        GameState.mark_level_cleared("boss")
        hud.show_perfect("VICTORY! [R]RESTART", Color(1, 0.9, 0.2))
        effects.start_slowmo(1.0, 0.2)
        effects.start_shake(10.0, 3.0)
        audio.play("level_up")
        for i in range(3):
                effects.spawn_rage_burst(boss.pos + Vector2(randf_range(-30, 30), randf_range(-40, 0)))

func _on_boss_telegraph(attack_type: String, direction: float, duration: float) -> void:
        audio.play("telegraph", 0.5)

func _on_boss_attack_active(is_active: bool) -> void:
        if not is_active:
                hud.hide_telegraph()

func _on_player_died() -> void:
        battle_active = false
        player_dead = true
        respawn_timer = 1.5
        effects.start_slowmo(0.5, 0.3)
        hud.show_perfect("DEFEATED [R]RETRY", Color(0.5, 0.5, 0.5))
        audio.play("death")

func _respawn_player() -> void:
        player_dead = false
        warrior.hp = warrior.max_hp
        warrior.rage = 50.0
        warrior.pos = Vector2(150, GROUND_Y)
        warrior.vel = Vector2.ZERO
        warrior.is_hurt = false
        warrior.invincible_timer = 2.0
        warrior.is_attacking = false
        warrior.is_guarding = false
        warrior.hit_count = 0
        battle_active = true
        effects.time_scale = 1.0
        hud.update_player_hp(warrior.hp, warrior.max_hp)
        hud.update_rage(warrior.rage, warrior.max_rage)
        hud.show_perfect("FIGHT!", Color(1, 0.3, 0.1))
        audio.play("war_cry", 0.5)

func _restart_battle() -> void:
        warrior.hp = warrior.max_hp
        warrior.rage = 0.0
        warrior.pos = Vector2(150, GROUND_Y)
        warrior.vel = Vector2.ZERO
        warrior.is_hurt = false
        warrior.invincible_timer = 0
        warrior.is_attacking = false
        warrior.is_guarding = false
        warrior.hit_count = 0
        warrior.war_cry_buff = false

        boss.hp = boss.max_hp
        boss.pos = Vector2(480, GROUND_Y)
        boss.facing = -1.0
        boss.vel = Vector2.ZERO
        boss.is_stunned = false
        boss.phase = 1
        boss.super_armor = false
        boss.poise = boss.max_poise
        boss.change_state(0)  # IDLE

        battle_intro = true
        battle_active = false
        boss_victory = false
        player_dead = false
        intro_timer = 0.0
        frame_count = 0
        player_hit_applied = false
        boss_hit_applied = false
        earth_shatter_active = false

        effects.time_scale = 1.0

        hud.update_player_hp(warrior.hp, warrior.max_hp)
        hud.update_rage(warrior.rage, warrior.max_rage)
        hud.show_boss_hp("矿脉甲虫")
        hud.update_boss_hp(boss.hp, boss.max_hp)
        hud.clear_combo()

func _update_telegraph() -> void:
        var info: Dictionary = boss.get_telegraph_info()
        var warning_level: int = info.get("warning_level", 0)
        if warning_level > 0:
                hud.show_telegraph(info["type"], boss.pos, boss.facing, warning_level)
        else:
                hud.hide_telegraph()

func _update_hud() -> void:
        hud.update_player_hp(warrior.hp, warrior.max_hp)
        hud.update_rage(warrior.rage, warrior.max_rage)
        hud.update_hit_count(warrior.hit_count)

func _update_visuals() -> void:
        var shake = camera_offset

        player_sprite.position = warrior.pos + Vector2(0, -32) + shake
        player_sprite.flip_h = (warrior.facing < 0)

        if warrior.invincible_timer > 0:
                player_sprite.visible = int(frame_count / 3) % 2 == 0
        else:
                player_sprite.visible = true

        if warrior.war_cry_buff:
                if int(frame_count / 4) % 3 == 0:
                        player_sprite.modulate = Color(1.2, 1.0, 0.7)
                else:
                        player_sprite.modulate = Color(1, 1, 1)

        if warrior.is_guarding and warrior.is_perfect_parry_window:
                parry_indicator.visible = true
                parry_indicator.position = warrior.pos + Vector2(-10 * warrior.facing, -42) + shake
                parry_indicator.color = Color(0.5, 0.8, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
        else:
                parry_indicator.visible = false

        boss_sprite.position = boss.pos + Vector2(-16, -32) + shake
        boss_sprite.flip_h = (boss.facing < 0)

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img:
                img.save_png("/home/z/my-project/download/" + filename)
                print("Screenshot saved: " + filename)

# === 自动演示（仅服务器截图模式）===
func _run_demo() -> void:
        match frame_count:
                150:
                        warrior.vel.x = 220
                        warrior.facing = 1.0
                180:
                        warrior.do_attack("L")
                        audio.play("swing")
                210:
                        warrior.do_attack("L")
                        audio.play("swing")
                240:
                        warrior.do_attack("L")
                        audio.play("swing")
                270:
                        warrior.vel.x = 0
                300:
                        warrior.do_attack("H")
                        audio.play("swing")
                330:
                        warrior.do_attack("L")
                        audio.play("swing")
                360:
                        warrior.do_attack("H")
                        audio.play("swing")
                390:
                        warrior.rage = 100
                        hud.show_perfect("RAGE FULL!", Color(1, 0.7, 0.1))
                        effects.spawn_rage_burst(warrior.pos)
                        audio.play("war_cry", 0.7)
                410:
                        warrior.vel.x = 0
