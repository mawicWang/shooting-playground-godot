class_name ShieldBreakEffect extends Node2D

const FRAGMENT_COUNT := 8
const FRAGMENT_SIZE := Vector2(5.0, 5.0)
const SPREAD_DISTANCE := 40.0
const DURATION := 0.5
const FRAGMENT_COLOR := Color(0.4, 0.65, 1.0, 0.9)

func play(world_pos: Vector2) -> void:
	global_position = world_pos

	for i in FRAGMENT_COUNT:
		var base_angle := (TAU / FRAGMENT_COUNT) * i
		var angle := base_angle + randf_range(-0.3, 0.3)
		var fragment := _create_fragment()
		add_child(fragment)

		var target_pos := Vector2.from_angle(angle) * SPREAD_DISTANCE * randf_range(0.6, 1.2)
		var target_rotation := randf_range(-PI, PI)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(fragment, "position", target_pos, DURATION)
		tween.tween_property(fragment, "modulate:a", 0.0, DURATION)
		tween.tween_property(fragment, "rotation", target_rotation, DURATION)

	await get_tree().create_timer(DURATION + 0.05).timeout
	queue_free()

func _create_fragment() -> ColorRect:
	var rect := ColorRect.new()
	rect.size = FRAGMENT_SIZE
	rect.color = FRAGMENT_COLOR.lerp(Color.WHITE, randf_range(0.0, 0.3))
	rect.pivot_offset = FRAGMENT_SIZE / 2.0
	rect.position = -FRAGMENT_SIZE / 2.0
	return rect
