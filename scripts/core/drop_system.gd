## 掉落/拾取系统 - Beta v0.10
## 敌人死亡后掉落物品，玩家走过去自动拾取
## 物品类型：生命药水、怒气水晶、矿石碎片
## v0.10: 追踪药水/水晶拾取计数，修复存档同步
extends Node2D

# === 掉落物类型 ===
enum ItemType {
        HEALTH_POTION,    # 生命药水 - 回复20HP
        RAGE_CRYSTAL,     # 怒气水晶 - +20怒气
        ORE_FRAGMENT,     # 矿石碎片 - 技能树升级货币
}

# === 掉落物数据 ===
# 每个掉落物：{type, pos, vel, node, lifetime, bob_phase}
var drops: Array = []

# === 拾取范围 ===
var pickup_range: float = 40.0

# === 掉落物视觉 ===
# 颜色和大小配置
const DROP_COLORS = {
        ItemType.HEALTH_POTION: Color(0.2, 0.9, 0.3),    # 绿色
        ItemType.RAGE_CRYSTAL: Color(0.9, 0.4, 0.1),     # 橙红
        ItemType.ORE_FRAGMENT: Color(0.7, 0.6, 0.9),     # 紫色
}

const DROP_SIZES = {
        ItemType.HEALTH_POTION: Vector2(8, 10),
        ItemType.RAGE_CRYSTAL: Vector2(7, 9),
        ItemType.ORE_FRAGMENT: Vector2(6, 6),
}

const DROP_LABELS = {
        ItemType.HEALTH_POTION: "+",
        ItemType.RAGE_CRYSTAL: "◆",
        ItemType.ORE_FRAGMENT: "◇",
}

# === 掉落概率配置 ===
# 格式：{enemy_type: {item_type: probability}}
# enemy_type: "wraith" / "bat" / "boss"
const DROP_TABLES = {
        "wraith": {
                ItemType.HEALTH_POTION: 0.35,
                ItemType.RAGE_CRYSTAL: 0.40,
                ItemType.ORE_FRAGMENT: 0.50,
        },
        "bat": {
                ItemType.HEALTH_POTION: 0.15,
                ItemType.RAGE_CRYSTAL: 0.55,
                ItemType.ORE_FRAGMENT: 0.30,
        },
        "boss": {
                ItemType.HEALTH_POTION: 1.0,
                ItemType.RAGE_CRYSTAL: 1.0,
                ItemType.ORE_FRAGMENT: 1.0,  # spawn_drop额外处理Boss掉2个碎片
        },
}

# === 拾取回调 ===
signal item_picked_up(item_type: int, count: int)
signal pickup_message(text: String, color: Color)

# === 玩家引用 ===
var player: Node2D = null

# === 拾取计数 ===
var ore_fragments: int = 0
var health_potions: int = 0
var rage_crystals: int = 0

# === HUD引用 ===
var hud: Node2D = null

# === 音效引用 ===
var audio: Node2D = null

func _ready() -> void:
        pass

func set_player(p: Node2D) -> void:
        player = p

func set_hud(h: Node2D) -> void:
        hud = h

func set_audio(a: Node2D) -> void:
        audio = a

func process(delta: float) -> void:
        # 更新所有掉落物
        for i in range(drops.size() - 1, -1, -1):
                var drop: Dictionary = drops[i]
                if drop["node"] == null or not is_instance_valid(drop["node"]):
                        drops.remove_at(i)
                        continue

                # 生命周期
                drop["lifetime"] -= delta
                if drop["lifetime"] <= 0:
                        drop["node"].queue_free()
                        drops.remove_at(i)
                        continue

                # 弹出物理（初始弹出弧线）
                if drop["vel"].length_squared() > 1:
                        drop["vel"].y += 400 * delta  # 重力
                        drop["pos"] += drop["vel"] * delta
                        if drop["pos"].y > drop["ground_y"]:
                                drop["pos"].y = drop["ground_y"]
                                drop["vel"] = Vector2.ZERO
                        drop["node"].position = drop["pos"]
                else:
                        # 落地后：上下浮动 + 闪烁
                        drop["bob_phase"] += delta * 4
                        var bob_offset: float = sin(drop["bob_phase"]) * 2
                        drop["node"].position = drop["pos"] + Vector2(0, bob_offset)

                        # 快过期时闪烁
                        if drop["lifetime"] < 3.0:
                                var blink: bool = int(drop["lifetime"] * 5) % 2 == 0
                                drop["node"].visible = blink
                        else:
                                drop["node"].visible = true

                # 吸引效果：玩家靠近时飞向玩家
                if player and is_instance_valid(player) and drop["vel"].length_squared() < 1:
                        var dist_to_player: float = abs(drop["pos"].x - player.pos.x)
                        var magnet_range: float = 50.0
                        if dist_to_player < magnet_range:
                                var dir: float = 1.0 if player.pos.x > drop["pos"].x else -1.0
                                drop["pos"].x += dir * 120 * delta
                                drop["node"].position = drop["pos"]

                # 拾取检测
                if player and is_instance_valid(player):
                        var dist: float = abs(drop["pos"].x - player.pos.x)
                        var dist_y: float = abs(drop["pos"].y - player.pos.y)
                        if dist < pickup_range and dist_y < 40:
                                _on_pickup(i)
                                break  # 一帧只拾取一个

func spawn_drop(enemy_pos: Vector2, enemy_type: String, ground_y: float) -> void:
        """敌人死亡时调用，根据掉落表生成掉落物"""
        if not DROP_TABLES.has(enemy_type):
                return

        var table: Dictionary = DROP_TABLES[enemy_type]
        var spawn_offset: float = 0.0

        for item_type: int in table:
                var prob: float = table[item_type]
                if randf() < prob:
                        _create_drop(item_type, enemy_pos + Vector2(spawn_offset, -10), ground_y)
                        spawn_offset += 15  # 错开位置避免重叠

        # Boss额外掉1个矿石碎片
        if enemy_type == "boss":
                _create_drop(ItemType.ORE_FRAGMENT, enemy_pos + Vector2(spawn_offset, -10), ground_y)

func _create_drop(item_type: int, pos: Vector2, ground_y: float) -> void:
        """创建一个掉落物"""
        # 主节点
        var node = Node2D.new()
        add_child(node)

        # 视觉：主体
        var color: Color = DROP_COLORS.get(item_type, Color.WHITE)
        var size: Vector2 = DROP_SIZES.get(item_type, Vector2(6, 6))

        var body = ColorRect.new()
        body.size = size
        body.position = Vector2(-size.x / 2, -size.y / 2)
        body.color = color
        node.add_child(body)

        # 视觉：发光效果
        var glow = ColorRect.new()
        glow.size = size + Vector2(4, 4)
        glow.position = Vector2(-size.x / 2 - 2, -size.y / 2 - 2)
        glow.color = Color(color.r, color.g, color.b, 0.3)
        node.add_child(glow)

        # 视觉：标签（符号）
        var label = Label.new()
        label.text = DROP_LABELS.get(item_type, "?")
        label.position = Vector2(-3, -size.y - 8)
        label.add_theme_font_size_override("font_size", 6)
        label.add_theme_color_override("font_color", color)
        node.add_child(label)

        # 设置位置和弹出速度
        var spawn_pos: Vector2 = pos
        node.position = spawn_pos

        # 弹出弧线：随机向上 + 微横向
        var vel: Vector2 = Vector2(randf_range(-40, 40), randf_range(-120, -80))

        var drop_data: Dictionary = {
                "type": item_type,
                "pos": spawn_pos,
                "vel": vel,
                "ground_y": ground_y,
                "node": node,
                "lifetime": 10.0,  # 10秒后消失
                "bob_phase": randf() * TAU,
        }
        drops.append(drop_data)

func _on_pickup(index: int) -> void:
        """拾取掉落物"""
        if index < 0 or index >= drops.size():
                return

        var drop: Dictionary = drops[index]
        var item_type: int = drop["type"]

        # 清理视觉
        if drop["node"] and is_instance_valid(drop["node"]):
                drop["node"].queue_free()

        drops.remove_at(index)

        # 应用效果
        var msg: String = ""
        var msg_color: Color = Color.WHITE

        match item_type:
                ItemType.HEALTH_POTION:
                        health_potions += 1
                        if player and is_instance_valid(player):
                                var heal: float = 20.0
                                player.hp = min(player.max_hp, player.hp + heal)
                                player.health_changed.emit(player.hp)
                        msg = "+20 HP"
                        msg_color = Color(0.2, 0.9, 0.3)
                ItemType.RAGE_CRYSTAL:
                        rage_crystals += 1
                        if player and is_instance_valid(player):
                                var rage_gain: float = 20.0
                                player.rage = min(player.max_rage, player.rage + rage_gain)
                                player.rage_changed.emit(player.rage)
                        msg = "+20 RAGE"
                        msg_color = Color(0.9, 0.4, 0.1)
                ItemType.ORE_FRAGMENT:
                        ore_fragments += 1
                        msg = "+1 ORE"
                        msg_color = Color(0.7, 0.6, 0.9)

        # 发出拾取信号
        item_picked_up.emit(item_type, 1)
        pickup_message.emit(msg, msg_color)

        # 音效
        if audio:
                audio.play("level_up", 0.4)

        # HUD显示拾取信息
        if hud:
                hud.show_perfect(msg, msg_color)

func get_ore_count() -> int:
        return ore_fragments

func get_potion_count() -> int:
        return health_potions

func get_crystal_count() -> int:
        return rage_crystals

func add_ore(count: int) -> void:
        ore_fragments += count

func spend_ore(count: int) -> bool:
        if ore_fragments >= count:
                ore_fragments -= count
                return true
        return false

func set_pickup_counts(ore: int, potions: int, crystals: int) -> void:
        """从存档恢复拾取计数"""
        ore_fragments = ore
        health_potions = potions
        rage_crystals = crystals

func get_pickup_counts() -> Dictionary:
        """获取所有拾取计数用于存档"""
        return {
                "ore_fragments": ore_fragments,
                "health_potions": health_potions,
                "rage_crystals": rage_crystals,
        }

func clear_all() -> void:
        for drop in drops:
                if drop["node"] and is_instance_valid(drop["node"]):
                        drop["node"].queue_free()
        drops.clear()
