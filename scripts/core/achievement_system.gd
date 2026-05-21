## 成就系统 - Beta v0.19
## 追踪玩家成就：击杀、Boss、连击、探索等
## 弹窗通知+持久存储
extends Node2D

# === 成就定义 ===
var achievement_defs: Dictionary = {
        "first_kill": {"name": "初次击杀", "desc": "击败第一个敌人", "icon": "sword"},
        "kill_10": {"name": "战士之路", "desc": "累计击杀10个敌人", "icon": "sword"},
        "kill_50": {"name": "屠戮者", "desc": "累计击杀50个敌人", "icon": "sword"},
        "kill_100": {"name": "传说猎手", "desc": "累计击杀100个敌人", "icon": "sword"},
        "combo_10": {"name": "连击新手", "desc": "达成10连击", "icon": "combo"},
        "combo_20": {"name": "连击大师", "desc": "达成20连击", "icon": "combo"},
        "combo_50": {"name": "连击传说", "desc": "达成50连击", "icon": "combo"},
        "boss_beetle": {"name": "甲虫克星", "desc": "击败矿脉甲虫", "icon": "boss"},
        "boss_turtle": {"name": "熔岩征服者", "desc": "击败熔岩龟", "icon": "boss"},
        "boss_spirit": {"name": "知识终结者", "desc": "击败堕落书灵", "icon": "boss"},
        "all_bosses": {"name": "传说猎人", "desc": "击败所有Boss", "icon": "crown"},
        "perfect_parry": {"name": "完美防御", "desc": "完成一次完美格挡", "icon": "shield"},
        "perfect_parry_10": {"name": "铜墙铁壁", "desc": "完成10次完美格挡", "icon": "shield"},
        "no_damage_boss": {"name": "无伤大师", "desc": "无伤击败任意Boss", "icon": "crown"},
        "explore_all": {"name": "探险家", "desc": "探索所有关卡", "icon": "map"},
        "ore_100": {"name": "矿石收藏家", "desc": "累计收集100矿石", "icon": "ore"},
        "ore_500": {"name": "矿业大亨", "desc": "累计收集500矿石", "icon": "ore"},
        "craft_first": {"name": "锻造师入门", "desc": "首次打造装备", "icon": "craft"},
        "class_ranger": {"name": "暗影行者", "desc": "以游侠完成一个关卡", "icon": "class"},
        "class_mage": {"name": "元素使者", "desc": "以法师完成一个关卡", "icon": "class"},
}

# === 追踪数据 ===
var unlocked: Dictionary = {}  # achievement_id -> true
var stats: Dictionary = {
        "total_kills": 0,
        "max_combo": 0,
        "total_perfect_parries": 0,
        "total_ore_collected": 0,
        "bosses_defeated": [],
        "levels_cleared": [],
        "classes_cleared": [],
}

# 通知队列
var notification_queue: Array = []
var current_notification: Dictionary = {}
var notification_timer: float = 0.0
var notification_alpha: float = 0.0

# 视觉元素
var notif_panel: ColorRect
var notif_border: ColorRect
var notif_title: Label
var notif_desc: Label
var notif_icon: ColorRect
var notif_new_label: Label

var frame_count: int = 0

func _ready() -> void:
        _build_notification_ui()

func _build_notification_ui() -> void:
        # 成就通知面板（顶部居中弹出）
        notif_border = ColorRect.new()
        notif_border.size = Vector2(220, 44)
        notif_border.position = Vector2(210, 8)
        notif_border.color = Color(0.7, 0.55, 0.2, 0.0)
        notif_border.z_index = 600
        add_child(notif_border)

        notif_panel = ColorRect.new()
        notif_panel.size = Vector2(216, 40)
        notif_panel.position = Vector2(212, 10)
        notif_panel.color = Color(0.06, 0.05, 0.08, 0.0)
        notif_panel.z_index = 601
        add_child(notif_panel)

        # 图标占位
        notif_icon = ColorRect.new()
        notif_icon.size = Vector2(20, 20)
        notif_icon.position = Vector2(220, 20)
        notif_icon.color = Color(0.92, 0.78, 0.32, 0.0)
        notif_icon.z_index = 602
        add_child(notif_icon)

        # NEW!标签
        notif_new_label = Label.new()
        notif_new_label.text = "NEW!"
        notif_new_label.position = Vector2(244, 14)
        notif_new_label.add_theme_font_size_override("font_size", 8)
        notif_new_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 0.0))
        notif_new_label.z_index = 602
        add_child(notif_new_label)

        # 标题
        notif_title = Label.new()
        notif_title.text = ""
        notif_title.position = Vector2(244, 22)
        notif_title.add_theme_font_size_override("font_size", 10)
        notif_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55, 0.0))
        notif_title.z_index = 602
        add_child(notif_title)

        # 描述
        notif_desc = Label.new()
        notif_desc.text = ""
        notif_desc.position = Vector2(244, 36)
        notif_desc.add_theme_font_size_override("font_size", 7)
        notif_desc.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5, 0.0))
        notif_desc.z_index = 602
        add_child(notif_desc)

func unlock(achievement_id: String) -> void:
        """解锁成就"""
        if unlocked.has(achievement_id):
                return
        if not achievement_defs.has(achievement_id):
                return

        unlocked[achievement_id] = true
        var def: Dictionary = achievement_defs[achievement_id]

        # 加入通知队列
        notification_queue.append({
                "id": achievement_id,
                "name": def["name"],
                "desc": def["desc"],
                "icon": def["icon"],
        })

        print("Achievement unlocked: " + def["name"] + " - " + def["desc"])

func check_kill_achievements(kills: int) -> void:
        if kills >= 1:
                unlock("first_kill")
        if kills >= 10:
                unlock("kill_10")
        if kills >= 50:
                unlock("kill_50")
        if kills >= 100:
                unlock("kill_100")
        stats["total_kills"] = kills

func check_combo_achievements(combo: int) -> void:
        if combo >= 10:
                unlock("combo_10")
        if combo >= 20:
                unlock("combo_20")
        if combo >= 50:
                unlock("combo_50")
        stats["max_combo"] = max(stats["max_combo"], combo)

func check_boss_achievement(boss_id: String) -> void:
        unlock("boss_" + boss_id)
        if not stats["bosses_defeated"].has(boss_id):
                stats["bosses_defeated"].append(boss_id)
        # 检查是否击败所有Boss
        if stats["bosses_defeated"].size() >= 3:
                unlock("all_bosses")

func check_parry_achievements(count: int) -> void:
        if count >= 1:
                unlock("perfect_parry")
        if count >= 10:
                unlock("perfect_parry_10")
        stats["total_perfect_parries"] = max(stats["total_perfect_parries"], count)

func check_no_damage_boss() -> void:
        unlock("no_damage_boss")

func check_explore_achievement(level_name: String) -> void:
        if not stats["levels_cleared"].has(level_name):
                stats["levels_cleared"].append(level_name)
        if stats["levels_cleared"].size() >= 7:
                unlock("explore_all")

func check_ore_achievements(ore: int) -> void:
        if ore >= 100:
                unlock("ore_100")
        if ore >= 500:
                unlock("ore_500")
        stats["total_ore_collected"] = max(stats["total_ore_collected"], ore)

func check_class_achievement(cls_name: String) -> void:
        if not stats["classes_cleared"].has(cls_name):
                stats["classes_cleared"].append(cls_name)
        if cls_name == "ranger":
                unlock("class_ranger")
        if cls_name == "mage":
                unlock("class_mage")

func check_craft_achievement() -> void:
        unlock("craft_first")

func process_notifications(delta: float) -> void:
        frame_count += 1

        # 当前通知倒计时
        if notification_timer > 0:
                notification_timer -= delta
                # 淡入
                if notification_alpha < 1.0:
                        notification_alpha = min(1.0, notification_alpha + delta * 4.0)
                # 最后1秒淡出
                if notification_timer < 1.0:
                        notification_alpha = max(0.0, notification_timer)
                _update_notification_alpha(notification_alpha)
        elif notification_queue.size() > 0:
                # 显示下一个通知
                current_notification = notification_queue.pop_front()
                _show_notification(current_notification)
                notification_timer = 3.0
                notification_alpha = 0.0
        else:
                # 无通知时隐藏
                notification_alpha = max(0.0, notification_alpha - delta * 3.0)
                if notification_alpha <= 0:
                        _update_notification_alpha(0.0)

func _show_notification(data: Dictionary) -> void:
        if notif_title:
                notif_title.text = data["name"]
        if notif_desc:
                notif_desc.text = data["desc"]
        # 图标颜色根据类型
        var icon_color: Color = Color(0.92, 0.78, 0.32, 1.0)
        match data["icon"]:
                "sword":
                        icon_color = Color(0.9, 0.3, 0.2, 1.0)
                "combo":
                        icon_color = Color(1, 0.85, 0.2, 1.0)
                "boss":
                        icon_color = Color(0.8, 0.2, 0.6, 1.0)
                "crown":
                        icon_color = Color(1, 0.85, 0.15, 1.0)
                "shield":
                        icon_color = Color(0.3, 0.7, 1.0, 1.0)
                "map":
                        icon_color = Color(0.3, 0.9, 0.5, 1.0)
                "ore":
                        icon_color = Color(0.7, 0.6, 0.9, 1.0)
                "craft":
                        icon_color = Color(0.9, 0.6, 0.2, 1.0)
                "class":
                        icon_color = Color(0.5, 0.8, 0.9, 1.0)
        if notif_icon:
                notif_icon.color = icon_color

func _update_notification_alpha(alpha: float) -> void:
        if notif_border:
                notif_border.color = Color(0.7, 0.55, 0.2, alpha * 0.8)
        if notif_panel:
                notif_panel.color = Color(0.06, 0.05, 0.08, alpha * 0.95)
        if notif_icon:
                var base: Color = notif_icon.color
                notif_icon.color = Color(base.r, base.g, base.b, alpha)
        if notif_new_label:
                notif_new_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, alpha))
        if notif_title:
                var c: Color = notif_title.get_theme_color("font_color")
                notif_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55, alpha))
        if notif_desc:
                notif_desc.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5, alpha))

func get_save_data() -> Dictionary:
        return {
                "unlocked": unlocked.duplicate(),
                "stats": stats.duplicate(),
        }

func load_save_data(data: Dictionary) -> void:
        if data.has("unlocked"):
                unlocked = data["unlocked"].duplicate()
        if data.has("stats"):
                var s: Dictionary = data["stats"]
                for key in s:
                        stats[key] = s[key]

func get_unlocked_count() -> int:
        return unlocked.size()

func get_total_count() -> int:
        return achievement_defs.size()

func get_achievement_list() -> Array:
        var result: Array = []
        for id in achievement_defs:
                var def: Dictionary = achievement_defs[id]
                result.append({
                        "id": id,
                        "name": def["name"],
                        "desc": def["desc"],
                        "icon": def["icon"],
                        "unlocked": unlocked.has(id),
                })
        return result
