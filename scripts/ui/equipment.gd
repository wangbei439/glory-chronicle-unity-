## 装备系统 - Beta v0.12
## 管理武器、护甲的获取、装备、属性加成 + 打造选项卡
## v0.12: 新增"打造"选项卡，4个打造配方，材料消耗
extends Node2D

# === 基础装备定义 ===
const WEAPONS: Dictionary = {
        "iron_sword": {
                "name": "铁剑",
                "desc": "坚固的铁制长剑",
                "attack_mult": 1.2,
                "defense_mult": 1.0,
                "rage_bonus": 0.0,
                "color": Color(0.7, 0.7, 0.75),
                "cost_ore": 3,
        },
        "crystal_blade": {
                "name": "水晶刃",
                "desc": "蕴含矿脉能量的水晶剑",
                "attack_mult": 1.4,
                "defense_mult": 1.0,
                "rage_bonus": 0.2,
                "color": Color(0.4, 0.7, 1.0),
                "cost_ore": 6,
        },
        "berserker_axe": {
                "name": "狂战斧",
                "desc": "以防御换攻击的凶兵",
                "attack_mult": 1.6,
                "defense_mult": 0.85,
                "rage_bonus": 0.0,
                "color": Color(0.9, 0.3, 0.2),
                "cost_ore": 10,
        },
}

const ARMORS: Dictionary = {
        "leather_vest": {
                "name": "皮甲",
                "desc": "轻便的矿工皮甲",
                "defense_mult": 0.85,
                "max_hp_bonus": 0.0,
                "rage_bonus": 0.0,
                "color": Color(0.6, 0.4, 0.25),
                "cost_ore": 3,
        },
        "iron_plate": {
                "name": "铁甲",
                "desc": "厚重的铁板护甲",
                "defense_mult": 0.7,
                "max_hp_bonus": 20.0,
                "rage_bonus": 0.0,
                "color": Color(0.6, 0.65, 0.7),
                "cost_ore": 6,
        },
        "crystal_mail": {
                "name": "水晶甲",
                "desc": "攻守兼备的水晶铠",
                "defense_mult": 0.75,
                "max_hp_bonus": 0.0,
                "rage_bonus": 0.15,
                "color": Color(0.5, 0.8, 1.0),
                "cost_ore": 10,
        },
}

# === 打造配方（与crafting_system.gd同步）===
const CRAFT_RECIPES: Array = [
        {
                "id": "lava_greatsword",
                "name": "熔岩巨剑",
                "desc": "注入熔岩之力的毁灭巨剑",
                "type": "weapon",
                "attack_mult": 1.8,
                "defense_mult": 0.9,
                "rage_bonus": 0.1,
                "ore_cost": 8,
                "materials": {"lava_core": 2, "beetle_shell": 1},
                "color": Color(1.0, 0.4, 0.15),
        },
        {
                "id": "beetle_bulwark",
                "name": "甲虫壁垒",
                "desc": "以甲虫壳锻造的坚不可摧之盾",
                "type": "armor",
                "defense_mult": 0.6,
                "max_hp_bonus": 30.0,
                "rage_bonus": 0.0,
                "ore_cost": 8,
                "materials": {"beetle_shell": 2, "lava_core": 1},
                "color": Color(0.3, 0.55, 0.9),
        },
        {
                "id": "shadow_twin_blades",
                "name": "暗影双刃",
                "desc": "蕴含暗影之力的双刀，怒气激增",
                "type": "weapon",
                "attack_mult": 1.5,
                "defense_mult": 1.0,
                "rage_bonus": 0.3,
                "ore_cost": 6,
                "materials": {"shadow_essence": 3},
                "color": Color(0.5, 0.3, 0.8),
        },
        {
                "id": "vein_holy_garb",
                "name": "地脉圣衣",
                "desc": "元素结晶编织的攻守兼备战袍",
                "type": "armor",
                "defense_mult": 0.65,
                "max_hp_bonus": 15.0,
                "rage_bonus": 0.2,
                "ore_cost": 7,
                "materials": {"vein_crystal": 2, "shadow_essence": 1},
                "color": Color(0.95, 0.7, 0.25),
        },
]

const MATERIAL_NAMES: Dictionary = {
        "beetle_shell": "甲虫壳",
        "lava_core": "熔岩核心",
        "shadow_essence": "暗影精华",
        "vein_crystal": "地脉结晶",
}

# === UI状态 ===
var is_open: bool = false
var panel_nodes: Array = []
var current_tab: int = 0  # 0=武器, 1=护甲, 2=打造
var selected_index: int = 0
var tab_labels: Array = []
var item_slots: Array = []
var craft_info_label: Label  # 打造材料详情

# === 外部引用 ===
var drop_system: Node2D = null
var crafting_system: Node2D = null

# === 状态 ===
var need_refresh: bool = true

func _ready() -> void:
        pass

func set_drop_system(ds: Node2D) -> void:
        drop_system = ds

func set_crafting_system(cs: Node2D) -> void:
        crafting_system = cs

func build() -> void:
        # 全屏半透明遮罩
        var overlay = ColorRect.new()
        overlay.size = Vector2(640, 360)
        overlay.position = Vector2(0, 0)
        overlay.color = Color(0, 0, 0, 0.5)
        overlay.visible = false
        add_child(overlay)
        panel_nodes.append(overlay)

        # 边框（纹理面板框架）
        var border_frame_tex = load("res://assets/sprites/ui/panel_frame_440x290.png")
        var border: TextureRect = null
        if border_frame_tex:
                border = TextureRect.new()
                border.texture = border_frame_tex
                border.size = Vector2(444, 294)
                border.position = Vector2(98, 33)
                border.stretch_mode = TextureRect.STRETCH_SCALE
                border.visible = false
                add_child(border)
                border_bg_visible(border, false)
        else:
                var border_fallback = ColorRect.new()
                border_fallback.size = Vector2(444, 294)
                border_fallback.position = Vector2(98, 33)
                border_fallback.color = Color(0.5, 0.4, 0.3, 0.8)
                border_fallback.visible = false
                add_child(border_fallback)
                border_bg_visible(border_fallback, false)
        panel_nodes.append(border if border else get_child(get_child_count() - 1))

        # 主面板背景
        var panel_bg = ColorRect.new()
        panel_bg.size = Vector2(440, 290)
        panel_bg.position = Vector2(100, 35)
        panel_bg.color = Color(0.08, 0.07, 0.12, 0.95)
        panel_bg.visible = false
        add_child(panel_bg)
        panel_nodes.append(panel_bg)

        # 标题
        var title = Label.new()
        title.text = "装 备 / 打 造"
        title.position = Vector2(230, 42)
        title.add_theme_font_size_override("font_size", 14)
        title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
        title.visible = false
        add_child(title)
        panel_nodes.append(title)

        # Tab标签（武器/护甲/打造）
        var tab_weapon = Label.new()
        tab_weapon.text = "[ 武器 ]"
        tab_weapon.position = Vector2(120, 65)
        tab_weapon.add_theme_font_size_override("font_size", 10)
        tab_weapon.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
        tab_weapon.visible = false
        add_child(tab_weapon)
        panel_nodes.append(tab_weapon)
        tab_labels.append(tab_weapon)

        var tab_armor = Label.new()
        tab_armor.text = "  护甲  "
        tab_armor.position = Vector2(220, 65)
        tab_armor.add_theme_font_size_override("font_size", 10)
        tab_armor.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
        tab_armor.visible = false
        add_child(tab_armor)
        panel_nodes.append(tab_armor)
        tab_labels.append(tab_armor)

        var tab_craft = Label.new()
        tab_craft.text = "  打造  "
        tab_craft.position = Vector2(320, 65)
        tab_craft.add_theme_font_size_override("font_size", 10)
        tab_craft.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
        tab_craft.visible = false
        add_child(tab_craft)
        panel_nodes.append(tab_craft)
        tab_labels.append(tab_craft)

        # 矿石数量
        var ore_label = Label.new()
        ore_label.text = "ORE: 0"
        ore_label.position = Vector2(420, 65)
        ore_label.add_theme_font_size_override("font_size", 9)
        ore_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
        ore_label.visible = false
        add_child(ore_label)
        panel_nodes.append(ore_label)
        item_slots.append({"ore_label": ore_label})

        # 装备列表区域（4个槽位 - 打造有4个配方）
        var start_y: float = 85
        for i in range(4):
                var slot_y: float = start_y + i * 48

                # 装备槽位背景（更深色底层）
                var slot_bg = ColorRect.new()
                slot_bg.size = Vector2(414, 48)
                slot_bg.position = Vector2(113, slot_y - 2)
                slot_bg.color = Color(0.06, 0.05, 0.1, 0.6)
                slot_bg.visible = false
                add_child(slot_bg)
                panel_nodes.append(slot_bg)

                var bg = ColorRect.new()
                bg.size = Vector2(410, 44)
                bg.position = Vector2(115, slot_y)
                bg.color = Color(0.15, 0.12, 0.2, 0.6)
                bg.visible = false
                add_child(bg)
                panel_nodes.append(bg)

                var icon = ColorRect.new()
                icon.size = Vector2(22, 22)
                icon.position = Vector2(124, slot_y + 11)
                icon.color = Color(0.5, 0.5, 0.5)
                icon.visible = false
                add_child(icon)
                panel_nodes.append(icon)

                var name_label = Label.new()
                name_label.text = ""
                name_label.position = Vector2(155, slot_y + 3)
                name_label.add_theme_font_size_override("font_size", 10)
                name_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
                name_label.visible = false
                add_child(name_label)
                panel_nodes.append(name_label)

                var desc_label = Label.new()
                desc_label.text = ""
                desc_label.position = Vector2(155, slot_y + 16)
                desc_label.add_theme_font_size_override("font_size", 7)
                desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
                desc_label.visible = false
                add_child(desc_label)
                panel_nodes.append(desc_label)

                var cost_label = Label.new()
                cost_label.text = ""
                cost_label.position = Vector2(155, slot_y + 28)
                cost_label.add_theme_font_size_override("font_size", 7)
                cost_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
                cost_label.visible = false
                add_child(cost_label)
                panel_nodes.append(cost_label)

                var equip_label = Label.new()
                equip_label.text = ""
                equip_label.position = Vector2(440, slot_y + 12)
                equip_label.add_theme_font_size_override("font_size", 8)
                equip_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
                equip_label.visible = false
                add_child(equip_label)
                panel_nodes.append(equip_label)

                item_slots.append({
                        "slot_bg": slot_bg,
                        "bg": bg,
                        "icon": icon,
                        "name_label": name_label,
                        "desc_label": desc_label,
                        "cost_label": cost_label,
                        "equip_label": equip_label,
                        "id": "",
                })

        # 打造详情标签
        craft_info_label = Label.new()
        craft_info_label.text = ""
        craft_info_label.position = Vector2(120, 280)
        craft_info_label.add_theme_font_size_override("font_size", 7)
        craft_info_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
        craft_info_label.visible = false
        add_child(craft_info_label)
        panel_nodes.append(craft_info_label)

        # 操作提示
        var hint = Label.new()
        hint.text = "A/D:切换分类  W/S:选择  J:购买/装备/打造  K:卸下  E:关闭"
        hint.position = Vector2(115, 300)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
        hint.visible = false
        add_child(hint)
        panel_nodes.append(hint)

        # 当前装备信息
        var current_equip = Label.new()
        current_equip.text = ""
        current_equip.position = Vector2(115, 312)
        current_equip.add_theme_font_size_override("font_size", 8)
        current_equip.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
        current_equip.visible = false
        add_child(current_equip)
        panel_nodes.append(current_equip)
        item_slots.append({"current_equip": current_equip})

func border_bg_visible(border: CanvasItem, vis: bool) -> void:
        border.visible = vis

func toggle() -> void:
        is_open = not is_open
        for node in panel_nodes:
                if is_instance_valid(node):
                        node.visible = is_open
        if is_open:
                selected_index = 0
                need_refresh = true
                _refresh_display()

func close() -> void:
        is_open = false
        for node in panel_nodes:
                if is_instance_valid(node):
                        node.visible = false

func process_input() -> void:
        if not is_open:
                return

        # E键关闭
        if Input.is_key_pressed(KEY_E):
                close()
                return

        # A/D切换Tab
        if Input.is_action_just_pressed("move_left"):
                current_tab = (current_tab - 1) % 3
                if current_tab < 0: current_tab = 2
                selected_index = 0
                need_refresh = true
        elif Input.is_action_just_pressed("move_right"):
                current_tab = (current_tab + 1) % 3
                selected_index = 0
                need_refresh = true

        # W/S选择
        if Input.is_action_just_pressed("jump"):  # W键
                var max_idx: int = 2 if current_tab < 2 else 3
                selected_index = (selected_index - 1) % (max_idx + 1)
                if selected_index < 0: selected_index = max_idx
                need_refresh = true

        # 上下
        if Input.is_key_pressed(KEY_UP):
                var max_idx: int = 2 if current_tab < 2 else 3
                selected_index = (selected_index - 1) % (max_idx + 1)
                if selected_index < 0: selected_index = max_idx
                need_refresh = true
        elif Input.is_key_pressed(KEY_DOWN):
                var max_idx: int = 2 if current_tab < 2 else 3
                selected_index = (selected_index + 1) % (max_idx + 1)
                need_refresh = true

        # K键卸下
        if Input.is_action_just_pressed("heavy_attack"):
                if current_tab < 2:
                        _unequip_selected()
                        need_refresh = true

        # J键操作
        if Input.is_action_just_pressed("attack"):
                _on_action_selected()
                need_refresh = true

        if need_refresh:
                _refresh_display()
                need_refresh = false

func _refresh_display() -> void:
        var items: Dictionary = {}
        var max_items: int = 3

        if current_tab == 0:
                items = WEAPONS
                max_items = 3
        elif current_tab == 1:
                items = ARMORS
                max_items = 3
        else:
                max_items = 4  # 打造有4个配方

        var equipped_id: String = GameState.equipped_weapon if current_tab == 0 else GameState.equipped_armor
        if current_tab == 2:
                equipped_id = ""

        # Tab高亮
        var tab_texts: Array = ["  武器  ", "  护甲  ", "  打造  "]
        var tab_active: Array = ["[ 武器 ]", "[ 护甲 ]", "[ 打造 ]"]
        for i in range(3):
                if i < tab_labels.size():
                        tab_labels[i].text = tab_active[i] if i == current_tab else tab_texts[i]
                        tab_labels[i].add_theme_color_override("font_color",
                                Color(1, 0.9, 0.6) if i == current_tab else Color(0.6, 0.6, 0.6))

        # 矿石数量
        if item_slots.size() > 0 and item_slots[0].has("ore_label"):
                var ore_count: int = drop_system.get_ore_count() if drop_system else 0
                item_slots[0]["ore_label"].text = "ORE: " + str(ore_count)

        # 装备/打造槽位
        for i in range(4):
                if i + 1 >= item_slots.size():
                        break
                var slot: Dictionary = item_slots[i + 1]

                if current_tab < 2:
                        # 武器/护甲模式
                        var item_keys: Array = items.keys()
                        if i < item_keys.size():
                                var key: String = item_keys[i]
                                var info: Dictionary = items[key]
                                var is_owned: bool = GameState.owned_equipment.has(key)
                                var is_equipped: bool = (key == equipped_id)
                                var is_selected: bool = (i == selected_index)

                                slot["id"] = key
                                if slot.has("bg"):
                                        slot["bg"].color = Color(0.25, 0.2, 0.35, 0.8) if is_selected else Color(0.15, 0.12, 0.2, 0.6)
                                        slot["bg"].visible = true
                                if slot.has("icon"):
                                        slot["icon"].color = info.get("color", Color(0.5, 0.5, 0.5))
                                        slot["icon"].visible = true
                                if slot.has("name_label"):
                                        slot["name_label"].text = info.get("name", key)
                                        slot["name_label"].add_theme_color_override("font_color",
                                                Color(1, 0.95, 0.7) if is_equipped else Color(0.85, 0.8, 0.7))
                                        slot["name_label"].visible = true
                                if slot.has("desc_label"):
                                        slot["desc_label"].text = info.get("desc", "")
                                        slot["desc_label"].visible = true
                                if slot.has("cost_label"):
                                        var cost_text: String = ""
                                        if current_tab == 0:
                                                cost_text = "ATK+" + str(int((info.get("attack_mult", 1.0) - 1.0) * 100)) + "%"
                                                if info.get("rage_bonus", 0.0) > 0:
                                                        cost_text += " RAGE+" + str(int(info.get("rage_bonus", 0.0) * 100)) + "%"
                                                if info.get("defense_mult", 1.0) < 1.0:
                                                        cost_text += " DEF" + str(int((info.get("defense_mult", 1.0) - 1.0) * 100)) + "%"
                                        else:
                                                var def_val: int = int((1.0 - info.get("defense_mult", 1.0)) * 100)
                                                cost_text = "DEF+" + str(def_val) + "%"
                                                if info.get("max_hp_bonus", 0.0) > 0:
                                                        cost_text += " HP+" + str(int(info.get("max_hp_bonus", 0.0)))
                                                if info.get("rage_bonus", 0.0) > 0:
                                                        cost_text += " RAGE+" + str(int(info.get("rage_bonus", 0.0) * 100)) + "%"
                                        if not is_owned:
                                                cost_text += "  |  " + str(info.get("cost_ore", 0)) + "矿石"
                                        slot["cost_label"].text = cost_text
                                        slot["cost_label"].visible = true
                                if slot.has("equip_label"):
                                        if is_equipped:
                                                slot["equip_label"].text = "装备中"
                                                slot["equip_label"].add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
                                        elif is_owned:
                                                slot["equip_label"].text = "已拥有"
                                                slot["equip_label"].add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
                                        else:
                                                slot["equip_label"].text = "购买"
                                                slot["equip_label"].add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
                                        slot["equip_label"].visible = true
                        else:
                                _hide_slot(slot, i)
                else:
                        # 打造模式
                        if i < CRAFT_RECIPES.size():
                                var recipe: Dictionary = CRAFT_RECIPES[i]
                                var is_owned: bool = GameState.owned_equipment.has(recipe["id"])
                                var is_equipped: bool = (recipe["id"] == GameState.equipped_weapon or recipe["id"] == GameState.equipped_armor)
                                var is_selected: bool = (i == selected_index)
                                var can_make: bool = _can_craft_recipe(recipe)

                                slot["id"] = recipe["id"]
                                if slot.has("bg"):
                                        slot["bg"].color = Color(0.3, 0.2, 0.15, 0.8) if is_selected else Color(0.15, 0.1, 0.08, 0.6)
                                        slot["bg"].visible = true
                                if slot.has("icon"):
                                        slot["icon"].color = recipe.get("color", Color(0.5, 0.5, 0.5))
                                        slot["icon"].visible = true
                                if slot.has("name_label"):
                                        slot["name_label"].text = recipe.get("name", "")
                                        var name_color: Color = Color(1, 0.95, 0.7) if is_equipped else (Color(0.95, 0.75, 0.4) if can_make else Color(0.6, 0.5, 0.45))
                                        slot["name_label"].add_theme_color_override("font_color", name_color)
                                        slot["name_label"].visible = true
                                if slot.has("desc_label"):
                                        slot["desc_label"].text = recipe.get("desc", "")
                                        slot["desc_label"].visible = true
                                if slot.has("cost_label"):
                                        var cost_text: String = ""
                                        if recipe["type"] == "weapon":
                                                cost_text = "ATK+" + str(int((recipe.get("attack_mult", 1.0) - 1.0) * 100)) + "%"
                                                if recipe.get("rage_bonus", 0.0) > 0:
                                                        cost_text += " RAGE+" + str(int(recipe.get("rage_bonus", 0.0) * 100)) + "%"
                                        else:
                                                var def_val: int = int((1.0 - recipe.get("defense_mult", 1.0)) * 100)
                                                cost_text = "DEF+" + str(def_val) + "%"
                                                if recipe.get("max_hp_bonus", 0.0) > 0:
                                                        cost_text += " HP+" + str(int(recipe.get("max_hp_bonus", 0.0)))
                                                if recipe.get("rage_bonus", 0.0) > 0:
                                                        cost_text += " RAGE+" + str(int(recipe.get("rage_bonus", 0.0) * 100)) + "%"
                                        # 材料需求
                                        cost_text += " | " + str(recipe.get("ore_cost", 0)) + "矿"
                                        var mat_dict: Dictionary = recipe.get("materials", {})
                                        for mat_key: String in mat_dict:
                                                cost_text += " " + MATERIAL_NAMES.get(mat_key, mat_key) + "x" + str(mat_dict[mat_key])
                                        slot["cost_label"].text = cost_text
                                        slot["cost_label"].add_theme_color_override("font_color",
                                                Color(0.9, 0.7, 0.3) if can_make else Color(0.5, 0.4, 0.35))
                                        slot["cost_label"].visible = true
                                if slot.has("equip_label"):
                                        if is_equipped:
                                                slot["equip_label"].text = "装备中"
                                                slot["equip_label"].add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
                                        elif is_owned:
                                                slot["equip_label"].text = "已拥有"
                                                slot["equip_label"].add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
                                        elif can_make:
                                                slot["equip_label"].text = "可打造"
                                                slot["equip_label"].add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
                                        else:
                                                slot["equip_label"].text = "缺材料"
                                                slot["equip_label"].add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
                                        slot["equip_label"].visible = true
                        else:
                                _hide_slot(slot, i)

        # 打造材料详情
        if craft_info_label:
                if current_tab == 2:
                        craft_info_label.visible = true
                        var cm: Dictionary = GameState.crafting_materials
                        craft_info_label.text = "持有: 甲壳x" + str(cm.get("beetle_shell", 0)) + " 熔岩x" + str(cm.get("lava_core", 0)) + " 暗影x" + str(cm.get("shadow_essence", 0)) + " 地脉x" + str(cm.get("vein_crystal", 0))
                else:
                        craft_info_label.visible = false

        # 当前装备摘要
        if item_slots.size() > 5 and item_slots[5].has("current_equip"):
                var summary: String = ""
                if GameState.equipped_weapon != "":
                        var w_name: String = _get_equip_name(GameState.equipped_weapon)
                        summary += "武器:" + w_name + "  "
                if GameState.equipped_armor != "":
                        var a_name: String = _get_equip_name(GameState.equipped_armor)
                        summary += "护甲:" + a_name
                if summary == "":
                        summary = "当前无装备"
                item_slots[5]["current_equip"].text = summary

func _hide_slot(slot: Dictionary, i: int) -> void:
        slot["id"] = ""
        if slot.has("slot_bg"):
                slot["slot_bg"].color = Color(0.04, 0.03, 0.08, 0.4)
        if slot.has("bg"):
                slot["bg"].color = Color(0.1, 0.08, 0.15, 0.4)
        if slot.has("icon"):
                slot["icon"].color = Color(0.2, 0.2, 0.2, 0.3)
        if slot.has("name_label"):
                slot["name_label"].text = "— 空 —"
                slot["name_label"].add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
        if slot.has("desc_label"):
                slot["desc_label"].text = ""
        if slot.has("cost_label"):
                slot["cost_label"].text = ""
        if slot.has("equip_label"):
                slot["equip_label"].text = ""

func _get_equip_name(equip_id: String) -> String:
        if WEAPONS.has(equip_id):
                return WEAPONS[equip_id]["name"]
        if ARMORS.has(equip_id):
                return ARMORS[equip_id]["name"]
        for recipe in CRAFT_RECIPES:
                if recipe["id"] == equip_id:
                        return recipe["name"]
        return equip_id

func _can_craft_recipe(recipe: Dictionary) -> bool:
        if GameState.owned_equipment.has(recipe["id"]):
                return false
        var ore_count: int = drop_system.get_ore_count() if drop_system else 0
        if ore_count < recipe.get("ore_cost", 999):
                return false
        var cm: Dictionary = GameState.crafting_materials
        var mat_dict: Dictionary = recipe.get("materials", {})
        for mat_key: String in mat_dict:
                if int(cm.get(mat_key, 0)) < mat_dict[mat_key]:
                        return false
        return true

func _on_action_selected() -> void:
        if selected_index + 1 >= item_slots.size():
                return
        var slot: Dictionary = item_slots[selected_index + 1]
        var item_id: String = slot.get("id", "")
        if item_id == "":
                return

        if current_tab < 2:
                # 武器/护甲模式：购买/装备/卸下
                var is_owned: bool = GameState.owned_equipment.has(item_id)
                var items: Dictionary = WEAPONS if current_tab == 0 else ARMORS
                var equipped_id: String = GameState.equipped_weapon if current_tab == 0 else GameState.equipped_armor
                var is_equipped: bool = (item_id == equipped_id)

                if is_equipped:
                        if current_tab == 0:
                                GameState.unequip_weapon()
                        else:
                                GameState.unequip_armor()
                elif is_owned:
                        if current_tab == 0:
                                GameState.equip_weapon(item_id)
                        else:
                                GameState.equip_armor(item_id)
                else:
                        var cost: int = items[item_id].get("cost_ore", 999)
                        if drop_system and drop_system.spend_ore(cost):
                                GameState.owned_equipment.append(item_id)
                                if current_tab == 0:
                                        GameState.equip_weapon(item_id)
                                else:
                                        GameState.equip_armor(item_id)
        else:
                # 打造模式
                if selected_index < CRAFT_RECIPES.size():
                        var recipe: Dictionary = CRAFT_RECIPES[selected_index]
                        if _can_craft_recipe(recipe):
                                _craft_item(recipe)

func _craft_item(recipe: Dictionary) -> void:
        """打造装备"""
        # 消耗矿石
        if drop_system:
                drop_system.spend_ore(recipe["ore_cost"])
                GameState.ore_fragments = drop_system.get_ore_count()
        # 消耗材料
        var mat_dict: Dictionary = recipe.get("materials", {})
        for mat_key: String in mat_dict:
                GameState.crafting_materials[mat_key] = int(GameState.crafting_materials.get(mat_key, 0)) - mat_dict[mat_key]
        # 同步到crafting_system
        if crafting_system:
                crafting_system.load_save_data(GameState.crafting_materials)
                crafting_system.set_ore_count(GameState.ore_fragments)
        # 添加到拥有列表
        GameState.owned_equipment.append(recipe["id"])
        # 自动装备
        if recipe["type"] == "weapon":
                GameState.equip_weapon(recipe["id"])
        else:
                GameState.equip_armor(recipe["id"])

func _unequip_selected() -> void:
        if current_tab == 0:
                GameState.unequip_weapon()
        else:
                GameState.unequip_armor()

func get_attack_bonus() -> float:
        var stats: Dictionary = GameState.get_equipment_stats()
        return stats.get("attack_mult", 1.0)

func get_defense_bonus() -> float:
        var stats: Dictionary = GameState.get_equipment_stats()
        return 1.0 - stats.get("defense_mult", 1.0)

func get_max_hp_bonus() -> float:
        var stats: Dictionary = GameState.get_equipment_stats()
        return stats.get("max_hp_bonus", 0.0)

func get_rage_bonus() -> float:
        var stats: Dictionary = GameState.get_equipment_stats()
        return stats.get("rage_bonus", 0.0)
