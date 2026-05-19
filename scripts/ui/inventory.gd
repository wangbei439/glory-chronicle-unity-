## 物品栏UI - Alpha v0.9
## 显示收集的物品和数量，Shift+Tab切换
extends Node2D

# === UI状态 ===
var is_open: bool = false
var panel_nodes: Array = []

# === 外部引用 ===
var drop_system: Node2D = null

# === 物品数据 ===
var item_labels: Dictionary = {}

func _ready() -> void:
	pass

func set_drop_system(ds: Node2D) -> void:
	drop_system = ds

func build() -> void:
	"""构建物品栏UI面板"""
	# 背景
	var panel_bg = ColorRect.new()
	panel_bg.size = Vector2(240, 160)
	panel_bg.position = Vector2(200, 100)
	panel_bg.color = Color(0.05, 0.05, 0.1, 0.92)
	panel_bg.visible = false
	add_child(panel_bg)
	panel_nodes.append(panel_bg)

	# 边框
	var border = ColorRect.new()
	border.size = Vector2(244, 164)
	border.position = Vector2(198, 98)
	border.color = Color(0.4, 0.35, 0.3, 0.8)
	border.visible = false
	add_child(border)
	panel_nodes.append(border)

	# 标题
	var title = Label.new()
	title.text = "物 品 栏"
	title.position = Vector2(270, 104)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	title.visible = false
	add_child(title)
	panel_nodes.append(title)

	# 物品列表
	var items_data = [
		{"key": "health_potion", "name": "生命药水", "color": Color(0.2, 0.9, 0.3)},
		{"key": "rage_crystal", "name": "怒气水晶", "color": Color(0.9, 0.4, 0.1)},
		{"key": "ore_fragment", "name": "矿石碎片", "color": Color(0.7, 0.6, 0.9)},
	]

	var start_y: float = 128
	for i in range(items_data.size()):
		var info = items_data[i]

		# 物品图标（小色块）
		var icon = ColorRect.new()
		icon.size = Vector2(12, 12)
		icon.position = Vector2(216, start_y + i * 28)
		icon.color = info["color"]
		icon.visible = false
		add_child(icon)
		panel_nodes.append(icon)

		# 物品名称
		var name_label = Label.new()
		name_label.text = info["name"]
		name_label.position = Vector2(234, start_y + i * 28 - 2)
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
		name_label.visible = false
		add_child(name_label)
		panel_nodes.append(name_label)

		# 物品数量
		var count_label = Label.new()
		count_label.text = "x0"
		count_label.position = Vector2(340, start_y + i * 28 - 2)
		count_label.add_theme_font_size_override("font_size", 9)
		count_label.add_theme_color_override("font_color", info["color"])
		count_label.visible = false
		add_child(count_label)
		panel_nodes.append(count_label)

		item_labels[info["key"]] = count_label

	# 操作提示
	var hint = Label.new()
	hint.text = "Shift+Tab:关闭"
	hint.position = Vector2(240, 242)
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
	hint.visible = false
	add_child(hint)
	panel_nodes.append(hint)

func toggle() -> void:
	is_open = not is_open
	for node in panel_nodes:
		if is_instance_valid(node):
			node.visible = is_open
	if is_open:
		_update_display()

func close() -> void:
	is_open = false
	for node in panel_nodes:
		if is_instance_valid(node):
			node.visible = false

func process_input() -> void:
	if not is_open:
		return
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_TAB):
		close()

func _update_display() -> void:
	"""更新物品数量显示"""
	if drop_system:
		# 生命药水和怒气水晶计数来自掉落系统的已拾取统计
		# 矿石碎片直接从drop_system获取
		if item_labels.has("ore_fragment"):
			item_labels["ore_fragment"].text = "x" + str(drop_system.get_ore_count())
