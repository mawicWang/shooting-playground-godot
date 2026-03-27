class_name HealthBar extends Node2D

## HealthBar - 敌人血量条
## 作为敌人的子节点，跟随敌人移动。通过 update() 方法刷新显示。

const BAR_WIDTH := 48.0
const BAR_HEIGHT := 6.0
const OFFSET_Y := -36.0

var _current: float = 1.0
var _max: float = 1.0

func update(current: float, max_hp: float) -> void:
	_current = current
	_max = max_hp
	queue_redraw()

func _draw() -> void:
	if _max <= 0.0:
		return
	var ratio := clampf(_current / _max, 0.0, 1.0)
	var origin := Vector2(-BAR_WIDTH * 0.5, OFFSET_Y)

	# 背景
	draw_rect(Rect2(origin, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color(0.15, 0.15, 0.15, 0.85))

	# 血量填充
	if ratio > 0.0:
		var col: Color
		if ratio > 0.5:
			col = Color(0.2, 0.8, 0.2)
		elif ratio > 0.25:
			col = Color(0.9, 0.7, 0.1)
		else:
			col = Color(0.85, 0.2, 0.2)
		draw_rect(Rect2(origin, Vector2(BAR_WIDTH * ratio, BAR_HEIGHT)), col)

	# 边框
	draw_rect(Rect2(origin, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color(0.0, 0.0, 0.0, 0.9), false, 1.0)
