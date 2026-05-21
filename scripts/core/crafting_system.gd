## 装备打造系统 - v0.20
## 设计文档§3.2：基底+附材=玩家定向合成，材料来源绑定特定Boss
## v0.20: 新增阶梯式合成路径、书灵Boss掉落、配方图标
extends Node2D

# === 打造材料类型 ===
enum MaterialType {
	BEETLE_SHELL,     # 甲虫壳碎片 - 矿脉甲虫Boss掉落
	LAVA_CORE,        # 熔岩核心 - 远古熔岩龟Boss掉落
	SHADOW_ESSENCE,   # 暗影精华 - 矿井小怪稀有掉落
	VEIN_CRYSTAL,     # 地脉结晶 - 地脉小怪稀有掉落
	ARCANE_PAGE,      # 秘法残页 - 堕落书灵Boss掉落
}

# === 材料信息 (含图标路径) ===
const MATERIAL_INFO: Dictionary = {
	MaterialType.BEETLE_SHELL: {
		"name": "甲虫壳碎片",
		"color": Color(0.75, 0.5, 0.2),
		"desc": "矿脉甲虫的坚硬外壳碎片",
		"icon": "res://assets/sprites/materials/beetle_shell.png",
	},
	MaterialType.LAVA_CORE: {
		"name": "熔岩核心",
		"color": Color(1.0, 0.4, 0.1),
		"desc": "熔岩龟体内灼热的核心",
		"icon": "res://assets/sprites/materials/lava_core.png",
	},
	MaterialType.SHADOW_ESSENCE: {
		"name": "暗影精华",
		"color": Color(0.6, 0.4, 0.8),
		"desc": "矿井亡魂残留的暗影力量",
		"icon": "res://assets/sprites/materials/shadow_essence.png",
	},
	MaterialType.VEIN_CRYSTAL: {
		"name": "地脉结晶",
		"color": Color(0.3, 0.8, 0.7),
		"desc": "地脉中凝结的元素结晶",
		"icon": "res://assets/sprites/materials/vein_crystal.png",
	},
	MaterialType.ARCANE_PAGE: {
		"name": "秘法残页",
		"color": Color(0.5, 0.3, 0.7),
		"desc": "堕落书灵散落的魔法书页",
		"icon": "res://assets/sprites/materials/ore_fragment.png",
	},
}

# === 打造配方 - 阶梯式合成路径 ===
# T1: 矿井初期(暗影精华) → T2: 甲虫战后(甲壳) → T3: 熔岩战后(熔岩核心) → T4: 终极(全材料)
const RECIPES: Array = [
	# --- T1: 矿井前期(只需暗影精华+矿石) ---
	{
		"id": "wraith_pick",
		"name": "亡魂镐刃",
		"desc": "附魔暗影的采矿镐，攻速极快",
		"type": "weapon",
		"tier": 1,
		"stats": {
			"attack_mult": 1.3,
			"defense_mult": 1.0,
			"rage_bonus": 0.1,
			"max_hp_bonus": 0.0,
		},
		"materials": {
			MaterialType.SHADOW_ESSENCE: 1,
		},
		"ore_cost": 4,
		"color": Color(0.5, 0.35, 0.7),
		"icon": "res://assets/sprites/equipment/iron_sword.png",
		"upgrade_from": "",  # 无前置
	},
	{
		"id": "shadow_cloak",
		"name": "暗影斗篷",
		"desc": "融入暗影的轻盈斗篷，提升怒气",
		"type": "armor",
		"tier": 1,
		"stats": {
			"defense_mult": 0.8,
			"max_hp_bonus": 5.0,
			"rage_bonus": 0.05,
		},
		"materials": {
			MaterialType.SHADOW_ESSENCE: 1,
		},
		"ore_cost": 3,
		"color": Color(0.4, 0.3, 0.6),
		"icon": "res://assets/sprites/equipment/leather_vest.png",
		"upgrade_from": "",
	},
	# --- T2: 甲虫战后(甲壳材料) ---
	{
		"id": "beetle_carapace_sword",
		"name": "甲壳剑",
		"desc": "甲虫壳锻造的锋利长剑，坚固耐用",
		"type": "weapon",
		"tier": 2,
		"stats": {
			"attack_mult": 1.5,
			"defense_mult": 0.95,
			"rage_bonus": 0.0,
			"max_hp_bonus": 0.0,
		},
		"materials": {
			MaterialType.BEETLE_SHELL: 1,
			MaterialType.SHADOW_ESSENCE: 1,
		},
		"ore_cost": 5,
		"color": Color(0.75, 0.55, 0.25),
		"icon": "res://assets/sprites/equipment/crystal_blade.png",
		"upgrade_from": "wraith_pick",
	},
	{
		"id": "beetle_shield",
		"name": "甲壳盾",
		"desc": "甲虫壳制成的坚固护盾，大幅提升防御",
		"type": "armor",
		"tier": 2,
		"stats": {
			"defense_mult": 0.7,
			"max_hp_bonus": 10.0,
			"rage_bonus": 0.0,
		},
		"materials": {
			MaterialType.BEETLE_SHELL: 1,
		},
		"ore_cost": 5,
		"color": Color(0.8, 0.6, 0.3),
		"icon": "res://assets/sprites/equipment/beetle_bulwark.png",
		"upgrade_from": "shadow_cloak",
	},
	# --- T3: 熔岩战后(熔岩核心) ---
	{
		"id": "lava_greatsword",
		"name": "熔岩巨剑",
		"desc": "注入熔岩之力的毁灭巨剑，攻击极强但降低防御",
		"type": "weapon",
		"tier": 3,
		"stats": {
			"attack_mult": 1.8,
			"defense_mult": 0.9,
			"rage_bonus": 0.1,
			"max_hp_bonus": 0.0,
		},
		"materials": {
			MaterialType.LAVA_CORE: 2,
			MaterialType.BEETLE_SHELL: 1,
		},
		"ore_cost": 8,
		"color": Color(1.0, 0.4, 0.15),
		"icon": "res://assets/sprites/equipment/lava_greatsword.png",
		"upgrade_from": "beetle_carapace_sword",
	},
	{
		"id": "beetle_bulwark",
		"name": "甲虫壁垒",
		"desc": "以甲虫壳和熔岩核心锻造的坚不可摧之盾",
		"type": "armor",
		"tier": 3,
		"stats": {
			"defense_mult": 0.6,
			"max_hp_bonus": 30.0,
			"rage_bonus": 0.0,
		},
		"materials": {
			MaterialType.BEETLE_SHELL: 2,
			MaterialType.LAVA_CORE: 1,
		},
		"ore_cost": 8,
		"color": Color(0.3, 0.55, 0.9),
		"icon": "res://assets/sprites/equipment/beetle_bulwark.png",
		"upgrade_from": "beetle_shield",
	},
	{
		"id": "shadow_twin_blades",
		"name": "暗影双刃",
		"desc": "蕴含暗影之力的双刀，怒气激增",
		"type": "weapon",
		"tier": 3,
		"stats": {
			"attack_mult": 1.5,
			"defense_mult": 1.0,
			"rage_bonus": 0.3,
			"max_hp_bonus": 0.0,
		},
		"materials": {
			MaterialType.SHADOW_ESSENCE: 3,
		},
		"ore_cost": 6,
		"color": Color(0.5, 0.3, 0.8),
		"icon": "res://assets/sprites/equipment/shadow_twin_blades.png",
		"upgrade_from": "",
	},
	# --- T4: 终极装备(全区域材料) ---
	{
		"id": "vein_holy_garb",
		"name": "地脉圣衣",
		"desc": "元素结晶编织的攻守兼备战袍",
		"type": "armor",
		"tier": 4,
		"stats": {
			"defense_mult": 0.65,
			"max_hp_bonus": 15.0,
			"rage_bonus": 0.2,
		},
		"materials": {
			MaterialType.VEIN_CRYSTAL: 2,
			MaterialType.SHADOW_ESSENCE: 1,
		},
		"ore_cost": 7,
		"color": Color(0.95, 0.7, 0.25),
		"icon": "res://assets/sprites/equipment/vein_holy_garb.png",
		"upgrade_from": "beetle_bulwark",
	},
	{
		"id": "arcane_codex",
		"name": "秘典·终焉",
		"desc": "集齐三域之力的终极法典，全属性大幅提升",
		"type": "weapon",
		"tier": 4,
		"stats": {
			"attack_mult": 2.0,
			"defense_mult": 0.95,
			"rage_bonus": 0.15,
			"max_hp_bonus": 10.0,
		},
		"materials": {
			MaterialType.ARCANE_PAGE: 2,
			MaterialType.LAVA_CORE: 1,
			MaterialType.VEIN_CRYSTAL: 1,
		},
		"ore_cost": 12,
		"color": Color(0.6, 0.3, 0.9),
		"icon": "res://assets/sprites/equipment/crystal_blade.png",
		"upgrade_from": "lava_greatsword",
	},
	{
		"id": "crystalline_aegis",
		"name": "结晶圣盾",
		"desc": "融合全部元素结晶的终极防御，几乎坚不可摧",
		"type": "armor",
		"tier": 4,
		"stats": {
			"defense_mult": 0.55,
			"max_hp_bonus": 20.0,
			"rage_bonus": 0.1,
		},
		"materials": {
			MaterialType.VEIN_CRYSTAL: 2,
			MaterialType.BEETLE_SHELL: 1,
			MaterialType.ARCANE_PAGE: 1,
		},
		"ore_cost": 10,
		"color": Color(0.4, 0.7, 0.9),
		"icon": "res://assets/sprites/equipment/crystal_mail.png",
		"upgrade_from": "vein_holy_garb",
	},
]

# === 材料掉落配置 ===
const BOSS_DROPS: Dictionary = {
	"beetle": {
		MaterialType.BEETLE_SHELL: {"prob": 1.0, "count": 2},
	},
	"lava_turtle": {
		MaterialType.LAVA_CORE: {"prob": 1.0, "count": 2},
	},
	"book_spirit": {
		MaterialType.ARCANE_PAGE: {"prob": 1.0, "count": 2},
	},
}

# 小怪稀有掉落
const ENEMY_DROPS: Dictionary = {
	"wraith": {
		MaterialType.SHADOW_ESSENCE: {"prob": 0.12, "count": 1},
	},
	"bat_mine": {
		MaterialType.SHADOW_ESSENCE: {"prob": 0.08, "count": 1},
	},
	"bat_lava": {
		MaterialType.VEIN_CRYSTAL: {"prob": 0.10, "count": 1},
	},
	"wraith_lava": {
		MaterialType.VEIN_CRYSTAL: {"prob": 0.12, "count": 1},
	},
	"bat_library": {
		MaterialType.ARCANE_PAGE: {"prob": 0.06, "count": 1},
	},
	"wraith_library": {
		MaterialType.ARCANE_PAGE: {"prob": 0.08, "count": 1},
	},
}

# === 材料库存 ===
var materials: Dictionary = {
	MaterialType.BEETLE_SHELL: 0,
	MaterialType.LAVA_CORE: 0,
	MaterialType.SHADOW_ESSENCE: 0,
	MaterialType.VEIN_CRYSTAL: 0,
	MaterialType.ARCANE_PAGE: 0,
}

var ore_fragments: int = 0

func _ready() -> void:
	pass

func set_ore_count(count: int) -> void:
	ore_fragments = count

func get_material_count(mat_type: int) -> int:
	return materials.get(mat_type, 0)

func add_material(mat_type: int, count: int = 1) -> void:
	if materials.has(mat_type):
		materials[mat_type] += count

func can_craft(recipe_index: int) -> bool:
	if recipe_index < 0 or recipe_index >= RECIPES.size():
		return false
	var recipe: Dictionary = RECIPES[recipe_index]
	if GameState.owned_equipment.has(recipe["id"]):
		return false
	if ore_fragments < recipe["ore_cost"]:
		return false
	for mat_type: int in recipe["materials"]:
		var needed: int = recipe["materials"][mat_type]
		if materials.get(mat_type, 0) < needed:
			return false
	return true

func craft(recipe_index: int) -> bool:
	if not can_craft(recipe_index):
		return false
	var recipe: Dictionary = RECIPES[recipe_index]
	ore_fragments -= recipe["ore_cost"]
	for mat_type: int in recipe["materials"]:
		materials[mat_type] -= recipe["materials"][mat_type]
	GameState.owned_equipment.append(recipe["id"])
	if recipe["type"] == "weapon":
		GameState.equip_weapon(recipe["id"])
	else:
		GameState.equip_armor(recipe["id"])
	return true

func get_recipe_status(recipe_index: int) -> String:
	if recipe_index < 0 or recipe_index >= RECIPES.size():
		return ""
	var recipe: Dictionary = RECIPES[recipe_index]
	if GameState.owned_equipment.has(recipe["id"]):
		var equipped_id: String = GameState.equipped_weapon if recipe["type"] == "weapon" else GameState.equipped_armor
		if recipe["id"] == equipped_id:
			return "已装备"
		else:
			return "已拥有"
	if can_craft(recipe_index):
		return "可打造"
	return "材料不足"

func get_missing_materials_text(recipe_index: int) -> String:
	if recipe_index < 0 or recipe_index >= RECIPES.size():
		return ""
	var recipe: Dictionary = RECIPES[recipe_index]
	var missing: String = ""
	if ore_fragments < recipe["ore_cost"]:
		missing += "矿石x" + str(recipe["ore_cost"] - ore_fragments) + " "
	for mat_type: int in recipe["materials"]:
		var needed: int = recipe["materials"][mat_type]
		var have: int = materials.get(mat_type, 0)
		if have < needed:
			var info: Dictionary = MATERIAL_INFO[mat_type]
			missing += info["name"] + "x" + str(needed - have) + " "
	return missing.strip_edges()

## 获取合成路径树 (用于UI展示)
func get_craft_tree() -> Dictionary:
	var tree: Dictionary = {}
	for i in range(RECIPES.size()):
		var recipe: Dictionary = RECIPES[i]
		var tier: int = recipe.get("tier", 1)
		if not tree.has(tier):
			tree[tier] = []
		tree[tier].append({
			"index": i,
			"id": recipe["id"],
			"name": recipe["name"],
			"type": recipe["type"],
			"upgrade_from": recipe.get("upgrade_from", ""),
			"status": get_recipe_status(i),
		})
	return tree

func get_save_data() -> Dictionary:
	return {
		"beetle_shell": materials[MaterialType.BEETLE_SHELL],
		"lava_core": materials[MaterialType.LAVA_CORE],
		"shadow_essence": materials[MaterialType.SHADOW_ESSENCE],
		"vein_crystal": materials[MaterialType.VEIN_CRYSTAL],
		"arcane_page": materials[MaterialType.ARCANE_PAGE],
	}

func load_save_data(data: Dictionary) -> void:
	materials[MaterialType.BEETLE_SHELL] = int(data.get("beetle_shell", 0))
	materials[MaterialType.LAVA_CORE] = int(data.get("lava_core", 0))
	materials[MaterialType.SHADOW_ESSENCE] = int(data.get("shadow_essence", 0))
	materials[MaterialType.VEIN_CRYSTAL] = int(data.get("vein_crystal", 0))
	materials[MaterialType.ARCANE_PAGE] = int(data.get("arcane_page", 0))

func reset() -> void:
	materials[MaterialType.BEETLE_SHELL] = 0
	materials[MaterialType.LAVA_CORE] = 0
	materials[MaterialType.SHADOW_ESSENCE] = 0
	materials[MaterialType.VEIN_CRYSTAL] = 0
	materials[MaterialType.ARCANE_PAGE] = 0

# 静态方法：获取打造装备的属性
static func get_crafted_weapon_stats(weapon_id: String) -> Dictionary:
	for recipe in RECIPES:
		if recipe["id"] == weapon_id and recipe["type"] == "weapon":
			return recipe["stats"]
	return {}

static func get_crafted_armor_stats(armor_id: String) -> Dictionary:
	for recipe in RECIPES:
		if recipe["id"] == armor_id and recipe["type"] == "armor":
			return recipe["stats"]
	return {}

static func get_all_recipe_ids() -> Array:
	var ids: Array = []
	for recipe in RECIPES:
		ids.append(recipe["id"])
	return ids
