## 远古熔岩龟 Boss 战 - Beta v0.19
## 失地产脉关底Boss战
## 特色：熔岩喷吐、龟壳旋转(霸体+硬直窗口)、熔岩雨(狂暴AOE)
## v0.14：视效升级（视差背景、地面贴图、环境装饰、玩家阴影、环境粒子）
extends Node2D

const GROUND_Y: float = 309.0

@export var auto_demo: bool = false
@export var auto_quit_frame: int = 0

# 子系统
var player: Node2D
var warrior: Node2D:
        get:
                return player
var boss: Node2D
var hud: Node2D
var effects: Node2D
var camera: Node2D
var audio: Node2D
var drop_system: Node2D
var skill_tree: Node2D
var equipment: Node2D
var crafting_system: Node2D
var game_over: Node2D
var pause_menu: CanvasLayer
var achievements: Node2D
var victory_ui: Node2D

# 视觉
var player_sprite: AnimatedSprite2D
var boss_sprite: AnimatedSprite2D
var player_shadow: TextureRect
var parry_indicator: ColorRect
var camera_offset: Vector2 = Vector2.ZERO

# 战斗状态
var battle_active: bool = false
var battle_intro: bool = true
var intro_timer: float = 0.0
var frame_count: int = 0
var player_hit_applied: bool = false
var boss_hit_applied: bool = false

# 刃风暴
var blade_storm_active: bool = false

# 熔岩弹
var lava_projectiles: Array = []

# 死亡/重生
var player_dead: bool = false
var respawn_timer: float = 0.0
var boss_victory: bool = false

# 跳跃音效
var was_on_ground: bool = true

# 输入消耗标志（防止按住键时反复触发）
var _tab_consumed: bool = false
var _e_consumed: bool = false
var _esc_consumed: bool = false
var _r_consumed: bool = false

# 地面熔岩池装饰
var lava_pool: ColorRect

func _ready() -> void:
        _build_scene()
        # 场景淡入效果
        var fade_in: ColorRect = ColorRect.new()
        fade_in.size = Vector2(640, 360)
        fade_in.color = Color(0, 0, 0, 1.0)
        fade_in.z_index = 200
        add_child(fade_in)
        # 渐隐动画
        var tween: Tween = create_tween()
        tween.tween_property(fade_in, "color:a", 0.0, 0.5)
        tween.tween_callback(fade_in.queue_free)

func _build_scene() -> void:
        # === 视差背景（远景熔岩）===
        var far_tex = load("res://assets/sprites/background/parallax_lava_far.png")
        if far_tex:
                var far_bg = TextureRect.new()
                far_bg.texture = far_tex
                far_bg.size = Vector2(640, 360)
                far_bg.stretch_mode = TextureRect.STRETCH_SCALE
                far_bg.modulate = Color(0.8, 0.5, 0.4, 0.5)
                add_child(far_bg)

        # 主背景
        var bg_tex = load("res://assets/sprites/background/lava_vein_640x360.png")
        if bg_tex:
                var bg = TextureRect.new()
                bg.texture = bg_tex
                bg.size = Vector2(640, 360)
                bg.stretch_mode = TextureRect.STRETCH_SCALE
                add_child(bg)
        else:
                var bg2 = ColorRect.new()
                bg2.size = Vector2(640, 360)
                bg2.color = Color(0.12, 0.05, 0.06, 1.0)
                add_child(bg2)

        # === 地面贴图（ground_lava_32.png tiles）===
        var ground_tile_tex = load("res://assets/sprites/tiles/ground_lava_32.png")
        var tile_count: int = 20  # 640 / 32 = 20
        if ground_tile_tex:
                for tx in range(tile_count):
                        var tile = TextureRect.new()
                        tile.texture = ground_tile_tex
                        tile.size = Vector2(32, 32)
                        tile.position = Vector2(tx * 32, 328)
                        tile.stretch_mode = TextureRect.STRETCH_SCALE
                        add_child(tile)
        else:
                # fallback
                var ground_top = ColorRect.new()
                ground_top.position = Vector2(0, 329)
                ground_top.size = Vector2(640, 2)
                ground_top.color = Color(0.4, 0.25, 0.15, 0.8)
                add_child(ground_top)
                var ground = ColorRect.new()
                ground.position = Vector2(0, 330)
                ground.size = Vector2(640, 30)
                ground.color = Color(0.18, 0.1, 0.08, 0.7)
                add_child(ground)

        # === 环境装饰 ===
        # 火炬 x4
        var torch_positions: Array = [Vector2(50, 290), Vector2(220, 290), Vector2(420, 290), Vector2(590, 290)]
        var torch_tex = load("res://assets/sprites/environment/torch_0.png")
        for tp in torch_positions:
                if torch_tex:
                        var torch_sprite = TextureRect.new()
                        torch_sprite.texture = torch_tex
                        torch_sprite.size = Vector2(16, 24)
                        torch_sprite.position = tp
                        torch_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        add_child(torch_sprite)
                else:
                        var torch_fallback = ColorRect.new()
                        torch_fallback.size = Vector2(6, 16)
                        torch_fallback.position = tp
                        torch_fallback.color = Color(0.7, 0.4, 0.1)
                        add_child(torch_fallback)
                # 火焰光晕
                var torch_glow = ColorRect.new()
                torch_glow.size = Vector2(24, 24)
                torch_glow.position = tp + Vector2(-4, -8)
                torch_glow.color = Color(1.0, 0.5, 0.15, 0.2)
                add_child(torch_glow)

        # 水晶 x3
        var crystal_positions: Array = [Vector2(150, 298), Vector2(350, 300), Vector2(520, 296)]
        var crystal_tex = load("res://assets/sprites/environment/crystal_cluster_0.png")
        for cp in crystal_positions:
                if crystal_tex:
                        var crystal_sprite = TextureRect.new()
                        crystal_sprite.texture = crystal_tex
                        crystal_sprite.size = Vector2(16, 20)
                        crystal_sprite.position = cp
                        crystal_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        crystal_sprite.modulate = Color(1.0, 0.6, 0.4, 0.9)
                        add_child(crystal_sprite)
                else:
                        var crystal_fallback = ColorRect.new()
                        crystal_fallback.size = Vector2(8, 14)
                        crystal_fallback.position = cp
                        crystal_fallback.color = Color(0.9, 0.4, 0.2, 0.8)
                        add_child(crystal_fallback)

        # 钟乳石 x3
        var stalactite_positions: Array = [Vector2(100, 0), Vector2(320, 0), Vector2(540, 0)]
        var stalactite_tex = load("res://assets/sprites/environment/stalactite_small.png")
        for sp in stalactite_positions:
                if stalactite_tex:
                        var stalactite_sprite = TextureRect.new()
                        stalactite_sprite.texture = stalactite_tex
                        stalactite_sprite.size = Vector2(12, 32)
                        stalactite_sprite.position = sp
                        stalactite_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        stalactite_sprite.modulate = Color(0.8, 0.5, 0.4, 0.7)
                        add_child(stalactite_sprite)
                else:
                        var stalactite_fallback = ColorRect.new()
                        stalactite_fallback.size = Vector2(6, 24)
                        stalactite_fallback.position = sp
                        stalactite_fallback.color = Color(0.5, 0.3, 0.25, 0.7)
                        add_child(stalactite_fallback)

        # 地面熔岩池（装饰+伤害区域）
        lava_pool = ColorRect.new()
        lava_pool.position = Vector2(250, 326)
        lava_pool.size = Vector2(140, 4)
        lava_pool.color = Color(0.9, 0.35, 0.05, 0.8)
        add_child(lava_pool)
        var lava_glow = ColorRect.new()
        lava_glow.position = Vector2(248, 324)
        lava_glow.size = Vector2(144, 8)
        lava_glow.color = Color(1.0, 0.5, 0.1, 0.3)
        add_child(lava_glow)

        # 摄像机
        var camera_script = load("res://scripts/core/camera_controller.gd")
        camera = Node2D.new()
        camera.set_script(camera_script)
        add_child(camera)
        camera.setup(Vector2(640, 360), Vector2.ZERO, Vector2(640, 360))
        camera.set_position_immediate(Vector2(320, 180))
        camera.activate()

        # 音效
        var audio_script = load("res://scripts/audio/audio_manager.gd")
        audio = Node2D.new()
        audio.set_script(audio_script)
        add_child(audio)

        # 打击感特效
        var effects_script = load("res://scripts/core/combat_effects.gd")
        effects = Node2D.new()
        effects.set_script(effects_script)
        add_child(effects)
        effects.setup_ambient("embers", 10)

        # === 玩家阴影 ===
        var shadow_tex = load("res://assets/sprites/common/shadow_ellipse.png")
        if shadow_tex:
                player_shadow = TextureRect.new()
                player_shadow.texture = shadow_tex
                player_shadow.size = Vector2(28, 8)
                player_shadow.stretch_mode = TextureRect.STRETCH_SCALE
                player_shadow.modulate = Color(1, 1, 1, 0.35)
                add_child(player_shadow)
        else:
                var shadow_fallback = ColorRect.new()
                shadow_fallback.size = Vector2(28, 8)
                shadow_fallback.color = Color(0, 0, 0, 0.2)
                add_child(shadow_fallback)

        # 玩家（双职业）
        var player_script: GDScript = null
        if GameState.is_ranger():
                player_script = load("res://scripts/player/ranger.gd")
        elif GameState.is_mage():
                player_script = load("res://scripts/player/mage.gd")
        else:
                player_script = load("res://scripts/player/warrior.gd")
        player = Node2D.new()
        player.set_script(player_script)
        add_child(player)

        player_sprite = AnimatedSprite2D.new()
        add_child(player_sprite)
        player.setup_sprite(player_sprite)
        player.pos = Vector2(150, GROUND_Y)

        var state = GameState.get_player_state()
        player.hp = state["hp"]
        player.rage = state["rage"]
        player.hit_count = state["hit_count"]
        # 游侠max_hp兼容
        if GameState.is_ranger() and state.has("max_hp"):
                player.max_hp = state["max_hp"]
        if GameState.is_mage() and state.has("max_hp"):
                player.max_hp = state["max_hp"]
        var equip_stats: Dictionary = GameState.get_equipment_stats()
        if equip_stats.get("max_hp_bonus", 0.0) > 0:
                player.max_hp += equip_stats["max_hp_bonus"]
                player.hp = min(player.hp, player.max_hp)

        parry_indicator = ColorRect.new()
        parry_indicator.size = Vector2(20, 20)
        parry_indicator.color = Color(0.5, 0.8, 1.0, 0.4)
        parry_indicator.visible = false
        add_child(parry_indicator)
        player.parry_indicator = parry_indicator

        # 远古熔岩龟 Boss
        var boss_script = load("res://scripts/enemy/boss_lava_turtle.gd")
        boss = Node2D.new()
        boss.set_script(boss_script)
        add_child(boss)

        boss_sprite = AnimatedSprite2D.new()
        add_child(boss_sprite)
        boss.setup(boss_sprite)
        boss.pos = Vector2(480, GROUND_Y)
        boss.facing = -1.0

        # HUD
        var hud_script = load("res://scripts/ui/hud.gd")
        hud = Node2D.new()
        hud.set_script(hud_script)
        add_child(hud)
        hud.build()

        # 连接信号
        player.attack_hit.connect(_on_player_attack)
        player.rage_changed.connect(func(v): hud.update_rage(v, 100))
        player.health_changed.connect(func(v): hud.update_player_hp(v, player.max_hp))
        player.parry_success.connect(_on_parry_success)
        player.died.connect(_on_player_died)
        if player.has_signal("slash_trail"):
                player.slash_trail.connect(_on_slash_trail)
        if GameState.is_ranger():
                player.dodge_success.connect(_on_dodge_success)
        boss.boss_health_changed.connect(func(h, m): hud.update_boss_hp(h, m))
        boss.boss_phase_changed.connect(_on_boss_phase_changed)
        boss.boss_died.connect(_on_boss_died)
        boss.boss_telegraph.connect(_on_boss_telegraph)
        boss.boss_attack_active.connect(_on_boss_attack_active)
        boss.boss_lava_spawn.connect(_on_boss_lava_spawn)

        # 掉落系统
        var drop_script = load("res://scripts/core/drop_system.gd")
        drop_system = Node2D.new()
        drop_system.set_script(drop_script)
        add_child(drop_system)
        drop_system.set_player(player)
        drop_system.set_hud(hud)
        drop_system.set_audio(audio)
        drop_system.set_pickup_counts(GameState.ore_fragments, GameState.health_potions, GameState.rage_crystals)

        # 技能树
        var skill_script = load("res://scripts/ui/skill_tree.gd")
        skill_tree = Node2D.new()
        skill_tree.set_script(skill_script)
        add_child(skill_tree)
        skill_tree.build()
        skill_tree.set_drop_system(drop_system)
        skill_tree.load_skill_data(GameState.skill_levels)

        # 装备系统
        var equip_script = load("res://scripts/ui/equipment.gd")
        equipment = Node2D.new()
        equipment.set_script(equip_script)
        add_child(equipment)
        equipment.build()
        equipment.set_drop_system(drop_system)

        # === 打造系统 ===
        var craft_script = load("res://scripts/core/crafting_system.gd")
        crafting_system = Node2D.new()
        crafting_system.set_script(craft_script)
        add_child(crafting_system)
        crafting_system.load_save_data(GameState.crafting_materials)
        crafting_system.set_ore_count(drop_system.ore_fragments)
        equipment.set_crafting_system(crafting_system)

        # === GameOver画面 ===
        var go_script = load("res://scripts/ui/game_over.gd")
        game_over = Node2D.new()
        game_over.set_script(go_script)
        add_child(game_over)
        game_over.retry_pressed.connect(_on_game_over_retry)
        game_over.quit_pressed.connect(_quit_to_title)

        # === 暂停菜单 ===
        var pause_script = load("res://scripts/ui/pause_menu.gd")
        pause_menu = CanvasLayer.new()
        pause_menu.set_script(pause_script)
        add_child(pause_menu)
        pause_menu.resume_pressed.connect(func(): pass)
        pause_menu.quit_pressed.connect(_quit_to_title)

        # === 成就系统 ===
        var ach_script = load("res://scripts/core/achievement_system.gd")
        achievements = Node2D.new()
        achievements.set_script(ach_script)
        add_child(achievements)

        # === Victory画面 ===
        var vic_script = load("res://scripts/ui/victory_screen.gd")
        victory_ui = Node2D.new()
        victory_ui.set_script(vic_script)
        add_child(victory_ui)
        victory_ui.continue_pressed.connect(_quit_to_title)

        # 版本号
        var ver = Label.new()
        ver.text = "v0.19"
        ver.position = Vector2(600, 350)
        ver.add_theme_font_size_override("font_size", 7)
        ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
        add_child(ver)

        # 关卡标题
        var level_title = Label.new()
        level_title.text = "失落地脉 - 熔岩龟"
        level_title.position = Vector2(220, 5)
        level_title.add_theme_font_size_override("font_size", 10)
        level_title.add_theme_color_override("font_color", Color(0.9, 0.4, 0.2, 0.8))
        add_child(level_title)

        # 操作提示
        var hint = Label.new()
        var guard_text: String = "L:魔盾" if GameState.is_mage() else ("L:闪避" if GameState.is_ranger() else "L:格挡")
        var skill1_text: String = "U:闪现" if GameState.is_mage() else ("U:影步" if GameState.is_ranger() else "U:战吼")
        var skill2_text: String = "I:暴风雪" if GameState.is_mage() else ("I:刃风暴" if GameState.is_ranger() else "I:裂地斩")
        hint.text = "A/D:移动 W/Space:跳跃 J:轻攻 K:重攻 " + guard_text + " " + skill1_text + " " + skill2_text + " Tab:技能树 E:装备 R:重来 Esc:主菜单"
        hint.position = Vector2(30, 350)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.7))
        add_child(hint)

func _physics_process(delta: float) -> void:
        frame_count += 1

        # GameOver画面处理
        if game_over and game_over.is_open:
                game_over.process_input(delta)
                if achievements: achievements.process_notifications(delta)
                return

        # 暂停菜单处理
        if pause_menu and pause_menu.is_open:
                pause_menu.process_input(delta)
                if achievements: achievements.process_notifications(delta)
                return

        # 成就通知处理
        if achievements: achievements.process_notifications(delta)

        # Victory画面处理
        if victory_ui and victory_ui.is_open:
                victory_ui.process_input(delta)
                return

        # 面板暂停
        if skill_tree and skill_tree.is_open:
                skill_tree.process_input()
                return
        if equipment and equipment.is_open:
                equipment.process_input(delta)
                return
        if Input.is_action_just_pressed("menu_tab"):
                if not _tab_consumed:
                        _tab_consumed = true
                        if skill_tree:
                                skill_tree.toggle()
                return
        else:
                _tab_consumed = false
        if Input.is_action_just_pressed("menu_equip"):
                if not _e_consumed:
                        _e_consumed = true
                        if equipment:
                                equipment.toggle()
                return
        else:
                _e_consumed = false
        if Input.is_action_just_pressed("menu_quit"):
                if not _esc_consumed:
                        _esc_consumed = true
                        _save_state()
                        if pause_menu:
                                pause_menu.open()
                return
        else:
                _esc_consumed = false

        # Hitstop
        if effects.hitstop_active:
                effects.process(delta)
                return

        camera_offset = effects.get_shake_offset()
        camera.apply_shake(camera_offset)

        if battle_intro:
                _process_intro(delta)
                camera.follow(player.pos, player.facing, delta)
                return

        # 死亡→GameOver画面
        if player_dead:
                respawn_timer -= delta
                if respawn_timer <= 0:
                        if game_over and not game_over.is_open:
                                var go_data: Dictionary = {
                                        "play_time": GameState.play_time,
                                        "total_kills": GameState.total_kills,
                                        "max_combo": player.hit_count,
                                        "total_damage": 0,
                                        "ore_fragments": drop_system.ore_fragments if drop_system else 0,
                                        "potions_used": 0,
                                }
                                game_over.open(go_data)
                                audio.play("death")
                effects.process(delta)
                camera.follow(player.pos, player.facing, delta)
                return

        # Boss胜利→Victory画面
        if boss_victory:
                effects.process(delta)
                camera.follow(player.pos, player.facing, delta)
                if victory_ui and not victory_ui.is_open:
                        var vic_data: Dictionary = {
                                "boss_name": "远古熔岩龟",
                                "play_time": GameState.play_time,
                                "total_kills": GameState.total_kills,
                                "ore_fragments": drop_system.ore_fragments if drop_system else 0,
                        }
                        victory_ui.open(vic_data)
                return

        if not battle_active:
                return

        effects.process(delta)
        player.process(delta, GROUND_Y)

        # 跳跃/落地
        var on_ground: bool = player.pos.y >= GROUND_Y - 3
        if not was_on_ground and on_ground:
                audio.play("land")
        was_on_ground = on_ground

        boss.process(delta, player.pos, GROUND_Y)

        # 碰撞检测
        _check_combat_collisions()

        # 熔岩池伤害
        _check_lava_pool(delta)

        # 熔岩弹
        _process_lava_projectiles(delta)

        # 裂地斩AOE
        _process_earth_shatter(delta)

        # 刃风暴AOE（游侠）
        _process_blade_storm(delta)

        # 更新
        _update_visuals()
        _update_hud()
        camera.follow(player.pos, player.facing, delta)
        drop_system.process(delta)
        _save_state()

        # 连招
        if player.combo_timer <= 0 and not player.is_attacking:
                hud.clear_combo()
        if player.is_attacking and player.attack_name != "":
                var info = player.get_attack_info()
                hud.show_combo(player.attack_name, info.get("war_cry_active", false))

        # 预警
        _update_telegraph()
        hud.show_war_cry_buff(player.war_cry_buff, player.war_cry_timer)

        # Boss狂暴定期火焰
        if boss.phase == 2 and boss.hp > 0 and frame_count % 25 == 0:
                effects.spawn_boss_enrage_aura(boss.pos)
                audio.play("boss_enrage", 0.5)

        hud.process_effects(delta)

        # 自动演示
        if auto_demo:
                _run_demo()
        if auto_quit_frame > 0 and frame_count >= auto_quit_frame:
                get_tree().quit()

func _process_intro(delta: float) -> void:
        intro_timer += delta
        boss_sprite.play("idle")
        boss_sprite.position = boss.pos + Vector2(-32, -32) + camera_offset
        boss_sprite.flip_h = (boss.facing < 0)

        player_sprite.play("idle")
        player_sprite.position = player.pos + Vector2(-24, -64) + camera_offset

        hud.show_boss_hp("远古熔岩龟")
        hud.update_boss_hp(boss.hp, boss.max_hp)
        hud.update_player_hp(player.hp, player.max_hp)

        if intro_timer > 2.0:
                battle_intro = false
                battle_active = true
                hud.show_perfect("FIGHT!", Color(1, 0.4, 0.1))
                audio.play("war_cry", 0.7)

func _check_combat_collisions() -> void:
        var dist = abs(player.pos.x - boss.pos.x)

        # 玩家攻击Boss
        if player.is_in_active_frames() and not boss_hit_applied:
                if dist < 100:
                        var base_dmg: float = player.get_attack_damage()
                        var dmg: float = base_dmg * (skill_tree.get_attack_bonus() if skill_tree else 1.0) * (equipment.get_attack_bonus() if equipment else 1.0)
                        boss.take_damage(dmg)
                        player.mark_hit_dealt()
                        boss_hit_applied = true

                        var hit_pos: Vector2 = (player.pos + boss.pos) / 2 + Vector2(0, -20)
                        # v0.19: 根据攻击类型/连击步骤差异化视觉反馈
                        var is_finisher: bool = player.is_combo_finisher if player.has_method("get") else false
                        var is_heavy: bool = player.is_heavy_attack if player.has_method("get") else dmg >= 20
                        var combo_step: int = player.current_combo_step if player.has_method("get") else 0

                        if is_finisher:
                                effects.spawn_hit_spark(hit_pos, Color(0.8, 0.5, 1.0))
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.9, 1.0))
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.15); effects.start_shake(7.0, 6.0)
                                effects.start_flash(0.1, Color(0.8, 0.5, 1.0))
                                audio.play("hit_heavy")
                        elif is_heavy:
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.4, 0.15))
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.8, 0.3))
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.12); effects.start_shake(5.0, 7.0)
                                effects.start_flash(0.06, Color(1, 0.5, 0.2))
                                audio.play("hit_heavy")
                        elif combo_step >= 3:
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.85, 0.3))
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.09); effects.start_shake(3.0, 6.0)
                                audio.play("hit_light")
                        elif combo_step >= 2:
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.95, 0.6))
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.07); effects.start_shake(2.0, 6.0)
                                audio.play("hit_light")
                        else:
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.95, 0.8))
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.05); effects.start_shake(1.5, 6.0)
                                audio.play("hit_light")

                        hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, is_heavy or is_finisher)
                        var combo_info = player.get_attack_info()
                        var rage_gain: float = 5.0 * combo_info.get("damage_mult", 1.0) * (skill_tree.get_rage_bonus() if skill_tree else 1.0)
                        player.rage = min(player.max_rage, player.rage + rage_gain)

        if not player.is_attacking or player.attack_phase != player.AttackPhase.ACTIVE:
                if player.attack_phase == player.AttackPhase.RECOVERY:
                        boss_hit_applied = false

        # Boss攻击玩家
        if boss.is_in_attack_state() and boss.is_attack_active() and not player_hit_applied:
                if dist < 95:
                        var base_dmg: float = boss.get_attack_damage()
                        var dmg: float = base_dmg * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        var kb: Vector2 = boss.get_attack_knockback()
                        player.take_damage(dmg, kb)
                        if dmg > 0:
                                hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, dmg >= 25)
                                var hit_pos: Vector2 = (player.pos + boss.pos) / 2 + Vector2(0, -20)
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.3, 0.2))

                                if dmg >= 25:
                                        effects.start_hitstop(0.12); effects.start_shake(6.0, 10.0); audio.play("hit_boss")
                                else:
                                        effects.start_hitstop(0.05); effects.start_shake(2.0, 7.0); audio.play("hurt")

                                player_hit_applied = true

        if not boss.is_attack_active():
                player_hit_applied = false

func _check_lava_pool(delta: float) -> void:
        """地面熔岩池伤害"""
        if player.pos.y >= GROUND_Y - 5 and player.invincible_timer <= 0:
                if player.pos.x >= 250 and player.pos.x <= 390:
                        var dmg: float = 5.0 * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        player.take_damage(dmg, Vector2(randf_range(-2, 2), -3))
                        hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                        hud.show_perfect("LAVA!", Color(1, 0.4, 0.1))
                        audio.play("hurt", 0.4)

        # 熔岩池闪烁
        if lava_pool and is_instance_valid(lava_pool):
                var intensity: float = 0.6 + 0.4 * sin(frame_count * 0.05)
                lava_pool.color = Color(0.9 * intensity, 0.35 * intensity, 0.05, 0.8)

func _process_earth_shatter(delta: float) -> void:
        if player.current_anim == "earth_shatter" and not get("earth_shatter_active"):
                set_meta("earth_shatter_active", true)
                set_meta("earth_shatter_timer", 0.5)
                set_meta("earth_shatter_dealt", false)
                effects.spawn_rage_burst(player.pos)
                effects.start_shake(5.0, 8.0)
                audio.play("earth_shatter")
                hud.show_perfect("EARTH SHATTER!", Color(1, 0.3, 0.1))

        if get_meta("earth_shatter_active", false):
                var es_timer: float = get_meta("earth_shatter_timer", 0.0)
                es_timer -= delta
                set_meta("earth_shatter_timer", es_timer)
                if es_timer <= 0.3 and not get_meta("earth_shatter_dealt", false):
                        set_meta("earth_shatter_dealt", true)
                        var dist = abs(player.pos.x - boss.pos.x)
                        if dist < 120:
                                var dmg: float = 60.0 * (equipment.get_attack_bonus() if equipment else 1.0)
                                if player.war_cry_buff:
                                        dmg *= player.war_cry_damage_mult
                                boss.take_damage(dmg)
                                hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, true)
                                effects.spawn_earth_shatter(player.pos, player.facing)
                                effects.start_hitstop(0.15); effects.start_shake(8.0, 12.0); audio.play("hit_boss")
                        else:
                                effects.spawn_earth_shatter(player.pos, player.facing)

                if es_timer <= 0:
                        set_meta("earth_shatter_active", false)

func _process_lava_projectiles(delta: float) -> void:
        for i in range(lava_projectiles.size() - 1, -1, -1):
                var proj: Dictionary = lava_projectiles[i]
                if proj["node"] == null or not is_instance_valid(proj["node"]):
                        lava_projectiles.remove_at(i)
                        continue

                proj["lifetime"] -= delta
                if proj["lifetime"] <= 0:
                        proj["node"].queue_free()
                        lava_projectiles.remove_at(i)
                        continue

                proj["vel"].y += 500 * delta
                proj["pos"] += proj["vel"] * delta
                proj["node"].position = proj["pos"]

                # 落地
                if proj["pos"].y >= GROUND_Y - 5:
                        var dist: float = abs(player.pos.x - proj["pos"].x)
                        if dist < 40 and player.invincible_timer <= 0:
                                var dmg: float = 10.0 * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                                player.take_damage(dmg, Vector2(randf_range(-3, 3), -4))
                                hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                                audio.play("hurt", 0.5)
                        effects.spawn_hit_spark(proj["pos"], Color(1.0, 0.5, 0.1))
                        effects.start_shake(1.5, 6.0)
                        audio.play("rock_fall", 0.3)
                        proj["node"].queue_free()
                        lava_projectiles.remove_at(i)
                        continue

                # 飞行中碰撞
                var dist: float = abs(player.pos.x - proj["pos"].x)
                var dist_y: float = abs(player.pos.y - 30 - proj["pos"].y)
                if dist < 25 and dist_y < 30 and player.invincible_timer <= 0:
                        var dmg: float = 12.0 * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        player.take_damage(dmg, Vector2(randf_range(-3, 3), -4))
                        hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, true)
                        effects.spawn_hit_spark(proj["pos"], Color(1.0, 0.5, 0.1))
                        audio.play("hurt")
                        proj["node"].queue_free()
                        lava_projectiles.remove_at(i)

func _on_boss_lava_spawn(spawn_pos: Vector2, vel: Vector2) -> void:
        """Boss熔岩弹信号"""
        var node = Node2D.new()
        add_child(node)

        var body = ColorRect.new()
        body.size = Vector2(10, 10)
        body.position = Vector2(-5, -5)
        body.color = Color(1.0, 0.5, 0.1, 0.9)
        node.add_child(body)

        var glow = ColorRect.new()
        glow.size = Vector2(14, 14)
        glow.position = Vector2(-7, -7)
        glow.color = Color(1.0, 0.3, 0.0, 0.4)
        node.add_child(glow)

        node.position = spawn_pos

        lava_projectiles.append({
                "pos": spawn_pos,
                "vel": vel,
                "node": node,
                "lifetime": 4.0,
        })

func _on_player_attack(_target: Node2D, _damage: float, _knockback: Vector2) -> void: pass

func _on_slash_trail(trail_type: String, trail_pos: Vector2, trail_facing: float) -> void:
        var combo_step: int = player.current_combo_step if player.has_method("get") else 1
        effects.spawn_slash_arc(trail_pos, trail_facing, trail_type, combo_step)
        audio.play("swing")

func _process_blade_storm(delta: float) -> void:
        # Ranger刃风暴AOE
        if GameState.is_ranger() and player.blade_storm_active:
                if not blade_storm_active:
                        blade_storm_active = true
                        hud.show_perfect("BLADE STORM!", Color(0.6, 0.3, 1.0))
                        effects.spawn_rage_burst(player.pos)
                        effects.start_shake(6.0, 8.0)
                        audio.play("earth_shatter")  # reuse sound
                if player.blade_storm_hit_timer <= 0.0:
                        var dist = abs(player.pos.x - boss.pos.x)
                        if dist < 120:
                                var bs_dmg: float = 8.0
                                if player.shadow_step_buff:
                                        bs_dmg *= player.shadow_step_damage_mult
                                boss.take_damage(bs_dmg)
                                hud.spawn_damage_number(boss.pos + Vector2(0, -40), bs_dmg, false)
                                effects.spawn_hit_spark((player.pos + boss.pos) / 2 + Vector2(0, -20), Color(0.6, 0.3, 1.0))
                                effects.start_hitstop(0.02)
                                effects.start_shake(2.0, 4.0)
        else:
                blade_storm_active = false

func _on_dodge_success(is_perfect: bool) -> void:
        if is_perfect:
                hud.show_perfect("PERFECT DODGE!", Color(0.6, 0.3, 1.0))
                var dodge_pos: Vector2 = player.pos + Vector2(15 * player.facing, -25)
                effects.spawn_parry_spark(dodge_pos, true)
                effects.start_hitstop(0.08)
                effects.start_shake(2.0, 6.0)
                audio.play("parry_perfect")
        else:
                hud.show_perfect("DODGE!", Color(0.4, 0.7, 0.9))
                audio.play("parry")

func _on_parry_success(is_perfect: bool) -> void:
        if GameState.is_ranger():
                if is_perfect:
                        hud.show_perfect("PERFECT DODGE!", Color(0.6, 0.3, 1.0))
                        var dodge_pos: Vector2 = player.pos + Vector2(15 * player.facing, -25)
                        effects.spawn_parry_spark(dodge_pos, true)
                        effects.start_hitstop(0.08); effects.start_shake(2.0, 6.0)
                        audio.play("parry_perfect")
                else:
                        hud.show_perfect("DODGE!", Color(0.4, 0.7, 0.9))
                        audio.play("parry")
        else:
                if is_perfect:
                        hud.show_perfect("PERFECT PARRY!", Color(0.5, 0.8, 1.0))
                        var parry_pos: Vector2 = player.pos + Vector2(15 * player.facing, -25)
                        effects.spawn_parry_spark(parry_pos, true)
                        effects.start_hitstop(0.08); effects.start_shake(2.0, 6.0)
                        player.rage = min(player.max_rage, player.rage + 15)
                        hud.update_rage(player.rage, player.max_rage)
                        audio.play("parry_perfect")
                else:
                        hud.show_perfect("PARRY!", Color(0.7, 0.9, 1.0))
                        var parry_pos: Vector2 = player.pos + Vector2(15 * player.facing, -25)
                        effects.spawn_parry_spark(parry_pos, false)
                        effects.start_hitstop(0.04)
                        audio.play("parry")

func _on_boss_phase_changed(phase: int) -> void:
        hud.update_boss_phase(phase)
        effects.start_slowmo(0.5, 0.3)
        effects.spawn_boss_enrage_aura(boss.pos)
        hud.show_perfect("LAVA ENRAGED!", Color(1, 0.2, 0.1))
        audio.play("boss_enrage")

func _on_boss_died() -> void:
        battle_active = false
        boss_victory = true
        GameState.mark_level_cleared("lava_boss")
        hud.show_perfect("VICTORY! [R]RESTART", Color(1, 0.9, 0.2))
        effects.start_slowmo(1.0, 0.2)
        effects.start_shake(10.0, 3.0)
        audio.play("level_up")
        for i in range(3):
                effects.spawn_rage_burst(boss.pos + Vector2(randf_range(-40, 40), randf_range(-50, 0)))
        drop_system.spawn_drop(boss.pos, "boss", GROUND_Y)
        # v0.12: Boss掉落打造材料（熔岩核心x2）
        GameState.crafting_materials["lava_core"] = int(GameState.crafting_materials.get("lava_core", 0)) + 2
        hud.show_perfect("+2 熔岩核心!", Color(1.0, 0.4, 0.1))
        # 清理刃风暴状态
        blade_storm_active = false

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
        player.hp = player.max_hp
        player.rage = 50.0
        player.pos = Vector2(150, GROUND_Y)
        player.vel = Vector2.ZERO
        player.is_hurt = false
        player.invincible_timer = 2.0
        player.is_attacking = false
        player.is_guarding = false
        player.hit_count = 0
        battle_active = true
        effects.time_scale = 1.0
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        hud.show_perfect("FIGHT!", Color(1, 0.4, 0.1))
        audio.play("war_cry", 0.5)

func _restart_battle() -> void:
        player.hp = player.max_hp
        player.rage = 0.0
        player.pos = Vector2(150, GROUND_Y)
        player.vel = Vector2.ZERO
        player.is_hurt = false
        player.invincible_timer = 0
        player.is_attacking = false
        player.is_guarding = false
        player.hit_count = 0
        player.war_cry_buff = false

        boss.hp = boss.max_hp
        boss.pos = Vector2(480, GROUND_Y)
        boss.facing = -1.0
        boss.vel = Vector2.ZERO
        boss.is_stunned = false
        boss.is_spinning = false
        boss.phase = 1
        boss.super_armor = false
        boss.poise = boss.max_poise
        boss.change_state(boss.State.IDLE)

        battle_intro = true
        battle_active = false
        boss_victory = false
        player_dead = false
        intro_timer = 0.0
        frame_count = 0
        player_hit_applied = false
        boss_hit_applied = false
        blade_storm_active = false

        # 清理熔岩弹
        for proj in lava_projectiles:
                if proj["node"] and is_instance_valid(proj["node"]):
                        proj["node"].queue_free()
        lava_projectiles.clear()

        crafting_system.load_save_data(GameState.crafting_materials)
        crafting_system.set_ore_count(drop_system.ore_fragments)
        equipment.set_crafting_system(crafting_system)

        effects.time_scale = 1.0
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        hud.show_boss_hp("远古熔岩龟")
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
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        hud.update_hit_count(player.hit_count)

func _update_visuals() -> void:
        var shake = camera_offset

        # 更新玩家阴影位置
        if player_shadow:
                player_shadow.position = Vector2(player.pos.x - 14, GROUND_Y - 2) + shake

        player_sprite.position = player.pos + Vector2(-24, -64) + shake
        player_sprite.flip_h = (player.facing < 0)

        if player.invincible_timer > 0:
                player_sprite.visible = int(frame_count / 3) % 2 == 0
        else:
                player_sprite.visible = true

        if player.war_cry_buff:
                if int(frame_count / 4) % 3 == 0:
                        player_sprite.modulate = Color(1.2, 1.0, 0.7)
                else:
                        player_sprite.modulate = Color(1, 1, 1)

        if player.is_guarding and player.is_perfect_parry_window:
                parry_indicator.visible = true
                parry_indicator.position = player.pos + Vector2(-10 * player.facing, -42) + shake
                parry_indicator.color = Color(0.5, 0.8, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
        elif GameState.is_ranger() and player.is_dodging and player.is_perfect_dodge_window:
                parry_indicator.visible = true
                parry_indicator.position = player.pos + Vector2(-10 * player.facing, -42) + shake
                parry_indicator.color = Color(0.6, 0.3, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
        else:
                parry_indicator.visible = false

        boss_sprite.position = boss.pos + Vector2(-32, -32) + shake
        boss_sprite.flip_h = (boss.facing < 0)

func _save_state() -> void:
        GameState.save_player_state(player.hp, player.rage, player.hit_count)
        GameState.save_resources(drop_system.ore_fragments, skill_tree.get_skill_data() if skill_tree else {})
        var pickup_counts: Dictionary = drop_system.get_pickup_counts()
        GameState.save_pickup_counts(pickup_counts["ore_fragments"], pickup_counts["health_potions"], pickup_counts["rage_crystals"])
        GameState.save_crafting_materials(crafting_system.get_save_data())

func _quit_to_title() -> void:
        _save_state()
        GameState.go_to_title()

func _on_game_over_retry() -> void:
        player_dead = false
        player.hp = player.max_hp
        player.rage = 50.0
        player.pos = Vector2(150, GROUND_Y)
        player.vel = Vector2.ZERO
        player.is_hurt = false
        player.invincible_timer = 2.0
        player.is_attacking = false
        player.is_guarding = false
        player.hit_count = 0
        battle_active = true
        if effects: effects.time_scale = 1.0
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        hud.show_perfect("FIGHT!", Color(1, 0.4, 0.1))
        if audio: audio.play("war_cry", 0.5)

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img:
                img.save_png("/home/z/my-project/download/" + filename)

func _run_demo() -> void:
        match frame_count:
                150:
                        player.vel.x = 220; player.facing = 1.0
                180:
                        player.do_attack("L"); audio.play("swing")
                270:
                        player.vel.x = 0
