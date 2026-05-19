## 装备系统 - Beta v0.10
## 管理武器和护甲的获取、装备、属性加成
## 对应设计文档§3.2：装备与材料 - 玩法驱动循环
## 武器：铁剑/水晶刃/狂战斧  护甲：皮甲/铁甲/水晶甲
extends Node2D

# === 装备定义 ===
# 武器：id, name, desc, attack_mult, defense_mult, rage_bonus, color, cost_ore
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

# 护甲：id, name, desc, defense_mult, max_hp_bonus, rage_bonus, color, cost_ore
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

# === UI状态 ===
var is_open: bool = false
var panel_nodes: Array = []
var current_tab: int = 0  # 0=武器, 1=护甲
var selected_index: int = 0
var tab_labels: Array = []
var item_slots: Array = []  # 每个slot: {bg, icon, name_label, desc_label, cost_label, equip_label, id}

# === 外部引用 ===
var drop_system: Node2D = null

# === 状态 ===
var need_refresh: bool = true

func _ready() -> void:
        pass

func set_drop_system(ds: Node2D) -> void:
        drop_system = ds

func build() -> void:
        """构建装备系统UI"""
        # 全屏半透明遮罩
        var overlay = ColorRect.new()
        overlay.size = Vector2(640, 360)
        overlay.position = Vector2(0, 0)
        overlay.color = Color(0, 0, 0, 0.5)
        overlay.visible = false
        add_child(overlay)
        panel_nodes.append(overlay)

        # 主面板背景
        var panel_bg = ColorRect.new()
        panel_bg.size = Vector2(400, 280)
        panel_bg.position = Vector2(120, 40)
        panel_bg.color = Color(0.08, 0.07, 0.12, 0.95)
        panel_bg.visible = false
        add_child(panel_bg)
        panel_nodes.append(panel_bg)

        # 边框
        var border = ColorRect.new()
        border.size = Vector2(404, 284)
        border.position = Vector2(118, 38)
        border.color = Color(0.5, 0.4, 0.3, 0.8)
        border.visible = false
        add_child(border)
        panel_nodes.append(border)

        # 标题
        var title = Label.new()
        title.text = "装 备 系 统"
        title.position = Vector2(240, 48)
        title.add_theme_font_size_override("font_size", 14)
        title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
        title.visible = false
        add_child(title)
        panel_nodes.append(title)

        # Tab标签（武器/护甲）
        var tab_weapon = Label.new()
        tab_weapon.text = "[ 武器 ]"
        tab_weapon.position = Vector2(175, 72)
        tab_weapon.add_theme_font_size_override("font_size", 11)
        tab_weapon.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
        tab_weapon.visible = false
        add_child(tab_weapon)
        panel_nodes.append(tab_weapon)
        tab_labels.append(tab_weapon)

        var tab_armor = Label.new()
        tab_armor.text = "  护甲  "
        tab_armor.position = Vector2(310, 72)
        tab_armor.add_theme_font_size_override("font_size", 11)
        tab_armor.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
        tab_armor.visible = false
        add_child(tab_armor)
        panel_nodes.append(tab_armor)
        tab_labels.append(tab_armor)

        # 矿石数量显示
        var ore_label = Label.new()
        ore_label.text = "ORE: 0"
        ore_label.position = Vector2(400, 72)
        ore_label.add_theme_font_size_override("font_size", 9)
        ore_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
        ore_label.visible = false
        add_child(ore_label)
        panel_nodes.append(ore_label)
        item_slots.append({"ore_label": ore_label})  # 特殊slot存矿石标签

        # 装备列表区域（3个装备槽位）
        var start_y: float = 95
        for i in range(3):
                var slot_y: float = start_y + i * 55

                # 选中高亮背景
                var bg = ColorRect.new()
                bg.size = Vector2(370, 50)
                bg.position = Vector2(135, slot_y)
                bg.color = Color(0.15, 0.12, 0.2, 0.6)
                bg.visible = false
                add_child(bg)
                panel_nodes.append(bg)

                # 装备图标
                var icon = ColorRect.new()
                icon.size = Vector2(24, 24)
                icon.position = Vector2(145, slot_y + 13)
                icon.color = Color(0.5, 0.5, 0.5)
                icon.visible = false
                add_child(icon)
                panel_nodes.append(icon)

                # 装备名称
                var name_label = Label.new()
                name_label.text = ""
                name_label.position = Vector2(178, slot_y + 4)
                name_label.add_theme_font_size_override("font_size", 10)
                name_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
                name_label.visible = false
                add_child(name_label)
                panel_nodes.append(name_label)

                # 装备描述
                var desc_label = Label.new()
                desc_label.text = ""
                desc_label.position = Vector2(178, slot_y + 18)
                desc_label.add_theme_font_size_override("font_size", 7)
                desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
                desc_label.visible = false
                add_child(desc_label)
                panel_nodes.append(desc_label)

                # 消耗/属性标签
                var cost_label = Label.new()
                cost_label.text = ""
                cost_label.position = Vector2(178, slot_y + 30)
                cost_label.add_theme_font_size_override("font_size", 7)
                cost_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
                cost_label.visible = false
                add_child(cost_label)
                panel_nodes.append(cost_label)

                # 装备状态标签（已装备/已拥有/可购买）
                var equip_label = Label.new()
                equip_label.text = ""
                equip_label.position = Vector2(410, slot_y + 13)
                equip_label.add_theme_font_size_override("font_size", 8)
                equip_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
                equip_label.visible = false
                add_child(equip_label)
                panel_nodes.append(equip_label)

                item_slots.append({
                        "bg": bg,
                        "icon": icon,
                        "name_label": name_label,
                        "desc_label": desc_label,
                        "cost_label": cost_label,
                        "equip_label": equip_label,
                        "id": "",
                })

        # 操作提示
        var hint = Label.new()
        hint.text = "A/D:切换分类  W/S:选择  J:购买/装备  K:卸下  E:关闭"
        hint.position = Vector2(155, 268)
        hint.add_theme_font_size_override("font_size", 7)
        hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
        hint.visible = false
        add_child(hint)
        panel_nodes.append(hint)

        # 当前装备信息
        var current_equip = Label.new()
        current_equip.text = ""
        current_equip.position = Vector2(155, 285)
        current_equip.add_theme_font_size_override("font_size", 8)
        current_equip.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
        current_equip.visible = false
        add_child(current_equip)
        panel_nodes.append(current_equip)
        item_slots.append({"current_equip": current_equip})  # 特殊slot

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
                current_tab = (current_tab - 1) % 2
                if current_tab < 0: current_tab = 1
                selected_index = 0
                need_refresh = true
        elif Input.is_action_just_pressed("move_right"):
                current_tab = (current_tab + 1) % 2
                selected_index = 0
                need_refresh = true

        # W/S选择
        if Input.is_action_just_pressed("jump"):  # W键
                selected_index = (selected_index - 1) % 3
                if selected_index < 0: selected_index = 2
                need_refresh = true
        elif Input.is_action_just_pressed("heavy_attack"):  # K键暂时用于卸下
                # K = 卸下当前装备
                _unequip_selected()
                need_refresh = true

        # 上下选择也支持方向键
        if Input.is_key_pressed(KEY_UP):
                selected_index = (selected_index - 1) % 3
                if selected_index < 0: selected_index = 2
                need_refresh = true
        elif Input.is_key_pressed(KEY_DOWN):
                selected_index = (selected_index + 1) % 3
                need_refresh = true

        # J键购买/装备
        if Input.is_action_just_pressed("attack"):  # J键
                _on_action_selected()
                need_refresh = true

        if need_refresh:
                _refresh_display()
                need_refresh = false

func _refresh_display() -> void:
        """刷新装备列表显示"""
        var items: Dictionary = WEAPONS if current_tab == 0 else ARMORS
        var item_keys: Array = items.keys()
        var equipped_id: String = GameState.equipped_weapon if current_tab == 0 else GameState.equipped_armor

        # 更新Tab高亮
        if tab_labels.size() >= 2:
                tab_labels[0].add_theme_color_override("font_color",
                        Color(1, 0.9, 0.6) if current_tab == 0 else Color(0.6, 0.6, 0.6))
                tab_labels[0].text = "[ 武器 ]" if current_tab == 0 else "  武器  "
                tab_labels[1].add_theme_color_override("font_color",
                        Color(1, 0.9, 0.6) if current_tab == 1 else Color(0.6, 0.6, 0.6))
                tab_labels[1].text = "[ 护甲 ]" if current_tab == 1 else "  护甲  "

        # 更新矿石数量
        if item_slots.size() > 0 and item_slots[0].has("ore_label"):
                var ore_count: int = drop_system.get_ore_count() if drop_system else 0
                item_slots[0]["ore_label"].text = "ORE: " + str(ore_count)

        # 更新装备槽位
        for i in range(3):
                if i + 1 >= item_slots.size():
                        break
                var slot: Dictionary = item_slots[i + 1]
                if i < item_keys.size():
                        var key: String = item_keys[i]
                        var info: Dictionary = items[key]
                        var is_owned: bool = GameState.owned_equipment.has(key)
                        var is_equipped: bool = (key == equipped_id)
                        var is_selected: bool = (i == selected_index)

                        slot["id"] = key

                        # 选中高亮
                        if slot.has("bg"):
                                slot["bg"].color = Color(0.25, 0.2, 0.35, 0.8) if is_selected else Color(0.15, 0.12, 0.2, 0.6)

                        # 图标颜色
                        if slot.has("icon"):
                                slot["icon"].color = info.get("color", Color(0.5, 0.5, 0.5))

                        # 名称
                        if slot.has("name_label"):
                                slot["name_label"].text = info.get("name", key)
                                slot["name_label"].add_theme_color_override("font_color",
                                        Color(1, 0.95, 0.7) if is_equipped else Color(0.85, 0.8, 0.7))

                        # 描述
                        if slot.has("desc_label"):
                                slot["desc_label"].text = info.get("desc", "")

                        # 属性标签
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
                                        cost_text += "  |  消耗" + str(info.get("cost_ore", 0)) + "矿石"
                                slot["cost_label"].text = cost_text

                        # 装备状态
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
                else:
                        # 空槽位
                        slot["id"] = ""
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

        # 当前装备摘要
        if item_slots.size() > 4 and item_slots[4].has("current_equip"):
                var summary: String = ""
                if GameState.equipped_weapon != "" and WEAPONS.has(GameState.equipped_weapon):
                        summary += "武器:" + WEAPONS[GameState.equipped_weapon]["name"] + "  "
                if GameState.equipped_armor != "" and ARMORS.has(GameState.equipped_armor):
                        summary += "护甲:" + ARMORS[GameState.equipped_armor]["name"]
                if summary == "":
                        summary = "当前无装备"
                item_slots[4]["current_equip"].text = summary

func _on_action_selected() -> void:
        """J键 - 购买或装备选中项"""
        if selected_index + 1 >= item_slots.size():
                return
        var slot: Dictionary = item_slots[selected_index + 1]
        var item_id: String = slot.get("id", "")
        if item_id == "":
                return

        var is_owned: bool = GameState.owned_equipment.has(item_id)
        var items: Dictionary = WEAPONS if current_tab == 0 else ARMORS
        var equipped_id: String = GameState.equipped_weapon if current_tab == 0 else GameState.equipped_armor
        var is_equipped: bool = (item_id == equipped_id)

        if is_equipped:
                # 已装备 -> 卸下
                if current_tab == 0:
                        GameState.unequip_weapon()
                else:
                        GameState.unequip_armor()
        elif is_owned:
                # 已拥有 -> 装备
                if current_tab == 0:
                        GameState.equip_weapon(item_id)
                else:
                        GameState.equip_armor(item_id)
        else:
                # 未拥有 -> 购买
                var cost: int = items[item_id].get("cost_ore", 999)
                if drop_system and drop_system.spend_ore(cost):
                        # 购买成功，自动装备
                        GameState.owned_equipment.append(item_id)
                        if current_tab == 0:
                                GameState.equip_weapon(item_id)
                        else:
                                GameState.equip_armor(item_id)
                # 购买失败（矿石不够）不提示，靠UI显示矿石数量判断

func _unequip_selected() -> void:
        """K键 - 卸下当前装备"""
        if current_tab == 0:
                GameState.unequip_weapon()
        else:
                GameState.unequip_armor()

func get_attack_bonus() -> float:
        """获取装备攻击加成"""
        var stats: Dictionary = GameState.get_equipment_stats()
        return stats.get("attack_mult", 1.0)

func get_defense_bonus() -> float:
        """获取装备防御加成（返回减免比例）"""
        var stats: Dictionary = GameState.get_equipment_stats()
        return 1.0 - stats.get("defense_mult", 1.0)  # 转为减免比例

func get_max_hp_bonus() -> float:
        """获取装备生命加成"""
        var stats: Dictionary = GameState.get_equipment_stats()
        return stats.get("max_hp_bonus", 0.0)

func get_rage_bonus() -> float:
        """获取装备怒气加成"""
        var stats: Dictionary = GameState.get_equipment_stats()
        return stats.get("rage_bonus", 0.0)
