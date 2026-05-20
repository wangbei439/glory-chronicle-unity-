## 技能树系统 - Alpha v0.8
## 3个基础技能节点，矿石碎片升级，Tab键开关
## 技能效果实际影响战斗属性
extends Node2D

# === 技能定义 ===
enum SkillId {
        ATTACK_BOOST,    # 攻击强化
        DEFENSE_BOOST,   # 防御强化
        RAGE_MASTERY,    # 怒气精通
}

# 技能数据
const SKILL_DEFS = {
        SkillId.ATTACK_BOOST: {
                "name": "攻击强化",
                "desc": "提升物理伤害",
                "icon_color": Color(1.0, 0.4, 0.3),
                "max_level": 3,
                "cost_per_level": [3, 5, 8],  # 每级所需矿石碎片
                "bonus_per_level": [0.10, 0.10, 0.10],  # 每级加成(累计)
        },
        SkillId.DEFENSE_BOOST: {
                "name": "防御强化",
                "desc": "减少受到的伤害",
                "icon_color": Color(0.3, 0.6, 1.0),
                "max_level": 3,
                "cost_per_level": [3, 5, 8],
                "bonus_per_level": [0.08, 0.08, 0.09],  # 减伤比例
        },
        SkillId.RAGE_MASTERY: {
                "name": "怒气精通",
                "desc": "提升怒气获取效率",
                "icon_color": Color(1.0, 0.7, 0.2),
                "max_level": 3,
                "cost_per_level": [2, 4, 6],
                "bonus_per_level": [0.15, 0.15, 0.20],  # 怒气获取加成
        },
}

# === 技能等级 ===
var skill_levels: Dictionary = {
        SkillId.ATTACK_BOOST: 0,
        SkillId.DEFENSE_BOOST: 0,
        SkillId.RAGE_MASTERY: 0,
}

# === UI状态 ===
var is_open: bool = false
var selected_skill: int = 0  # 当前选中的技能ID
var panel_nodes: Array = []  # 面板节点引用
var cursor_node: ColorRect = null
var title_label: Label = null
var ore_label: Label = null
var desc_label: Label = null
var info_label: Label = null

# === 外部引用 ===
var drop_system: Node2D = null  # 掉落系统（获取矿石碎片数）

# === 信号 ===
signal skill_upgraded(skill_id: int, new_level: int)

func _ready() -> void:
        pass

func set_drop_system(ds: Node2D) -> void:
        drop_system = ds

func build() -> void:
        """构建技能树UI面板"""
        # 边框（纹理面板框架）
        var border_frame_tex = load("res://assets/sprites/ui/panel_frame_280x200.png")
        var border: TextureRect = null
        if border_frame_tex:
                border = TextureRect.new()
                border.texture = border_frame_tex
                border.size = Vector2(304, 224)
                border.position = Vector2(168, 68)
                border.stretch_mode = TextureRect.STRETCH_SCALE
                border.visible = false
                add_child(border)
        else:
                var border_fallback = ColorRect.new()
                border_fallback.size = Vector2(304, 224)
                border_fallback.position = Vector2(168, 68)
                border_fallback.color = Color(0.4, 0.35, 0.3, 0.8)
                border_fallback.visible = false
                add_child(border_fallback)
        panel_nodes.append(border if border else get_child(get_child_count() - 1))

        # 背景面板
        var panel_bg = ColorRect.new()
        panel_bg.size = Vector2(300, 220)
        panel_bg.position = Vector2(170, 70)
        panel_bg.color = Color(0.05, 0.05, 0.1, 0.95)
        panel_bg.visible = false
        add_child(panel_bg)
        panel_nodes.append(panel_bg)

        # 标题
        title_label = Label.new()
        title_label.text = "技 能 树"
        title_label.position = Vector2(270, 74)
        title_label.add_theme_font_size_override("font_size", 12)
        title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
        title_label.visible = false
        add_child(title_label)
        panel_nodes.append(title_label)

        # 标题下划线装饰
        var title_underline = ColorRect.new()
        title_underline.size = Vector2(80, 1)
        title_underline.position = Vector2(260, 88)
        title_underline.color = Color(0.6, 0.55, 0.45, 0.5)
        title_underline.visible = false
        add_child(title_underline)
        panel_nodes.append(title_underline)

        # 矿石碎片计数
        ore_label = Label.new()
        ore_label.text = "ORE: 0"
        ore_label.position = Vector2(350, 74)
        ore_label.add_theme_font_size_override("font_size", 9)
        ore_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
        ore_label.visible = false
        add_child(ore_label)
        panel_nodes.append(ore_label)

        # 3个技能节点
        var skill_ids = [SkillId.ATTACK_BOOST, SkillId.DEFENSE_BOOST, SkillId.RAGE_MASTERY]
        var skill_icon_paths = [
                "res://assets/sprites/ui/skill_icon_attack.png",
                "res://assets/sprites/ui/skill_icon_defense.png",
                "res://assets/sprites/ui/skill_icon_rage.png",
        ]
        for i in range(3):
                var sid: int = skill_ids[i]
                var def: Dictionary = SKILL_DEFS[sid]
                var x: float = 185 + i * 90
                var y: float = 100

                # 技能图标背景
                var icon_bg = ColorRect.new()
                icon_bg.size = Vector2(60, 60)
                icon_bg.position = Vector2(x, y)
                icon_bg.color = Color(0.1, 0.1, 0.15, 0.9)
                icon_bg.visible = false
                add_child(icon_bg)
                panel_nodes.append(icon_bg)

                # 技能图标（纹理）
                var icon_tex = load(skill_icon_paths[i])
                var icon: TextureRect = null
                if icon_tex:
                        icon = TextureRect.new()
                        icon.texture = icon_tex
                        icon.size = Vector2(40, 40)
                        icon.position = Vector2(x + 10, y + 4)
                        icon.stretch_mode = TextureRect.STRETCH_SCALE
                        icon.visible = false
                        add_child(icon)
                else:
                        # fallback: 彩色方块
                        var icon_fallback = ColorRect.new()
                        icon_fallback.size = Vector2(40, 40)
                        icon_fallback.position = Vector2(x + 10, y + 4)
                        icon_fallback.color = def["icon_color"]
                        icon_fallback.visible = false
                        add_child(icon_fallback)
                panel_nodes.append(icon if icon else get_child(get_child_count() - 1))

                # 技能等级指示
                for lv in range(3):
                        var dot = ColorRect.new()
                        dot.size = Vector2(8, 4)
                        dot.position = Vector2(x + 10 + lv * 14, y + 48)
                        dot.color = Color(0.3, 0.3, 0.3, 0.8)  # 默认暗色
                        dot.visible = false
                        add_child(dot)
                        panel_nodes.append(dot)

                # 技能名称
                var name_label = Label.new()
                name_label.text = def["name"]
                name_label.position = Vector2(x + 2, y + 56)
                name_label.add_theme_font_size_override("font_size", 7)
                name_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
                name_label.visible = false
                add_child(name_label)
                panel_nodes.append(name_label)

        # 选择光标
        cursor_node = ColorRect.new()
        cursor_node.size = Vector2(64, 64)
        cursor_node.position = Vector2(183, 98)
        cursor_node.color = Color(1, 0.9, 0.5, 0.3)
        cursor_node.visible = false
        add_child(cursor_node)
        panel_nodes.append(cursor_node)

        # 描述区域
        desc_label = Label.new()
        desc_label.text = ""
        desc_label.position = Vector2(185, 188)
        desc_label.add_theme_font_size_override("font_size", 8)
        desc_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
        desc_label.visible = false
        add_child(desc_label)
        panel_nodes.append(desc_label)

        # 操作提示
        info_label = Label.new()
        info_label.text = "A/D:选择  J:升级  Tab:关闭"
        info_label.position = Vector2(210, 268)
        info_label.add_theme_font_size_override("font_size", 7)
        info_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
        info_label.visible = false
        add_child(info_label)
        panel_nodes.append(info_label)

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
        """处理技能树输入（只在打开时调用）"""
        if not is_open:
                return

        # A/D 切换选择
        if Input.is_action_just_pressed("move_left"):
                selected_skill = max(0, selected_skill - 1)
                _update_display()
        elif Input.is_action_just_pressed("move_right"):
                selected_skill = min(2, selected_skill + 1)
                _update_display()

        # J 升级技能
        if Input.is_action_just_pressed("attack"):
                _try_upgrade(selected_skill)

        # Tab 关闭
        if Input.is_key_pressed(KEY_TAB):
                close()

func _try_upgrade(skill_index: int) -> void:
        """尝试升级技能"""
        var skill_ids = [SkillId.ATTACK_BOOST, SkillId.DEFENSE_BOOST, SkillId.RAGE_MASTERY]
        var sid: int = skill_ids[skill_index]
        var def: Dictionary = SKILL_DEFS[sid]
        var current_level: int = skill_levels[sid]

        if current_level >= def["max_level"]:
                return  # 已满级

        var cost: int = def["cost_per_level"][current_level]
        if drop_system and drop_system.spend_ore(cost):
                skill_levels[sid] = current_level + 1
                skill_upgraded.emit(sid, skill_levels[sid])
                _update_display()

func _update_display() -> void:
        """更新UI显示"""
        # 更新矿石数量
        if drop_system:
                ore_label.text = "ORE: " + str(drop_system.get_ore_count())

        # 更新光标位置
        var cursor_positions = [Vector2(183, 98), Vector2(273, 98), Vector2(363, 98)]
        cursor_node.position = cursor_positions[selected_skill]

        # 更新技能等级指示点
        var skill_ids = [SkillId.ATTACK_BOOST, SkillId.DEFENSE_BOOST, SkillId.RAGE_MASTERY]
        for i in range(3):
                var sid: int = skill_ids[i]
                var level: int = skill_levels[sid]
                var def: Dictionary = SKILL_DEFS[sid]
                var x: float = 195 + i * 90
                # 每个技能有3个等级点（从第5+i*6个panel节点开始）
                var base_idx = 5 + i * 6  # 每个技能占6个节点
                for lv in range(3):
                        var dot_idx = base_idx + 2 + lv  # 等级点在icon_bg, icon之后
                        if dot_idx < panel_nodes.size():
                                var dot: ColorRect = panel_nodes[dot_idx]
                                if lv < level:
                                        dot.color = def["icon_color"]
                                else:
                                        dot.color = Color(0.3, 0.3, 0.3, 0.8)

        # 更新描述
        var sel_sid: int = skill_ids[selected_skill]
        var sel_def: Dictionary = SKILL_DEFS[sel_sid]
        var sel_level: int = skill_levels[sel_sid]
        var desc_text: String = sel_def["name"] + " Lv." + str(sel_level) + "/" + str(sel_def["max_level"])
        desc_text += " | " + sel_def["desc"]
        if sel_level < sel_def["max_level"]:
                var cost: int = sel_def["cost_per_level"][sel_level]
                var bonus: float = sel_def["bonus_per_level"][sel_level]
                desc_text += " | 下一级: " + str(bonus * 100) + "% (需" + str(cost) + "矿石)"
        else:
                desc_text += " | 已满级"
        desc_label.text = desc_text

# === 获取技能加成 ===

func get_attack_bonus() -> float:
        """获取攻击加成倍率（1.0 = 无加成）"""
        var level: int = skill_levels[SkillId.ATTACK_BOOST]
        var total: float = 1.0
        var def: Dictionary = SKILL_DEFS[SkillId.ATTACK_BOOST]
        for i in range(level):
                total += def["bonus_per_level"][i]
        return total

func get_defense_bonus() -> float:
        """获取减伤比例（0.0 = 无减伤）"""
        var level: int = skill_levels[SkillId.DEFENSE_BOOST]
        var total: float = 0.0
        var def: Dictionary = SKILL_DEFS[SkillId.DEFENSE_BOOST]
        for i in range(level):
                total += def["bonus_per_level"][i]
        return total

func get_rage_bonus() -> float:
        """获取怒气获取加成倍率（1.0 = 无加成）"""
        var level: int = skill_levels[SkillId.RAGE_MASTERY]
        var total: float = 1.0
        var def: Dictionary = SKILL_DEFS[SkillId.RAGE_MASTERY]
        for i in range(level):
                total += def["bonus_per_level"][i]
        return total

func get_skill_data() -> Dictionary:
        """获取所有技能等级（用于保存）"""
        return {
                "attack_boost": skill_levels[SkillId.ATTACK_BOOST],
                "defense_boost": skill_levels[SkillId.DEFENSE_BOOST],
                "rage_mastery": skill_levels[SkillId.RAGE_MASTERY],
        }

func load_skill_data(data: Dictionary) -> void:
        """加载技能等级"""
        if data.has("attack_boost"):
                skill_levels[SkillId.ATTACK_BOOST] = data["attack_boost"]
        if data.has("defense_boost"):
                skill_levels[SkillId.DEFENSE_BOOST] = data["defense_boost"]
        if data.has("rage_mastery"):
                skill_levels[SkillId.RAGE_MASTERY] = data["rage_mastery"]
