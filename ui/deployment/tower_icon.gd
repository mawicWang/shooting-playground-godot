# tower_icon.gd
extends TextureRect

@export var tower_data: TowerData = preload("res://resources/simple_emitter.tres")

var current_drag_rotation = DragManager.ROT_UP
var is_dragging_initiated = false
var drag_enabled = true

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

	return {"tower_data": tower_data, "icon": texture, "is_moving": false, "rotation": current_drag_rotation}

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging_initiated:
			is_dragging_initiated = false
			DragManager.end_drag()
