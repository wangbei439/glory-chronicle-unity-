## 全局游戏状态 - Beta v0.13
## Autoload单例，跨场景保存玩家状态
## v0.13：职业选择系统、游侠属性支持
extends Node

# === 玩家持久状态 ===
var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_rage: float = 0.0
var player_max_rage: float = 100.0
var player_hit_count: int = 0

# === v0.13：职业选择 ===
var selected_class: String = "warrior"  # "warrior" / "ranger"

# === 游戏进度 ===
var current_level: String = ""  # "training" / "mine" / "boss" / "lava" / "lava_boss"
var levels_cleared: Dictionary = {}  # {"mine": true, "boss": true}
var total_kills: int = 0
var play_time: float = 0.0

# === v0.8：资源与技能 ===
var ore_fragments: int = 0
var health_potions: int = 0
var rage_crystals: int = 0
var skill_levels: Dictionary = {
        "attack_boost": 0,
        "defense_boost": 0,
        "rage_mastery": 0,
}

# === v0.10：装备系统 ===
var equipped_weapon: String = ""
var equipped_armor: String = ""
var owned_equipment: Array = []

# === v0.12：打造材料 ===
var crafting_materials: Dictionary = {
        "beetle_shell": 0,
        "lava_core": 0,
        "shadow_essence": 0,
        "vein_crystal": 0,
}

# === 关卡过渡 ===
var transition_from: String = ""
var transition_to: String = ""
var is_transitioning: bool = false

# === 场景路径 ===
const SCENES = {
        "title": "res://scenes/menus/title_screen.tscn",
        "training": "res://scenes/levels/training_ground.tscn",
        "mine": "res://scenes/levels/mine_level.tscn",
        "boss": "res://scenes/levels/boss_arena.tscn",
        "lava": "res://scenes/levels/lava_level.tscn",
        "lava_boss": "res://scenes/levels/lava_boss.tscn",
}

func _process(delta: float) -> void:
        play_time += delta

func save_player_state(hp: float, rage: float, hit_count: int) -> void:
        player_hp = hp
        player_rage = rage
        player_hit_count = hit_count

func save_resources(ore: int, skills: Dictionary) -> void:
        ore_fragments = ore
        if skills.has("attack_boost"):
                skill_levels["attack_boost"] = skills["attack_boost"]
        if skills.has("defense_boost"):
                skill_levels["defense_boost"] = skills["defense_boost"]
        if skills.has("rage_mastery"):
                skill_levels["rage_mastery"] = skills["rage_mastery"]

func save_pickup_counts(ore: int, potions: int, crystals: int) -> void:
        ore_fragments = ore
        health_potions = potions
        rage_crystals = crystals

func save_crafting_materials(data: Dictionary) -> void:
        crafting_materials = data.duplicate()

func equip_weapon(weapon_id: String) -> void:
        if equipped_weapon != "":
                if not owned_equipment.has(equipped_weapon):
                        owned_equipment.append(equipped_weapon)
        equipped_weapon = weapon_id
        if not owned_equipment.has(weapon_id):
                owned_equipment.append(weapon_id)

func equip_armor(armor_id: String) -> void:
        if equipped_armor != "":
                if not owned_equipment.has(equipped_armor):
                        owned_equipment.append(equipped_armor)
        equipped_armor = armor_id
        if not owned_equipment.has(armor_id):
                owned_equipment.append(armor_id)

func unequip_weapon() -> void:
        if equipped_weapon != "":
                if not owned_equipment.has(equipped_weapon):
                        owned_equipment.append(equipped_weapon)
                equipped_weapon = ""

func unequip_armor() -> void:
        if equipped_armor != "":
                if not owned_equipment.has(equipped_armor):
                        owned_equipment.append(equipped_armor)
                equipped_armor = ""

func get_equipment_stats() -> Dictionary:
        """获取当前装备的属性加成（含打造装备）"""
        var stats: Dictionary = {"attack_mult": 1.0, "defense_mult": 1.0, "max_hp_bonus": 0.0, "rage_bonus": 0.0}

        # 基础装备武器加成
        match equipped_weapon:
                "iron_sword":
                        stats["attack_mult"] = 1.2
                "crystal_blade":
                        stats["attack_mult"] = 1.4
                        stats["rage_bonus"] = 0.2
                "berserker_axe":
                        stats["attack_mult"] = 1.6
                        stats["defense_mult"] = 0.85

        # 基础装备护甲加成
        match equipped_armor:
                "leather_vest":
                        stats["defense_mult"] *= 0.85
                "iron_plate":
                        stats["defense_mult"] *= 0.7
                        stats["max_hp_bonus"] = 20.0
                "crystal_mail":
                        stats["defense_mult"] *= 0.75
                        stats["rage_bonus"] += 0.15

        # 打造装备武器加成
        var crafted_weapons: Dictionary = _get_crafted_weapon_stats(equipped_weapon)
        if crafted_weapons.size() > 0:
                stats["attack_mult"] = crafted_weapons.get("attack_mult", 1.0)
                stats["defense_mult"] *= crafted_weapons.get("defense_mult", 1.0)
                stats["rage_bonus"] += crafted_weapons.get("rage_bonus", 0.0)

        # 打造装备护甲加成
        var crafted_armors: Dictionary = _get_crafted_armor_stats(equipped_armor)
        if crafted_armors.size() > 0:
                stats["defense_mult"] *= crafted_armors.get("defense_mult", 1.0)
                stats["max_hp_bonus"] += crafted_armors.get("max_hp_bonus", 0.0)
                stats["rage_bonus"] += crafted_armors.get("rage_bonus", 0.0)

        return stats

func _get_crafted_weapon_stats(weapon_id: String) -> Dictionary:
        """查询打造武器属性"""
        match weapon_id:
                "lava_greatsword":
                        return {"attack_mult": 1.8, "defense_mult": 0.9, "rage_bonus": 0.1}
                "shadow_twin_blades":
                        return {"attack_mult": 1.5, "defense_mult": 1.0, "rage_bonus": 0.3}
        return {}

func _get_crafted_armor_stats(armor_id: String) -> Dictionary:
        """查询打造护甲属性"""
        match armor_id:
                "beetle_bulwark":
                        return {"defense_mult": 0.6, "max_hp_bonus": 30.0, "rage_bonus": 0.0}
                "vein_holy_garb":
                        return {"defense_mult": 0.65, "max_hp_bonus": 15.0, "rage_bonus": 0.2}
        return {}

func get_player_state() -> Dictionary:
        return {
                "hp": player_hp,
                "max_hp": player_max_hp,
                "rage": player_rage,
                "max_rage": player_max_rage,
                "hit_count": player_hit_count,
        }

func reset_player_state() -> void:
        player_hp = player_max_hp
        player_rage = 0.0
        player_hit_count = 0

func is_warrior() -> bool:
        return selected_class == "warrior"

func is_ranger() -> bool:
        return selected_class == "ranger"

func get_class_name() -> String:
        if selected_class == "ranger":
                return "游侠"
        return "战士"

func reset_all_progress() -> void:
        reset_player_state()
        ore_fragments = 0
        health_potions = 0
        rage_crystals = 0
        skill_levels = {"attack_boost": 0, "defense_boost": 0, "rage_mastery": 0}
        levels_cleared = {}
        total_kills = 0
        equipped_weapon = ""
        equipped_armor = ""
        owned_equipment = []
        crafting_materials = {"beetle_shell": 0, "lava_core": 0, "shadow_essence": 0, "vein_crystal": 0}
        selected_class = "warrior"

func mark_level_cleared(level_name: String) -> void:
        levels_cleared[level_name] = true

func go_to_level(level_name: String) -> void:
        if SCENES.has(level_name):
                transition_to = level_name
                is_transitioning = true
                current_level = level_name
                get_tree().change_scene_to_file(SCENES[level_name])

func go_to_title() -> void:
        current_level = ""
        get_tree().change_scene_to_file(SCENES["title"])
