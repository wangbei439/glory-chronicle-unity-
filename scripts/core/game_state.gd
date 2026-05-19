## 全局游戏状态 - Beta v0.10
## Autoload单例，跨场景保存玩家状态
## v0.10新增：装备系统、拾取计数持久化
extends Node

# === 玩家持久状态 ===
var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_rage: float = 0.0
var player_max_rage: float = 100.0
var player_hit_count: int = 0

# === 游戏进度 ===
var current_level: String = ""  # "training" / "mine" / "boss"
var levels_cleared: Dictionary = {}  # {"mine": true, "boss": true}
var total_kills: int = 0
var play_time: float = 0.0

#=== v0.8 新增：资源与技能 ===
var ore_fragments: int = 0  # 矿石碎片（技能树货币）
var health_potions: int = 0  # 拾取的生命药水计数
var rage_crystals: int = 0  # 拾取的怒气水晶计数
var skill_levels: Dictionary = {  # 技能等级
        "attack_boost": 0,
        "defense_boost": 0,
        "rage_mastery": 0,
}

# === v0.10 新增：装备系统 ===
var equipped_weapon: String = ""  # 当前装备武器ID
var equipped_armor: String = ""   # 当前装备护甲ID
var owned_equipment: Array = []   # 已拥有的装备ID列表

# === 关卡过渡 ===
var transition_from: String = ""  # 来源关卡
var transition_to: String = ""    # 目标关卡
var is_transitioning: bool = false

# === 场景路径 ===
const SCENES = {
        "title": "res://scenes/menus/title_screen.tscn",
        "training": "res://scenes/levels/training_ground.tscn",
        "mine": "res://scenes/levels/mine_level.tscn",
        "boss": "res://scenes/levels/boss_arena.tscn",
}

func _process(delta: float) -> void:
        play_time += delta

func save_player_state(hp: float, rage: float, hit_count: int) -> void:
        player_hp = hp
        player_rage = rage
        player_hit_count = hit_count

func save_resources(ore: int, skills: Dictionary) -> void:
        """保存矿石碎片和技能等级"""
        ore_fragments = ore
        if skills.has("attack_boost"):
                skill_levels["attack_boost"] = skills["attack_boost"]
        if skills.has("defense_boost"):
                skill_levels["defense_boost"] = skills["defense_boost"]
        if skills.has("rage_mastery"):
                skill_levels["rage_mastery"] = skills["rage_mastery"]

func save_pickup_counts(ore: int, potions: int, crystals: int) -> void:
        """保存拾取计数"""
        ore_fragments = ore
        health_potions = potions
        rage_crystals = crystals

func equip_weapon(weapon_id: String) -> void:
        """装备武器"""
        if equipped_weapon != "":
                if not owned_equipment.has(equipped_weapon):
                        owned_equipment.append(equipped_weapon)
        equipped_weapon = weapon_id
        if not owned_equipment.has(weapon_id):
                owned_equipment.append(weapon_id)

func equip_armor(armor_id: String) -> void:
        """装备护甲"""
        if equipped_armor != "":
                if not owned_equipment.has(equipped_armor):
                        owned_equipment.append(equipped_armor)
        equipped_armor = armor_id
        if not owned_equipment.has(armor_id):
                owned_equipment.append(armor_id)

func unequip_weapon() -> void:
        """卸下武器"""
        if equipped_weapon != "":
                if not owned_equipment.has(equipped_weapon):
                        owned_equipment.append(equipped_weapon)
                equipped_weapon = ""

func unequip_armor() -> void:
        """卸下护甲"""
        if equipped_armor != "":
                if not owned_equipment.has(equipped_armor):
                        owned_equipment.append(equipped_armor)
                equipped_armor = ""

func get_equipment_stats() -> Dictionary:
        """获取当前装备的属性加成"""
        var stats: Dictionary = {"attack_mult": 1.0, "defense_mult": 1.0, "max_hp_bonus": 0.0, "rage_bonus": 0.0}
        # 武器加成
        match equipped_weapon:
                "iron_sword":
                        stats["attack_mult"] = 1.2  # +20%攻击
                "crystal_blade":
                        stats["attack_mult"] = 1.4  # +40%攻击
                        stats["rage_bonus"] = 0.2  # +20%怒气获取
                "berserker_axe":
                        stats["attack_mult"] = 1.6  # +60%攻击
                        stats["defense_mult"] = 0.85  # -15%防御(玻璃大炮)
        # 护甲加成
        match equipped_armor:
                "leather_vest":
                        stats["defense_mult"] *= 0.85  # -15%受伤
                "iron_plate":
                        stats["defense_mult"] *= 0.7  # -30%受伤
                        stats["max_hp_bonus"] = 20.0  # +20HP
                "crystal_mail":
                        stats["defense_mult"] *= 0.75  # -25%受伤
                        stats["rage_bonus"] += 0.15  # +15%怒气获取
        return stats

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

func reset_all_progress() -> void:
        """完全重置所有进度"""
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
