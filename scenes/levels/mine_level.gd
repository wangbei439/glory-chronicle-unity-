## 幽影矿井关卡 - Beta v0.10
## 多房间滚动关卡：入口(640px)→矿道深处(640px)→Boss门前(640px)
## 总宽度1920px，摄像机跟随滚动
## v0.9: 多房间地图、矿车障碍、存档集成、物品栏
## v0.10: bug修复(war_cry双计时/物品栏/魔法数字) + 装备系统
extends Node2D

const GROUND_Y: float = 309.0
const LEVEL_WIDTH: float = 1920.0  # 3个房间 × 640px

# === 自动演示模式 ===
@export var auto_demo: bool = false
@export var auto_quit_frame: int = 0

# 子系统
var warrior: Node2D
var effects: Node2D
var hud: Node2D
var camera: Node2D
var audio: Node2D
var drop_system: Node2D
var skill_tree: Node2D
var inventory_ui: Node2D
var equipment: Node2D

# 小怪（矿工亡魂）
var enemies: Array = []
var enemy_sprites: Array = []

# 蝙蝠
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

# 陷阱（落石）
var rock_traps: Array = []
var trap_triggered: Dictionary = {}

# 矿车障碍
var mine_carts: Array = []
var cart_timer: float = 0.0
var cart_interval: float = 5.0
var cart_warning_shown: bool = false

# 传送门（在第三个房间末尾）
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
const AUTO_SAVE_INTERVAL: float = 30.0  # 每30秒自动存档

func _ready() -> void:
        _build_scene()

func _build_scene() -> void:
        # === 背景（3个房间的拼接背景）===
        for i in range(3):
                var bg_tex = load("res://assets/sprites/background/dungeon_mine_640x360.png")
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
                        bg2.color = Color(0.05, 0.05, 0.12, 1.0)
                        add_child(bg2)

        # 房间分隔线（装饰性拱门标记）
        for i in range(1, 3):
                var pillar_l = ColorRect.new()
                pillar_l.position = Vector2(i * 640 - 10, 60)
                pillar_l.size = Vector2(20, 270)
                pillar_l.color = Color(0.12, 0.1, 0.15, 0.6)
                add_child(pillar_l)
                var cap_l = ColorRect.new()
                cap_l.position = Vector2(i * 640 - 15, 55)
                cap_l.size = Vector2(30, 8)
                cap_l.color = Color(0.18, 0.15, 0.22, 0.7)
                add_child(cap_l)

        # === 地面 ===
        _build_ground()

        # === 房间1：入口（小怪+蝙蝠）===
        _build_room_entrance()

        # === 房间2：矿道深处（矿车+更多敌人+落石）===
        _build_room_mineshaft()

        # === 房间3：Boss门前（强敌+传送门）===
        _build_room_boss_gate()

        # === 摄像机控制器 ===
        var camera_script = load("res://scripts/core/camera_controller.gd")
        camera = Node2D.new()
        camera.set_script(camera_script)
        add_child(camera)
        camera.setup(Vector2(640, 360), Vector2.ZERO, Vector2(LEVEL_WIDTH, 360))
        camera.set_position_immediate(Vector2(320, 180))
        camera.activate()

        # === 音效系统 ===
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
        drop_system.ore_fragments = GameState.ore_fragments

        # === 物品栏UI ===
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

        # === 战士 ===
        var warrior_script = load("res://scripts/player/warrior.gd")
        warrior = Node2D.new()
        warrior.set_script(warrior_script)
        add_child(warrior)

        player_sprite = AnimatedSprite2D.new()
        add_child(player_sprite)
        warrior.setup_sprite(player_sprite)
        warrior.pos = Vector2(60, GROUND_Y)

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

        # 设置掉落系统引用
        drop_system.set_player(warrior)
        drop_system.set_hud(null)
        drop_system.set_audio(audio)

        # === HUD ===
        var hud_script = load("res://scripts/ui/hud.gd")
        hud = Node2D.new()
        hud.set_script(hud_script)
        add_child(hud)
        hud.build()
        hud.update_player_hp(warrior.hp, warrior.max_hp)
        hud.update_rage(warrior.rage, warrior.max_rage)
        drop_system.set_hud(hud)

        # === HUD矿石计数 ===
        ore_display = Label.new()
        ore_display.text = "ORE: " + str(drop_system.ore_fragments)
        ore_display.position = Vector2(560, 5)
        ore_display.add_theme_font_size_override("font_size", 8)
        ore_display.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9, 0.9))
        add_child(ore_display)

        # === 房间名称显示 ===
        room_label = Label.new()
        room_label.text = "幽影矿井 - 入口"
        room_label.position = Vector2(230, 150)
        room_label.add_theme_font_size_override("font_size", 14)
        room_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 0.0))
        add_child(room_label)

        # === 版本/操作提示 ===
        var ver = Label.new()
        ver.text = "v0.10"
        ver.position = Vector2(600, 350)
        ver.add_theme_font_size_override("font_size", 7)
        ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
        add_child(ver)

        var hint = Label.new()
        hint.text = "A/D:移动 W/Space:跳跃 J:轻攻 K:重攻 L:格挡 U:战吼 I:裂地斩 Tab:技能树 E:装备 Shift+Tab:物品 Esc:主菜单"
        hint.position = Vector2(40, 350)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.7))
        add_child(hint)

        # 入场显示房间名
        _show_room_name("幽影矿井 - 入口")

func _build_ground() -> void:
        # 地面（覆盖全部3个房间）
        var ground_top = ColorRect.new()
        ground_top.position = Vector2(0, 329)
        ground_top.size = Vector2(LEVEL_WIDTH, 2)
        ground_top.color = Color(0.35, 0.4, 0.45, 0.8)
        add_child(ground_top)

        var ground = ColorRect.new()
        ground.position = Vector2(0, 330)
        ground.size = Vector2(LEVEL_WIDTH, 30)
        ground.color = Color(0.15, 0.17, 0.2, 0.6)
        add_child(ground)

        # 裂缝装饰（分散在3个房间）
        for x in [80, 200, 400, 750, 900, 1050, 1350, 1500, 1700]:
                var crack = ColorRect.new()
                crack.position = Vector2(x, 329)
                crack.size = Vector2(randf_range(8, 20), 2)
                crack.color = Color(0.1, 0.12, 0.15, 0.5)
                add_child(crack)

func _build_room_entrance() -> void:
        """房间1：入口 (x: 0-640) - 简单敌人+蝙蝠入门"""
        # 平台
        _build_platform(130, 260, 80)
        _build_platform(300, 240, 100)
        _build_platform(480, 260, 80)

        # 落石陷阱
        _add_trap(280)
        _add_trap(450)

        # 小怪
        _spawn_enemy(Vector2(220, GROUND_Y), 200)
        _spawn_enemy(Vector2(520, GROUND_Y), 160)

        # 蝙蝠
        _spawn_bat(Vector2(350, 200), 180)

func _build_room_mineshaft() -> void:
        """房间2：矿道深处 (x: 640-1280) - 矿车+密集敌人+落石"""
        # 平台
        _build_platform(780, 260, 80)
        _build_platform(900, 230, 120)
        _build_platform(1080, 250, 80)
        _build_platform(1200, 220, 60)

        # 轨道（矿车运行轨道标记）
        var track = ColorRect.new()
        track.position = Vector2(640, 325)
        track.size = Vector2(640, 2)
        track.color = Color(0.4, 0.35, 0.25, 0.6)
        add_child(track)

        var track2 = ColorRect.new()
        track2.position = Vector2(640, 328)
        track2.size = Vector2(640, 1)
        track2.color = Color(0.3, 0.25, 0.18, 0.4)
        add_child(track2)

        # 轨道枕木
        for x in range(650, 1280, 40):
                var tie = ColorRect.new()
                tie.position = Vector2(x, 323)
                tie.size = Vector2(15, 5)
                tie.color = Color(0.3, 0.22, 0.15, 0.5)
                add_child(tie)

        # 落石陷阱
        _add_trap(850)
        _add_trap(1100)

        # 小怪
        _spawn_enemy(Vector2(750, GROUND_Y), 180)
        _spawn_enemy(Vector2(950, GROUND_Y), 160)
        _spawn_enemy(Vector2(1150, GROUND_Y), 140)

        # 蝙蝠
        _spawn_bat(Vector2(800, 190), 160)
        _spawn_bat(Vector2(1050, 170), 150)

func _build_room_boss_gate() -> void:
        """房间3：Boss门前 (x: 1280-1920) - 强敌+传送门"""
        # 平台
        _build_platform(1350, 250, 100)
        _build_platform(1520, 230, 80)
        _build_platform(1700, 260, 80)

        # Boss门装饰
        var gate_arch = ColorRect.new()
        gate_arch.position = Vector2(1830, 220)
        gate_arch.size = Vector2(60, 110)
        gate_arch.color = Color(0.15, 0.12, 0.2, 0.9)
        add_child(gate_arch)
        var gate_top = ColorRect.new()
        gate_top.position = Vector2(1825, 215)
        gate_top.size = Vector2(70, 8)
        gate_top.color = Color(0.25, 0.2, 0.35, 0.8)
        add_child(gate_top)
        # 门上发光符号
        var gate_glow = ColorRect.new()
        gate_glow.position = Vector2(1850, 250)
        gate_glow.size = Vector2(20, 20)
        gate_glow.color = Color(0.5, 0.3, 0.8, 0.4)
        add_child(gate_glow)

        # 落石
        _add_trap(1400)
        _add_trap(1650)

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
        plat.color = Color(0.25, 0.27, 0.3, 0.8)
        add_child(plat)
        # 支撑柱
        var support = ColorRect.new()
        support.position = Vector2(x + 2, y + 6)
        support.size = Vector2(2, GROUND_Y - y - 6)
        support.color = Color(0.2, 0.22, 0.25, 0.4)
        add_child(support)
        var support2 = ColorRect.new()
        support2.position = Vector2(x + width - 4, y + 6)
        support2.size = Vector2(2, GROUND_Y - y - 6)
        support2.color = Color(0.2, 0.22, 0.25, 0.4)
        add_child(support2)

func _add_trap(x: float) -> void:
        var marker = ColorRect.new()
        marker.position = Vector2(x - 15, 327)
        marker.size = Vector2(30, 2)
        marker.color = Color(0.6, 0.5, 0.2, 0.3)
        add_child(marker)
        rock_traps.append({"x": x, "active": false, "rocks": []})
        trap_triggered[rock_traps.size() - 1] = false

func _build_portal() -> void:
        portal = ColorRect.new()
        portal.size = Vector2(12, 50)
        portal.position = portal_pos + Vector2(0, -50)
        portal.color = Color(0.3, 0.6, 1.0, 0.5)
        add_child(portal)

        var portal_border = ColorRect.new()
        portal_border.size = Vector2(14, 52)
        portal_border.position = portal_pos + Vector2(-1, -51)
        portal_border.color = Color(0.5, 0.8, 1.0, 0.3)
        add_child(portal_border)

        portal_label = Label.new()
        portal_label.text = "→Boss"
        portal_label.position = portal_pos + Vector2(-25, -60)
        portal_label.add_theme_font_size_override("font_size", 7)
        portal_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.7))
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
        """显示房间名称（渐隐效果）"""
        room_label.text = name
        room_label_timer = 3.0

func _physics_process(delta: float) -> void:
        frame_count += 1

        # 技能树/物品栏/装备面板打开时暂停游戏
        if skill_tree.is_open:
                skill_tree.process_input()
                return
        if inventory_ui.is_open:
                inventory_ui.process_input()
                return
        if equipment.is_open:
                equipment.process_input()
                return

        # Tab键打开技能树/物品栏/装备（Shift+Tab切换物品栏, E装备）
        if Input.is_key_pressed(KEY_TAB):
                if Input.is_key_pressed(KEY_SHIFT):
                        inventory_ui.toggle()
                else:
                        skill_tree.toggle()
                return

        # E键打开装备
        if Input.is_key_pressed(KEY_E):
                equipment.toggle()
                return

        # Esc返回主菜单
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

        # 处理战士（war_cry计时已在warrior.process()内部处理，不在关卡重复减）
        warrior.process(delta, GROUND_Y)

        # 限制玩家不出关卡边界
        warrior.pos.x = clamp(warrior.pos.x, 20, LEVEL_WIDTH - 20)

        # 跳跃/落地音效
        var on_ground: bool = warrior.pos.y >= GROUND_Y - 3
        if not was_on_ground and on_ground:
                audio.play("land")
        was_on_ground = on_ground

        # 检测房间切换
        _check_room_change()

        # 处理小怪
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp > 0:
                        enemy.process(delta, warrior.pos, GROUND_Y)

        # 处理蝙蝠
        for i in range(bats.size()):
                var bat: Node2D = bats[i]
                if bat.hp > 0:
                        bat.process(delta, warrior.pos, GROUND_Y)

        # 碰撞检测
        _check_player_vs_enemies()
        _check_player_vs_bats()
        _check_enemies_vs_player()
        _check_bats_vs_player()

        # 陷阱
        _process_traps()

        # 矿车
        _process_mine_carts(delta)

        # 掉落物
        drop_system.process(delta)

        # 传送门
        _check_portal()

        # 更新视觉
        _update_visuals()

        # 更新摄像机
        camera.follow(warrior.pos, warrior.facing, delta)

        # 更新HUD
        hud.update_player_hp(warrior.hp, warrior.max_hp)
        hud.update_rage(warrior.rage, warrior.max_rage)
        hud.update_hit_count(warrior.hit_count)
        hud.show_war_cry_buff(warrior.war_cry_buff, warrior.war_cry_timer)
        hud.process_effects(delta)
        effects.process(delta)

        # 矿石计数
        ore_display.text = "ORE: " + str(drop_system.ore_fragments)

        # 房间名称渐隐
        if room_label_timer > 0:
                room_label_timer -= delta
                var alpha: float = min(1.0, room_label_timer / 1.5)
                room_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, alpha))

        # 连招
        if warrior.combo_timer <= 0 and not warrior.is_attacking:
                hud.clear_combo()
        if warrior.is_attacking and warrior.attack_name != "":
                hud.show_combo(warrior.attack_name, warrior.war_cry_buff)

        # 死亡重生
        if warrior.hp <= 0 and warrior.invincible_timer <= 0:
                if Input.is_key_pressed(KEY_R):
                        warrior.hp = warrior.max_hp
                        warrior.rage = 0
                        warrior.pos = Vector2(max(60, warrior.pos.x - 200), GROUND_Y)
                        warrior.vel = Vector2.ZERO
                        warrior.is_hurt = false
                        warrior.invincible_timer = 2.0
                        warrior.hit_count = 0
                        audio.play("level_up", 0.5)

        # 截图
        if frame_count == 120:
                _take_screenshot("legend_mine_level.png")

        # 自动演示/退出
        if auto_demo:
                _run_demo()
        if auto_quit_frame > 0 and frame_count >= auto_quit_frame:
                _take_screenshot("legend_mine_level_auto.png")
                get_tree().quit()

        # 清理
        _cleanup_dead_enemies()
        _cleanup_dead_bats()

        # 保存状态
        _save_state()

        # 自动存档
        save_timer += delta
        if save_timer >= AUTO_SAVE_INTERVAL:
                save_timer = 0
                SaveSystem.save_game()

        # 传送门闪烁
        if portal:
                portal.color = Color(0.3, 0.6, 1.0, 0.3 + 0.3 * sin(frame_count * 0.08))

func _check_room_change() -> void:
        var new_room: int = int(warrior.pos.x / 640.0)
        new_room = clamp(new_room, 0, 2)
        if new_room != current_room:
                current_room = new_room
                match current_room:
                        0: _show_room_name("幽影矿井 - 入口")
                        1: _show_room_name("幽影矿井 - 矿道深处")
                        2: _show_room_name("幽影矿井 - Boss门前")

                # 矿车只在矿道区域生成
                cart_timer = 0

# === 矿车系统 ===
func _process_mine_carts(delta: float) -> void:
        # 只在矿道区域(640-1280)且有玩家在场时生成矿车
        if current_room != 1:
                cart_timer = 0
                return

        cart_timer += delta
        if cart_timer >= cart_interval:
                cart_timer = 0
                _spawn_mine_cart()

        # 更新矿车
        for i in range(mine_carts.size() - 1, -1, -1):
                var cart: Dictionary = mine_carts[i]
                if cart["node"] == null or not is_instance_valid(cart["node"]):
                        mine_carts.remove_at(i)
                        continue

                cart["pos"] += cart["vel"] * delta
                cart["node"].position = cart["pos"]

                # 矿车离开区域
                if cart["pos"].x < 620 or cart["pos"].x > 1310:
                        cart["node"].queue_free()
                        mine_carts.remove_at(i)
                        continue

                # 碰撞检测
                var dist_x: float = abs(warrior.pos.x - cart["pos"].x)
                var dist_y: float = abs(warrior.pos.y - cart["pos"].y)
                if dist_x < 35 and dist_y < 30 and warrior.invincible_timer <= 0:
                        var base_dmg: float = 15.0
                        var dmg: float = base_dmg * (1.0 - skill_tree.get_defense_bonus()) * (1.0 - equipment.get_defense_bonus())
                        var kb: Vector2 = Vector2(cart["dir"] * 8, -5)
                        warrior.take_damage(dmg, kb)
                        hud.spawn_damage_number(warrior.pos + Vector2(0, -40), dmg, true)
                        effects.start_hitstop(0.08)
                        effects.start_shake(4.0, 8.0)
                        audio.play("hit_boss")
                        hud.show_perfect("MINCART!", Color(1, 0.6, 0.2))

func _spawn_mine_cart() -> void:
        """生成一辆矿车"""
        var from_left: bool = randf() < 0.5
        var dir: float = 1.0 if from_left else -1.0
        var start_x: float = 650 if from_left else 1270
        var speed: float = 250 + randf() * 100

        # 预警
        audio.play("telegraph", 0.6)
        hud.show_perfect("矿车来了!", Color(1, 0.7, 0.2) if from_left else Color(1, 0.3, 0.2))

        # 创建矿车视觉
        var cart_node = Node2D.new()
        add_child(cart_node)

        # 车身
        var body = ColorRect.new()
        body.size = Vector2(40, 24)
        body.position = Vector2(-20, -18)
        body.color = Color(0.4, 0.35, 0.3, 1.0)
        cart_node.add_child(body)

        # 车斗
        var bucket = ColorRect.new()
        bucket.size = Vector2(30, 16)
        bucket.position = Vector2(-15, -30)
        bucket.color = Color(0.5, 0.4, 0.25, 1.0)
        cart_node.add_child(bucket)

        # 轮子
        for wx in [-12, 8]:
                var wheel = ColorRect.new()
                wheel.size = Vector2(8, 8)
                wheel.position = Vector2(wx, -4)
                wheel.color = Color(0.25, 0.2, 0.15, 1.0)
                cart_node.add_child(wheel)

        # 矿石（车斗里的矿石）
        var ore = ColorRect.new()
        ore.size = Vector2(20, 8)
        ore.position = Vector2(-10, -34)
        ore.color = Color(0.7, 0.6, 0.3, 0.8)
        cart_node.add_child(ore)

        cart_node.position = Vector2(start_x, GROUND_Y - 4)

        mine_carts.append({
                "node": cart_node,
                "pos": Vector2(start_x, GROUND_Y - 4),
                "vel": Vector2(dir * speed, 0),
                "dir": dir,
        })

# === 技能加成 ===
func _get_skill_boosted_damage(base_dmg: float) -> float:
        return base_dmg * skill_tree.get_attack_bonus()

func _get_skill_reduced_damage(base_dmg: float) -> float:
        return base_dmg * (1.0 - skill_tree.get_defense_bonus())

func _get_skill_boosted_rage(base_rage: float) -> float:
        return base_rage * skill_tree.get_rage_bonus()

func _check_portal() -> void:
        var dist_to_portal = abs(warrior.pos.x - portal_pos.x)
        if dist_to_portal < 25:
                audio.play("portal")
                GameState.mark_level_cleared("mine")
                SaveSystem.save_game()  # 进入Boss前保存
                GameState.go_to_level("boss")

func _check_player_vs_enemies() -> void:
        if not warrior.is_in_active_frames():
                return
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp <= 0: continue
                var dist = abs(warrior.pos.x - enemy.pos.x)
                if dist < 65:
                        var dmg: float = _get_skill_boosted_damage(warrior.get_attack_damage()) * equipment.get_attack_bonus()
                        enemy.take_damage(dmg)
                        warrior.mark_hit_dealt()
                        var hit_pos: Vector2 = (warrior.pos + enemy.pos) / 2 + Vector2(0, -20)
                        effects.spawn_hit_spark(hit_pos, Color(1, 0.9, 0.5))
                        if dmg >= 20:
                                effects.start_hitstop(0.08); effects.start_shake(3.0, 8.0); audio.play("hit_heavy")
                        else:
                                effects.start_hitstop(0.04); effects.start_shake(1.0, 6.0); audio.play("hit_light")
                        hud.spawn_damage_number(enemy.pos + Vector2(0, -40), dmg, dmg >= 20)
                        warrior.rage = min(warrior.max_rage, warrior.rage + _get_skill_boosted_rage(5.0))
                        break

func _check_player_vs_bats() -> void:
        if not warrior.is_in_active_frames():
                return
        for i in range(bats.size()):
                var bat: Node2D = bats[i]
                if bat.hp <= 0: continue
                var dist_x = abs(warrior.pos.x - bat.pos.x)
                var dist_y = abs(warrior.pos.y - bat.pos.y)
                if dist_x < 65 and dist_y < 50:
                        var dmg: float = _get_skill_boosted_damage(warrior.get_attack_damage()) * equipment.get_attack_bonus()
                        bat.take_damage(dmg)
                        warrior.mark_hit_dealt()
                        effects.spawn_hit_spark((warrior.pos + bat.pos) / 2, Color(1, 0.6, 0.8))
                        effects.start_hitstop(0.04); effects.start_shake(1.5, 7.0); audio.play("hit_light")
                        hud.spawn_damage_number(bat.pos + Vector2(0, -40), dmg, dmg >= 20)
                        warrior.rage = min(warrior.max_rage, warrior.rage + _get_skill_boosted_rage(5.0))
                        break

func _check_enemies_vs_player() -> void:
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp <= 0: continue
                var dist = abs(warrior.pos.x - enemy.pos.x)
                if enemy.is_in_attack_active() and not player_hit_by_enemy.get(i, false):
                        if dist < 60:
                                var dmg: float = _get_skill_reduced_damage(enemy.get_attack_damage()) * (1.0 - equipment.get_defense_bonus())
                                warrior.take_damage(dmg, Vector2(4 * enemy.facing, -2))
                                hud.spawn_damage_number(warrior.pos + Vector2(0, -40), dmg, false)
                                effects.start_hitstop(0.04); effects.start_shake(2.0, 7.0); audio.play("hurt")
                                player_hit_by_enemy[i] = true
                if not enemy.is_in_attack_active():
                        player_hit_by_enemy[i] = false

func _check_bats_vs_player() -> void:
        for i in range(bats.size()):
                var bat: Node2D = bats[i]
                if bat.hp <= 0: continue
                if bat.is_in_attack_active() and not player_hit_by_bat.get(i, false):
                        var dist_x = abs(warrior.pos.x - bat.pos.x)
                        var dist_y = abs(warrior.pos.y - bat.pos.y)
                        if dist_x < 45 and dist_y < 40:
                                var dmg: float = _get_skill_reduced_damage(bat.get_attack_damage()) * (1.0 - equipment.get_defense_bonus())
                                warrior.take_damage(dmg, Vector2(3 * bat.facing, -3))
                                hud.spawn_damage_number(warrior.pos + Vector2(0, -40), dmg, false)
                                effects.start_hitstop(0.04); effects.start_shake(1.5, 7.0); audio.play("hurt")
                                player_hit_by_bat[i] = true
                if not bat.is_in_attack_active():
                        player_hit_by_bat[i] = false

func _process_traps() -> void:
        for i in range(rock_traps.size()):
                var trap: Dictionary = rock_traps[i]
                if trap["active"]: continue
                var dist = abs(warrior.pos.x - trap["x"])
                if dist < 25 and not trap_triggered.get(i, false):
                        trap_triggered[i] = true
                        trap["active"] = true
                        for j in range(3):
                                var rock = ColorRect.new()
                                rock.size = Vector2(randf_range(4, 8), randf_range(4, 8))
                                rock.position = Vector2(trap["x"] + randf_range(-15, 15), -20 - j * 20)
                                rock.color = Color(0.5, 0.45, 0.4, 1)
                                add_child(rock)
                                trap["rocks"].append({"node": rock, "vel": Vector2(randf_range(-10, 10), randf_range(100, 200)), "ground_y": GROUND_Y - 4})
                        hud.show_perfect("DANGER!", Color(1, 0.5, 0.1))
                        effects.start_shake(1.5, 6.0); audio.play("rock_fall")

        for trap in rock_traps:
                for rock_data in trap["rocks"]:
                        var node = rock_data["node"]
                        if node and is_instance_valid(node):
                                rock_data["vel"].y += 500 * (1.0/60.0)
                                node.position += rock_data["vel"] * (1.0/60.0)
                                var rock_dist = abs(warrior.pos.x - node.position.x)
                                if rock_dist < 20 and abs(warrior.pos.y - 30 - node.position.y) < 30:
                                        var dmg: float = _get_skill_reduced_damage(8.0) * (1.0 - equipment.get_defense_bonus())
                                        warrior.take_damage(dmg, Vector2(randf_range(-3, 3), -3))
                                        hud.spawn_damage_number(warrior.pos + Vector2(0, -40), dmg, false)
                                        audio.play("hurt", 0.5); node.queue_free(); rock_data["node"] = null
                                if node.position.y >= rock_data["ground_y"]:
                                        effects.start_shake(1.0, 6.0); audio.play("rock_fall", 0.3)
                                        node.queue_free(); rock_data["node"] = null

func _on_enemy_hit_player(damage: float, knockback: Vector2) -> void: pass
func _on_enemy_died(pos: Vector2) -> void:
        effects.spawn_hit_spark(pos, Color(0.7, 0.8, 1.0))
        warrior.rage = min(warrior.max_rage, warrior.rage + _get_skill_boosted_rage(15.0))
        hud.show_perfect("+15 RAGE", Color(0.5, 0.8, 1.0)); audio.play("enemy_die")
        GameState.total_kills += 1
        drop_system.spawn_drop(pos, "wraith", GROUND_Y)

func _on_bat_hit_player(damage: float, knockback: Vector2) -> void: pass
func _on_bat_died(pos: Vector2) -> void:
        effects.spawn_hit_spark(pos, Color(0.8, 0.5, 0.9))
        warrior.rage = min(warrior.max_rage, warrior.rage + _get_skill_boosted_rage(10.0))
        hud.show_perfect("+10 RAGE", Color(0.8, 0.5, 0.9)); audio.play("enemy_die")
        GameState.total_kills += 1
        drop_system.spawn_drop(pos, "bat", GROUND_Y)

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
        player_sprite.position = warrior.pos + Vector2(0, -32) + shake
        player_sprite.flip_h = (warrior.facing < 0)
        if warrior.invincible_timer > 0:
                player_sprite.visible = int(frame_count / 3) % 2 == 0
        else:
                player_sprite.visible = true
        if warrior.war_cry_buff:
                if int(frame_count / 4) % 3 == 0: player_sprite.modulate = Color(1.2, 1.0, 0.7)
                else: player_sprite.modulate = Color(1, 1, 1)
        if warrior.is_guarding and warrior.is_perfect_parry_window:
                parry_indicator.visible = true
                parry_indicator.position = warrior.pos + Vector2(-10 * warrior.facing, -42) + shake
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
        GameState.save_player_state(warrior.hp, warrior.rage, warrior.hit_count)
        GameState.save_resources(drop_system.ore_fragments, skill_tree.get_skill_data())
        var pickup_counts: Dictionary = drop_system.get_pickup_counts()
        GameState.save_pickup_counts(pickup_counts["ore_fragments"], pickup_counts["health_potions"], pickup_counts["rage_crystals"])
        GameState.current_level = "mine"

func _save_and_quit() -> void:
        _save_state()
        SaveSystem.save_game()
        GameState.go_to_title()

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img: img.save_png("/home/z/my-project/download/" + filename)

func _run_demo() -> void:
        match frame_count:
                60: warrior.vel.x = 200; warrior.facing = 1.0
                100: warrior.do_attack("L"); audio.play("swing")
                140: warrior.do_attack("L"); audio.play("swing")
                180: warrior.vel.x = 0
