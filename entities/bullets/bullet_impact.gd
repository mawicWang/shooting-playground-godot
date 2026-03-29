class_name BulletImpact extends Node2D

## BulletImpact - 子弹碰撞特效
## 生成 4 个小方块碎片向四周飞散，0.25s 后淡出消失。

const FRAGMENT_COUNT = 4
const HALF = 2.0  # 碎片半径（像素）
const IMPACT_COLOR = Color(0.4, 0.9, 1.0, 1.0)  # 淡蓝色能量

func spawn(world_pos: Vector2) -> void:
	global_position = world_pos
	for i in range(FRAGMENT_COUNT):
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-HALF, -HALF), Vector2(HALF, -HALF),
			Vector2(HALF, HALF),  Vector2(-HALF, HALF)
		])
		poly.color = IMPACT_COLOR
		add_child(poly)

		var angle := (float(i) / FRAGMENT_COUNT) * TAU + randf_range(-0.3, 0.3)
		var dist := randf_range(6.0, 16.0)
		var target := Vector2(cos(angle), sin(angle)) * dist

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(poly, "position", target, 0.25)
		tween.tween_property(poly, "modulate:a", 0.0, 0.25)

	get_tree().create_timer(0.3).timeout.connect(queue_free)
