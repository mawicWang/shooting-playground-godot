extends Node2D

## battlefield_container.gd — 战场容器
## 管理战场的拖拽平移和缩放动画

# 战场范围（以 Cell 为单位），Grid 居中其内
@export var battlefield_cells: int = 12
const CELL_SIZE := 80.0

# 缩放参数
const COMBAT_SCALE := 0.85
const ZOOM_DURATION := 0.3

# 拖拽状态
var _pan_enabled := false
var _is_dragging := false
var _drag_start_pos := Vector2.ZERO
var _container_start_pos := Vector2.ZERO
var _initial_position := Vector2.ZERO

# 缩放 tween
var _zoom_tween: Tween = null

func _ready():
	add_to_group("bullet_layer")
	_initial_position = position

## 战场范围的半边长（像素）
func _get_battlefield_half_extent() -> float:
	return battlefield_cells * CELL_SIZE / 2.0

## 获取平移的最大偏移量（像素）
func _get_max_pan_offset() -> Vector2:
	var half_extent := _get_battlefield_half_extent()
	var grid_half := 5 * CELL_SIZE / 2.0
	var max_offset := half_extent - grid_half
	return Vector2(max_offset, max_offset)

func _input(event: InputEvent) -> void:
	if not _pan_enabled:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_is_dragging = true
			_drag_start_pos = event.position
			_container_start_pos = position
		else:
			_is_dragging = false

	elif event is InputEventScreenDrag and _is_dragging:
		var delta := event.position - _drag_start_pos
		var new_pos := _container_start_pos + delta / scale
		var max_offset := _get_max_pan_offset()
		new_pos.x = clampf(new_pos.x, _initial_position.x - max_offset.x, _initial_position.x + max_offset.x)
		new_pos.y = clampf(new_pos.y, _initial_position.y - max_offset.y, _initial_position.y + max_offset.y)
		position = new_pos

	# 也支持鼠标拖拽（桌面端调试）
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_start_pos = event.position
				_container_start_pos = position
			else:
				_is_dragging = false

	elif event is InputEventMouseMotion and _is_dragging:
		var delta := event.position - _drag_start_pos
		var new_pos := _container_start_pos + delta / scale
		var max_offset := _get_max_pan_offset()
		new_pos.x = clampf(new_pos.x, _initial_position.x - max_offset.x, _initial_position.x + max_offset.x)
		new_pos.y = clampf(new_pos.y, _initial_position.y - max_offset.y, _initial_position.y + max_offset.y)
		position = new_pos

## 进入战斗：缩放到 COMBAT_SCALE，启用拖拽
func enter_combat() -> void:
	_pan_enabled = true
	_is_dragging = false
	_kill_zoom_tween()
	_zoom_tween = create_tween()
	_zoom_tween.set_trans(Tween.TRANS_QUAD)
	_zoom_tween.set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(self, "scale", Vector2.ONE * COMBAT_SCALE, ZOOM_DURATION)

## 退出战斗：缩放回 1.0，平移归位，禁用拖拽
func exit_combat() -> void:
	_pan_enabled = false
	_is_dragging = false
	_kill_zoom_tween()
	_zoom_tween = create_tween()
	_zoom_tween.set_trans(Tween.TRANS_QUAD)
	_zoom_tween.set_ease(Tween.EASE_OUT)
	_zoom_tween.set_parallel(true)
	_zoom_tween.tween_property(self, "scale", Vector2.ONE, ZOOM_DURATION)
	_zoom_tween.tween_property(self, "position", _initial_position, ZOOM_DURATION)

func _kill_zoom_tween() -> void:
	if is_instance_valid(_zoom_tween) and _zoom_tween.is_running():
		_zoom_tween.kill()
	_zoom_tween = null
