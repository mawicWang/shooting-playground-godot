# module_stack_icon.gd
# 模块叠加图标：同类型模块显示 x N，安装/卸载自动增减计数
extends TextureRect

const FALLBACK_TEX = preload("res://assets/bullet.svg")

var module_data: Module
var count: int = 1
var drag_enabled: bool = true
var _count_label: Label

func _ready() -> void:
	_count_label = Label.new()
	_count_label.anchor_left = 0.0
	_count_label.anchor_right = 1.0
	_count_label.anchor_top = 0.0
	_count_label.anchor_bottom = 1.0
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count_label.add_theme_font_size_override("font_size", 16)
	_count_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_count_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_count_label.add_theme_constant_override("outline_size", 2)
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_label)

	if module_data:
		texture = module_data.icon if module_data.icon else FALLBACK_TEX
		if "slot_color" in module_data:
			modulate = module_data.slot_color
		tooltip_text = "%s\n%s" % [module_data.module_name, module_data.description]
	_update_count_label()

func _update_count_label() -> void:
	if not is_instance_valid(_count_label):
		return
	if count > 1:
		_count_label.text = "x%d" % count
		_count_label.visible = true
	else:
		_count_label.visible = false

func set_drag_enabled(enabled: bool) -> void:
	drag_enabled = enabled
	modulate.a = 1.0 if enabled else 0.5

## 安装一个：计数 -1，归零时隐藏图标
func mark_deployed() -> void:
	count -= 1
	if count <= 0:
		count = 0
		visible = false
	else:
		_update_count_label()

## 卸载一个：计数 +1，之前归零的重新显示
func mark_returned() -> void:
	count += 1
	if not visible:
		visible = true
	set_drag_enabled(true)
	_update_count_label()

func _get_drag_data(_at_position) -> Variant:
	if not drag_enabled or not module_data or not GameState.can_drag():
		return null

	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = Vector2(60, 60)
	preview.modulate.a = 0.7
	set_drag_preview(preview)

	return {"module_data": module_data, "entity_id": -1, "source_icon": self}
