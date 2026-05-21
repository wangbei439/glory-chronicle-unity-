## 存档系统 - Beta v0.17
## JSON格式存档，自动/手动保存游戏进度
## v0.17: 法师职业存档支持
extends Node

# === 存档数据结构 ===
var save_data: Dictionary = {
        "version": "0.17",
        "timestamp": "",
        "player_hp": 100.0,
        "player_max_hp": 100.0,
        "player_rage": 0.0,
        "ore_fragments": 0,
        "health_potions": 0,
        "rage_crystals": 0,
        "skill_levels": {
                "attack_boost": 0,
                "defense_boost": 0,
                "rage_mastery": 0,
        },
        "levels_cleared": {},
        "total_kills": 0,
        "play_time": 0.0,
        "current_level": "",
        "equipped_weapon": "",
        "equipped_armor": "",
        "owned_equipment": [],
        "crafting_materials": {
                "beetle_shell": 0,
                "lava_core": 0,
                "shadow_essence": 0,
                "vein_crystal": 0,
        },
        "selected_class": "warrior",
}

var save_path: String = "user://save_data.json"
var has_save: bool = false

func _ready() -> void:
        has_save = _file_exists(save_path)

func _file_exists(path: String) -> bool:
        return FileAccess.file_exists(path)

func save_game() -> bool:
        save_data["player_hp"] = GameState.player_hp
        save_data["player_max_hp"] = GameState.player_max_hp
        save_data["player_rage"] = GameState.player_rage
        save_data["ore_fragments"] = GameState.ore_fragments
        save_data["health_potions"] = GameState.health_potions
        save_data["rage_crystals"] = GameState.rage_crystals
        save_data["skill_levels"] = GameState.skill_levels.duplicate()
        save_data["levels_cleared"] = GameState.levels_cleared.duplicate()
        save_data["total_kills"] = GameState.total_kills
        save_data["play_time"] = GameState.play_time
        save_data["current_level"] = GameState.current_level
        save_data["equipped_weapon"] = GameState.equipped_weapon
        save_data["equipped_armor"] = GameState.equipped_armor
        save_data["owned_equipment"] = GameState.owned_equipment.duplicate()
        save_data["crafting_materials"] = GameState.crafting_materials.duplicate()
        save_data["selected_class"] = GameState.selected_class
        save_data["timestamp"] = Time.get_datetime_string_from_system()

        var json_string: String = JSON.stringify(save_data, "\t")
        var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
        if file == null:
                print("SaveGame: Failed to open save file!")
                return false

        file.store_string(json_string)
        file.close()
        has_save = true
        print("SaveGame: Saved successfully at " + save_data["timestamp"])
        return true

func load_game() -> bool:
        if not has_save:
                print("SaveGame: No save file found!")
                return false

        var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
        if file == null:
                print("SaveGame: Failed to open save file for reading!")
                return false

        var json_string: String = file.get_as_text()
        file.close()

        var json: JSON = JSON.new()
        var error: Error = json.parse(json_string)
        if error != OK:
                print("SaveGame: JSON parse error!")
                return false

        var data: Dictionary = json.data
        if not data is Dictionary:
                print("SaveGame: Invalid save data format!")
                return false

        # 恢复到GameState
        if data.has("player_hp"):
                GameState.player_hp = data["player_hp"]
        if data.has("player_max_hp"):
                GameState.player_max_hp = data["player_max_hp"]
        if data.has("player_rage"):
                GameState.player_rage = data["player_rage"]
        if data.has("ore_fragments"):
                GameState.ore_fragments = int(data["ore_fragments"])
        if data.has("health_potions"):
                GameState.health_potions = int(data["health_potions"])
        if data.has("rage_crystals"):
                GameState.rage_crystals = int(data["rage_crystals"])
        if data.has("skill_levels"):
                GameState.skill_levels = data["skill_levels"]
        if data.has("levels_cleared"):
                GameState.levels_cleared = data["levels_cleared"]
        if data.has("total_kills"):
                GameState.total_kills = int(data["total_kills"])
        if data.has("play_time"):
                GameState.play_time = data["play_time"]
        if data.has("current_level"):
                GameState.current_level = data["current_level"]
        if data.has("equipped_weapon"):
                GameState.equipped_weapon = data["equipped_weapon"]
        if data.has("equipped_armor"):
                GameState.equipped_armor = data["equipped_armor"]
        if data.has("owned_equipment"):
                GameState.owned_equipment = data["owned_equipment"]
        # v0.12: 打造材料
        if data.has("crafting_materials"):
                GameState.crafting_materials = data["crafting_materials"]
        else:
                # 旧存档兼容
                GameState.crafting_materials = {"beetle_shell": 0, "lava_core": 0, "shadow_essence": 0, "vein_crystal": 0}

        # v0.13: 职业选择
        if data.has("selected_class"):
                GameState.selected_class = data["selected_class"]
        else:
                GameState.selected_class = "warrior"

        save_data = data.duplicate()

        print("SaveGame: Loaded successfully! Play time: " + str(int(GameState.play_time)) + "s")
        return true

func delete_save() -> void:
        if has_save:
                DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
                has_save = false
                print("SaveGame: Save file deleted")

func get_save_info() -> Dictionary:
        if not has_save:
                return {"exists": false}

        var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
        if file == null:
                return {"exists": false}

        var json_string: String = file.get_as_text()
        file.close()

        var json: JSON = JSON.new()
        if json.parse(json_string) != OK:
                return {"exists": false}

        var data: Dictionary = json.data
        var play_mins: int = int(data.get("play_time", 0)) / 60
        var kills: int = int(data.get("total_kills", 0))
        var ore: int = int(data.get("ore_fragments", 0))
        var ts: String = data.get("timestamp", "未知")
        var level: String = data.get("current_level", "")

        var level_name: String = "主菜单"
        match level:
                "training":
                        level_name = "训练场"
                "mine":
                        level_name = "幽影矿井"
                "boss":
                        level_name = "Boss战(矿脉甲虫)"
                "lava":
                        level_name = "失落地脉"
                "lava_boss":
                        level_name = "Boss战(熔岩龟)"
                "library":
                        level_name = "禁术图书馆"
                "library_boss":
                        level_name = "Boss战(堕落书灵)"

        var cm: Dictionary = data.get("crafting_materials", {})
        var mat_summary: String = ""
        if int(cm.get("beetle_shell", 0)) > 0:
                mat_summary += "甲壳x" + str(cm["beetle_shell"]) + " "
        if int(cm.get("lava_core", 0)) > 0:
                mat_summary += "熔岩x" + str(cm["lava_core"]) + " "
        if int(cm.get("shadow_essence", 0)) > 0:
                mat_summary += "暗影x" + str(cm["shadow_essence"]) + " "
        if int(cm.get("vein_crystal", 0)) > 0:
                mat_summary += "地脉x" + str(cm["vein_crystal"])

        return {
                "exists": true,
                "timestamp": ts,
                "play_time": str(play_mins) + "分钟",
                "total_kills": kills,
                "ore_fragments": ore,
                "current_level": level_name,
                "player_hp": data.get("player_hp", 100),
                "materials": mat_summary,
        }

func new_game() -> void:
        GameState.reset_all_progress()
        has_save = false
