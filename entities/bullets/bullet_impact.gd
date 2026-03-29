class_name BulletImpact extends Node2D

## BulletImpact - 子弹碰撞特效
## 生成 4 个小方块碎片向四周飞散，0.25s 后淡出消失。

const COLORS_ENEMY = [
	Color(1.0, 0.2, 0.05, 1.0),  # 红
	Color(1.0, 0.5, 0.0,  1.0),  # 橙
	Color(1.0, 0.75, 0.1, 1.0),  # 橙黄
]
const COLORS_TOWER = [
	Color(0.2, 0.7, 1.0,  1.0),  # 蓝
	Color(0.1, 1.0, 0.6,  1.0),  # 青绿
	Color(0.5, 1.0, 0.3,  1.0),  # 亮绿
]

func spawn(world_pos: Vector2, colors: Array = COLORS_ENEMY) -> void:
	global_position = world_pos
	var count := randi_range(3, 5)
	for i in range(count):
		var half := randf_range(3.0, 5.5)
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-half, -half), Vector2(half, -half),
			Vector2(half,  half),  Vector2(-half, half),
		])
		poly.color = colors[randi() % colors.size()]
		add_child(poly)

		var angle := (float(i) / count) * TAU + randf_range(-0.4, 0.4)
		var dist  := randf_range(18.0, 38.0)
		var target := Vector2(cos(angle), sin(angle)) * dist

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(poly, "position", target, 0.35)
		tween.tween_property(poly, "modulate:a", 0.0,  0.35)

	get_tree().create_timer(0.3).timeout.connect(queue_free)
