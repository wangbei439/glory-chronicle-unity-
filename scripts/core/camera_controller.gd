## 摄像机跟随控制器 - Alpha v0.7
## 平滑跟随玩家，支持镜头边界、震屏偏移
extends Node2D

# === 配置 ===
@export var follow_speed: float = 5.0       # 跟随速度（越大越紧）
@export var lookahead: float = 40.0         # 前方预瞄偏移
@export var vertical_offset: float = -30.0  # 垂直偏移（镜头在玩家上方）
@export var smooth_y: float = 3.0           # Y轴跟随速度（更慢，减少上下抖动）

# === 镜头边界 ===
@export var bounds_min: Vector2 = Vector2(320, 180)   # 镜头左上角最小位置
@export var bounds_max: Vector2 = Vector2(320, 180)   # 镜头右下角最大位置（世界坐标）

# === 状态 ===
var camera: Camera2D
var target_pos: Vector2 = Vector2(320, 180)
var current_pos: Vector2 = Vector2(320, 180)
var shake_offset: Vector2 = Vector2.ZERO
var is_active: bool = false

# 房间切换过渡
var transition_active: bool = false
var transition_speed: float = 3.0
var transition_target: Vector2 = Vector2.ZERO

func _ready() -> void:
        _create_camera()

func _create_camera() -> void:
        camera = Camera2D.new()
        camera.zoom = Vector2(1, 1)
        camera.position_smoothing_enabled = false  # 我们手动平滑
        camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER  # 位置=视口中心，配合bounds计算
        add_child(camera)

func setup(viewport_size: Vector2, level_min: Vector2, level_max: Vector2) -> void:
        # 根据关卡大小设置镜头边界
        # viewport_size: 640x360
        # level_min/level_max: 关卡世界坐标范围
        bounds_min = Vector2(
                viewport_size.x / 2,
                viewport_size.y / 2
        )
        bounds_max = Vector2(
                max(viewport_size.x / 2, level_max.x - viewport_size.x / 2),
                max(viewport_size.y / 2, level_max.y - viewport_size.y / 2)
        )

func follow(player_pos: Vector2, player_facing: float, delta: float) -> void:
        if not is_active:
                return

        # 目标位置 = 玩家位置 + 前方预瞄 + 垂直偏移
        target_pos = player_pos + Vector2(lookahead * player_facing, vertical_offset)

        # 平滑跟随（X和Y分开处理）
        current_pos.x = lerp(current_pos.x, target_pos.x, follow_speed * delta)
        current_pos.y = lerp(current_pos.y, target_pos.y, smooth_y * delta)

        # 边界限制
        current_pos.x = clamp(current_pos.x, bounds_min.x, bounds_max.x)
        current_pos.y = clamp(current_pos.y, bounds_min.y, bounds_max.y)

        # 应用位置（含震屏偏移）
        camera.position = current_pos + shake_offset

func apply_shake(offset: Vector2) -> void:
        shake_offset = offset

func start_transition(target: Vector2) -> void:
        transition_active = true
        transition_target = target

func process_transition(delta: float) -> bool:
        # 返回true表示过渡完成
        if not transition_active:
                return true
        current_pos = lerp(current_pos, transition_target, transition_speed * delta)
        camera.position = current_pos + shake_offset
        if current_pos.distance_to(transition_target) < 2:
                transition_active = false
                return true
        return false

func set_position_immediate(pos: Vector2) -> void:
        current_pos = pos
        target_pos = pos
        if camera:
                camera.position = pos

func activate() -> void:
        is_active = true
        if camera:
                camera.make_current()

func deactivate() -> void:
        is_active = false
