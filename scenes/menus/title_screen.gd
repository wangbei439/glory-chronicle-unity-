## 主菜单/标题画面 - Beta v0.14 美术升级版
## 游戏入口：标题动画、菜单选项、职业选择、存档信息、背景粒子
## v0.14: 全面美术升级 - Logo图片 + 视差背景 + 精美菜单 + 环境装饰
extends Node2D

# 菜单选项
var menu_items: Array = []
var selected_index: int = 0
var frame_count: int = 0

# 视觉元素
var title_label: Label
var subtitle_label: Label
var version_label: Label
var cursor: TextureRect
var cursor_glow: ColorRect
var bg_particles: Array = []
var save_info_label: Label = null

# 环境装饰
var torch_sprites: Array = []
var crystal_sprites: Array = []
var stalactite_sprites: Array = []

# 职业选择
var class_select_active: bool = false
var class_select_index: int = 0
var class_nodes: Array = []
var warrior_desc: Label
var ranger_desc: Label
var warrior_stats: Label
var ranger_stats: Label
var class_cursor: ColorRect

# 场景路径
const SCENES = {
	"training": "res://scenes/levels/training_ground.tscn",
	"mine": "res://scenes/levels/mine_level.tscn",
	"boss": "res://scenes/levels/boss_arena.tscn",
	"lava": "res://scenes/levels/lava_level.tscn",
	"lava_boss": "res://scenes/levels/lava_boss.tscn",
}

# 淡入淡出
var fade_overlay: ColorRect
var is_transitioning: bool = false
var fade_alpha: float = 0.0
var target_scene: String = ""

# Logo
var logo_rect: TextureRect

func _ready() -> void:
	_build_scene()

func _build_scene() -> void:
	# === 视差背景 ===
	_build_parallax_background()
	
	# === 环境装饰 ===
	_build_environment()
	
	# === 背景粒子 ===
	for i in range(40):
		var p = ColorRect.new()
		p.size = Vector2(randf_range(1, 2), randf_range(1, 2))
		p.position = Vector2(randf() * 640, randf() * 360)
		var colors = [
			Color(0.4, 0.6, 0.8, 0.3),
			Color(0.6, 0.4, 0.8, 0.25),
			Color(0.8, 0.7, 0.3, 0.2),
			Color(0.5, 0.8, 1.0, 0.2),
		]
		p.color = colors[i % 4]
		add_child(p)
		bg_particles.append({
			"node": p,
			"vel": Vector2(randf_range(-5, 5), randf_range(-12, -3)),
			"base_y": p.position.y,
			"phase": randf() * TAU,
		})
	
	# === 地面 ===
	_build_ground()
	
	# === 游戏Logo ===
	var logo_tex = load("res://assets/sprites/ui/game_logo_small.png")
	if logo_tex:
		logo_rect = TextureRect.new()
		logo_rect.texture = logo_tex
		logo_rect.position = Vector2(220, 30)
		logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(logo_rect)
	
	# === 游戏标题 ===
	title_label = Label.new()
	title_label.text = "代号：传说"
	title_label.position = Vector2(175, 55)
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1.0))
	add_child(title_label)
	
	# 副标题
	subtitle_label = Label.new()
	subtitle_label.text = "CODE: LEGEND"
	subtitle_label.position = Vector2(220, 100)
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 0.7))
	add_child(subtitle_label)
	
	# 装饰线
	var line_left = ColorRect.new()
	line_left.position = Vector2(160, 120)
	line_left.size = Vector2(80, 1)
	line_left.color = Color(0.7, 0.55, 0.3, 0.5)
	add_child(line_left)
	
	var diamond = ColorRect.new()
	diamond.position = Vector2(316, 117)
	diamond.size = Vector2(8, 8)
	diamond.color = Color(0.9, 0.75, 0.3, 0.6)
	add_child(diamond)
	
	var line_right = ColorRect.new()
	line_right.position = Vector2(400, 120)
	line_right.size = Vector2(80, 1)
	line_right.color = Color(0.7, 0.55, 0.3, 0.5)
	add_child(line_right)
	
	# === 菜单选项 ===
	var menu_data = []
	if SaveSystem.has_save:
		menu_data.append({"text": "继续游戏", "scene": "continue"})
	menu_data.append({"text": "开始冒险", "scene": "mine"})
	menu_data.append({"text": "失落地脉", "scene": "lava"})
	menu_data.append({"text": "训练场", "scene": "training"})
	menu_data.append({"text": "Boss挑战(甲虫)", "scene": "boss"})
	menu_data.append({"text": "Boss挑战(熔岩龟)", "scene": "lava_boss"})
	
	var start_y: float = 150
	for i in range(menu_data.size()):
		# 菜单项背景
		var item_bg = ColorRect.new()
		item_bg.size = Vector2(200, 24)
		item_bg.position = Vector2(220, start_y + i * 30 - 3)
		item_bg.color = Color(0, 0, 0, 0)
		add_child(item_bg)
		
		var item = Label.new()
		item.text = menu_data[i]["text"]
		item.position = Vector2(260, start_y + i * 30)
		item.add_theme_font_size_override("font_size", 12)
		item.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 0.8))
		add_child(item)
		menu_items.append({"label": item, "bg": item_bg, "scene": menu_data[i]["scene"]})
	
	# 选中光标（使用精灵纹理）
	var cursor_tex = load("res://assets/sprites/ui/cursor_arrow.png")
	if cursor_tex:
		cursor = TextureRect.new()
		cursor.texture = cursor_tex
		cursor.size = Vector2(8, 8)
		cursor.position = Vector2(244, start_y + selected_index * 30 + 3)
		add_child(cursor)
	else:
		cursor = TextureRect.new()
		cursor.size = Vector2(8, 8)
		cursor.position = Vector2(244, start_y + selected_index * 30 + 3)
		add_child(cursor)
	
	# 光标发光
	cursor_glow = ColorRect.new()
	cursor_glow.size = Vector2(12, 12)
	cursor_glow.position = Vector2(242, start_y + selected_index * 30 + 1)
	cursor_glow.color = Color(0.9, 0.75, 0.3, 0.2)
	add_child(cursor_glow)
	
	# === 底部信息 ===
	version_label = Label.new()
	version_label.text = "Beta v0.14"
	version_label.position = Vector2(555, 345)
	version_label.add_theme_font_size_override("font_size", 7)
	version_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.5))
	add_child(version_label)
	
	# === 存档信息 ===
	if SaveSystem.has_save:
		var info: Dictionary = SaveSystem.get_save_info()
		save_info_label = Label.new()
		var save_text: String = "存档: " + str(info.get("play_time", "")) + " | 击杀:" + str(info.get("total_kills", 0)) + " | 矿石:" + str(info.get("ore_fragments", 0))
		var mat_text: String = str(info.get("materials", ""))
		if mat_text != "":
			save_text += " | " + mat_text
		save_info_label.text = save_text
		save_info_label.position = Vector2(180, 330)
		save_info_label.add_theme_font_size_override("font_size", 7)
		save_info_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35, 0.6))
		add_child(save_info_label)
	
	var controls = Label.new()
	controls.text = "W/S:选择  Enter/J:确认  Esc:退出"
	controls.position = Vector2(210, 305)
	controls.add_theme_font_size_override("font_size", 8)
	controls.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 0.6))
	add_child(controls)
	
	var copyright_label = Label.new()
	copyright_label.text = "Powered by Godot 4.6"
	copyright_label.position = Vector2(505, 345)
	copyright_label.add_theme_font_size_override("font_size", 7)
	copyright_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35, 0.4))
	add_child(copyright_label)
	
	# === 淡入淡出遮罩 ===
	fade_overlay = ColorRect.new()
	fade_overlay.size = Vector2(640, 360)
	fade_overlay.color = Color(0, 0, 0, 0)
	add_child(fade_overlay)
	
	# 初始淡入效果
	fade_alpha = 1.0
	fade_overlay.color = Color(0, 0, 0, 1)
	
	# === 职业选择界面 ===
	_build_class_select()

func _build_parallax_background() -> void:
	# 远景层
	var far_tex = load("res://assets/sprites/background/parallax_mine_far.png")
	if far_tex:
		var far_bg = TextureRect.new()
		far_bg.texture = far_tex
		far_bg.size = Vector2(640, 360)
		far_bg.stretch_mode = TextureRect.STRETCH_SCALE
		far_bg.position = Vector2(0, 0)
		far_bg.modulate = Color(1, 1, 1, 0.5)
		add_child(far_bg)
	
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
		bg2.color = Color(0.03, 0.03, 0.08, 1.0)
		add_child(bg2)
	
	# 中景层
	var mid_tex = load("res://assets/sprites/background/parallax_mine_mid.png")
	if mid_tex:
		var mid_bg = TextureRect.new()
		mid_bg.texture = mid_tex
		mid_bg.size = Vector2(640, 360)
		mid_bg.stretch_mode = TextureRect.STRETCH_SCALE
		mid_bg.position = Vector2(0, 0)
		mid_bg.modulate = Color(1, 1, 1, 0.3)
		add_child(mid_bg)
	
	# 渐变遮罩（底部变暗）
	var gradient = ColorRect.new()
	gradient.size = Vector2(640, 60)
	gradient.position = Vector2(0, 300)
	gradient.color = Color(0, 0, 0, 0.4)
	add_child(gradient)

func _build_environment() -> void:
	# 火炬（左右各一）
	var torch_tex = load("res://assets/sprites/environment/torch_sheet.png")
	for x_pos in [60, 560]:
		if torch_tex:
			var torch = TextureRect.new()
			torch.texture = torch_tex
			torch.size = Vector2(32, 48)
			torch.position = Vector2(x_pos - 16, 170)
			torch.stretch_mode = TextureRect.STRETCH_SCALE
			add_child(torch)
			torch_sprites.append(torch)
		else:
			# 退化方案：ColorRect火炬
			var torch_body = ColorRect.new()
			torch_body.size = Vector2(4, 20)
			torch_body.position = Vector2(x_pos - 2, 195)
			torch_body.color = Color(0.35, 0.2, 0.1, 1.0)
			add_child(torch_body)
			var torch_fire = ColorRect.new()
			torch_fire.size = Vector2(6, 6)
			torch_fire.position = Vector2(x_pos - 3, 188)
			torch_fire.color = Color(1, 0.7, 0.2, 1.0)
			add_child(torch_fire)
		
		# 火炬光晕
		var glow = ColorRect.new()
		glow.size = Vector2(40, 40)
		glow.position = Vector2(x_pos - 20, 175)
		glow.color = Color(1, 0.7, 0.2, 0.06)
		add_child(glow)
	
	# 水晶装饰
	var crystal_tex = load("res://assets/sprites/environment/crystal_cluster_sheet.png")
	if crystal_tex:
		for cx in [30, 610]:
			var crystal = TextureRect.new()
			crystal.texture = crystal_tex
			crystal.size = Vector2(32, 32)
			crystal.position = Vector2(cx - 16, 270)
			crystal.stretch_mode = TextureRect.STRETCH_SCALE
			add_child(crystal)
			crystal_sprites.append(crystal)
	
	# 钟乳石（顶部）
	var stal_tex = load("res://assets/sprites/environment/stalactite_small.png")
	if stal_tex:
		for sx in [100, 250, 400, 540]:
			var stal = TextureRect.new()
			stal.texture = stal_tex
			stal.size = Vector2(16, 32)
			stal.position = Vector2(sx, 0)
			stal.stretch_mode = TextureRect.STRETCH_SCALE
			add_child(stal)
			stalactite_sprites.append(stal)

func _build_ground() -> void:
	# 地面（使用瓦片纹理）
	var tile_tex = load("res://assets/sprites/tiles/ground_stone_32.png")
	if tile_tex:
		for x in range(0, 640, 32):
			var tile = TextureRect.new()
			tile.texture = tile_tex
			tile.size = Vector2(32, 32)
			tile.position = Vector2(x, 320)
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			add_child(tile)
	else:
		var ground = ColorRect.new()
		ground.position = Vector2(0, 320)
		ground.size = Vector2(640, 40)
		ground.color = Color(0.08, 0.07, 0.12, 1.0)
		add_child(ground)

func _build_class_select() -> void:
	# 全屏半透明遮罩
	var overlay = ColorRect.new()
	overlay.size = Vector2(640, 360)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.visible = false
	add_child(overlay)
	class_nodes.append(overlay)
	
	# 标题
	var cs_title = Label.new()
	cs_title.text = "选 择 职 业"
	cs_title.position = Vector2(240, 30)
	cs_title.add_theme_font_size_override("font_size", 20)
	cs_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	cs_title.visible = false
	add_child(cs_title)
	class_nodes.append(cs_title)
	
	# === 战士面板 ===
	var w_panel_bg = ColorRect.new()
	w_panel_bg.size = Vector2(260, 220)
	w_panel_bg.position = Vector2(40, 70)
	w_panel_bg.color = Color(0.12, 0.1, 0.08, 0.9)
	w_panel_bg.visible = false
	add_child(w_panel_bg)
	class_nodes.append(w_panel_bg)
	
	var w_border = ColorRect.new()
	w_border.size = Vector2(264, 224)
	w_border.position = Vector2(38, 68)
	w_border.color = Color(0.8, 0.65, 0.3, 0.8)
	w_border.visible = false
	add_child(w_border)
	class_nodes.append(w_border)
	
	# 战士图标（使用技能图标）
	var w_icon_tex = load("res://assets/sprites/ui/skill_icon_attack.png")
	if w_icon_tex:
		var w_icon = TextureRect.new()
		w_icon.texture = w_icon_tex
		w_icon.size = Vector2(40, 40)
		w_icon.position = Vector2(150, 95)
		w_icon.stretch_mode = TextureRect.STRETCH_SCALE
		w_icon.visible = false
		add_child(w_icon)
		class_nodes.append(w_icon)
	else:
		var w_icon = ColorRect.new()
		w_icon.size = Vector2(40, 40)
		w_icon.position = Vector2(150, 95)
		w_icon.color = Color(0.8, 0.65, 0.3, 0.6)
		w_icon.visible = false
		add_child(w_icon)
		class_nodes.append(w_icon)
	
	var w_name = Label.new()
	w_name.text = "战  士"
	w_name.position = Vector2(120, 80)
	w_name.add_theme_font_size_override("font_size", 18)
	w_name.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	w_name.visible = false
	add_child(w_name)
	class_nodes.append(w_name)
	
	warrior_desc = Label.new()
	warrior_desc.text = "近战重装战士，以怒气驱动强力技能"
	warrior_desc.position = Vector2(55, 140)
	warrior_desc.add_theme_font_size_override("font_size", 8)
	warrior_desc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	warrior_desc.visible = false
	add_child(warrior_desc)
	class_nodes.append(warrior_desc)
	
	warrior_stats = Label.new()
	warrior_stats.text = "HP:100  ATK:高  DEF:高  SPD:中\n怒气系统(0-100): 命中+怒气\n格挡: L键 完美格挡=0伤害+回血\n战吼: U键(50怒气) +15%伤害8秒\n裂地斩: I键(100怒气) AOE"
	warrior_stats.position = Vector2(55, 155)
	warrior_stats.add_theme_font_size_override("font_size", 7)
	warrior_stats.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
	warrior_stats.visible = false
	add_child(warrior_stats)
	class_nodes.append(warrior_stats)
	
	# === 游侠面板 ===
	var r_panel = ColorRect.new()
	r_panel.size = Vector2(260, 220)
	r_panel.position = Vector2(340, 70)
	r_panel.color = Color(0.08, 0.12, 0.1, 0.9)
	r_panel.visible = false
	add_child(r_panel)
	class_nodes.append(r_panel)
	
	var r_border = ColorRect.new()
	r_border.size = Vector2(264, 224)
	r_border.position = Vector2(338, 68)
	r_border.color = Color(0.3, 0.7, 0.5, 0.8)
	r_border.visible = false
	add_child(r_border)
	class_nodes.append(r_border)
	
	var r_icon_tex = load("res://assets/sprites/ui/skill_icon_defense.png")
	if r_icon_tex:
		var r_icon = TextureRect.new()
		r_icon.texture = r_icon_tex
		r_icon.size = Vector2(40, 40)
		r_icon.position = Vector2(450, 95)
		r_icon.stretch_mode = TextureRect.STRETCH_SCALE
		r_icon.visible = false
		add_child(r_icon)
		class_nodes.append(r_icon)
	else:
		var r_icon = ColorRect.new()
		r_icon.size = Vector2(40, 40)
		r_icon.position = Vector2(450, 95)
		r_icon.color = Color(0.3, 0.7, 0.5, 0.6)
		r_icon.visible = false
		add_child(r_icon)
		class_nodes.append(r_icon)
	
	var r_name = Label.new()
	r_name.text = "游  侠"
	r_name.position = Vector2(420, 80)
	r_name.add_theme_font_size_override("font_size", 18)
	r_name.add_theme_color_override("font_color", Color(0.4, 0.85, 0.6))
	r_name.visible = false
	add_child(r_name)
	class_nodes.append(r_name)
	
	ranger_desc = Label.new()
	ranger_desc.text = "敏捷暗影刺客，以连击点释放致命技能"
	ranger_desc.position = Vector2(355, 140)
	ranger_desc.add_theme_font_size_override("font_size", 8)
	ranger_desc.add_theme_color_override("font_color", Color(0.65, 0.8, 0.7))
	ranger_desc.visible = false
	add_child(ranger_desc)
	class_nodes.append(ranger_desc)
	
	ranger_stats = Label.new()
	ranger_stats.text = "HP:80  ATK:中  DEF:低  SPD:快\n连击点(0-5): 命中+1点 4秒-1点\n闪避: L键 0.35秒无敌 完美闪避+1CP\n影步: U键(2CP) 传送+40%伤害2秒\n刃风暴: I键(5CP) 旋转AOE"
	ranger_stats.position = Vector2(355, 155)
	ranger_stats.add_theme_font_size_override("font_size", 7)
	ranger_stats.add_theme_color_override("font_color", Color(0.5, 0.65, 0.55))
	ranger_stats.visible = false
	add_child(ranger_stats)
	class_nodes.append(ranger_stats)
	
	# 光标
	class_cursor = ColorRect.new()
	class_cursor.size = Vector2(12, 12)
	class_cursor.position = Vector2(140, 92)
	class_cursor.color = Color(0.9, 0.75, 0.3, 1.0)
	class_cursor.visible = false
	add_child(class_cursor)
	class_nodes.append(class_cursor)
	
	# 操作提示
	var cs_hint = Label.new()
	cs_hint.text = "A/D:选择职业  Enter/J:确认  Esc:返回"
	cs_hint.position = Vector2(200, 310)
	cs_hint.add_theme_font_size_override("font_size", 8)
	cs_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	cs_hint.visible = false
	add_child(cs_hint)
	class_nodes.append(cs_hint)
	
	# NEW标签
	var new_label = Label.new()
	new_label.text = "NEW!"
	new_label.position = Vector2(480, 78)
	new_label.add_theme_font_size_override("font_size", 10)
	new_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 1.0))
	new_label.visible = false
	add_child(new_label)
	class_nodes.append(new_label)

func _physics_process(delta: float) -> void:
	frame_count += 1
	
	if is_transitioning:
		fade_alpha = min(1.0, fade_alpha + delta * 2.0)
		fade_overlay.color = Color(0, 0, 0, fade_alpha)
		if fade_alpha >= 1.0:
			get_tree().change_scene_to_file(target_scene)
		return
	
	# 淡入
	if fade_alpha > 0:
		fade_alpha = max(0, fade_alpha - delta * 1.5)
		fade_overlay.color = Color(0, 0, 0, fade_alpha)
	
	# 更新背景粒子
	for p in bg_particles:
		var node: ColorRect = p["node"]
		p["phase"] += delta * 0.5
		node.position.x += p["vel"].x * delta
		node.position.y = p["base_y"] + sin(p["phase"]) * 15
		if node.position.x < -10:
			node.position.x = 650
		elif node.position.x > 650:
			node.position.x = -10
	
	# 标题闪烁效果
	if title_label:
		var glow = 0.85 + 0.15 * sin(frame_count * 0.03)
		title_label.add_theme_color_override("font_color", Color(0.9 * glow, 0.75 * glow, 0.3 * glow, 1.0))
	
	# 火炬动画
	for ts in torch_sprites:
		if is_instance_valid(ts):
			var flicker = 0.95 + 0.05 * sin(frame_count * 0.1 + randf() * 0.5)
			ts.modulate = Color(flicker, flicker, flicker, 1.0)
	
	# 水晶闪烁
	for cs in crystal_sprites:
		if is_instance_valid(cs):
			var shimmer = 0.9 + 0.1 * sin(frame_count * 0.05 + randf())
			cs.modulate = Color(shimmer, shimmer, shimmer + 0.05, 1.0)
	
	# 光标动画
	if cursor_glow and not class_select_active:
		var pulse = 0.15 + 0.1 * sin(frame_count * 0.08)
		cursor_glow.color = Color(0.9, 0.75, 0.3, pulse)
	
	# === 职业选择界面 ===
	if class_select_active:
		_process_class_select()
		return
	
	# === 主菜单输入 ===
	if Input.is_action_just_pressed("move_left") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		selected_index = (selected_index - 1) % menu_items.size()
		if selected_index < 0:
			selected_index = menu_items.size() - 1
		_update_cursor()
	
	if Input.is_action_just_pressed("move_right") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		selected_index = (selected_index + 1) % menu_items.size()
		_update_cursor()
	
	if Input.is_key_pressed(KEY_ENTER) or Input.is_action_just_pressed("attack"):
		_confirm_selection()
	
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _process_class_select() -> void:
	if Input.is_action_just_pressed("move_left"):
		class_select_index = 0
		_update_class_cursor()
	if Input.is_action_just_pressed("move_right"):
		class_select_index = 1
		_update_class_cursor()
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		class_select_index = 0
		_update_class_cursor()
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		class_select_index = 1
		_update_class_cursor()
	if Input.is_key_pressed(KEY_ENTER) or Input.is_action_just_pressed("attack"):
		_confirm_class_selection()
	if Input.is_key_pressed(KEY_ESCAPE):
		_close_class_select()

func _update_class_cursor() -> void:
	if class_cursor:
		if class_select_index == 0:
			class_cursor.position = Vector2(140, 92)
			class_cursor.color = Color(0.9, 0.75, 0.3, 1.0)
		else:
			class_cursor.position = Vector2(440, 92)
			class_cursor.color = Color(0.3, 0.85, 0.5, 1.0)
	if class_select_index == 0:
		if class_nodes.size() > 3:
			class_nodes[3].color = Color(0.9, 0.75, 0.3, 1.0)
		if class_nodes.size() > 9:
			class_nodes[9].color = Color(0.3, 0.7, 0.5, 0.4)
	else:
		if class_nodes.size() > 3:
			class_nodes[3].color = Color(0.8, 0.65, 0.3, 0.4)
		if class_nodes.size() > 9:
			class_nodes[9].color = Color(0.3, 0.85, 0.5, 1.0)

func _confirm_class_selection() -> void:
	if class_select_index == 0:
		GameState.selected_class = "warrior"
	else:
		GameState.selected_class = "ranger"
	_close_class_select()
	_goto_selected_scene()

func _close_class_select() -> void:
	class_select_active = false
	for node in class_nodes:
		if is_instance_valid(node):
			node.visible = false

func _show_class_select() -> void:
	class_select_active = true
	class_select_index = 0 if GameState.selected_class == "warrior" else 1
	for node in class_nodes:
		if is_instance_valid(node):
			node.visible = true
	_update_class_cursor()

func _update_cursor() -> void:
	var start_y: float = 150
	if cursor:
		cursor.position.y = start_y + selected_index * 30 + 3
	if cursor_glow:
		cursor_glow.position.y = start_y + selected_index * 30 + 1
	for i in range(menu_items.size()):
		var label: Label = menu_items[i]["label"]
		var bg: ColorRect = menu_items[i]["bg"]
		if i == selected_index:
			label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1.0))
			bg.color = Color(0.9, 0.75, 0.3, 0.08)
		else:
			label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 0.8))
			bg.color = Color(0, 0, 0, 0)

func _confirm_selection() -> void:
	if is_transitioning:
		return
	var scene_key: String = menu_items[selected_index]["scene"]
	if scene_key == "continue":
		SaveSystem.load_game()
		var last_level: String = GameState.current_level
		if last_level == "" or not SCENES.has(last_level):
			last_level = "mine"
		target_scene = SCENES[last_level]
		is_transitioning = true
		return
	if scene_key == "mine":
		if SaveSystem.has_save:
			SaveSystem.new_game()
		_show_class_select()
		return
	if not SaveSystem.has_save and GameState.selected_class == "":
		_show_class_select()
		return
	_goto_selected_scene()

func _goto_selected_scene() -> void:
	var scene_key: String = menu_items[selected_index]["scene"]
	if scene_key == "continue":
		scene_key = GameState.current_level
		if scene_key == "" or not SCENES.has(scene_key):
			scene_key = "mine"
	if SCENES.has(scene_key):
		target_scene = SCENES[scene_key]
		is_transitioning = true

func _take_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("/home/z/my-project/download/" + filename)
		print("Screenshot saved: " + filename)
