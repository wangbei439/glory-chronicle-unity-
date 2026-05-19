## 幽影矿井关卡 - Alpha v0.6
## 多区域关卡：入口→矿道→Boss门前
## 小怪：矿工亡魂 ×3 + 平台 + 落石陷阱
extends Node2D

const GROUND_Y: float = 309.0

# === 自动演示模式 ===
@export var auto_demo: bool = false
@export var auto_quit_frame: int = 0

# 子系统
var warrior: Node2D
var effects: Node2D
var hud: Node2D

# 小怪
var enemies: Array = []
var enemy_sprites: Array = []

# 视觉
var player_sprite: AnimatedSprite2D
var parry_indicator: ColorRect
var camera_offset: Vector2 = Vector2.ZERO

# 打击感
var hitstop_timer: float = 0.0
var shake_intensity: float = 0.0
var particles: Array = []

# 状态
var frame_count: int = 0
var hit_effects: Array = []
var player_hit_by_enemy: Dictionary = {}  # enemy_id -> bool

# 陷阱（落石）
var rock_traps: Array = []
var trap_triggered: Dictionary = {}

func _ready() -> void:
        _build_scene()

func _build_scene() -> void:
        # === 背景 ===
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
                bg2.color = Color(0.05, 0.05, 0.12, 1.0)
                add_child(bg2)
        
        # === 地面 ===
        _build_ground()
        
        # === 平台 ===
        _build_platforms()
        
        # === 落石陷阱区域标记 ===
        _build_trap_markers()
        
        # === 打击感特效 ===
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
        warrior.pos = Vector2(60, GROUND_Y)
        
        parry_indicator = ColorRect.new()
        parry_indicator.size = Vector2(20, 20)
        parry_indicator.color = Color(0.5, 0.8, 1.0, 0.4)
        parry_indicator.visible = false
        add_child(parry_indicator)
        warrior.parry_indicator = parry_indicator
        
        # === 小怪 ===
        _spawn_enemy(Vector2(220, GROUND_Y), 200)
        _spawn_enemy(Vector2(380, GROUND_Y), 180)
        _spawn_enemy(Vector2(520, GROUND_Y), 160)
        
        # === HUD ===
        var hud_script = load("res://scripts/ui/hud.gd")
        hud = Node2D.new()
        hud.set_script(hud_script)
        add_child(hud)
        hud.build()
        hud.update_player_hp(warrior.hp, warrior.max_hp)
        hud.update_rage(warrior.rage, warrior.max_rage)
        
        # === 关卡标题 ===
        var title = Label.new()
        title.text = "幽影矿井 - 入口"
        title.position = Vector2(240, 5)
        title.add_theme_font_size_override("font_size", 10)
        title.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55, 0.9))
        add_child(title)
        
        # === 版本/操作提示 ===
        var ver = Label.new()
        ver.text = "v0.6"
        ver.position = Vector2(600, 350)
        ver.add_theme_font_size_override("font_size", 7)
        ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
        add_child(ver)
        
        var hint = Label.new()
        hint.text = "A/D:移动 W/Space:跳跃 J:轻攻 K:重攻 L:格挡 U:战吼 I:裂地斩 R:重来"
        hint.position = Vector2(100, 350)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.7))
        add_child(hint)

func _build_ground() -> void:
        # 地面线
        var ground_top = ColorRect.new()
        ground_top.position = Vector2(0, 329)
        ground_top.size = Vector2(640, 2)
        ground_top.color = Color(0.35, 0.4, 0.45, 0.8)
        add_child(ground_top)
        
        # 地面
        var ground = ColorRect.new()
        ground.position = Vector2(0, 330)
        ground.size = Vector2(640, 30)
        ground.color = Color(0.15, 0.17, 0.2, 0.6)
        add_child(ground)
        
        # 地面装饰（裂缝/碎石）
        for x in [80, 200, 350, 500]:
                var crack = ColorRect.new()
                crack.position = Vector2(x, 329)
                crack.size = Vector2(randf_range(8, 20), 2)
                crack.color = Color(0.1, 0.12, 0.15, 0.5)
                add_child(crack)

func _build_platforms() -> void:
        # 上层平台
        var platforms = [
                {"pos": Vector2(130, 260), "size": Vector2(80, 6)},
                {"pos": Vector2(300, 240), "size": Vector2(100, 6)},
                {"pos": Vector2(480, 260), "size": Vector2(80, 6)},
        ]
        for p in platforms:
                var plat = ColorRect.new()
                plat.position = p["pos"]
                plat.size = p["size"]
                plat.color = Color(0.25, 0.27, 0.3, 0.8)
                add_child(plat)
                # 平台支撑
                var support = ColorRect.new()
                support.position = p["pos"] + Vector2(2, 6)
                support.size = Vector2(2, GROUND_Y - p["pos"].y - 6)
                support.color = Color(0.2, 0.22, 0.25, 0.4)
                add_child(support)
                var support2 = ColorRect.new()
                support2.position = p["pos"] + Vector2(p["size"].x - 4, 6)
                support2.size = Vector2(2, GROUND_Y - p["pos"].y - 6)
                support2.color = Color(0.2, 0.22, 0.25, 0.4)
                add_child(support2)

func _build_trap_markers() -> void:
        # 落石陷阱区域（黄色警告标记）
        var trap_positions = [280, 450]
        for i in range(trap_positions.size()):
                var x = trap_positions[i]
                # 地面裂缝标记
                var marker = ColorRect.new()
                marker.position = Vector2(x - 15, 327)
                marker.size = Vector2(30, 2)
                marker.color = Color(0.6, 0.5, 0.2, 0.3)
                add_child(marker)
                
                rock_traps.append({"x": x, "active": false, "rocks": []})
                trap_triggered[i] = false

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
        
        # 连接信号
        enemy.enemy_hit_player.connect(_on_enemy_hit_player)
        enemy.enemy_died.connect(_on_enemy_died)

func _physics_process(delta: float) -> void:
        frame_count += 1
        
        # Hitstop
        if effects.hitstop_active:
                effects.process(delta)
                return
        
        # 震屏衰减
        if shake_intensity > 0:
                shake_intensity = max(0, shake_intensity - 6.0 * delta)
                camera_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
        else:
                camera_offset = Vector2.ZERO
        
        # 战吼buff
        if warrior.war_cry_buff:
                warrior.war_cry_timer -= delta
                if warrior.war_cry_timer <= 0:
                        warrior.war_cry_buff = false
        
        # 处理战士
        warrior.process(delta, GROUND_Y)
        
        # 处理小怪
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp > 0:
                        enemy.process(delta, warrior.pos, GROUND_Y)
        
        # 战士攻击小怪
        _check_player_vs_enemies()
        
        # 小怪攻击战士
        _check_enemies_vs_player()
        
        # 落石陷阱
        _process_traps()
        
        # 更新视觉
        _update_visuals()
        
        # 更新HUD
        hud.update_player_hp(warrior.hp, warrior.max_hp)
        hud.update_rage(warrior.rage, warrior.max_rage)
        hud.update_hit_count(warrior.hit_count)
        hud.show_war_cry_buff(warrior.war_cry_buff, warrior.war_cry_timer)
        
        # 粒子
        effects.process(delta)
        _process_particles(delta)
        _process_hit_effects(delta)
        
        # 连招超时
        if warrior.combo_timer <= 0 and not warrior.is_attacking:
                hud.clear_combo()
        
        if warrior.is_attacking and warrior.attack_name != "":
                hud.show_combo(warrior.attack_name, warrior.war_cry_buff)
        
        # 死亡
        if warrior.hp <= 0 and warrior.invincible_timer <= 0:
                if Input.is_key_pressed(KEY_R):
                        warrior.hp = warrior.max_hp
                        warrior.rage = 0
                        warrior.pos = Vector2(60, GROUND_Y)
                        warrior.vel = Vector2.ZERO
                        warrior.is_hurt = false
                        warrior.invincible_timer = 2.0
                        warrior.hit_count = 0
        
        # 自动截图（服务器验证用）
        if frame_count == 120:
                _take_screenshot("legend_mine_level.png")
        
        # 自动演示/退出
        if auto_demo:
                _run_demo()
        if auto_quit_frame > 0 and frame_count >= auto_quit_frame:
                _take_screenshot("legend_mine_level_auto.png")
                get_tree().quit()
        
        # 清理死亡敌人
        _cleanup_dead_enemies()

func _check_player_vs_enemies() -> void:
        if not warrior.is_in_active_frames():
                return
        
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp <= 0:
                        continue
                
                var dist = abs(warrior.pos.x - enemy.pos.x)
                if dist < 65:
                        var dmg: float = warrior.get_attack_damage()
                        enemy.take_damage(dmg)
                        warrior.mark_hit_dealt()
                        
                        # 打击感
                        var hit_pos: Vector2 = (warrior.pos + enemy.pos) / 2 + Vector2(0, -20)
                        effects.spawn_hit_spark(hit_pos, Color(1, 0.9, 0.5))
                        
                        if dmg >= 20:
                                hitstop_timer = 0.08
                                shake_intensity = 3.0
                        else:
                                hitstop_timer = 0.04
                                shake_intensity = 1.0
                        
                        hud.spawn_damage_number(enemy.pos + Vector2(0, -40), dmg, dmg >= 20)
                        
                        # 怒气
                        warrior.rage = min(warrior.max_rage, warrior.rage + 5)
                        
                        break  # 每次只打一个

func _check_enemies_vs_player() -> void:
        for i in range(enemies.size()):
                var enemy: Node2D = enemies[i]
                if enemy.hp <= 0:
                        continue
                
                var dist = abs(warrior.pos.x - enemy.pos.x)
                if enemy.is_in_attack_active() and not player_hit_by_enemy.get(i, false):
                        if dist < 60:
                                var dmg: float = enemy.get_attack_damage()
                                var kb: Vector2 = Vector2(4 * enemy.facing, -2)
                                warrior.take_damage(dmg, kb)
                                
                                hud.spawn_damage_number(warrior.pos + Vector2(0, -40), dmg, false)
                                hitstop_timer = 0.04
                                shake_intensity = 2.0
                                
                                player_hit_by_enemy[i] = true
                
                if not enemy.is_in_attack_active():
                        player_hit_by_enemy[i] = false

func _process_traps() -> void:
        for i in range(rock_traps.size()):
                var trap: Dictionary = rock_traps[i]
                if trap["active"]:
                        continue
                
                var dist = abs(warrior.pos.x - trap["x"])
                if dist < 25 and not trap_triggered.get(i, false):
                        trap_triggered[i] = true
                        trap["active"] = true
                        # 生成落石
                        for j in range(3):
                                var rock = ColorRect.new()
                                rock.size = Vector2(randf_range(4, 8), randf_range(4, 8))
                                rock.position = Vector2(trap["x"] + randf_range(-15, 15), -20 - j * 20)
                                rock.color = Color(0.5, 0.45, 0.4, 1)
                                add_child(rock)
                                trap["rocks"].append({
                                        "node": rock, "vel": Vector2(randf_range(-10, 10), randf_range(100, 200)),
                                        "ground_y": GROUND_Y - 4
                                })
                        
                        hud.show_perfect("DANGER!", Color(1, 0.5, 0.1))
                        shake_intensity = 1.5
        
        # 更新落石位置
        for trap in rock_traps:
                for rock_data in trap["rocks"]:
                        var node = rock_data["node"]
                        if node and is_instance_valid(node):
                                rock_data["vel"].y += 500 * (1.0/60.0)
                                node.position += rock_data["vel"] * (1.0/60.0)
                                
                                # 落石击中玩家
                                var rock_dist = abs(warrior.pos.x - node.position.x)
                                if rock_dist < 20 and abs(warrior.pos.y - 30 - node.position.y) < 30:
                                        warrior.take_damage(8, Vector2(randf_range(-3, 3), -3))
                                        hud.spawn_damage_number(warrior.pos + Vector2(0, -40), 8, false)
                                        node.queue_free()
                                        rock_data["node"] = null
                                
                                # 落地
                                if node.position.y >= rock_data["ground_y"]:
                                        shake_intensity = max(shake_intensity, 1.0)
                                        node.queue_free()
                                        rock_data["node"] = null

func _on_enemy_hit_player(damage: float, knockback: Vector2) -> void:
        pass  # 已在_check_enemies_vs_player中处理

func _on_enemy_died(pos: Vector2) -> void:
        # 击杀特效
        effects.spawn_hit_spark(pos, Color(0.7, 0.8, 1.0))
        warrior.rage = min(warrior.max_rage, warrior.rage + 15)
        hud.show_perfect("+15 RAGE", Color(0.5, 0.8, 1.0))

func _cleanup_dead_enemies() -> void:
        for i in range(enemies.size() - 1, -1, -1):
                var enemy: Node2D = enemies[i]
                if enemy.hp <= 0 and enemy.current_state == 5:  # DYING
                        # 检查死亡动画是否完成
                        if not enemy.sprite or not enemy.sprite.is_playing():
                                # 清理
                                if enemy.sprite and is_instance_valid(enemy.sprite):
                                        enemy.sprite.queue_free()
                                enemy.queue_free()
                                enemies.remove_at(i)
                                enemy_sprites.remove_at(i)

func _update_visuals() -> void:
        var shake = camera_offset
        
        # 战士
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
        
        # 格挡指示器
        if warrior.is_guarding and warrior.is_perfect_parry_window:
                parry_indicator.visible = true
                parry_indicator.position = warrior.pos + Vector2(-10 * warrior.facing, -42) + shake
        else:
                parry_indicator.visible = false
        
        # 小怪
        for i in range(enemies.size()):
                if i < enemy_sprites.size() and is_instance_valid(enemy_sprites[i]):
                        var esprite: AnimatedSprite2D = enemy_sprites[i]
                        var enemy: Node2D = enemies[i]
                        esprite.position = enemy.pos + Vector2(0, -32) + shake
                        esprite.flip_h = (enemy.facing < 0)

func _process_particles(delta: float) -> void:
        # 简化版粒子处理（训练场已实现完整版）
        pass

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
                        warrior.vel.x = 200
                        warrior.facing = 1.0
                100:
                        warrior.do_attack("L")
                140:
                        warrior.do_attack("L")
                180:
                        warrior.vel.x = 0
