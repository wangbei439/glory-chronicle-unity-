## 幽影矿井 Boss 战 - Beta v0.19
## 矿脉甲虫 vs 战士/游侠/法师 完整战斗
## v0.19: GameOver/Victory/Pause/成就系统集成
extends Node2D

const GROUND_Y: float = 309.0

# === 自动演示模式（服务器截图用，玩家下载后默认关闭）===
@export var auto_demo: bool = false
@export var auto_quit_frame: int = 0  # 0=不自动退出

# 子系统
var player: Node2D
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
var victory_ui: Node2D
var pause_menu: CanvasLayer
var achievements: Node2D

# 战斗统计
var battle_start_time: float = 0.0
var battle_damage_taken: float = 0.0
var battle_max_combo: int = 0
var battle_kills: int = 0

# 兼容别名
var warrior: Node2D:
        get:
                return player

# 视觉节点
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

# 地震斩
var earth_shatter_active: bool = false
var earth_shatter_timer: float = 0.0
var earth_shatter_dealt: bool = false

# 刃风暴
var blade_storm_active: bool = false

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
        # === 视差背景（远景）===
        var far_tex = load("res://assets/sprites/background/parallax_mine_far.png")
        if far_tex:
                var far_bg = TextureRect.new()
                far_bg.texture = far_tex
                far_bg.size = Vector2(640, 360)
                far_bg.stretch_mode = TextureRect.STRETCH_SCALE
                far_bg.modulate = Color(0.6, 0.6, 0.7, 0.5)
                add_child(far_bg)

        # === 视差背景（中景）===
        var mid_tex = load("res://assets/sprites/background/parallax_mine_mid.png")
        if mid_tex:
                var mid_bg = TextureRect.new()
                mid_bg.texture = mid_tex
                mid_bg.size = Vector2(640, 360)
                mid_bg.stretch_mode = TextureRect.STRETCH_SCALE
                mid_bg.modulate = Color(0.8, 0.8, 0.85, 0.7)
                add_child(mid_bg)

        # 主背景
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

        # === 地面贴图（ground_stone_32.png tiles）===
        var ground_tile_tex = load("res://assets/sprites/tiles/ground_stone_32.png")
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
                ground_top.color = Color(0.35, 0.4, 0.45, 0.8)
                add_child(ground_top)
                var ground = ColorRect.new()
                ground.position = Vector2(0, 330)
                ground.size = Vector2(640, 30)
                ground.color = Color(0.15, 0.17, 0.2, 0.6)
                add_child(ground)

        # === 环境装饰 ===
        # 火炬 x4（竞技场四周）
        var torch_positions: Array = [Vector2(40, 290), Vector2(200, 290), Vector2(440, 290), Vector2(600, 290)]
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
                torch_glow.color = Color(1.0, 0.7, 0.2, 0.15)
                add_child(torch_glow)

        # 钟乳石 x2
        var stalactite_positions: Array = [Vector2(160, 0), Vector2(480, 0)]
        var stalactite_tex = load("res://assets/sprites/environment/stalactite_small.png")
        for sp in stalactite_positions:
                if stalactite_tex:
                        var stalactite_sprite = TextureRect.new()
                        stalactite_sprite.texture = stalactite_tex
                        stalactite_sprite.size = Vector2(12, 32)
                        stalactite_sprite.position = sp
                        stalactite_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        add_child(stalactite_sprite)
                else:
                        var stalactite_fallback = ColorRect.new()
                        stalactite_fallback.size = Vector2(6, 24)
                        stalactite_fallback.position = sp
                        stalactite_fallback.color = Color(0.4, 0.38, 0.45, 0.7)
                        add_child(stalactite_fallback)

        # 水晶 x2
        var crystal_positions: Array = [Vector2(300, 298), Vector2(500, 300)]
        var crystal_tex = load("res://assets/sprites/environment/crystal_cluster_0.png")
        for cp in crystal_positions:
                if crystal_tex:
                        var crystal_sprite = TextureRect.new()
                        crystal_sprite.texture = crystal_tex
                        crystal_sprite.size = Vector2(16, 20)
                        crystal_sprite.position = cp
                        crystal_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        add_child(crystal_sprite)
                else:
                        var crystal_fallback = ColorRect.new()
                        crystal_fallback.size = Vector2(8, 14)
                        crystal_fallback.position = cp
                        crystal_fallback.color = Color(0.3, 0.6, 0.9, 0.8)
                        add_child(crystal_fallback)

        # 蛛网 x3
        var cobweb_positions: Array = [Vector2(10, 40), Vector2(580, 30), Vector2(300, 20)]
        var cobweb_tex = load("res://assets/sprites/environment/cobweb.png")
        for cwp in cobweb_positions:
                if cobweb_tex:
                        var cobweb_sprite = TextureRect.new()
                        cobweb_sprite.texture = cobweb_tex
                        cobweb_sprite.size = Vector2(28, 28)
                        cobweb_sprite.position = cwp
                        cobweb_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        cobweb_sprite.modulate = Color(1, 1, 1, 0.5)
                        add_child(cobweb_sprite)
                else:
                        var cobweb_fallback = ColorRect.new()
                        cobweb_fallback.size = Vector2(20, 20)
                        cobweb_fallback.position = cwp
                        cobweb_fallback.color = Color(0.5, 0.5, 0.5, 0.2)
                        add_child(cobweb_fallback)

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
        effects.setup_ambient("dust", 8)

        # === 玩家阴影 ===
        var shadow_tex = load("res://assets/sprites/common/shadow_ellipse.png")
        if shadow_tex:
                player_shadow = TextureRect.new()
                player_shadow.texture = shadow_tex
                player_shadow.size = Vector2(28, 8)
                player_shadow.stretch_mode = TextureRect.STRETCH_SCALE
                player_shadow.modulate = Color(1, 1, 1, 0.4)
                add_child(player_shadow)
        else:
                var shadow_fallback = ColorRect.new()
                shadow_fallback.size = Vector2(28, 8)
                shadow_fallback.color = Color(0, 0, 0, 0.25)
                add_child(shadow_fallback)

        # === 玩家（根据职业选择创建）===
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

        # 从全局状态恢复
        var state = GameState.get_player_state()
        player.hp = state["hp"]
        player.rage = state["rage"]
        player.hit_count = state["hit_count"]
        if GameState.is_ranger():
                player.hp = min(player.hp, 80.0)  # Ranger max HP is 80
        if GameState.is_mage() and state.has("max_hp"):
                player.max_hp = state["max_hp"]

        parry_indicator = ColorRect.new()
        parry_indicator.size = Vector2(20, 20)
        parry_indicator.color = Color(0.5, 0.8, 1.0, 0.4)
        parry_indicator.visible = false
        add_child(parry_indicator)
        player.parry_indicator = parry_indicator

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
        player.attack_hit.connect(_on_player_attack)
        player.rage_changed.connect(func(v): hud.update_rage(v, 100))
        player.health_changed.connect(func(v): hud.update_player_hp(v, 100))
        player.parry_success.connect(_on_parry_success)
        player.died.connect(_on_player_died)
        # 斩击弧线特效
        if player.has_signal("slash_trail"):
                player.slash_trail.connect(_on_slash_trail)
        # Ranger-specific signal
        if GameState.is_ranger():
                if player.has_signal("dodge_success"):
                        player.dodge_success.connect(_on_parry_success)
        boss.boss_health_changed.connect(func(h, m): hud.update_boss_hp(h, m))
        boss.boss_phase_changed.connect(_on_boss_phase_changed)
        boss.boss_died.connect(_on_boss_died)
        boss.boss_telegraph.connect(_on_boss_telegraph)
        boss.boss_attack_active.connect(_on_boss_attack_active)

        # === 掉落系统 ===
        var drop_script = load("res://scripts/core/drop_system.gd")
        drop_system = Node2D.new()
        drop_system.set_script(drop_script)
        add_child(drop_system)
        drop_system.set_player(player)
        drop_system.set_hud(hud)
        drop_system.set_audio(audio)
        drop_system.ore_fragments = GameState.ore_fragments

        # === 技能树 ===
        var skill_script = load("res://scripts/ui/skill_tree.gd")
        skill_tree = Node2D.new()
        skill_tree.set_script(skill_script)
        add_child(skill_tree)
        skill_tree.build()
        skill_tree.set_drop_system(drop_system)
        skill_tree.load_skill_data(GameState.skill_levels)

        # === 装备系统 ===
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
        game_over.retry_pressed.connect(_respawn_player)
        game_over.quit_pressed.connect(_quit_to_title)

        # === 胜利画面 ===
        var vic_script = load("res://scripts/ui/victory_screen.gd")
        victory_ui = Node2D.new()
        victory_ui.set_script(vic_script)
        add_child(victory_ui)
        victory_ui.continue_pressed.connect(_restart_battle)

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

        # 版本号
        var ver = Label.new()
        ver.text = "v0.19"
        ver.position = Vector2(600, 350)
        ver.add_theme_font_size_override("font_size", 7)
        ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
        add_child(ver)

        # 操作提示
        var guard_text: String = "L:魔盾" if GameState.is_mage() else ("L:闪避" if GameState.is_ranger() else "L:格挡")
        var skill1_text: String = "U:闪现" if GameState.is_mage() else ("U:影步" if GameState.is_ranger() else "U:战吼")
        var skill2_text: String = "I:暴风雪" if GameState.is_mage() else ("I:刃风暴" if GameState.is_ranger() else "I:裂地斩")
        var hint = Label.new()
        hint.text = "A/D:移动 W/Space:跳跃 J:轻攻 K:重攻 " + guard_text + " " + skill1_text + " " + skill2_text + " Tab:技能树 E:装备 R:重来 Esc:主菜单"
        hint.position = Vector2(50, 350)
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

        # GameOver画面处理
        if game_over and game_over.is_open:
                game_over.process_input(delta)
                achievements.process_notifications(delta)
                return

        # 胜利画面处理
        if victory_ui and victory_ui.is_open:
                victory_ui.process_input(delta)
                achievements.process_notifications(delta)
                return

        # 暂停菜单处理
        if pause_menu and pause_menu.is_open:
                pause_menu.process_input(delta)
                achievements.process_notifications(delta)
                return

        # 成就通知处理
        achievements.process_notifications(delta)

        # 技能树打开时暂停游戏
        if skill_tree and skill_tree.is_open:
                skill_tree.process_input()
                return

        # Tab键打开技能树/装备(Shift+Tab物品栏)
        if Input.is_action_just_pressed("menu_tab"):
                if not _tab_consumed:
                        _tab_consumed = true
                        if Input.is_action_pressed("menu_shift"):
                                pass  # Shift+Tab 暂无物品栏在此场景
                        else:
                                if skill_tree:
                                        skill_tree.toggle()
                return
        else:
                _tab_consumed = false

        # E键打开装备
        if Input.is_action_just_pressed("menu_equip"):
                if not _e_consumed:
                        _e_consumed = true
                        if equipment:
                                equipment.toggle()
                return
        else:
                _e_consumed = false

        # 装备面板打开时暂停
        if equipment and equipment.is_open:
                equipment.process_input(delta)
                return

        # Esc暂停菜单
        if Input.is_action_just_pressed("menu_quit"):
                if not _esc_consumed:
                        _esc_consumed = true
                        _save_state()
                        if pause_menu:
                                pause_menu.open()
                return
        else:
                _esc_consumed = false

        # Hitstop：顿帧期间只处理特效
        if effects.hitstop_active:
                effects.process(delta)
                return

        # 应用震屏偏移
        camera_offset = effects.get_shake_offset()
        camera.apply_shake(camera_offset)

        if battle_intro:
                _process_intro(delta)
                camera.follow(player.pos, player.facing, delta)
                return

        # === 死亡等待GameOver画面 ===
        if player_dead:
                respawn_timer -= delta
                effects.process(delta)
                camera.follow(player.pos, player.facing, delta)
                return

        # === Boss胜利等待Victory画面 ===
        if boss_victory:
                effects.process(delta)
                camera.follow(player.pos, player.facing, delta)
                return

        if not battle_active:
                return

        # 处理特效系统
        effects.process(delta)

        # 处理玩家
        player.process(delta, GROUND_Y)

        # 跳跃/落地音效
        var on_ground: bool = player.pos.y >= GROUND_Y - 3
        if not was_on_ground and on_ground:
                audio.play("land")
        was_on_ground = on_ground

        # 处理Boss
        boss.process(delta, player.pos, GROUND_Y)

        # 碰撞检测
        _check_combat_collisions()

        # 裂地斩AOE
        _process_earth_shatter(delta)

        # 刃风暴AOE（游侠）
        _process_blade_storm(delta)

        # 更新视觉
        _update_visuals()

        # 更新HUD
        _update_hud()

        # 更新摄像机
        camera.follow(player.pos, player.facing, delta)

        # 掉落物
        drop_system.process(delta)

        # 保存全局状态
        _save_state()

        # 连招超时
        if player.combo_timer <= 0 and not player.is_attacking:
                hud.clear_combo()

        # 攻击状态显示
        if player.is_attacking and player.attack_name != "":
                var info = player.get_attack_info()
                hud.show_combo(player.attack_name, info.get("war_cry_active", false))

        # 预警显示
        _update_telegraph()

        # 战吼buff显示
        hud.show_war_cry_buff(player.war_cry_buff, player.war_cry_timer)

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
        player_sprite.position = player.pos + Vector2(-24, -64) + camera_offset

        hud.show_boss_hp("矿脉甲虫")
        hud.update_boss_hp(boss.hp, boss.max_hp)
        hud.update_player_hp(player.hp, player.max_hp)

        if intro_timer > 2.0:
                battle_intro = false
                battle_active = true
                hud.show_perfect("FIGHT!", Color(1, 0.3, 0.1))
                audio.play("war_cry", 0.7)

func _check_combat_collisions() -> void:
        var dist = abs(player.pos.x - boss.pos.x)

        # === 玩家攻击Boss ===
        if player.is_in_active_frames() and not boss_hit_applied:
                if dist < 80:
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
                                # 终结技：紫白闪光 + 强震 + 长顿帧 + 屏幕闪光
                                effects.spawn_hit_spark(hit_pos, Color(0.8, 0.5, 1.0))
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.9, 1.0))  # 双重火花
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.15)
                                effects.start_shake(7.0, 6.0)
                                effects.start_flash(0.1, Color(0.8, 0.5, 1.0))
                                audio.play("hit_heavy")
                        elif is_heavy:
                                # 重击：红橙闪光 + 强震 + 较长顿帧
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.4, 0.15))
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.8, 0.3))  # 双重火花
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.12)
                                effects.start_shake(5.0, 7.0)
                                effects.start_flash(0.06, Color(1, 0.5, 0.2))
                                audio.play("hit_heavy")
                        elif combo_step >= 3:
                                # 第3段轻攻：黄色火花 + 中等震屏 + 顿帧
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.85, 0.3))
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.09)
                                effects.start_shake(3.0, 6.0)
                                audio.play("hit_light")
                        elif combo_step >= 2:
                                # 第2段轻攻：淡黄火花 + 轻震 + 短顿帧
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.95, 0.6))
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.07)
                                effects.start_shake(2.0, 6.0)
                                audio.play("hit_light")
                        else:
                                # 第1段轻攻：白黄火花 + 微震 + 最短顿帧
                                effects.spawn_hit_spark(hit_pos, Color(1, 0.95, 0.8))
                                effects.spawn_blood_splatter(hit_pos, player.facing)
                                effects.start_hitstop(0.05)
                                effects.start_shake(1.5, 6.0)
                                audio.play("hit_light")

                        hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, is_heavy or is_finisher)

                        var combo_info = player.get_attack_info()
                        var rage_gain: float = 5.0 * combo_info.get("damage_mult", 1.0) * (skill_tree.get_rage_bonus() if skill_tree else 1.0)
                        if player.war_cry_buff:
                                rage_gain *= 1.2
                        player.rage = min(player.max_rage, player.rage + rage_gain)

        if not player.is_attacking or player.attack_phase != player.AttackPhase.ACTIVE:
                if player.attack_phase == player.AttackPhase.RECOVERY:
                        boss_hit_applied = false

        # === Boss攻击玩家 ===
        if boss.is_in_attack_state() and boss.is_attack_active() and not player_hit_applied:
                if dist < 85:
                        var base_dmg: float = boss.get_attack_damage()
                        var dmg: float = base_dmg * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        var kb: Vector2 = boss.get_attack_knockback()
                        player.take_damage(dmg, kb)
                        if dmg > 0:
                                hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, dmg >= 25)

                                var hit_pos: Vector2 = (player.pos + boss.pos) / 2 + Vector2(0, -20)
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
        if player.current_anim == "earth_shatter" and not earth_shatter_active:
                earth_shatter_active = true
                earth_shatter_timer = 0.5
                earth_shatter_dealt = false
                effects.spawn_rage_burst(player.pos)
                effects.start_shake(5.0, 8.0)
                audio.play("earth_shatter")
                hud.show_perfect("EARTH SHATTER!", Color(1, 0.3, 0.1))

        if earth_shatter_active:
                earth_shatter_timer -= delta
                if earth_shatter_timer <= 0.3 and not earth_shatter_dealt:
                        earth_shatter_dealt = true
                        var dist = abs(player.pos.x - boss.pos.x)
                        if dist < 120:
                                var dmg: float = 60.0
                                if player.war_cry_buff:
                                        dmg *= player.war_cry_damage_mult
                                boss.take_damage(dmg)
                                hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, true)
                                effects.spawn_earth_shatter(player.pos, player.facing)
                                effects.start_hitstop(0.15)
                                effects.start_shake(8.0, 12.0)
                                audio.play("hit_boss")
                        else:
                                effects.spawn_earth_shatter(player.pos, player.facing)

                if earth_shatter_timer <= 0:
                        earth_shatter_active = false

        if player.current_anim == "war_cry" and frame_count % 8 == 0:
                effects.spawn_rage_burst(player.pos + Vector2(0, -30))

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

func _on_player_attack(_target: Node2D, _damage: float, _knockback: Vector2) -> void:
        pass

func _on_slash_trail(trail_type: String, trail_pos: Vector2, trail_facing: float) -> void:
        """斩击弧线特效 - 不同攻击类型有不同视觉"""
        var combo_step: int = player.current_combo_step if player.has_method("get") else 1
        effects.spawn_slash_arc(trail_pos, trail_facing, trail_type, combo_step)
        audio.play("swing")

func _on_parry_success(is_perfect: bool) -> void:
        if GameState.is_ranger():
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
        else:
                if is_perfect:
                        hud.show_perfect("PERFECT PARRY!", Color(0.5, 0.8, 1.0))
                        var parry_pos: Vector2 = player.pos + Vector2(15 * player.facing, -25)
                        effects.spawn_parry_spark(parry_pos, true)
                        effects.start_hitstop(0.08)
                        effects.start_shake(2.0, 6.0)
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
        hud.show_perfect("ENRAGED!", Color(1, 0.2, 0.1))
        audio.play("boss_enrage")

func _on_boss_died() -> void:
        battle_active = false
        boss_victory = true
        GameState.mark_level_cleared("boss")
        effects.start_slowmo(1.0, 0.2)
        effects.start_shake(10.0, 3.0)
        audio.play("level_up")
        for i in range(3):
                effects.spawn_rage_burst(boss.pos + Vector2(randf_range(-30, 30), randf_range(-40, 0)))
        # Boss掉落物品
        drop_system.spawn_drop(boss.pos, "boss", GROUND_Y)
        # Boss掉落打造材料（甲虫壳碎片x2）
        GameState.crafting_materials["beetle_shell"] = int(GameState.crafting_materials.get("beetle_shell", 0)) + 2
        # 清理刃风暴状态
        blade_storm_active = false
        # 成就触发
        if achievements:
                achievements.check_boss_achievement("beetle")
                achievements.check_combo_achievements(battle_max_combo)
                achievements.check_class_achievement(GameState.selected_class)
        # 显示Victory画面
        if victory_ui:
                var battle_time: float = GameState.play_time - battle_start_time
                var vic_data: Dictionary = {
                        "boss_name": "矿脉甲虫",
                        "ore": drop_system.ore_fragments if drop_system else 0,
                        "material_name": "甲虫壳碎片",
                        "material_count": 2,
                        "exp": int(boss.max_hp),
                        "kills": battle_kills,
                        "time": battle_time,
                        "damage_taken": battle_damage_taken,
                        "max_combo": battle_max_combo,
                }
                victory_ui.open(vic_data)
        else:
                hud.show_perfect("VICTORY! [R]RESTART", Color(1, 0.9, 0.2))

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
        audio.play("death")
        # 显示GameOver画面
        if game_over:
                var go_data: Dictionary = {
                        "play_time": GameState.play_time,
                        "total_kills": GameState.total_kills + battle_kills,
                        "max_combo": battle_max_combo,
                        "total_damage": 0,
                        "ore_fragments": drop_system.ore_fragments if drop_system else 0,
                        "potions_used": 0,
                }
                game_over.open(go_data)

func _quit_to_title() -> void:
        _save_state()
        GameState.go_to_title()

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
        hud.show_perfect("FIGHT!", Color(1, 0.3, 0.1))
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
        boss.phase = 1
        boss.super_armor = false
        boss.poise = boss.max_poise
        boss.change_state(boss.State.IDLE)

        crafting_system.load_save_data(GameState.crafting_materials)
        crafting_system.set_ore_count(drop_system.ore_fragments)
        equipment.set_crafting_system(crafting_system)

        battle_intro = true
        battle_active = false
        boss_victory = false
        player_dead = false
        intro_timer = 0.0
        frame_count = 0
        player_hit_applied = false
        boss_hit_applied = false
        earth_shatter_active = false
        blade_storm_active = false

        effects.time_scale = 1.0

        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
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

        # 格挡/闪避指示器
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

        boss_sprite.position = boss.pos + Vector2(0, -32) + shake
        boss_sprite.flip_h = (boss.facing < 0)

func _save_state() -> void:
        GameState.save_player_state(player.hp, player.rage, player.hit_count)
        GameState.save_resources(drop_system.ore_fragments, skill_tree.get_skill_data() if skill_tree else {})
        var pickup_counts: Dictionary = drop_system.get_pickup_counts()
        GameState.save_pickup_counts(pickup_counts["ore_fragments"], pickup_counts["health_potions"], pickup_counts["rage_crystals"])
        GameState.save_crafting_materials(crafting_system.get_save_data())

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img:
                img.save_png("/home/z/my-project/download/" + filename)
                print("Screenshot saved: " + filename)

# === 自动演示（仅服务器截图模式）===
func _run_demo() -> void:
        match frame_count:
                150:
                        player.vel.x = 220
                        player.facing = 1.0
                180:
                        player.do_attack("L")
                        audio.play("swing")
                210:
                        player.do_attack("L")
                        audio.play("swing")
                240:
                        player.do_attack("L")
                        audio.play("swing")
                270:
                        player.vel.x = 0
                300:
                        player.do_attack("H")
                        audio.play("swing")
                330:
                        player.do_attack("L")
                        audio.play("swing")
                360:
                        player.do_attack("H")
                        audio.play("swing")
                390:
                        player.rage = 100
                        hud.show_perfect("RAGE FULL!", Color(1, 0.7, 0.1))
                        effects.spawn_rage_burst(player.pos)
                        audio.play("war_cry", 0.7)
                410:
                        player.vel.x = 0
