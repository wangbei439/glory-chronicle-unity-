## 堕落书灵 Boss 战 - Beta v0.19
## 禁忌书库关底Boss战
## 特色：书页风暴(远程AOE)、魔光射线(横屏激光)、旋书追踪(追踪弹)
## v0.17：三职业支持（战士/游侠/法师）、书灵专属信号、魔法阵环境
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

# 刃风暴（游侠）
var blade_storm_active: bool = false

# 暴风雪（法师）
var blizzard_active: bool = false

# 书页弹
var page_projectiles: Array = []

# 旋书追踪弹
var tornado_projectiles: Array = []

# 魔光射线
var beam_is_active: bool = false
var beam_y: float = 0.0
var beam_timer: float = 0.0
var beam_visual: ColorRect
var beam_glow_visual: ColorRect

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

# 地面魔法阵装饰
var rune_circle: ColorRect

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
        # === 视差背景（远景矿脉，紫色色调）===
        var far_tex = load("res://assets/sprites/background/parallax_mine_far.png")
        if far_tex:
                var far_bg = TextureRect.new()
                far_bg.texture = far_tex
                far_bg.size = Vector2(640, 360)
                far_bg.stretch_mode = TextureRect.STRETCH_SCALE
                far_bg.modulate = Color(0.4, 0.3, 0.6, 0.5)
                add_child(far_bg)

        # 主背景（紫色色调的书库）
        var bg_tex = load("res://assets/sprites/background/dungeon_mine_640x360.png")
        if bg_tex:
                var bg = TextureRect.new()
                bg.texture = bg_tex
                bg.size = Vector2(640, 360)
                bg.stretch_mode = TextureRect.STRETCH_SCALE
                bg.modulate = Color(0.6, 0.5, 0.8, 1.0)  # 紫色色调
                add_child(bg)
        else:
                var bg2 = ColorRect.new()
                bg2.size = Vector2(640, 360)
                bg2.color = Color(0.08, 0.04, 0.14, 1.0)
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
                        tile.modulate = Color(0.7, 0.6, 0.9, 1.0)  # 紫色色调
                        add_child(tile)
        else:
                # fallback
                var ground_top = ColorRect.new()
                ground_top.position = Vector2(0, 329)
                ground_top.size = Vector2(640, 2)
                ground_top.color = Color(0.3, 0.25, 0.45, 0.8)
                add_child(ground_top)
                var ground = ColorRect.new()
                ground.position = Vector2(0, 330)
                ground.size = Vector2(640, 30)
                ground.color = Color(0.12, 0.08, 0.18, 0.7)
                add_child(ground)

        # === 环境装饰 ===
        # 魔法烛台 x4
        var candle_positions: Array = [Vector2(50, 290), Vector2(220, 290), Vector2(420, 290), Vector2(590, 290)]
        var torch_tex = load("res://assets/sprites/environment/torch_0.png")
        for tp in candle_positions:
                if torch_tex:
                        var torch_sprite = TextureRect.new()
                        torch_sprite.texture = torch_tex
                        torch_sprite.size = Vector2(16, 24)
                        torch_sprite.position = tp
                        torch_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        torch_sprite.modulate = Color(0.7, 0.6, 1.0, 0.9)  # 紫色烛光
                        add_child(torch_sprite)
                else:
                        var candle_fallback = ColorRect.new()
                        candle_fallback.size = Vector2(6, 16)
                        candle_fallback.position = tp
                        candle_fallback.color = Color(0.5, 0.3, 0.7)
                        add_child(candle_fallback)
                # 魔法光晕（紫色）
                var candle_glow = ColorRect.new()
                candle_glow.size = Vector2(24, 24)
                candle_glow.position = tp + Vector2(-4, -8)
                candle_glow.color = Color(0.5, 0.3, 1.0, 0.2)
                add_child(candle_glow)

        # 浮空书架 x3
        var bookshelf_positions: Array = [Vector2(80, 160), Vector2(300, 130), Vector2(520, 155)]
        var bookshelf_tex = load("res://assets/sprites/environment/bookshelf.png")
        for bp in bookshelf_positions:
                if bookshelf_tex:
                        var shelf_sprite = TextureRect.new()
                        shelf_sprite.texture = bookshelf_tex
                        shelf_sprite.size = Vector2(48, 64)
                        shelf_sprite.position = bp
                        shelf_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        shelf_sprite.modulate = Color(0.6, 0.5, 0.8, 0.6)
                        add_child(shelf_sprite)
                else:
                        var shelf_fallback = ColorRect.new()
                        shelf_fallback.size = Vector2(48, 64)
                        shelf_fallback.position = bp
                        shelf_fallback.color = Color(0.25, 0.15, 0.35, 0.6)
                        add_child(shelf_fallback)
                        # 书架上的书（彩色小方块）
                        for by in range(3):
                                var book_color = Color(0.5 + randf() * 0.3, 0.2 + randf() * 0.3, 0.6 + randf() * 0.4, 0.7)
                                var book = ColorRect.new()
                                book.size = Vector2(8 + randf() * 8, 6 + randf() * 4)
                                book.position = bp + Vector2(4 + by * 14, 10 + by * 18)
                                book.color = book_color
                                add_child(book)

        # 魔法符文 x3
        var rune_positions: Array = [Vector2(150, 60), Vector2(350, 45), Vector2(500, 70)]
        for rp in rune_positions:
                var rune = ColorRect.new()
                rune.size = Vector2(20, 20)
                rune.position = rp
                rune.color = Color(0.6, 0.3, 1.0, 0.3)
                add_child(rune)
                # 符文光晕
                var rune_glow = ColorRect.new()
                rune_glow.size = Vector2(28, 28)
                rune_glow.position = rp + Vector2(-4, -4)
                rune_glow.color = Color(0.5, 0.2, 0.9, 0.15)
                add_child(rune_glow)

        # 书堆 x3（地面装饰）
        var bookstack_positions: Array = [Vector2(130, 300), Vector2(330, 302), Vector2(510, 298)]
        for bsp in bookstack_positions:
                var stack = ColorRect.new()
                stack.size = Vector2(16, 14)
                stack.position = bsp
                stack.color = Color(0.4, 0.2, 0.5, 0.7)
                add_child(stack)
                # 顶部书本
                var top_book = ColorRect.new()
                top_book.size = Vector2(12, 4)
                top_book.position = bsp + Vector2(2, -4)
                top_book.color = Color(0.5, 0.25, 0.6, 0.6)
                add_child(top_book)

        # 地面魔法阵（装饰区域）
        rune_circle = ColorRect.new()
        rune_circle.position = Vector2(240, 322)
        rune_circle.size = Vector2(160, 6)
        rune_circle.color = Color(0.5, 0.2, 0.9, 0.6)
        add_child(rune_circle)
        var rune_glow_ground = ColorRect.new()
        rune_glow_ground.position = Vector2(238, 320)
        rune_glow_ground.size = Vector2(164, 10)
        rune_glow_ground.color = Color(0.6, 0.3, 1.0, 0.25)
        add_child(rune_glow_ground)

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
        effects.setup_ambient("magic_dust", 10)

        # === 玩家阴影 ===
        var shadow_tex = load("res://assets/sprites/common/shadow_ellipse.png")
        if shadow_tex:
                player_shadow = TextureRect.new()
                player_shadow.texture = shadow_tex
                player_shadow.size = Vector2(28, 8)
                player_shadow.stretch_mode = TextureRect.STRETCH_SCALE
                player_shadow.modulate = Color(1, 1, 1, 0.3)
                add_child(player_shadow)
        else:
                var shadow_fallback = ColorRect.new()
                shadow_fallback.size = Vector2(28, 8)
                shadow_fallback.color = Color(0, 0, 0, 0.18)
                add_child(shadow_fallback)

        # === 玩家（三职业选择）===
        var player_script: GDScript = null
        if GameState.selected_class == "mage":
                player_script = load("res://scripts/player/mage.gd")
        elif GameState.is_ranger():
                player_script = load("res://scripts/player/ranger.gd")
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
        # 游侠/法师max_hp兼容
        if GameState.selected_class == "mage" and state.has("max_hp"):
                player.max_hp = 70.0  # 法师max_hp
                player.hp = min(player.hp, player.max_hp)
        elif GameState.is_ranger() and state.has("max_hp"):
                player.max_hp = state["max_hp"]
        var equip_stats: Dictionary = GameState.get_equipment_stats()
        if equip_stats.get("max_hp_bonus", 0.0) > 0:
                player.max_hp += equip_stats["max_hp_bonus"]
                player.hp = min(player.hp, player.max_hp)

        parry_indicator = ColorRect.new()
        parry_indicator.size = Vector2(20, 20)
        if GameState.selected_class == "mage":
                parry_indicator.color = Color(0.3, 0.6, 1.0, 0.4)
        else:
                parry_indicator.color = Color(0.5, 0.8, 1.0, 0.4)
        parry_indicator.visible = false
        add_child(parry_indicator)
        player.parry_indicator = parry_indicator

        # === 堕落书灵 Boss ===
        var boss_script = load("res://scripts/enemy/boss_book_spirit.gd")
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
        player.died.connect(_on_player_died)

        # 职业特定信号
        if GameState.selected_class == "mage":
                if player.has_signal("shield_success"):
                        player.shield_success.connect(_on_shield_success)
        else:
                player.parry_success.connect(_on_parry_success)
                if GameState.is_ranger():
                        player.dodge_success.connect(_on_dodge_success)

        boss.boss_health_changed.connect(func(h, m): hud.update_boss_hp(h, m))
        boss.boss_phase_changed.connect(_on_boss_phase_changed)
        boss.boss_died.connect(_on_boss_died)
        boss.boss_telegraph.connect(_on_boss_telegraph)
        boss.boss_attack_active.connect(_on_boss_attack_active)
        boss.boss_page_spawn.connect(_on_boss_page_spawn)
        boss.boss_beam_active.connect(_on_boss_beam_active)
        boss.boss_tornado_spawn.connect(_on_boss_tornado_spawn)

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
        level_title.text = "禁忌书库 - 堕落书灵"
        level_title.position = Vector2(220, 5)
        level_title.add_theme_font_size_override("font_size", 10)
        level_title.add_theme_color_override("font_color", Color(0.7, 0.4, 1.0, 0.8))
        add_child(level_title)

        # 操作提示（三职业）
        var guard_text: String = "L:格挡"
        var skill1_text: String = "U:战吼"
        var skill2_text: String = "I:裂地斩"
        if GameState.selected_class == "mage":
                guard_text = "L:魔盾"
                skill1_text = "U:闪现"
                skill2_text = "I:暴风雪"
        elif GameState.is_ranger():
                guard_text = "L:闪避"
                skill1_text = "U:影步"
                skill2_text = "I:刃风暴"
        var hint = Label.new()
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
                                "boss_name": "堕落书灵",
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

        # 魔法阵伤害
        _check_rune_circle(delta)

        # 书页弹
        _process_page_projectiles(delta)

        # 旋书追踪弹
        _process_tornado_projectiles(delta)

        # 魔光射线碰撞
        _process_beam_damage(delta)

        # 裂地斩AOE
        _process_earth_shatter(delta)

        # 刃风暴AOE（游侠）
        _process_blade_storm(delta)

        # 暴风雪AOE（法师）
        _process_blizzard(delta)

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

        # Boss狂暴定期魔法特效
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

        hud.show_boss_hp("堕落书灵")
        hud.update_boss_hp(boss.hp, boss.max_hp)
        hud.update_player_hp(player.hp, player.max_hp)

        if intro_timer > 2.0:
                battle_intro = false
                battle_active = true
                hud.show_perfect("FIGHT!", Color(0.7, 0.3, 1.0))
                audio.play("war_cry", 0.7)

func _check_combat_collisions() -> void:
        var dist = abs(player.pos.x - boss.pos.x)

        # === 玩家攻击Boss ===
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

                        hud.spawn_damage_number(boss.pos + Vector2(0, -40), dmg, is_heavy)
                        var combo_info = player.get_attack_info()
                        var rage_gain: float = 5.0 * combo_info.get("damage_mult", 1.0) * (skill_tree.get_rage_bonus() if skill_tree else 1.0)
                        player.rage = min(player.max_rage, player.rage + rage_gain)

        if not player.is_attacking or player.attack_phase != player.AttackPhase.ACTIVE:
                if player.attack_phase == player.AttackPhase.RECOVERY:
                        boss_hit_applied = false

        # === Boss攻击玩家 ===
        if boss.is_in_attack_state() and boss.is_attack_active() and not player_hit_applied:
                # 书灵近战/书页风暴距离检查（魔光射线由专用函数处理）
                var hit_range: float = 95.0
                if dist < hit_range:
                        var base_dmg: float = boss.get_attack_damage()
                        var dmg: float = base_dmg * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        var kb: Vector2 = boss.get_attack_knockback()
                        player.take_damage(dmg, kb)
                        if dmg > 0:
                                hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, dmg >= 25)
                                var hit_pos: Vector2 = (player.pos + boss.pos) / 2 + Vector2(0, -20)
                                effects.spawn_hit_spark(hit_pos, Color(0.6, 0.3, 1.0))

                                if dmg >= 25:
                                        effects.start_hitstop(0.12); effects.start_shake(6.0, 10.0); audio.play("hit_boss")
                                else:
                                        effects.start_hitstop(0.05); effects.start_shake(2.0, 7.0); audio.play("hurt")

                                player_hit_applied = true

        if not boss.is_attack_active():
                player_hit_applied = false

func _check_rune_circle(delta: float) -> void:
        """地面魔法阵伤害"""
        if player.pos.y >= GROUND_Y - 5 and player.invincible_timer <= 0:
                if player.pos.x >= 240 and player.pos.x <= 400:
                        var dmg: float = 5.0 * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        player.take_damage(dmg, Vector2(randf_range(-2, 2), -3))
                        hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                        hud.show_perfect("RUNE!", Color(0.6, 0.3, 1.0))
                        audio.play("hurt", 0.4)

        # 魔法阵闪烁
        if rune_circle and is_instance_valid(rune_circle):
                var intensity: float = 0.5 + 0.5 * sin(frame_count * 0.04)
                rune_circle.color = Color(0.5 * intensity, 0.2 * intensity, 0.9, 0.6)

func _process_page_projectiles(delta: float) -> void:
        """书页弹处理 - 类似熔岩弹但有不同视觉"""
        for i in range(page_projectiles.size() - 1, -1, -1):
                var proj: Dictionary = page_projectiles[i]
                if proj["node"] == null or not is_instance_valid(proj["node"]):
                        page_projectiles.remove_at(i)
                        continue

                proj["lifetime"] -= delta
                if proj["lifetime"] <= 0:
                        proj["node"].queue_free()
                        page_projectiles.remove_at(i)
                        continue

                proj["vel"].y += 400 * delta  # 轻重力
                proj["pos"] += proj["vel"] * delta
                proj["node"].position = proj["pos"]

                # 旋转效果
                if proj["node"].get_child_count() > 0:
                        proj["node"].get_child(0).rotation += 5.0 * delta

                # 落地
                if proj["pos"].y >= GROUND_Y - 5:
                        var dist: float = abs(player.pos.x - proj["pos"].x)
                        if dist < 40 and player.invincible_timer <= 0:
                                var dmg: float = 10.0 * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                                player.take_damage(dmg, Vector2(randf_range(-3, 3), -4))
                                hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                                audio.play("hurt", 0.5)
                        effects.spawn_hit_spark(proj["pos"], Color(0.6, 0.3, 1.0))
                        effects.start_shake(1.5, 6.0)
                        audio.play("rock_fall", 0.3)
                        proj["node"].queue_free()
                        page_projectiles.remove_at(i)
                        continue

                # 飞行中碰撞
                var dist: float = abs(player.pos.x - proj["pos"].x)
                var dist_y: float = abs(player.pos.y - 30 - proj["pos"].y)
                if dist < 25 and dist_y < 30 and player.invincible_timer <= 0:
                        var dmg: float = 12.0 * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        player.take_damage(dmg, Vector2(randf_range(-3, 3), -4))
                        hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, true)
                        effects.spawn_hit_spark(proj["pos"], Color(0.7, 0.4, 1.0))
                        audio.play("hurt")
                        proj["node"].queue_free()
                        page_projectiles.remove_at(i)

func _process_tornado_projectiles(delta: float) -> void:
        """旋书追踪弹处理 - 追踪玩家的魔法书"""
        for i in range(tornado_projectiles.size() - 1, -1, -1):
                var proj: Dictionary = tornado_projectiles[i]
                if proj["node"] == null or not is_instance_valid(proj["node"]):
                        tornado_projectiles.remove_at(i)
                        continue

                proj["lifetime"] -= delta
                if proj["lifetime"] <= 0:
                        proj["node"].queue_free()
                        tornado_projectiles.remove_at(i)
                        continue

                # 追踪玩家
                var to_player: Vector2 = (player.pos + Vector2(0, -30) - proj["pos"])
                var track_speed: float = 180.0
                if to_player.length() > 5.0:
                        proj["vel"] = proj["vel"].lerp(to_player.normalized() * track_speed, 2.0 * delta)
                proj["pos"] += proj["vel"] * delta
                proj["node"].position = proj["pos"]

                # 旋转效果
                if proj["node"].get_child_count() > 0:
                        proj["node"].get_child(0).rotation += 8.0 * delta

                # 碰撞检测
                var dist: float = abs(player.pos.x - proj["pos"].x)
                var dist_y: float = abs(player.pos.y - 30 - proj["pos"].y)
                if dist < 20 and dist_y < 25 and player.invincible_timer <= 0:
                        var dmg: float = 15.0 * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        player.take_damage(dmg, Vector2(randf_range(-4, 4), -5))
                        hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, true)
                        effects.spawn_hit_spark(proj["pos"], Color(0.6, 0.3, 1.0))
                        effects.start_hitstop(0.05)
                        effects.start_shake(2.0, 6.0)
                        audio.play("hurt")
                        proj["node"].queue_free()
                        tornado_projectiles.remove_at(i)
                        continue

                # 落地消散
                if proj["pos"].y >= GROUND_Y:
                        effects.spawn_hit_spark(proj["pos"], Color(0.5, 0.2, 0.8))
                        proj["node"].queue_free()
                        tornado_projectiles.remove_at(i)

func _process_beam_damage(delta: float) -> void:
        """魔光射线伤害 - 横屏激光"""
        if not beam_is_active:
                return

        beam_timer -= delta
        if beam_timer <= 0:
                beam_is_active = false
                # 清理射线视觉
                if beam_visual and is_instance_valid(beam_visual):
                        var fade_tween: Tween = create_tween()
                        fade_tween.tween_property(beam_visual, "color:a", 0.0, 0.2)
                        fade_tween.tween_callback(beam_visual.queue_free)
                if beam_glow_visual and is_instance_valid(beam_glow_visual):
                        var fade_tween2: Tween = create_tween()
                        fade_tween2.tween_property(beam_glow_visual, "color:a", 0.0, 0.2)
                        fade_tween2.tween_callback(beam_glow_visual.queue_free)
                return

        # 射线闪烁效果
        if beam_visual and is_instance_valid(beam_visual):
                var flash: float = 0.6 + 0.4 * sin(frame_count * 0.8)
                beam_visual.color = Color(0.6 * flash, 0.3 * flash, 1.0, 0.8)
        if beam_glow_visual and is_instance_valid(beam_glow_visual):
                beam_glow_visual.color = Color(0.5, 0.2, 0.9, 0.2 + 0.15 * sin(frame_count * 0.5))

        # 射线碰撞 - 全屏横向，Y范围判定
        var beam_center_y: float = beam_y
        if abs(player.pos.y - 30 - beam_center_y) < 20 and player.invincible_timer <= 0:
                # 每隔一段时间才造成伤害，避免帧帧扣血
                if not get_meta("beam_dmg_cooldown", false):
                        var dmg: float = 8.0 * (1.0 - (skill_tree.get_defense_bonus() if skill_tree else 0.0)) * (1.0 - (equipment.get_defense_bonus() if equipment else 0.0))
                        var kb: Vector2 = Vector2(boss.facing * 8, -1)
                        player.take_damage(dmg, kb)
                        hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                        effects.spawn_hit_spark(player.pos + Vector2(0, -30), Color(0.6, 0.3, 1.0))
                        effects.start_shake(1.0, 4.0)
                        audio.play("hurt", 0.3)
                        set_meta("beam_dmg_cooldown", true)
                        # 0.3秒后重置冷却
                        get_tree().create_timer(0.3).timeout.connect(func(): set_meta("beam_dmg_cooldown", false))

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

func _process_blade_storm(delta: float) -> void:
        # 游侠刃风暴AOE
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

func _process_blizzard(delta: float) -> void:
        # 法师暴风雪AOE
        if GameState.selected_class == "mage" and player.blizzard_active:
                if not blizzard_active:
                        blizzard_active = true
                        hud.show_perfect("BLIZZARD!", Color(0.3, 0.6, 1.0))
                        effects.spawn_rage_burst(player.pos)
                        effects.start_shake(6.0, 8.0)
                        audio.play("earth_shatter")  # reuse sound
                if player.blizzard_hit_timer <= 0.0:
                        var dist = abs(player.pos.x - boss.pos.x)
                        if dist < 150:
                                var bz_dmg: float = 15.0
                                if player.blink_spell_amp > 1.0:
                                        bz_dmg *= player.blink_spell_amp
                                boss.take_damage(bz_dmg)
                                hud.spawn_damage_number(boss.pos + Vector2(0, -40), bz_dmg, false)
                                effects.spawn_hit_spark((player.pos + boss.pos) / 2 + Vector2(0, -20), Color(0.3, 0.6, 1.0))
                                effects.start_hitstop(0.02)
                                effects.start_shake(2.0, 4.0)
        else:
                blizzard_active = false

# === Boss信号处理 ===

func _on_boss_page_spawn(spawn_pos: Vector2, vel: Vector2) -> void:
        """Boss书页弹信号"""
        var node = Node2D.new()
        add_child(node)

        # 书页弹体 - 白色/紫色方块
        var body = ColorRect.new()
        body.size = Vector2(12, 8)
        body.position = Vector2(-6, -4)
        body.color = Color(0.8, 0.7, 1.0, 0.9)
        node.add_child(body)

        # 魔力光晕
        var glow = ColorRect.new()
        glow.size = Vector2(16, 12)
        glow.position = Vector2(-8, -6)
        glow.color = Color(0.5, 0.3, 1.0, 0.4)
        node.add_child(glow)

        node.position = spawn_pos

        page_projectiles.append({
                "pos": spawn_pos,
                "vel": vel,
                "node": node,
                "lifetime": 4.0,
        })

func _on_boss_beam_active(beam_pos: Vector2, facing_dir: float, duration: float) -> void:
        """Boss魔光射线信号 - 创建横屏激光视觉"""
        beam_is_active = true
        beam_y = beam_pos.y
        beam_timer = duration

        # 射线主体
        beam_visual = ColorRect.new()
        beam_visual.size = Vector2(640, 12)
        beam_visual.position = Vector2(0, beam_y - 6)
        beam_visual.color = Color(0.6, 0.3, 1.0, 0.8)
        beam_visual.z_index = 50
        add_child(beam_visual)

        # 射线光晕
        beam_glow_visual = ColorRect.new()
        beam_glow_visual.size = Vector2(640, 24)
        beam_glow_visual.position = Vector2(0, beam_y - 12)
        beam_glow_visual.color = Color(0.5, 0.2, 0.9, 0.3)
        beam_glow_visual.z_index = 49
        add_child(beam_glow_visual)

        # 预警闪光
        effects.start_shake(3.0, 6.0)
        audio.play("boss_enrage", 0.6)

func _on_boss_tornado_spawn(spawn_pos: Vector2, target_pos: Vector2) -> void:
        """Boss旋书追踪信号 - 生成追踪弹"""
        var node = Node2D.new()
        add_child(node)

        # 追踪书本 - 紫色旋转方块
        var body = ColorRect.new()
        body.size = Vector2(14, 10)
        body.position = Vector2(-7, -5)
        body.color = Color(0.6, 0.3, 0.9, 0.9)
        node.add_child(body)

        # 魔力尾焰
        var trail = ColorRect.new()
        trail.size = Vector2(10, 10)
        trail.position = Vector2(-5, -5)
        trail.color = Color(0.4, 0.2, 0.8, 0.4)
        node.add_child(trail)

        node.position = spawn_pos

        # 初始速度朝目标方向
        var init_vel: Vector2 = (target_pos - spawn_pos).normalized() * 100.0

        tornado_projectiles.append({
                "pos": spawn_pos,
                "vel": init_vel,
                "node": node,
                "lifetime": 2.5,
        })

func _on_player_attack(_target: Node2D, _damage: float, _knockback: Vector2) -> void: pass

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

func _on_shield_success(is_perfect: bool) -> void:
        """法师护盾成功"""
        if is_perfect:
                hud.show_perfect("PERFECT SHIELD!", Color(0.3, 0.6, 1.0))
                var shield_pos: Vector2 = player.pos + Vector2(15 * player.facing, -25)
                effects.spawn_parry_spark(shield_pos, true)
                effects.start_hitstop(0.08)
                effects.start_shake(2.0, 6.0)
                player.rage = min(player.max_rage, player.rage + 10)  # 回复魔力
                hud.update_rage(player.rage, player.max_rage)
                audio.play("parry_perfect")
        else:
                hud.show_perfect("SHIELD!", Color(0.4, 0.5, 0.9))
                var shield_pos: Vector2 = player.pos + Vector2(15 * player.facing, -25)
                effects.spawn_parry_spark(shield_pos, false)
                effects.start_hitstop(0.04)
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
        hud.show_perfect("ARCANE ENRAGED!", Color(0.7, 0.2, 1.0))
        audio.play("boss_enrage")

func _on_boss_died() -> void:
        battle_active = false
        boss_victory = true
        GameState.mark_level_cleared("library_boss")
        hud.show_perfect("VICTORY!", Color(1, 0.9, 0.2))
        effects.start_slowmo(1.0, 0.2)
        effects.start_shake(10.0, 3.0)
        audio.play("level_up")
        for i in range(3):
                effects.spawn_rage_burst(boss.pos + Vector2(randf_range(-40, 40), randf_range(-50, 0)))
        drop_system.spawn_drop(boss.pos, "boss", GROUND_Y)
        # Boss掉落打造材料（古卷残页x2）
        GameState.crafting_materials["ancient_scroll"] = int(GameState.crafting_materials.get("ancient_scroll", 0)) + 2
        hud.show_perfect("+2 古卷残页!", Color(0.6, 0.3, 1.0))
        # 清理状态
        blade_storm_active = false
        blizzard_active = false

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
        # 法师专用状态重置
        if GameState.selected_class == "mage":
                player.is_shielding = false
                player.is_perfect_shield_window = false
                player.blizzard_active = false
                player.blink_buff = false
                player.blink_timer = 0.0
                player.blink_spell_amp = 1.0
                player.blink_speed_mult = 1.0
        battle_active = true
        effects.time_scale = 1.0
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        hud.show_perfect("FIGHT!", Color(0.7, 0.3, 1.0))
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

        # 法师专用状态重置
        if GameState.selected_class == "mage":
                player.is_shielding = false
                player.is_perfect_shield_window = false
                player.blizzard_active = false
                player.blink_buff = false
                player.blink_timer = 0.0
                player.blink_spell_amp = 1.0
                player.blink_spell_amp_timer = 0.0
                player.blink_speed_mult = 1.0

        boss.hp = boss.max_hp
        boss.pos = Vector2(480, GROUND_Y)
        boss.facing = -1.0
        boss.vel = Vector2.ZERO
        boss.is_stunned = false
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
        blizzard_active = false

        # 清理书页弹
        for proj in page_projectiles:
                if proj["node"] and is_instance_valid(proj["node"]):
                        proj["node"].queue_free()
        page_projectiles.clear()

        # 清理旋书追踪弹
        for proj in tornado_projectiles:
                if proj["node"] and is_instance_valid(proj["node"]):
                        proj["node"].queue_free()
        tornado_projectiles.clear()

        # 清理射线视觉
        beam_is_active = false
        if beam_visual and is_instance_valid(beam_visual):
                beam_visual.queue_free()
                beam_visual = null
        if beam_glow_visual and is_instance_valid(beam_glow_visual):
                beam_glow_visual.queue_free()
                beam_glow_visual = null

        crafting_system.load_save_data(GameState.crafting_materials)
        crafting_system.set_ore_count(drop_system.ore_fragments)
        equipment.set_crafting_system(crafting_system)

        effects.time_scale = 1.0
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        hud.show_boss_hp("堕落书灵")
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
                if GameState.selected_class == "mage":
                        # 法师闪现buff - 蓝色闪光
                        if int(frame_count / 4) % 3 == 0:
                                player_sprite.modulate = Color(0.5, 0.7, 1.3)
                        else:
                                player_sprite.modulate = Color(1, 1, 1)
                else:
                        if int(frame_count / 4) % 3 == 0:
                                player_sprite.modulate = Color(1.2, 1.0, 0.7)
                        else:
                                player_sprite.modulate = Color(1, 1, 1)

        # 格挡/闪避/护盾指示器
        if GameState.selected_class == "mage":
                if player.is_shielding and player.is_perfect_shield_window:
                        parry_indicator.visible = true
                        parry_indicator.position = player.pos + Vector2(-10 * player.facing, -42) + shake
                        parry_indicator.color = Color(0.3, 0.6, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
                else:
                        parry_indicator.visible = false
        elif GameState.is_ranger():
                if player.is_dodging and player.is_perfect_dodge_window:
                        parry_indicator.visible = true
                        parry_indicator.position = player.pos + Vector2(-10 * player.facing, -42) + shake
                        parry_indicator.color = Color(0.6, 0.3, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
                else:
                        parry_indicator.visible = false
        else:
                if player.is_guarding and player.is_perfect_parry_window:
                        parry_indicator.visible = true
                        parry_indicator.position = player.pos + Vector2(-10 * player.facing, -42) + shake
                        parry_indicator.color = Color(0.5, 0.8, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
                else:
                        parry_indicator.visible = false

        # Boss精灵 - 128x64偏移
        boss_sprite.position = boss.pos + Vector2(-32, -32) + shake
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

func _run_demo() -> void:
        match frame_count:
                150:
                        player.vel.x = 220; player.facing = 1.0
                180:
                        player.do_attack("L"); audio.play("swing")
                270:
                        player.vel.x = 0

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
        effects.time_scale = 1.0
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        hud.show_perfect("FIGHT!", Color(0.7, 0.3, 1.0))
        audio.play("war_cry", 0.5)

func _quit_to_title() -> void:
        _save_state()
        GameState.go_to_title()
