# tower_icon.gd
extends TextureRect

@export var tower_data: TowerData = preload("res://resources/simple_emitter.tres")

var current_drag_rotation = DragManager.ROT_UP
var is_dragging_initiated = false
var drag_enabled = true

## 实体追踪：由 main.gd 在添加奖励时赋值
var entity_id: int = -1
var deployed_tower_node: Node = null

## 暂存区标记：暂存区的图标不计入储备数量
var is_staging: bool = false

## 状态变化回调（供 main.gd 监听暂存区变化）
var _on_state_changed: Callable = Callable()

## 标记为已部署（图标隐藏）
func mark_deployed(tower_node: Node) -> void:
	deployed_tower_node = tower_node
	visible = false
	if not is_staging:
		GameState.tower_reserve_count = max(0, GameState.tower_reserve_count - 1)
	if _on_state_changed.is_valid():
		_on_state_changed.call()

## 标记为已回收（图标重新显示）
func mark_returned() -> void:
	deployed_tower_node = null
	visible = true
	drag_enabled = true
	if not is_staging:
		GameState.tower_reserve_count += 1
	if _on_state_changed.is_valid():
		_on_state_changed.call()

func _ready():
	if tower_data and tower_data.icon:
		texture = tower_data.icon
	if tower_data and tower_data.tower_name:
		tooltip_text = tower_data.tower_name
		custom_minimum_size.y = 100
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		var label := Label.new()
		label.text = tower_data.tower_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_left = 0.0
		label.anchor_right = 1.0
		label.anchor_top = 1.0
		label.anchor_bottom = 1.0
		label.offset_top = -18
		label.offset_bottom = 0
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_add_ammo_badge()

func _add_ammo_badge() -> void:
	if not tower_data:
		return
	var ammo_text: String
	if tower_data.initial_ammo == -1:
		ammo_text = "∞"
	else:
		ammo_text = str(tower_data.initial_ammo)
	var badge := Label.new()
	badge.text = ammo_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.anchor_left = 0.0
	badge.anchor_right = 1.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 1.0
	badge.offset_top = 0
	badge.offset_bottom = 0
	badge.offset_left = 0
	badge.offset_right = 0
	badge.add_theme_font_size_override("font_size", 45)
	badge.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	badge.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	badge.add_theme_constant_override("outline_size", 8)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)

func set_drag_enabled(enabled: bool):
	drag_enabled = enabled
	modulate.a = 1.0 if enabled else 0.5

func _process(_delta):
	if is_dragging_initiated and is_instance_valid(DragManager.get_drag_source_node()) and DragManager.get_drag_source_node() == self:
		_update_drag_rotation()

func _update_drag_rotation():
	var target_center = get_global_rect().position + size / 2

	if is_instance_valid(DragManager.get_hovered_valid_cell()):
		target_center = DragManager.get_hovered_valid_cell().get_global_center()

	var mouse_pos = get_global_mouse_position()
	var offset = mouse_pos - target_center
	var angle = DragManager.ROT_UP

	if offset.length() < 3:
		angle = DragManager.ROT_UP
	elif abs(offset.x) > abs(offset.y):
		angle = DragManager.ROT_RIGHT if offset.x > 0 else DragManager.ROT_LEFT
	else:
		angle = DragManager.ROT_DOWN if offset.y > 0 else DragManager.ROT_UP

	current_drag_rotation = angle

func get_current_drag_rotation() -> float:
	return current_drag_rotation

func _get_drag_data(_at_position):
	if not drag_enabled or not GameState.can_drag():
		return null

	is_dragging_initiated = true
	_update_drag_rotation()
	DragManager.start_drag(texture, self)

	return {"tower_data": tower_data, "icon": texture, "is_moving": false, "rotation": current_drag_rotation, "entity_id": entity_id, "source_icon": self, "is_staging": is_staging}

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging_initiated:
			is_dragging_initiated = false
			DragManager.end_drag()
