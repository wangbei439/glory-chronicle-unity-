## 存档系统 - Alpha v0.9
## JSON格式存档，自动/手动保存游戏进度
## 存档路径：user://save_data.json
extends Node

# === 存档数据结构 ===
var save_data: Dictionary = {
	"version": "0.9",
	"timestamp": "",
	"player_hp": 100.0,
	"player_max_hp": 100.0,
	"player_rage": 0.0,
	"ore_fragments": 0,
	"skill_levels": {
		"attack_boost": 0,
		"defense_boost": 0,
		"rage_mastery": 0,
	},
	"levels_cleared": {},
	"total_kills": 0,
	"play_time": 0.0,
	"current_level": "",
	"potions_owned": 0,
	"crystals_owned": 0,
}

# === 存档文件路径 ===
var save_path: String = "user://save_data.json"

# === 是否有存档 ===
var has_save: bool = false

func _ready() -> void:
	# 检查是否有存档
	has_save = _file_exists(save_path)

func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

func save_game() -> bool:
	"""保存当前游戏状态到文件"""
	# 从GameState读取最新数据
	save_data["player_hp"] = GameState.player_hp
	save_data["player_max_hp"] = GameState.player_max_hp
	save_data["player_rage"] = GameState.player_rage
	save_data["ore_fragments"] = GameState.ore_fragments
	save_data["skill_levels"] = GameState.skill_levels.duplicate()
	save_data["levels_cleared"] = GameState.levels_cleared.duplicate()
	save_data["total_kills"] = GameState.total_kills
	save_data["play_time"] = GameState.play_time
	save_data["current_level"] = GameState.current_level
	save_data["timestamp"] = Time.get_datetime_string_from_system()

	# 写入JSON
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
	"""从文件加载游戏状态"""
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
	# 恢复存档数据到本地
	save_data = data.duplicate()

	print("SaveGame: Loaded successfully! Play time: " + str(int(GameState.play_time)) + "s")
	return true

func delete_save() -> void:
	"""删除存档"""
	if has_save:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		has_save = false
		print("SaveGame: Save file deleted")

func get_save_info() -> Dictionary:
	"""获取存档信息用于UI显示"""
	if not has_save:
		return {"exists": false}

	# 尝试读取存档但不应用
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
			level_name = "Boss战"

	return {
		"exists": true,
		"timestamp": ts,
		"play_time": str(play_mins) + "分钟",
		"total_kills": kills,
		"ore_fragments": ore,
		"current_level": level_name,
		"player_hp": data.get("player_hp", 100),
	}

func new_game() -> void:
	"""开始新游戏，重置所有进度"""
	GameState.reset_all_progress()
	has_save = false
