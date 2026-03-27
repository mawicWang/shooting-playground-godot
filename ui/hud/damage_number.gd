class_name DamageNumber extends Node2D

## DamageNumber - 伤害数字显示
## 在受伤位置生成，向上飘动并淡出。由 enemy.take_damage() 生成。

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_label.add_theme_constant_override("outline_size", 3)
	_label.offset_left = -20.0
	_label.offset_right = 20.0
	_label.offset_top = -12.0
	_label.offset_bottom = 12.0
	add_child(_label)

func show_damage(world_pos: Vector2, amount: float) -> void:
	global_position = world_pos + Vector2(randf_range(-8.0, 8.0), -10.0)
	_label.text = "%d" % int(amount) if amount == floorf(amount) else "%.1f" % amount

	var tween := create_tween()
	tween.tween_property(self, "global_position", global_position + Vector2(0.0, -45.0), 0.85)
	tween.parallel().tween_property(_label, "modulate:a", 0.0, 0.85)
	tween.tween_callback(queue_free)
