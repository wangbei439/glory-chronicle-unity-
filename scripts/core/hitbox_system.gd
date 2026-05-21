## 统一碰撞判定系统 - v0.20
## 解决问题：碰撞逻辑分散在5+关卡脚本中，缺少Y轴判定、朝向判定、攻击类型差异化
## 所有碰撞判定集中在此模块，关卡脚本只需调用
extends Node2D

class_name HitboxSystem

# === 攻击范围定义 ===
# 每个攻击类型有不同的判定范围 (以攻击者facing方向为正方向)
# rect格式: [x偏移(朝向侧), y偏移, 宽度, 高度]
# x偏移: 正值=朝向方向前方

const ATTACK_HITBOXES := {
	# === 玩家攻击 ===
	"warrior_light": {"rect": [12, -20, 40, 28], "y_tolerance": 30},
	"warrior_light2": {"rect": [10, -22, 45, 30], "y_tolerance": 30},
	"warrior_light3": {"rect": [8, -25, 50, 35], "y_tolerance": 32},  # 回旋斩范围更大
	"warrior_heavy": {"rect": [10, -28, 55, 40], "y_tolerance": 35},  # 重击范围最大
	"warrior_finisher": {"rect": [5, -30, 60, 42], "y_tolerance": 38},  # 终结技全方位
	"warrior_dash_slash": {"rect": [15, -18, 55, 22], "y_tolerance": 28},  # 冲刺斩纵向窄
	"warrior_upperslash": {"rect": [8, -40, 30, 45], "y_tolerance": 25},  # 上挑纵向长
	"warrior_slam": {"rect": [5, -15, 50, 20], "y_tolerance": 35},  # 下砸横向宽
	"warrior_earth_shatter": {"rect": [-40, -10, 80, 20], "y_tolerance": 40},  # AOE全方位
	"ranger_attack": {"rect": [10, -18, 35, 24], "y_tolerance": 25},
	"ranger_blade_storm": {"rect": [-30, -25, 60, 35], "y_tolerance": 35},  # 旋风全方位
	"mage_cast": {"rect": [15, -20, 50, 30], "y_tolerance": 30},
	"mage_blizzard": {"rect": [-50, -40, 100, 60], "y_tolerance": 50},  # 暴风雪大范围
	
	# === Boss攻击 ===
	"beetle_bite": {"rect": [15, -15, 35, 25], "y_tolerance": 30},
	"beetle_heavy": {"rect": [10, -20, 45, 35], "y_tolerance": 35},
	"beetle_charge": {"rect": [20, -15, 60, 25], "y_tolerance": 30},  # 冲刺范围长
	"beetle_slam": {"rect": [-25, -20, 50, 30], "y_tolerance": 40},  # 跳砸AOE
	"lava_bite": {"rect": [20, -18, 40, 28], "y_tolerance": 32},
	"lava_lava_spit": {"rect": [0, -8, 16, 16], "y_tolerance": 40},  # 弹幕
	"lava_shell_spin": {"rect": [-25, -20, 50, 35], "y_tolerance": 35},  # 旋转AOE
	"book_spell_beam": {"rect": [10, -5, 80, 10], "y_tolerance": 20},  # 横向长
	"book_page_storm": {"rect": [-35, -30, 70, 45], "y_tolerance": 40},  # AOE
	"book_tornado": {"rect": [0, -15, 20, 30], "y_tolerance": 35},  # 龙卷风小范围
}

# === 受击范围定义 ===
# 每个实体的受击判定框 (相对于pos)
const HURTBOXES := {
	"warrior": {"rect": [-10, -30, 20, 30]},  # 玩家窄
	"ranger": {"rect": [-8, -28, 16, 28]},   # 游侠更窄
	"mage": {"rect": [-9, -32, 18, 32]},     # 法师长袍略宽
	"boss_beetle": {"rect": [-25, -25, 50, 30]},  # Boss大
	"boss_lava_turtle": {"rect": [-35, -30, 70, 35]},  # 熔岩龟最大
	"boss_book_spirit": {"rect": [-18, -30, 36, 35]},  # 书灵中等
	"mine_wraith": {"rect": [-10, -22, 20, 22]},
	"cave_bat": {"rect": [-8, -8, 16, 16]},
}

## 检测攻击是否命中目标
## attacker_pos: 攻击者位置
## attacker_facing: 攻击者朝向 (1.0 或 -1.0)
## attack_type: 攻击类型 (对应ATTACK_HITBOXES的key)
## target_pos: 目标位置
## target_hurtbox_type: 目标受击框类型 (对应HURTBOXES的key)
## 返回: true=命中
static func check_hit(attacker_pos: Vector2, attacker_facing: float, attack_type: String,
					  target_pos: Vector2, target_hurtbox_type: String = "") -> bool:
	if not ATTACK_HITBOXES.has(attack_type):
		# 回退到默认检测
		var dist = abs(attacker_pos.x - target_pos.x)
		return dist < 60
	
	var atk_data: Dictionary = ATTACK_HITBOXES[attack_type]
	var atk_rect: Array = atk_data["rect"]
	var y_tol: float = atk_data.get("y_tolerance", 30.0)
	
	# 计算攻击判定框的世界位置
	var atk_world_x: float = attacker_pos.x + atk_rect[0] * attacker_facing
	var atk_world_y: float = attacker_pos.y + atk_rect[1]
	var atk_w: float = atk_rect[2]
	var atk_h: float = atk_rect[3]
	
	# 如果facing为负，需要调整x
	if attacker_facing < 0:
		atk_world_x = attacker_pos.x + atk_rect[0] * attacker_facing - atk_w
	
	# 获取目标受击框
	var target_rect: Array = [-8, -16, 16, 16]  # 默认
	if HURTBOXES.has(target_hurtbox_type):
		target_rect = HURTBOXES[target_hurtbox_type]
	
	var tar_world_x: float = target_pos.x + target_rect[0]
	var tar_world_y: float = target_pos.y + target_rect[1]
	var tar_w: float = target_rect[2]
	var tar_h: float = target_rect[3]
	
	# AABB碰撞检测
	var overlap_x: bool = (atk_world_x < tar_world_x + tar_w) and (atk_world_x + atk_w > tar_world_x)
	var overlap_y: bool = (atk_world_y < tar_world_y + tar_h) and (atk_world_y + atk_h > tar_world_y)
	
	# Y轴容差检测 (跳跃攻击等场景)
	var y_dist: float = abs(attacker_pos.y - target_pos.y)
	var y_ok: bool = y_dist < y_tol
	
	return overlap_x and (overlap_y or y_ok)

## 根据warrior攻击信息自动选择hitbox类型
static func get_warrior_attack_type(combo_key: String, is_heavy: bool, is_finisher: bool) -> String:
	if is_finisher:
		if combo_key.find("L,L,L") >= 0:
			return "warrior_light3"
		elif combo_key.find("DH") >= 0:
			return "warrior_slam"
		else:
			return "warrior_finisher"
	if is_heavy:
		if combo_key == "H":
			return "warrior_heavy"
		elif combo_key.find("冲刺") >= 0:
			return "warrior_dash_slash"
		else:
			return "warrior_heavy"
	# 轻攻击
	match combo_key.count(",") + 1:
		1:
			return "warrior_light"
		2:
			return "warrior_light2"
		3:
			return "warrior_light3"
		_:
			return "warrior_light"

## 根据boss攻击状态选择hitbox类型
static func get_boss_attack_type(boss_name: String, attack_state: String) -> String:
	var prefix := boss_name
	match boss_name:
		"boss_beetle":
			match attack_state:
				"ATTACK":
					return "beetle_bite"
				"HEAVY_ATTACK":
					return "beetle_heavy"
				"CHARGE":
					return "beetle_charge"
				"SPECIAL":
					return "beetle_slam"
				_:
					return "beetle_bite"
		"boss_lava_turtle":
			match attack_state:
				"ATTACK":
					return "lava_bite"
				"LAVA_SPIT":
					return "lava_lava_spit"
				"SHELL_SPIN":
					return "lava_shell_spin"
				_:
					return "lava_bite"
		"boss_book_spirit":
			match attack_state:
				"ATTACK":
					return "book_spell_beam"
				"PAGE_STORM":
					return "book_page_storm"
				"BOOK_TORNADO":
					return "book_tornado"
				_:
					return "book_spell_beam"
		_:
			return "beetle_bite"
	return prefix + "_bite"
