class_name AmmoNumber extends Node2D

## AmmoNumber - 弹药补充数字
## 在炮塔上方随机位置生成，向上飘动并淡出。

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.9))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_label.add_theme_constant_override("outline_size", 3)
	_label.offset_left = -30.0
	_label.offset_right = 30.0
	_label.offset_top = -16.0
	_label.offset_bottom = 16.0
	add_child(_label)

func show_ammo(world_pos: Vector2, amount: int) -> void:
	global_position = world_pos + Vector2(randf_range(-30.0, 30.0), randf_range(-65.0, -35.0))
	_label.text = "+%d" % amount

	var tween := create_tween()
	tween.tween_property(self, "global_position", global_position + Vector2(0.0, -38.0), 0.75)
	tween.parallel().tween_property(_label, "modulate:a", 0.0, 0.75)
	tween.tween_callback(queue_free)
