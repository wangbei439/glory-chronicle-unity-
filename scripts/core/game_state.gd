## 全局游戏状态 - Alpha v0.7
## Autoload单例，跨场景保存玩家状态
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
