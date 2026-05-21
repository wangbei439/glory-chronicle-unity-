## 训练场 - Beta v0.19
## 打击感增强版 + 连击计数 + 判定帧 + 粒子特效
## v0.19: GameOver/Pause/成就系统集成
extends Node2D

# === 自动演示模式（服务器截图用，玩家下载后默认关闭）===
@export var auto_demo: bool = false
@export var auto_quit_frame: int = 0  # 0=不自动退出

# === 战士状态 ===
var player_pos: Vector2 = Vector2(125, 309)
var player_vel: Vector2 = Vector2.ZERO
var player_facing: float = 1.0
var is_attacking: bool = false
var attack_frame: int = 0
var attack_duration: int = 20
var attack_name: String = ""
var is_guarding: bool = false
var guard_flash: float = 0.0
var is_perfect_parry_window: bool = false
var parry_window_timer: float = 0.0

# 攻击判定帧
enum AttackPhase { STARTUP, ACTIVE, RECOVERY }
var attack_phase: AttackPhase = AttackPhase.STARTUP
var attack_startup_frames: int = 4
var attack_active_frames: int = 6
var attack_hit_dealt: bool = false

# === 连招系统 ===
var combo_sequence: Array = []
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_tree: Dictionary = {}
var hit_count: int = 0

# === 怒气 ===
var rage: float = 0.0
var max_rage: float = 100.0
var war_cry_buff: bool = false
var war_cry_timer: float = 0.0

# === 视觉节点 ===
var player_sprite: AnimatedSprite2D
var player_shadow: TextureRect
var parry_indicator: ColorRect

# 木桩
var dummies: Array = []

# 打击感
var effects_node: Node2D
var combat_effects: Node2D
var camera_offset: Vector2 = Vector2.ZERO
var hitstop_timer: float = 0.0
var shake_intensity: float = 0.0
var particles: Array = []

# 音效
var audio: Node2D

# 跳跃音效
var was_on_ground: bool = true

# HUD
var hp_fill: ColorRect
var rage_fill: ColorRect
var combo_label: Label
var perfect_label: Label
var skill_label_1: Label
var skill_label_2: Label
var guard_text: String = "L:魔盾" if GameState.is_mage() else ("L:闪避" if GameState.is_ranger() else "L:格挡")
var hit_count_label: Label
var hit_effects: Array = []

var frame_count: int = 0
var current_anim: String = "idle"

# 输入消耗标志（防止按住键时反复触发）
var _esc_consumed: bool = false
var _r_consumed: bool = false
var pause_menu: CanvasLayer
var achievements: Node2D

func _ready() -> void:
        _build_combo_tree()
        _build_scene()

func _build_combo_tree() -> void:
        combo_tree["L"] = {"name": "横斩", "mult": 1.0, "rage": 5, "dur": 20, "startup": 4, "active": 6}
        combo_tree["L,L"] = {"name": "逆斩", "mult": 1.2, "rage": 5, "dur": 18, "startup": 3, "active": 5}
        combo_tree["L,L,L"] = {"name": "回旋斩", "mult": 1.8, "rage": 10, "dur": 25, "startup": 5, "active": 8}
        combo_tree["L,L,H"] = {"name": "上挑", "mult": 1.5, "rage": 8, "dur": 25, "startup": 4, "active": 6}
        combo_tree["L,L,DH"] = {"name": "下砸", "mult": 2.0, "rage": 10, "dur": 30, "startup": 6, "active": 8}
        combo_tree["L,H"] = {"name": "冲刺斩", "mult": 1.3, "rage": 7, "dur": 18, "startup": 2, "active": 6}
        combo_tree["H"] = {"name": "重击", "mult": 2.5, "rage": 8, "dur": 28, "startup": 8, "active": 6}
        combo_tree["H,L"] = {"name": "追击斩", "mult": 1.5, "rage": 6, "dur": 15, "startup": 2, "active": 5}

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
        var tile_row_count: int = 1  # 1 row of 30px height fits in 32px tiles
        if ground_tile_tex:
                for tx in range(tile_count):
                        for ty in range(tile_row_count):
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

        # 平台
        var p1 = ColorRect.new()
        p1.position = Vector2(135, 255)
        p1.size = Vector2(80, 6)
        p1.color = Color(0.25, 0.27, 0.3, 0.8)
        add_child(p1)

        var p2 = ColorRect.new()
        p2.position = Vector2(400, 230)
        p2.size = Vector2(100, 6)
        p2.color = Color(0.25, 0.27, 0.3, 0.8)
        add_child(p2)

        # === 环境装饰 ===
        # 火炬 x2
        var torch_positions: Array = [Vector2(60, 290), Vector2(580, 290)]
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

        # 水晶 x2
        var crystal_positions: Array = [Vector2(200, 300), Vector2(480, 296)]
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

        # 钟乳石 x2
        var stalactite_positions: Array = [Vector2(150, 0), Vector2(450, 0)]
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

        # 发光蘑菇 x3
        var mushroom_positions: Array = [Vector2(100, 320), Vector2(320, 318), Vector2(550, 321)]
        var mushroom_tex = load("res://assets/sprites/environment/mushroom_red.png")
        for mp in mushroom_positions:
                if mushroom_tex:
                        var mushroom_sprite = TextureRect.new()
                        mushroom_sprite.texture = mushroom_tex
                        mushroom_sprite.size = Vector2(10, 10)
                        mushroom_sprite.position = mp
                        mushroom_sprite.stretch_mode = TextureRect.STRETCH_SCALE
                        add_child(mushroom_sprite)
                else:
                        var mushroom_fallback = ColorRect.new()
                        mushroom_fallback.size = Vector2(6, 6)
                        mushroom_fallback.position = mp
                        mushroom_fallback.color = Color(0.9, 0.2, 0.15, 0.8)
                        add_child(mushroom_fallback)
                # 蘑菇微光
                var mushroom_glow = ColorRect.new()
                mushroom_glow.size = Vector2(14, 14)
                mushroom_glow.position = mp + Vector2(-2, -2)
                mushroom_glow.color = Color(0.9, 0.3, 0.2, 0.1)
                add_child(mushroom_glow)

        # === 音效系统 ===
        var audio_script = load("res://scripts/audio/audio_manager.gd")
        audio = Node2D.new()
        audio.set_script(audio_script)
        add_child(audio)

        # 打击感特效节点
        effects_node = Node2D.new()
        add_child(effects_node)

        # === 打击感特效系统（含环境粒子）===
        var effects_script = load("res://scripts/core/combat_effects.gd")
        combat_effects = Node2D.new()
        combat_effects.set_script(effects_script)
        add_child(combat_effects)
        combat_effects.setup_ambient("dust", 8)

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

        # === 玩家 ===
        player_sprite = AnimatedSprite2D.new()
        _build_player_animations()
        player_sprite.play("idle")
        add_child(player_sprite)

        parry_indicator = ColorRect.new()
        parry_indicator.size = Vector2(20, 20)
        parry_indicator.color = Color(0.5, 0.8, 1.0, 0.4)
        parry_indicator.visible = false
        add_child(parry_indicator)

        # === 训练木桩 ===
        _create_dummy(Vector2(275, 306))
        _create_dummy(Vector2(350, 306))
        _create_dummy(Vector2(175, 231))

        # === HUD ===
        _build_hud()

        # === 暂停菜单 ===
        var pause_script = load("res://scripts/ui/pause_menu.gd")
        pause_menu = CanvasLayer.new()
        pause_menu.set_script(pause_script)
        add_child(pause_menu)
        pause_menu.resume_pressed.connect(func(): pass)
        pause_menu.quit_pressed.connect(func(): GameState.go_to_title())

        # === 成就系统 ===
        var ach_script = load("res://scripts/core/achievement_system.gd")
        achievements = Node2D.new()
        achievements.set_script(ach_script)
        add_child(achievements)

func _build_player_animations() -> void:
        var sprite_frames = SpriteFrames.new()

        var anims = {
                "idle": {"path": "warrior_idle_sheet.png", "frames": 4, "speed": 8.0, "loop": true},
                "run": {"path": "warrior_run_sheet.png", "frames": 6, "speed": 10.0, "loop": true},
                "attack": {"path": "warrior_attack_sheet.png", "frames": 5, "speed": 12.0, "loop": false},
                "guard": {"path": "warrior_guard_sheet.png", "frames": 3, "speed": 6.0, "loop": true},
                "jump": {"path": "warrior_jump_sheet.png", "frames": 4, "speed": 4.0, "loop": false},
                "hurt": {"path": "warrior_hurt_sheet.png", "frames": 3, "speed": 8.0, "loop": false},
                "war_cry": {"path": "warrior_war_cry_sheet.png", "frames": 5, "speed": 6.0, "loop": false},
                "earth_shatter": {"path": "warrior_earth_shatter_sheet.png", "frames": 6, "speed": 6.0, "loop": false},
        }

        for anim_name: String in anims:
                var info: Dictionary = anims[anim_name]
                var tex = load("res://assets/sprites/player/" + info["path"])
                if not tex:
                        continue
                sprite_frames.add_animation(anim_name)
                sprite_frames.set_animation_speed(anim_name, info["speed"])
                sprite_frames.set_animation_loop(anim_name, info["loop"])
                var count: int = info["frames"]
                for i in range(count):
                        var frame_tex = _extract_frame(tex, count * 48, 64, count, i)
                        sprite_frames.add_frame(anim_name, frame_tex)

        if not sprite_frames.has_animation("idle"):
                sprite_frames.add_animation("idle")
                var fallback = load("res://assets/sprites/player/warrior_idle_64.png")
                if fallback:
                        sprite_frames.add_frame("idle", fallback)

        player_sprite.sprite_frames = sprite_frames

func _extract_frame(tex: Texture2D, sheet_w: int, sheet_h: int, hframes: int, frame_idx: int) -> AtlasTexture:
        var atlas = AtlasTexture.new()
        atlas.atlas = tex
        var frame_w: float = sheet_w / hframes
        atlas.region = Rect2(frame_idx * frame_w, 0, frame_w, sheet_h)
        atlas.filter_clip = false
        return atlas

func _play_anim(anim_name: String) -> void:
        if current_anim == anim_name:
                return
        current_anim = anim_name
        if player_sprite and player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation(anim_name):
                player_sprite.play(anim_name)

func _create_dummy(pos: Vector2) -> void:
        var sprite = Sprite2D.new()
        var dummy_tex = load("res://assets/sprites/enemy/training_dummy_64.png")
        if dummy_tex:
                sprite.texture = dummy_tex
                sprite.scale = Vector2(0.8, 0.8)
        sprite.position = pos
        add_child(sprite)

        dummies.append({
                "sprite": sprite, "pos": pos, "flash": 0.0,
                "shake": Vector2.ZERO, "hp": 999.0
        })

func _build_hud() -> void:
        var hp_bg = ColorRect.new()
        hp_bg.size = Vector2(125, 8)
        hp_bg.position = Vector2(10, 10)
        hp_bg.color = Color(0.2, 0.15, 0.15, 0.85)
        add_child(hp_bg)

        hp_fill = ColorRect.new()
        hp_fill.size = Vector2(124, 7)
        hp_fill.position = Vector2(10, 10)
        hp_fill.color = Color(0.85, 0.15, 0.1, 1.0)
        add_child(hp_fill)

        var rage_bg = ColorRect.new()
        rage_bg.size = Vector2(125, 8)
        rage_bg.position = Vector2(10, 21)
        rage_bg.color = Color(0.15, 0.15, 0.2, 0.85)
        add_child(rage_bg)

        rage_fill = ColorRect.new()
        rage_fill.size = Vector2(0, 7)
        rage_fill.position = Vector2(10, 21)
        rage_fill.color = Color(0.9, 0.6, 0.1, 1.0)
        add_child(rage_fill)

        var mark50 = ColorRect.new()
        mark50.size = Vector2(1, 7)
        mark50.position = Vector2(72, 21)
        mark50.color = Color(1, 1, 1, 0.3)
        add_child(mark50)

        skill_label_1 = Label.new()
        skill_label_1.text = "[U]闪现 2CP" if GameState.is_mage() else ("[U]影步 2CP" if GameState.is_ranger() else "[U]战吼 50怒气")
        skill_label_1.position = Vector2(10, 32)
        skill_label_1.add_theme_font_size_override("font_size", 7)
        skill_label_1.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
        add_child(skill_label_1)

        skill_label_2 = Label.new()
        skill_label_2.text = "[I]暴风雪 5CP" if GameState.is_mage() else ("[I]刃风暴 5CP" if GameState.is_ranger() else "[I]裂地斩 100怒气")
        skill_label_2.position = Vector2(10, 40)
        skill_label_2.add_theme_font_size_override("font_size", 7)
        skill_label_2.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
        add_child(skill_label_2)

        combo_label = Label.new()
        combo_label.position = Vector2(280, 270)
        combo_label.add_theme_font_size_override("font_size", 16)
        combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
        add_child(combo_label)

        hit_count_label = Label.new()
        hit_count_label.position = Vector2(550, 50)
        hit_count_label.add_theme_font_size_override("font_size", 18)
        hit_count_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 0.9))
        hit_count_label.visible = false
        add_child(hit_count_label)

        perfect_label = Label.new()
        perfect_label.position = Vector2(250, 140)
        perfect_label.add_theme_font_size_override("font_size", 20)
        perfect_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
        perfect_label.visible = false
        add_child(perfect_label)

        var title = Label.new()
        title.text = "代号：传说 - 训练场"
        title.position = Vector2(220, 5)
        title.add_theme_font_size_override("font_size", 12)
        title.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 0.9))
        add_child(title)

        var ver = Label.new()
        ver.text = "v0.19"
        ver.position = Vector2(590, 5)
        ver.add_theme_font_size_override("font_size", 7)
        ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
        add_child(ver)

        var hint = Label.new()
        var guard_hint: String = "L:魔盾" if GameState.is_mage() else ("L:闪避" if GameState.is_ranger() else "L:格挡")
        hint.text = "R:矿井关卡  " + guard_hint + "  Esc:主菜单"
        hint.position = Vector2(80, 350)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.7))
        add_child(hint)

func _physics_process(delta: float) -> void:
        frame_count += 1

        # 暂停菜单处理
        if pause_menu and pause_menu.is_open:
                pause_menu.process_input(delta)
                if achievements: achievements.process_notifications(delta)
                return

        # 成就通知处理
        if achievements: achievements.process_notifications(delta)

        # Esc暂停菜单
        if Input.is_action_just_pressed("menu_quit"):
                if not _esc_consumed:
                        _esc_consumed = true
                        GameState.save_player_state(100, rage, hit_count)
                        if pause_menu:
                                pause_menu.open()
                        else:
                                GameState.go_to_title()
                return
        else:
                _esc_consumed = false

        # Hitstop
        if hitstop_timer > 0:
                hitstop_timer -= delta
                return

        # 震屏衰减
        if shake_intensity > 0:
                shake_intensity = max(0, shake_intensity - 6.0 * delta)
                camera_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
        else:
                camera_offset = Vector2.ZERO

        # 战吼buff
        if war_cry_buff:
                war_cry_timer -= delta
                if war_cry_timer <= 0:
                        war_cry_buff = false

        _process_player(delta)
        _update_visuals(delta)
        _update_dummies(delta)
        _process_hit_effects(delta)
        _process_particles(delta)
        _update_hud()

        # 环境粒子更新
        if combat_effects:
                combat_effects.process(delta)

        # 场景切换 → 矿井关卡（防连发）
        if Input.is_action_just_pressed("menu_retry"):
                if not _r_consumed:
                        _r_consumed = true
                        GameState.save_player_state(100, rage, hit_count)
                        GameState.go_to_level("mine")
        else:
                _r_consumed = false

        # === 自动演示模式（仅服务器截图用）===
        if auto_demo:
                _run_demo()

        # === 自动退出（仅服务器用）===
        if auto_quit_frame > 0 and frame_count >= auto_quit_frame:
                _take_screenshot("legend_training_auto.png")
                get_tree().quit()

func _process_player(delta: float) -> void:
        var speed = 280.0
        var gravity = 980.0

        # 连招超时
        if combo_timer > 0:
                combo_timer -= delta
                if combo_timer <= 0:
                        combo_sequence.clear()
                        combo_count = 0
                        hit_count = 0

        # 格挡窗口
        if is_perfect_parry_window:
                parry_window_timer -= delta
                if parry_window_timer <= 0:
                        is_perfect_parry_window = false
                        if parry_indicator:
                                parry_indicator.visible = false

        # 攻击中 - 判定帧
        if is_attacking:
                attack_frame += 1
                var active_end: int = attack_startup_frames + attack_active_frames
                if attack_frame <= attack_startup_frames:
                        attack_phase = AttackPhase.STARTUP
                        player_vel.x = lerp(player_vel.x, 0.0, 0.15)
                elif attack_frame <= active_end:
                        attack_phase = AttackPhase.ACTIVE
                        if attack_name == "冲刺斩":
                                player_vel.x = player_facing * 180
                        else:
                                player_vel.x = lerp(player_vel.x, 0.0, 0.08)
                else:
                        attack_phase = AttackPhase.RECOVERY
                        player_vel.x = lerp(player_vel.x, 0.0, 0.12)

                if attack_frame >= attack_duration:
                        is_attacking = false
                        attack_frame = 0
                        attack_name = ""
                        attack_hit_dealt = false
                        attack_phase = AttackPhase.STARTUP
                        _play_anim("idle")

        # 格挡
        if is_guarding:
                player_vel.x = 0
                _play_anim("guard")
                return

        # 移动
        var is_moving = false
        if Input.is_action_pressed("move_right"):
                player_vel.x = speed
                player_facing = 1.0
                is_moving = true
        elif Input.is_action_pressed("move_left"):
                player_vel.x = -speed
                player_facing = -1.0
                is_moving = true
        else:
                player_vel.x = lerp(player_vel.x, 0.0, 0.2)

        if not is_attacking:
                if player_pos.y < 309:
                        _play_anim("jump")
                elif is_moving:
                        _play_anim("run")
                else:
                        _play_anim("idle")

        # 跳跃
        if Input.is_action_just_pressed("jump") and player_pos.y >= 306:
                player_vel.y = -450.0
                audio.play("jump")

        # 落地音效
        var on_ground: bool = player_pos.y >= 306
        if not was_on_ground and on_ground:
                audio.play("land")
        was_on_ground = on_ground

        if Input.is_action_just_pressed("attack"):
                _do_attack("L")
        elif Input.is_action_just_pressed("heavy_attack"):
                _do_attack("H")

        if Input.is_action_just_pressed("guard"):
                is_guarding = true
                is_perfect_parry_window = true
                parry_window_timer = 0.1
                parry_indicator.visible = true
                parry_indicator.color = Color(0.5, 0.8, 1.0, 0.5)

        if Input.is_action_just_released("guard"):
                is_guarding = false
                is_perfect_parry_window = false
                parry_indicator.visible = false

        # 战吼
        if Input.is_action_just_pressed("skill_1") and rage >= 50:
                rage -= 50
                war_cry_buff = true
                war_cry_timer = 8.0
                _play_anim("war_cry")
                _show_perfect("WAR CRY!", Color(0.9, 0.7, 0.2))
                _spawn_rage_particles(player_pos)
                shake_intensity = 2.0
                audio.play("war_cry")

        # 终极技
        if Input.is_action_just_pressed("ultimate") and rage >= 100:
                rage = 0
                _play_anim("earth_shatter")
                _show_perfect("EARTH SHATTER!", Color(1, 0.3, 0.1))
                hitstop_timer = 0.1
                shake_intensity = 6.0
                audio.play("earth_shatter")
                for d in dummies:
                        _hit_dummy(d, 50, true)
                _spawn_earth_particles(player_pos)

        # 重力
        if player_pos.y < 309:
                player_vel.y += gravity * delta

        player_pos += player_vel * delta

        if player_pos.y > 309:
                player_pos.y = 309
                player_vel.y = 0

func _do_attack(input_key: String) -> void:
        if is_attacking and attack_phase != AttackPhase.RECOVERY:
                return
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
        _play_anim("attack")

        # 挥砍音效
        audio.play("swing")

        var is_perfect = is_perfect_parry_window or randf() < 0.2
        var dmg: float = 10.0 * combo_data["mult"]
        if is_perfect:
                dmg *= 1.3
        if war_cry_buff:
                dmg *= 1.15

        for d in dummies:
                var dist = abs(d["pos"].x - player_pos.x)
                if dist < 60:
                        _hit_dummy(d, dmg, is_perfect)
                        attack_hit_dealt = true

                        var hit_pos: Vector2 = (player_pos + d["pos"]) / 2 + Vector2(0, -20)
                        _spawn_hit_spark(hit_pos, Color(1, 0.9, 0.5) if not is_perfect else Color(1, 0.5, 0.2))
                        if dmg >= 20:
                                hitstop_timer = 0.08
                                shake_intensity = 3.0
                                audio.play("hit_heavy")
                        else:
                                hitstop_timer = 0.04
                                shake_intensity = 1.0
                                audio.play("hit_light")

        var rage_gain: float = combo_data["rage"]
        if is_perfect:
                rage_gain *= 1.5
        rage = min(max_rage, rage + rage_gain)

        combo_label.text = attack_name
        if is_perfect:
                combo_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
                _show_perfect("PERFECT!", Color(1, 0.95, 0.5))
        else:
                combo_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _hit_dummy(d: Dictionary, damage: float, is_crit: bool = false) -> void:
        d["flash"] = 0.3
        d["shake"] = Vector2(randf_range(-3, 3), randf_range(-2, 2))
        d["hp"] -= damage

        var dmg_label = Label.new()
        dmg_label.text = str(int(damage))
        dmg_label.position = d["pos"] + Vector2(randf_range(-10, 10), -20)
        dmg_label.add_theme_font_size_override("font_size", 14 if is_crit else 10)
        if is_crit:
                dmg_label.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
        else:
                dmg_label.add_theme_color_override("font_color", Color(1, 1, 1))
        add_child(dmg_label)
        hit_effects.append({"node": dmg_label, "life": 0.8, "vel": Vector2(randf_range(-15, 15), -40)})

func _show_perfect(text: String, color: Color) -> void:
        perfect_label.text = text
        perfect_label.visible = true
        perfect_label.add_theme_color_override("font_color", color)
        var tween = create_tween()
        tween.tween_property(perfect_label, "modulate:a", 0, 0.8)
        tween.tween_callback(func(): perfect_label.visible = false; perfect_label.modulate.a = 1)

func _spawn_hit_spark(pos: Vector2, color: Color) -> void:
        for i in range(5):
                var angle: float = randf() * TAU
                var speed: float = randf_range(80, 180)
                var p = ColorRect.new()
                p.size = Vector2(2, 2)
                p.position = pos
                p.color = color
                add_child(p)
                particles.append({"node": p, "life": 0.2, "max_life": 0.2, "vel": Vector2(cos(angle) * speed, sin(angle) * speed), "gravity": 200.0})

func _spawn_rage_particles(pos: Vector2) -> void:
        var colors: Array = [Color(1, 0.5, 0.1), Color(1, 0.8, 0.2), Color(1, 0.3, 0.05)]
        for i in range(10):
                var angle: float = randf() * TAU
                var speed: float = randf_range(60, 180)
                var p = ColorRect.new()
                p.size = Vector2(randf_range(2, 4), randf_range(2, 4))
                p.position = pos
                p.color = colors[i % 3]
                add_child(p)
                particles.append({"node": p, "life": 0.4, "max_life": 0.4, "vel": Vector2(cos(angle) * speed, sin(angle) * speed), "gravity": -30.0})

func _spawn_earth_particles(pos: Vector2) -> void:
        for i in range(8):
                var angle: float = -PI/2 + randf_range(-1.0, 1.0)
                var speed: float = randf_range(100, 250)
                var p = ColorRect.new()
                p.size = Vector2(randf_range(3, 5), randf_range(3, 5))
                p.position = pos + Vector2(randf_range(-20, 20), 0)
                p.color = Color(0.5, 0.4, 0.3) if randf() > 0.3 else Color(0.6, 0.5, 0.3)
                add_child(p)
                particles.append({"node": p, "life": 0.5, "max_life": 0.5, "vel": Vector2(cos(angle) * speed, sin(angle) * speed - 80), "gravity": 350.0})

func _process_particles(delta: float) -> void:
        var to_remove: Array = []
        for i in range(particles.size()):
                var p: Dictionary = particles[i]
                p["life"] -= delta
                if p["life"] <= 0:
                        p["node"].queue_free()
                        to_remove.append(i)
                        continue
                var vel: Vector2 = p["vel"]
                p["node"].position += vel * delta
                p["vel"] = Vector2(vel.x, vel.y + p["gravity"] * delta)
                var ratio: float = p["life"] / p["max_life"]
                var mod: Color = p["node"].modulate
                mod.a = ratio
                p["node"].modulate = mod
        to_remove.reverse()
        for i in to_remove:
                particles.remove_at(i)

func _update_visuals(delta: float) -> void:
        var f = player_facing
        var shake = camera_offset

        # 更新玩家阴影位置
        if player_shadow:
                player_shadow.position = Vector2(player_pos.x - 14, 307) + shake

        player_sprite.position = player_pos + Vector2(-24, -64) + shake
        player_sprite.flip_h = (f < 0)

        if war_cry_buff:
                if int(frame_count / 4) % 3 == 0:
                        player_sprite.modulate = Color(1.2, 1.0, 0.7)
                else:
                        player_sprite.modulate = Color(1, 1, 1)

        if is_guarding and is_perfect_parry_window:
                parry_indicator.visible = true
                parry_indicator.position = player_pos + Vector2(-10 * f, -42) + shake
                parry_indicator.color = Color(0.5, 0.8, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
        else:
                parry_indicator.visible = false

        rage_fill.size.x = 124 * (rage / max_rage)
        if rage >= 100:
                rage_fill.color = Color(1, 0.85, 0.2, 1) if int(frame_count / 6) % 2 == 0 else Color(0.9, 0.5, 0.1, 1)
        elif rage >= 50:
                rage_fill.color = Color(0.95, 0.65, 0.1, 1)
        else:
                rage_fill.color = Color(0.9, 0.6, 0.1, 1)

        skill_label_1.add_theme_color_override("font_color",
                Color(0.3, 1, 0.3, 1) if rage >= 50 else Color(0.5, 0.5, 0.5, 0.5))
        skill_label_2.add_theme_color_override("font_color",
                Color(1, 0.3, 0.2, 1) if rage >= 100 else Color(0.5, 0.5, 0.5, 0.5))

        if combo_timer <= 0 and not is_attacking:
                combo_label.text = ""

func _update_dummies(delta: float) -> void:
        for d in dummies:
                d["shake"] = d["shake"].lerp(Vector2.ZERO, 0.15)
                var offset = d["shake"]
                if d.has("sprite"):
                        d["sprite"].position = d["pos"] + offset
                        if d["flash"] > 0:
                                d["flash"] -= delta
                                d["sprite"].modulate = Color(2, 1.5, 1) if int(d["flash"] * 20) % 2 == 0 else Color(1, 1, 1)
                        else:
                                d["sprite"].modulate = Color(1, 1, 1)

func _update_hud() -> void:
        if hit_count >= 2:
                hit_count_label.visible = true
                hit_count_label.text = str(hit_count) + " HIT"
                if hit_count >= 20:
                        hit_count_label.add_theme_color_override("font_color", Color(1, 0.2, 0.1, 1))
                elif hit_count >= 10:
                        hit_count_label.add_theme_color_override("font_color", Color(1, 0.6, 0.1, 1))
                elif hit_count >= 5:
                        hit_count_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
                else:
                        hit_count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
        else:
                hit_count_label.visible = false

func _process_hit_effects(delta: float) -> void:
        var to_remove: Array = []
        for i in range(hit_effects.size()):
                var e: Dictionary = hit_effects[i]
                e["life"] -= delta
                e["node"].position += e["vel"] * delta
                e["vel"].y += 80 * delta
                var mod: Color = e["node"].modulate
                mod.a = max(0, e["life"] / 0.8)
                e["node"].modulate = mod
                if e["life"] <= 0:
                        e["node"].queue_free()
                        to_remove.append(i)
        to_remove.reverse()
        for i in to_remove:
                hit_effects.remove_at(i)

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img:
                img.save_png("/home/z/my-project/download/" + filename)
                print("Screenshot saved: " + filename)

func _run_demo() -> void:
        match frame_count:
                60:
                        player_vel.x = 220
                        player_facing = 1.0
                100:
                        _do_attack("L")
                130:
                        _do_attack("L")
                160:
                        _do_attack("L")
                190:
                        player_vel.x = 150
                210:
                        _do_attack("L")
                230:
                        _do_attack("H")
                260:
                        player_vel.x = 0
                280:
                        _do_attack("H")
                310:
                        rage = 100
                        _show_perfect("RAGE FULL!", Color(1, 0.7, 0.1))
                        _spawn_rage_particles(player_pos)
                        audio.play("war_cry", 0.7)
                340:
                        _do_attack("L")
                355:
                        _do_attack("L")
                370:
                        _do_attack("H")
