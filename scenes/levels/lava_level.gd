## 失落地脉关卡 - Beta v0.13
## 设计文档§2.1：元素区域，服务"环境反应"
## 3房间滚动关卡，含熔岩池(触碰持续伤害)和间歇泉(定时喷发)
## 关底Boss：远古熔岩龟
extends Node2D

const GROUND_Y: float = 309.0
const LEVEL_WIDTH: float = 1920.0

# === 自动演示模式 ===
@export var auto_demo: bool = false
@export var auto_quit_frame: int = 0

# 子系统
var player: Node2D
var warrior: Node2D:
        get:
                return player
var effects: Node2D
var hud: Node2D
var camera: Node2D
var audio: Node2D
var drop_system: Node2D
var skill_tree: Node2D
var inventory_ui: Node2D
var equipment: Node2D
var crafting_system: Node2D

# 小怪（熔岩蜥蜴）
var enemies: Array = []
var enemy_sprites: Array = []

# 蝙蝠（火焰蝠）
var bats: Array = []
var bat_sprites: Array = []

# 视觉
var player_sprite: AnimatedSprite2D
var parry_indicator: ColorRect
var camera_offset: Vector2 = Vector2.ZERO

# 状态
var frame_count: int = 0
var player_hit_by_enemy: Dictionary = {}
var player_hit_by_bat: Dictionary = {}

# === 环境反应机制 ===
# 熔岩池（持续伤害区域）
var lava_pools: Array = []  # {x, width, node}
var lava_damage_timer: float = 0.0
const LAVA_DAMAGE: float = 5.0  # 每次触碰伤害
const LAVA_DAMAGE_INTERVAL: float = 0.8  # 伤害间隔

# 间歇泉（定时喷发）
var geysers: Array = []  # {x, y, timer, interval, active, duration, nodes}
var geyser_timer: float = 0.0

# Boss
var boss: Node2D
var boss_sprite: AnimatedSprite2D
var boss_hit_applied: bool = false

# 熔岩弹（Boss喷吐物）
var lava_projectiles: Array = []  # {pos, vel, node, lifetime, ground_y}

# 传送门
var portal: ColorRect
var portal_label: Label
var portal_pos: Vector2 = Vector2(1890, GROUND_Y)

# 跳跃音效
var was_on_ground: bool = true

# HUD矿石计数
var ore_display: Label

# 当前房间名
var room_label: Label
var room_label_timer: float = 0.0
var current_room: int = 0

# 存档计时器
var save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 30.0

# 战斗状态
var battle_active: bool = false
var boss_intro: bool = false
var boss_intro_timer: float = 0.0
var player_dead: bool = false
var respawn_timer: float = 0.0
var boss_victory: bool = false

func _ready() -> void:
        _build_scene()

func _build_scene() -> void:
        # === 背景（3个房间拼接）===
        for i in range(3):
                var bg_tex = load("res://assets/sprites/background/lava_vein_640x360.png")
                if bg_tex:
                        var bg = TextureRect.new()
                        bg.texture = bg_tex
                        bg.size = Vector2(640, 360)
                        bg.position = Vector2(i * 640, 0)
                        bg.stretch_mode = TextureRect.STRETCH_SCALE
                        add_child(bg)
                else:
                        var bg2 = ColorRect.new()
                        bg2.size = Vector2(640, 360)
                        bg2.position = Vector2(i * 640, 0)
                        bg2.color = Color(0.12, 0.05, 0.06, 1.0)
                        add_child(bg2)

        # 房间分隔拱门
        for i in range(1, 3):
                var pillar_l = ColorRect.new()
                pillar_l.position = Vector2(i * 640 - 10, 60)
                pillar_l.size = Vector2(20, 270)
                pillar_l.color = Color(0.18, 0.1, 0.08, 0.6)
                add_child(pillar_l)
                var cap_l = ColorRect.new()
                cap_l.position = Vector2(i * 640 - 15, 55)
                cap_l.size = Vector2(30, 8)
                cap_l.color = Color(0.3, 0.15, 0.1, 0.7)
                add_child(cap_l)

        # === 地面 ===
        _build_ground()

        # === 房间1：入口（熔岩蜥蜴+火焰蝠+熔岩池）===
        _build_room_entrance()

        # === 房间2：熔岩大厅（间歇泉+密集敌人+熔岩池）===
        _build_room_lava_hall()

        # === 房间3：Boss门前（强敌+传送门）===
        _build_room_boss_gate()

        # === 摄像机 ===
        var camera_script = load("res://scripts/core/camera_controller.gd")
        camera = Node2D.new()
        camera.set_script(camera_script)
        add_child(camera)
        camera.setup(Vector2(640, 360), Vector2.ZERO, Vector2(LEVEL_WIDTH, 360))
        camera.set_position_immediate(Vector2(320, 180))
        camera.activate()

        # === 音效 ===
        var audio_script = load("res://scripts/audio/audio_manager.gd")
        audio = Node2D.new()
        audio.set_script(audio_script)
        add_child(audio)

        # === 打击感特效 ===
        var effects_script = load("res://scripts/core/combat_effects.gd")
        effects = Node2D.new()
        effects.set_script(effects_script)
        add_child(effects)

        # === 掉落系统 ===
        var drop_script = load("res://scripts/core/drop_system.gd")
        drop_system = Node2D.new()
        drop_system.set_script(drop_script)
        add_child(drop_system)

        # === 技能树 ===
        var skill_script = load("res://scripts/ui/skill_tree.gd")
        skill_tree = Node2D.new()
        skill_tree.set_script(skill_script)
        add_child(skill_tree)
        skill_tree.build()
        skill_tree.set_drop_system(drop_system)
        skill_tree.load_skill_data(GameState.skill_levels)
        drop_system.set_pickup_counts(GameState.ore_fragments, GameState.health_potions, GameState.rage_crystals)

        # === 物品栏 ===
        var inv_script = load("res://scripts/ui/inventory.gd")
        inventory_ui = Node2D.new()
        inventory_ui.set_script(inv_script)
        add_child(inventory_ui)
        inventory_ui.build()
        inventory_ui.set_drop_system(drop_system)

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

        # === 玩家（双职业）===
        var player_script: GDScript = null
        if GameState.is_ranger():
                player_script = load("res://scripts/player/ranger.gd")
        else:
                player_script = load("res://scripts/player/warrior.gd")
        player = Node2D.new()
        player.set_script(player_script)
        add_child(player)

        player_sprite = AnimatedSprite2D.new()
        add_child(player_sprite)
        player.setup_sprite(player_sprite)
        player.pos = Vector2(60, GROUND_Y)

        var state = GameState.get_player_state()
        player.hp = state["hp"]
        player.rage = state["rage"]
        player.hit_count = state["hit_count"]
        # 游侠max_hp兼容
        if GameState.is_ranger() and state.has("max_hp"):
                player.max_hp = state["max_hp"]

        # 装备HP加成
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

        drop_system.set_player(player)
        drop_system.set_hud(null)
        drop_system.set_audio(audio)

        # === HUD ===
        var hud_script = load("res://scripts/ui/hud.gd")
        hud = Node2D.new()
        hud.set_script(hud_script)
        add_child(hud)
        hud.build()
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        drop_system.set_hud(hud)

        # === HUD矿石 ===
        ore_display = Label.new()
        ore_display.text = "ORE: " + str(drop_system.get_ore_count())
        ore_display.position = Vector2(560, 5)
        ore_display.add_theme_font_size_override("font_size", 8)
        ore_display.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9, 0.9))
        add_child(ore_display)

        # === 房间名称 ===
        room_label = Label.new()
        room_label.text = "失落地脉 - 入口"
        room_label.position = Vector2(230, 150)
        room_label.add_theme_font_size_override("font_size", 14)
        room_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3, 0.0))
        add_child(room_label)

        # === 版本/操作提示 ===
        var ver = Label.new()
        ver.text = "v0.13"
        ver.position = Vector2(600, 350)
        ver.add_theme_font_size_override("font_size", 7)
        ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
        add_child(ver)

        var hint = Label.new()
        var guard_text: String = "L:闪避" if GameState.is_ranger() else "L:格挡"
        var skill1_text: String = "U:影步" if GameState.is_ranger() else "U:战吼"
        var skill2_text: String = "I:刃风暴" if GameState.is_ranger() else "I:裂地斩"
        hint.text = "A/D:移动 W/Space:跳跃 J:轻攻 K:重攻 " + guard_text + " " + skill1_text + " " + skill2_text + " Tab:技能树 E:装备 Esc:主菜单"
        hint.position = Vector2(40, 350)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.7))
        add_child(hint)

        _show_room_name("失落地脉 - 入口")

func _build_ground() -> void:
        # 地面（覆盖3个房间）
        var ground_top = ColorRect.new()
        ground_top.position = Vector2(0, 329)
        ground_top.size = Vector2(LEVEL_WIDTH, 2)
        ground_top.color = Color(0.4, 0.25, 0.15, 0.8)
        add_child(ground_top)

        var ground = ColorRect.new()
        ground.position = Vector2(0, 330)
        ground.size = Vector2(LEVEL_WIDTH, 30)
        ground.color = Color(0.18, 0.1, 0.08, 0.7)
        add_child(ground)

        # 岩浆裂缝装饰
        for x in range(0, 1920, 40):
                if randf() < 0.35:
                        var crack = ColorRect.new()
                        crack.position = Vector2(x, 329)
                        crack.size = Vector2(randf_range(5, 15), 2)
                        crack.color = Color(0.8, 0.3, 0.05, 0.5)
                        add_child(crack)

func _build_room_entrance() -> void:
        """房间1：入口 - 熔岩蜥蜴+火焰蝠+熔岩池"""
        # 平台
        _build_platform(120, 260, 80)
        _build_platform(300, 240, 100)
        _build_platform(480, 260, 80)

        # 熔岩池（地面上的持续伤害区域）
        _add_lava_pool(180, 60)
        _add_lava_pool(420, 50)

        # 小怪（复用矿工亡魂AI作为熔岩蜥蜴）
        _spawn_enemy(Vector2(220, GROUND_Y), 200)
        _spawn_enemy(Vector2(520, GROUND_Y), 180)

        # 蝙蝠
        _spawn_bat(Vector2(350, 200), 180)

func _build_room_lava_hall() -> void:
        """房间2：熔岩大厅 - 间歇泉+密集敌人+熔岩池"""
        # 平台
        _build_platform(780, 260, 80)
        _build_platform(900, 230, 120)
        _build_platform(1080, 250, 80)
        _build_platform(1200, 220, 60)

        # 熔岩池
        _add_lava_pool(700, 80)
        _add_lava_pool(1000, 70)
        _add_lava_pool(1180, 50)

        # 间歇泉（定时喷发蒸汽/熔岩）
        _add_geyser(760, GROUND_Y, 6.0)
        _add_geyser(950, GROUND_Y, 8.0)
        _add_geyser(1150, GROUND_Y, 5.0)

        # 小怪
        _spawn_enemy(Vector2(750, GROUND_Y), 180)
        _spawn_enemy(Vector2(950, GROUND_Y), 160)
        _spawn_enemy(Vector2(1150, GROUND_Y), 150)

        # 蝙蝠
        _spawn_bat(Vector2(800, 190), 160)
        _spawn_bat(Vector2(1050, 170), 150)

func _build_room_boss_gate() -> void:
        """房间3：Boss门前 - 强敌+传送门到Boss战"""
        # 平台
        _build_platform(1350, 250, 100)
        _build_platform(1520, 230, 80)
        _build_platform(1700, 260, 80)

        # 熔岩池
        _add_lava_pool(1400, 60)
        _add_lava_pool(1650, 50)

        # 间歇泉
        _add_geyser(1500, GROUND_Y, 7.0)

        # Boss门装饰
        var gate_arch = ColorRect.new()
        gate_arch.position = Vector2(1830, 220)
        gate_arch.size = Vector2(60, 110)
        gate_arch.color = Color(0.2, 0.1, 0.12, 0.9)
        add_child(gate_arch)
        var gate_top = ColorRect.new()
        gate_top.position = Vector2(1825, 215)
        gate_top.size = Vector2(70, 8)
        gate_top.color = Color(0.35, 0.15, 0.1, 0.8)
        add_child(gate_top)
        # 门上发光符文
        var gate_glow = ColorRect.new()
        gate_glow.position = Vector2(1850, 250)
        gate_glow.size = Vector2(20, 20)
        gate_glow.color = Color(0.9, 0.4, 0.1, 0.4)
        add_child(gate_glow)

        # 强敌
        _spawn_enemy(Vector2(1400, GROUND_Y), 200)
        _spawn_enemy(Vector2(1650, GROUND_Y), 180)

        # 蝙蝠
        _spawn_bat(Vector2(1500, 180), 150)
        _spawn_bat(Vector2(1750, 200), 140)

        # 传送门
        _build_portal()

func _build_platform(x: float, y: float, width: float) -> void:
        var plat = ColorRect.new()
        plat.position = Vector2(x, y)
        plat.size = Vector2(width, 6)
        plat.color = Color(0.3, 0.18, 0.12, 0.8)
        add_child(plat)
        # 支撑柱
        var support = ColorRect.new()
        support.position = Vector2(x + 2, y + 6)
        support.size = Vector2(2, GROUND_Y - y - 6)
        support.color = Color(0.2, 0.12, 0.08, 0.4)
        add_child(support)
        var support2 = ColorRect.new()
        support2.position = Vector2(x + width - 4, y + 6)
        support2.size = Vector2(2, GROUND_Y - y - 6)
        support2.color = Color(0.2, 0.12, 0.08, 0.4)
        add_child(support2)

func _add_lava_pool(x: float, width: float) -> void:
        """创建地面熔岩池"""
        var pool_node = ColorRect.new()
        pool_node.position = Vector2(x, 326)
        pool_node.size = Vector2(width, 4)
        pool_node.color = Color(0.9, 0.35, 0.05, 0.8)
        add_child(pool_node)

        # 熔岩发光
        var glow = ColorRect.new()
        glow.position = Vector2(x - 2, 324)
        glow.size = Vector2(width + 4, 8)
        glow.color = Color(1.0, 0.5, 0.1, 0.3)
        add_child(glow)

        lava_pools.append({"x": x, "width": width, "node": pool_node})

func _add_geyser(x: float, y: float, interval: float) -> void:
        """创建间歇泉"""
        # 间歇泉口标记
        var vent = ColorRect.new()
        vent.position = Vector2(x - 8, y - 4)
        vent.size = Vector2(16, 4)
        vent.color = Color(0.5, 0.3, 0.15, 0.6)
        add_child(vent)

        geysers.append({
                "x": x,
                "y": y,
                "timer": randf() * interval,
                "interval": interval,
                "active": false,
                "duration": 0.0,
                "nodes": [],
                "vent": vent,
                "dealt_damage": false,
        })

func _build_portal() -> void:
        portal = ColorRect.new()
        portal.size = Vector2(12, 50)
        portal.position = portal_pos + Vector2(0, -50)
        portal.color = Color(1.0, 0.5, 0.2, 0.5)
        add_child(portal)

        var portal_border = ColorRect.new()
        portal_border.size = Vector2(14, 52)
        portal_border.position = portal_pos + Vector2(-1, -51)
        portal_border.color = Color(1.0, 0.7, 0.3, 0.3)
        add_child(portal_border)

        portal_label = Label.new()
        portal_label.text = "→Boss"
        portal_label.position = portal_pos + Vector2(-25, -60)
        portal_label.add_theme_font_size_override("font_size", 7)
        portal_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 0.7))
        add_child(portal_label)

func _spawn_enemy(pos: Vector2, detect: float) -> void:
        var enemy_script = load("res://scripts/enemy/mine_wraith.gd")
        var enemy = Node2D.new()
        enemy.set_script(enemy_script)
        enemy.pos = pos
        enemy.patrol_center = pos.x
        enemy.detect_range = detect
        add_child(enemy)
        var enemy_sprite = AnimatedSprite2D.new()
        add_child(enemy_sprite)
        enemy.setup(enemy_sprite)
        enemies.append(enemy)
        enemy_sprites.append(enemy_sprite)
        player_hit_by_enemy[enemies.size() - 1] = false
        enemy.enemy_hit_player.connect(_on_enemy_hit_player)
        enemy.enemy_died.connect(_on_enemy_died)

func _spawn_bat(pos: Vector2, detect: float) -> void:
        var bat_script = load("res://scripts/enemy/cave_bat.gd")
        var bat = Node2D.new()
        bat.set_script(bat_script)
        bat.pos = pos
        bat.hover_center = pos
        bat.detect_range = detect
        add_child(bat)
        var bat_sprite = AnimatedSprite2D.new()
        add_child(bat_sprite)
        bat.setup(bat_sprite)
        bats.append(bat)
        bat_sprites.append(bat_sprite)
        player_hit_by_bat[bats.size() - 1] = false
        bat.enemy_hit_player.connect(_on_bat_hit_player)
        bat.enemy_died.connect(_on_bat_died)

func _show_room_name(name: String) -> void:
        room_label.text = name
        room_label_timer = 3.0

func _physics_process(delta: float) -> void:
        frame_count += 1

        # 面板暂停
        if skill_tree.is_open:
                skill_tree.process_input()
                return
        if inventory_ui.is_open:
                inventory_ui.process_input()
                return
        if equipment.is_open:
                equipment.process_input()
                return

        # Tab/E/Esc
        if Input.is_key_pressed(KEY_TAB):
                if Input.is_key_pressed(KEY_SHIFT):
                        inventory_ui.toggle()
                else:
                        skill_tree.toggle()
                return
        if Input.is_key_pressed(KEY_E):
                equipment.toggle()
                return
        if Input.is_key_pressed(KEY_ESCAPE):
                _save_and_quit()
                return

        # Hitstop
        if effects.hitstop_active:
                effects.process(delta)
                camera.apply_shake(effects.get_shake_offset())
                return

        camera_offset = effects.get_shake_offset()
        camera.apply_shake(camera_offset)

        # 处理战士
        player.process(delta, GROUND_Y)
        player.pos.x = clamp(player.pos.x, 20, LEVEL_WIDTH - 20)

        # 跳跃/落地音效
        var on_ground: bool = player.pos.y >= GROUND_Y - 3
        if not was_on_ground and on_ground:
                audio.play("land")
        was_on_ground = on_ground

        # 检测房间切换
        _check_room_change()

        # 处理小怪
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp > 0:
                        enemy.process(delta, player.pos, GROUND_Y)

        # 处理蝙蝠
        for i in range(bats.size()):
                var bat: Node2D = bats[i]
                if bat.hp > 0:
                        bat.process(delta, player.pos, GROUND_Y)

        # === 环境反应：熔岩池 ===
        _process_lava_pools(delta)

        # === 环境反应：间歇泉 ===
        _process_geysers(delta)

        # 碰撞检测
        _check_player_vs_enemies()
        _check_player_vs_bats()
        _check_enemies_vs_player()
        _check_bats_vs_player()

        # 掉落物
        drop_system.process(delta)

        # 传送门
        _check_portal()

        # 更新视觉
        _update_visuals()

        # 更新摄像机
        camera.follow(player.pos, player.facing, delta)

        # 更新HUD
        hud.update_player_hp(player.hp, player.max_hp)
        hud.update_rage(player.rage, player.max_rage)
        hud.update_hit_count(player.hit_count)
        hud.show_war_cry_buff(player.war_cry_buff, player.war_cry_timer)
        hud.process_effects(delta)
        effects.process(delta)

        # 矿石计数
        ore_display.text = "ORE: " + str(drop_system.get_ore_count())

        # 房间名称渐隐
        if room_label_timer > 0:
                room_label_timer -= delta
                var alpha: float = min(1.0, room_label_timer / 1.5)
                room_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3, alpha))

        # 连招
        if player.combo_timer <= 0 and not player.is_attacking:
                hud.clear_combo()
        if player.is_attacking and player.attack_name != "":
                hud.show_combo(player.attack_name, player.war_cry_buff)

        # 死亡重生
        if player.hp <= 0 and player.invincible_timer <= 0:
                if Input.is_key_pressed(KEY_R):
                        player.hp = player.max_hp
                        player.rage = 0
                        player.pos = Vector2(max(60, player.pos.x - 200), GROUND_Y)
                        player.vel = Vector2.ZERO
                        player.is_hurt = false
                        player.invincible_timer = 2.0
                        player.hit_count = 0
                        audio.play("level_up", 0.5)

        # 熔岩弹更新
        _process_lava_projectiles(delta)

        # 截图
        if frame_count == 120:
                _take_screenshot("legend_lava_level.png")

        # 自动演示/退出
        if auto_demo:
                _run_demo()
        if auto_quit_frame > 0 and frame_count >= auto_quit_frame:
                _take_screenshot("legend_lava_auto.png")
                get_tree().quit()

        # 清理
        _cleanup_dead_enemies()
        _cleanup_dead_bats()

        # 保存
        _save_state()

        # 自动存档
        save_timer += delta
        if save_timer >= AUTO_SAVE_INTERVAL:
                save_timer = 0
                SaveSystem.save_game()

        # 传送门闪烁
        if portal:
                portal.color = Color(1.0, 0.5, 0.2, 0.3 + 0.3 * sin(frame_count * 0.08))

# === 环境反应：熔岩池 ===
func _process_lava_pools(delta: float) -> void:
        lava_damage_timer -= delta
        if lava_damage_timer > 0:
                return

        var player_on_ground: bool = player.pos.y >= GROUND_Y - 5
        if not player_on_ground:
                return

        for pool in lava_pools:
                if player.pos.x >= pool["x"] and player.pos.x <= pool["x"] + pool["width"]:
                        if player.invincible_timer <= 0:
                                var dmg: float = LAVA_DAMAGE * (1.0 - skill_tree.get_defense_bonus()) * (1.0 - equipment.get_defense_bonus())
                                player.take_damage(dmg, Vector2(randf_range(-2, 2), -3))
                                hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                                hud.show_perfect("LAVA!", Color(1.0, 0.4, 0.1))
                                audio.play("hurt", 0.4)
                                lava_damage_timer = LAVA_DAMAGE_INTERVAL
                        break

        # 熔岩池闪烁动画
        for pool in lava_pools:
                if pool["node"] and is_instance_valid(pool["node"]):
                        var intensity: float = 0.6 + 0.4 * sin(frame_count * 0.05)
                        pool["node"].color = Color(0.9 * intensity, 0.35 * intensity, 0.05, 0.8)

# === 环境反应：间歇泉 ===
func _process_geysers(delta: float) -> void:
        for geyser in geysers:
                if geyser["active"]:
                        geyser["duration"] -= delta
                        # 喷发伤害判定
                        if not geyser["dealt_damage"]:
                                var dist_x: float = abs(player.pos.x - geyser["x"])
                                var dist_y: float = abs(player.pos.y - GROUND_Y)
                                if dist_x < 30 and dist_y < 40 and player.invincible_timer <= 0:
                                        var dmg: float = 12.0 * (1.0 - skill_tree.get_defense_bonus()) * (1.0 - equipment.get_defense_bonus())
                                        player.take_damage(dmg, Vector2(randf_range(-3, 3), -6))
                                        hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                                        hud.show_perfect("GEYSER!", Color(1.0, 0.6, 0.1))
                                        effects.start_shake(3.0, 8.0)
                                        audio.play("rock_fall")
                                        geyser["dealt_damage"] = true

                        # 喷发粒子更新
                        for p in geyser["nodes"]:
                                if p["node"] and is_instance_valid(p["node"]):
                                        p["vel"].y -= 200 * delta
                                        p["pos"] += p["vel"] * delta
                                        p["node"].position = p["pos"]
                                        p["lifetime"] -= delta
                                        if p["lifetime"] <= 0:
                                                p["node"].queue_free()
                                        elif p["lifetime"] < 0.3:
                                                p["node"].visible = int(p["lifetime"] * 10) % 2 == 0

                        if geyser["duration"] <= 0:
                                geyser["active"] = false
                                geyser["timer"] = geyser["interval"]
                                # 清理粒子
                                for p in geyser["nodes"]:
                                        if p["node"] and is_instance_valid(p["node"]):
                                                p["node"].queue_free()
                                geyser["nodes"] = []
                else:
                        geyser["timer"] -= delta
                        # 预警：喷发前1秒闪烁
                        if geyser["timer"] < 1.0 and geyser["timer"] > 0:
                                if geyser["vent"] and is_instance_valid(geyser["vent"]):
                                        geyser["vent"].color = Color(1.0, 0.5, 0.1, 0.5 + 0.5 * sin(geyser["timer"] * 15))
                        if geyser["timer"] <= 0:
                                # 喷发！
                                geyser["active"] = true
                                geyser["duration"] = 1.0
                                geyser["dealt_damage"] = false
                                effects.start_shake(2.0, 6.0)
                                audio.play("rock_fall")
                                # 生成喷发粒子
                                for j in range(5):
                                        var particle = ColorRect.new()
                                        particle.size = Vector2(randf_range(3, 6), randf_range(3, 6))
                                        var p_pos: Vector2 = Vector2(geyser["x"] + randf_range(-8, 8), GROUND_Y - 5)
                                        particle.position = p_pos
                                        particle.color = Color(1.0, randf_range(0.3, 0.7), 0.0, 0.9)
                                        add_child(particle)
                                        geyser["nodes"].append({
                                                "node": particle,
                                                "pos": p_pos,
                                                "vel": Vector2(randf_range(-30, 30), randf_range(-250, -150)),
                                                "lifetime": randf_range(0.5, 1.0),
                                        })

# === 熔岩弹（Boss喷吐物） ===
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

                # 抛物线物理
                proj["vel"].y += 500 * delta
                proj["pos"] += proj["vel"] * delta
                proj["node"].position = proj["pos"]

                # 落地
                if proj["pos"].y >= proj["ground_y"]:
                        # 落地爆炸伤害
                        var dist: float = abs(player.pos.x - proj["pos"].x)
                        if dist < 40 and player.invincible_timer <= 0:
                                var dmg: float = 10.0 * (1.0 - skill_tree.get_defense_bonus()) * (1.0 - equipment.get_defense_bonus())
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
                        var dmg: float = 12.0 * (1.0 - skill_tree.get_defense_bonus()) * (1.0 - equipment.get_defense_bonus())
                        player.take_damage(dmg, Vector2(randf_range(-3, 3), -4))
                        hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, true)
                        effects.spawn_hit_spark(proj["pos"], Color(1.0, 0.5, 0.1))
                        audio.play("hurt")
                        proj["node"].queue_free()
                        lava_projectiles.remove_at(i)

func _spawn_lava_projectile(spawn_pos: Vector2, vel: Vector2) -> void:
        """生成熔岩弹"""
        var node = Node2D.new()
        add_child(node)

        # 熔岩弹视觉
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
                "ground_y": GROUND_Y - 5,
        })

func _check_room_change() -> void:
        var new_room: int = int(player.pos.x / 640.0)
        new_room = clamp(new_room, 0, 2)
        if new_room != current_room:
                current_room = new_room
                match current_room:
                        0: _show_room_name("失落地脉 - 入口")
                        1: _show_room_name("失落地脉 - 熔岩大厅")
                        2: _show_room_name("失地产脉 - Boss门前")

func _check_portal() -> void:
        var dist_to_portal = abs(player.pos.x - portal_pos.x)
        if dist_to_portal < 25:
                audio.play("portal")
                GameState.mark_level_cleared("lava")
                SaveSystem.save_game()
                GameState.go_to_level("lava_boss")

# === 碰撞检测 ===
func _check_player_vs_enemies() -> void:
        if not player.is_in_active_frames():
                return
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp <= 0: continue
                var dist = abs(player.pos.x - enemy.pos.x)
                if dist < 65:
                        var dmg: float = _get_skill_boosted_damage(player.get_attack_damage()) * equipment.get_attack_bonus()
                        enemy.take_damage(dmg)
                        player.mark_hit_dealt()
                        var hit_pos: Vector2 = (player.pos + enemy.pos) / 2 + Vector2(0, -20)
                        effects.spawn_hit_spark(hit_pos, Color(1, 0.9, 0.5))
                        if dmg >= 20:
                                effects.start_hitstop(0.08); effects.start_shake(3.0, 8.0); audio.play("hit_heavy")
                        else:
                                effects.start_hitstop(0.04); effects.start_shake(1.0, 6.0); audio.play("hit_light")
                        hud.spawn_damage_number(enemy.pos + Vector2(0, -40), dmg, dmg >= 20)
                        player.rage = min(player.max_rage, player.rage + _get_skill_boosted_rage(5.0))
                        break

func _check_player_vs_bats() -> void:
        if not player.is_in_active_frames():
                return
        for i in range(bats.size()):
                var bat: Node2D = bats[i]
                if bat.hp <= 0: continue
                var dist_x = abs(player.pos.x - bat.pos.x)
                var dist_y = abs(player.pos.y - bat.pos.y)
                if dist_x < 65 and dist_y < 50:
                        var dmg: float = _get_skill_boosted_damage(player.get_attack_damage()) * equipment.get_attack_bonus()
                        bat.take_damage(dmg)
                        player.mark_hit_dealt()
                        effects.spawn_hit_spark((player.pos + bat.pos) / 2, Color(1, 0.6, 0.8))
                        effects.start_hitstop(0.04); effects.start_shake(1.5, 7.0); audio.play("hit_light")
                        hud.spawn_damage_number(bat.pos + Vector2(0, -40), dmg, dmg >= 20)
                        player.rage = min(player.max_rage, player.rage + _get_skill_boosted_rage(5.0))
                        break

func _check_enemies_vs_player() -> void:
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp <= 0: continue
                var dist = abs(player.pos.x - enemy.pos.x)
                if enemy.is_in_attack_active() and not player_hit_by_enemy.get(i, false):
                        if dist < 60:
                                var dmg: float = _get_skill_reduced_damage(enemy.get_attack_damage()) * (1.0 - equipment.get_defense_bonus())
                                player.take_damage(dmg, Vector2(4 * enemy.facing, -2))
                                hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                                effects.start_hitstop(0.04); effects.start_shake(2.0, 7.0); audio.play("hurt")
                                player_hit_by_enemy[i] = true
                if not enemy.is_in_attack_active():
                        player_hit_by_enemy[i] = false

func _check_bats_vs_player() -> void:
        for i in range(bats.size()):
                var bat: Node2D = bats[i]
                if bat.hp <= 0: continue
                if bat.is_in_attack_active() and not player_hit_by_bat.get(i, false):
                        var dist_x = abs(player.pos.x - bat.pos.x)
                        var dist_y = abs(player.pos.y - bat.pos.y)
                        if dist_x < 45 and dist_y < 40:
                                var dmg: float = _get_skill_reduced_damage(bat.get_attack_damage()) * (1.0 - equipment.get_defense_bonus())
                                player.take_damage(dmg, Vector2(3 * bat.facing, -3))
                                hud.spawn_damage_number(player.pos + Vector2(0, -40), dmg, false)
                                effects.start_hitstop(0.04); effects.start_shake(1.5, 7.0); audio.play("hurt")
                                player_hit_by_bat[i] = true
                if not bat.is_in_attack_active():
                        player_hit_by_bat[i] = false

# === 技能加成 ===
func _get_skill_boosted_damage(base_dmg: float) -> float:
        return base_dmg * skill_tree.get_attack_bonus()

func _get_skill_reduced_damage(base_dmg: float) -> float:
        return base_dmg * (1.0 - skill_tree.get_defense_bonus())

func _get_skill_boosted_rage(base_rage: float) -> float:
        return base_rage * skill_tree.get_rage_bonus()

# === 事件回调 ===
func _on_enemy_hit_player(damage: float, knockback: Vector2) -> void: pass
func _on_enemy_died(pos: Vector2) -> void:
        effects.spawn_hit_spark(pos, Color(0.9, 0.5, 0.3))
        player.rage = min(player.max_rage, player.rage + _get_skill_boosted_rage(15.0))
        hud.show_perfect("+15 RAGE", Color(0.9, 0.5, 0.3)); audio.play("enemy_die")
        GameState.total_kills += 1
        drop_system.spawn_drop(pos, "wraith", GROUND_Y)
        # v0.12: 地脉小怪稀有掉落（地脉结晶12%）
        if randf() < 0.12:
                GameState.crafting_materials["vein_crystal"] = int(GameState.crafting_materials.get("vein_crystal", 0)) + 1
                hud.show_perfect("+1 地脉结晶!", Color(0.9, 0.6, 0.2))

func _on_bat_hit_player(damage: float, knockback: Vector2) -> void: pass
func _on_bat_died(pos: Vector2) -> void:
        effects.spawn_hit_spark(pos, Color(1.0, 0.6, 0.3))
        player.rage = min(player.max_rage, player.rage + _get_skill_boosted_rage(10.0))
        hud.show_perfect("+10 RAGE", Color(1.0, 0.6, 0.3)); audio.play("enemy_die")
        GameState.total_kills += 1
        drop_system.spawn_drop(pos, "bat", GROUND_Y)
        # v0.12: 地脉蝙蝠稀有掉落（地脉结晶10%）
        if randf() < 0.10:
                GameState.crafting_materials["vein_crystal"] = int(GameState.crafting_materials.get("vein_crystal", 0)) + 1
                hud.show_perfect("+1 地脉结晶!", Color(0.9, 0.6, 0.2))

func _cleanup_dead_enemies() -> void:
        for i in range(enemies.size() - 1, -1, -1):
                var enemy: Node2D = enemies[i]
                if enemy.hp <= 0 and enemy.current_state == 4:  # State.DYING
                        if not enemy.sprite or not enemy.sprite.is_playing():
                                if enemy.sprite and is_instance_valid(enemy.sprite): enemy.sprite.queue_free()
                                enemy.queue_free(); enemies.remove_at(i); enemy_sprites.remove_at(i)

func _cleanup_dead_bats() -> void:
        for i in range(bats.size() - 1, -1, -1):
                var bat: Node2D = bats[i]
                if bat.hp <= 0 and bat.current_state == 5:  # State.DYING
                        if not bat.sprite or not bat.sprite.is_playing():
                                if bat.sprite and is_instance_valid(bat.sprite): bat.sprite.queue_free()
                                bat.queue_free(); bats.remove_at(i); bat_sprites.remove_at(i)

func _update_visuals() -> void:
        var shake = camera_offset
        player_sprite.position = player.pos + Vector2(0, -32) + shake
        player_sprite.flip_h = (player.facing < 0)
        if player.invincible_timer > 0:
                player_sprite.visible = int(frame_count / 3) % 2 == 0
        else:
                player_sprite.visible = true
        if player.war_cry_buff:
                if int(frame_count / 4) % 3 == 0: player_sprite.modulate = Color(1.2, 1.0, 0.7)
                else: player_sprite.modulate = Color(1, 1, 1)
        if player.is_guarding and player.is_perfect_parry_window:
                parry_indicator.visible = true
                parry_indicator.position = player.pos + Vector2(-10 * player.facing, -42) + shake
        else:
                parry_indicator.visible = false
        for i in range(enemies.size()):
                if i < enemy_sprites.size() and is_instance_valid(enemy_sprites[i]):
                        enemy_sprites[i].position = enemies[i].pos + Vector2(0, -32) + shake
                        enemy_sprites[i].flip_h = (enemies[i].facing < 0)
        for i in range(bats.size()):
                if i < bat_sprites.size() and is_instance_valid(bat_sprites[i]):
                        bat_sprites[i].position = bats[i].pos + Vector2(0, -32) + shake
                        bat_sprites[i].flip_h = (bats[i].facing < 0)

func _save_state() -> void:
        GameState.save_player_state(player.hp, player.rage, player.hit_count)
        GameState.save_resources(drop_system.ore_fragments, skill_tree.get_skill_data())
        var pickup_counts: Dictionary = drop_system.get_pickup_counts()
        GameState.save_pickup_counts(pickup_counts["ore_fragments"], pickup_counts["health_potions"], pickup_counts["rage_crystals"])
        GameState.current_level = "lava"
        GameState.save_crafting_materials(crafting_system.get_save_data())

func _save_and_quit() -> void:
        _save_state()
        SaveSystem.save_game()
        GameState.go_to_title()

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img: img.save_png("/home/z/my-project/download/" + filename)

func _run_demo() -> void:
        match frame_count:
                60: player.vel.x = 200; player.facing = 1.0
                100: player.do_attack("L"); audio.play("swing")
                140: player.do_attack("L"); audio.play("swing")
                180: player.vel.x = 0
