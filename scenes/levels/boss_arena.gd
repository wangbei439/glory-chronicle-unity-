## 幽影矿井 Boss 战 - Alpha v0.4
## 矿脉甲虫 vs 战士 完整战斗
extends Node2D

const GROUND_Y: float = 309.0

# 子系统
var warrior: Node2D  # 战士脚本节点
var boss: Node2D     # Boss脚本节点
var hud: Node2D      # HUD脚本节点

# 视觉节点
var player_sprite: AnimatedSprite2D
var boss_sprite: AnimatedSprite2D
var parry_indicator: ColorRect

# 战斗状态
var battle_active: bool = false
var battle_intro: bool = true
var intro_timer: float = 0.0
var frame_count: int = 0
var player_hit_applied: bool = false
var boss_hit_applied: bool = false

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
        
        # === 战士 ===
        var warrior_script = load("res://scripts/player/warrior.gd")
        warrior = Node2D.new()
        warrior.set_script(warrior_script)
        add_child(warrior)
        
        player_sprite = AnimatedSprite2D.new()
        add_child(player_sprite)
        warrior.setup_sprite(player_sprite)
        warrior.pos = Vector2(150, GROUND_Y)
        
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
        boss.boss_health_changed.connect(func(h, m): hud.update_boss_hp(h, m))
        boss.boss_phase_changed.connect(func(p): hud.update_boss_phase(p))
        boss.boss_died.connect(_on_boss_died)

func _physics_process(delta: float) -> void:
        frame_count += 1
        
        if battle_intro:
                _process_intro(delta)
                return
        
        if not battle_active:
                return
        
        # 处理战士
        warrior.process(delta, GROUND_Y)
        
        # 处理Boss
        boss.process(delta, warrior.pos, GROUND_Y)
        
        # 碰撞检测
        _check_combat_collisions()
        
        # 更新视觉
        _update_visuals()
        
        # 更新HUD特效
        hud.process_effects(delta)
        
        # 连招超时
        if warrior.combo_timer <= 0 and not warrior.is_attacking:
                hud.clear_combo()
        
        # Boss攻击状态显示
        if warrior.is_attacking and warrior.attack_name != "":
                hud.show_combo(warrior.attack_name, randf() < 0.2)
        
        # 自动演示
        _run_demo()
        
        # 截图
        if frame_count == 120:
                _take_screenshot("legend_boss_battle.png")
        if frame_count > 600:
                _take_screenshot("legend_boss_combat.png")
                get_tree().quit()

func _process_intro(delta: float) -> void:
        intro_timer += delta
        boss_sprite.play("idle")
        boss_sprite.position = boss.pos + Vector2(0, -32)
        boss_sprite.flip_h = (boss.facing < 0)
        
        player_sprite.play("idle")
        player_sprite.position = warrior.pos + Vector2(0, -32)
        
        hud.show_boss_hp("矿脉甲虫")
        hud.update_boss_hp(boss.hp, boss.max_hp)
        hud.update_player_hp(warrior.hp, warrior.max_hp)
        
        if intro_timer > 2.0:
                battle_intro = false
                battle_active = true
                hud.show_perfect("FIGHT!", Color(1, 0.3, 0.1))

func _check_combat_collisions() -> void:
        var dist = abs(warrior.pos.x - boss.pos.x)
        
        # 玩家攻击Boss
        if warrior.is_attacking and not boss_hit_applied:
                if dist < 80:
                        var combo_info = warrior.get_attack_info()
                        var dmg: float = 10.0 * combo_info.get("damage_mult", 1.0)
                        var is_perfect = warrior.is_perfect_parry_window or randf() < 0.2
                        if is_perfect:
                                dmg *= 1.3
                        boss.take_damage(dmg)
                        hud.spawn_damage_number(boss.pos, dmg, is_perfect)
                        boss_hit_applied = true
        
        if not warrior.is_attacking:
                boss_hit_applied = false
        
        # Boss攻击玩家
        if boss.is_in_attack_state() and not player_hit_applied:
                if dist < 80:
                        var dmg: float = boss.get_attack_damage()
                        var kb: Vector2 = boss.get_attack_knockback()
                        warrior.take_damage(dmg, kb)
                        if dmg > 0:
                                hud.spawn_damage_number(warrior.pos, dmg, dmg >= 25)
                        player_hit_applied = true
        
        if not boss.is_in_attack_state():
                player_hit_applied = false

func _on_player_attack(_target: Node2D, _damage: float, _knockback: Vector2) -> void:
        pass

func _on_parry_success(is_perfect: bool) -> void:
        if is_perfect:
                hud.show_perfect("PERFECT PARRY!", Color(0.5, 0.8, 1.0))
                # 反击窗口：增加怒气
                warrior.rage = min(warrior.max_rage, warrior.rage + 15)
                hud.update_rage(warrior.rage, warrior.max_rage)
        else:
                hud.show_perfect("PARRY!", Color(0.7, 0.9, 1.0))

func _on_boss_died() -> void:
        battle_active = false
        hud.show_perfect("VICTORY!", Color(1, 0.9, 0.2))
        _take_screenshot("legend_boss_victory.png")

func _update_visuals() -> void:
        # 战士
        player_sprite.position = warrior.pos + Vector2(0, -32)
        player_sprite.flip_h = (warrior.facing < 0)
        # 无敌闪烁
        if warrior.invincible_timer > 0:
                player_sprite.visible = int(frame_count / 3) % 2 == 0
        else:
                player_sprite.visible = true
        
        # 格挡指示器
        if warrior.is_guarding and warrior.is_perfect_parry_window:
                parry_indicator.visible = true
                parry_indicator.position = warrior.pos + Vector2(-10 * warrior.facing, -42)
                parry_indicator.color = Color(0.5, 0.8, 1.0, 0.3 + 0.3 * sin(frame_count * 0.5))
        else:
                parry_indicator.visible = false
        
        # Boss (96x64 精灵, 中心偏移16)
        boss_sprite.position = boss.pos + Vector2(-16, -32)
        boss_sprite.flip_h = (boss.facing < 0)

func _take_screenshot(filename: String) -> void:
        var img = get_viewport().get_texture().get_image()
        if img:
                img.save_png("/home/z/my-project/download/" + filename)
                print("Screenshot saved: " + filename)

# === 自动演示 ===
func _run_demo() -> void:
        match frame_count:
                150:
                        warrior.vel.x = 220
                        warrior.facing = 1.0
                180:
                        warrior.do_attack("L")
                210:
                        warrior.do_attack("L")
                240:
                        warrior.do_attack("L")
                270:
                        warrior.vel.x = 0
                300:
                        warrior.do_attack("H")
                330:
                        warrior.do_attack("L")
                360:
                        warrior.do_attack("H")
                390:
                        warrior.rage = 100
                        hud.show_perfect("RAGE FULL!", Color(1, 0.7, 0.1))
                410:
                        warrior.vel.x = 0
