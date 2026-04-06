class_name ShieldBar extends Node2D

const BAR_WIDTH := 48.0
const BAR_HEIGHT := 5.0
const OFFSET_Y := -44.0
const SEGMENT_GAP := 2.0
const SHIELD_COLOR := Color(0.3, 0.55, 1.0, 0.9)
const SHIELD_BG := Color(0.1, 0.15, 0.3, 0.7)
const BORDER_COLOR := Color(0.15, 0.2, 0.5, 0.9)

var _current: int
var _max: int

func update(current: int, max_layers: int) -> void:
	_current = current
	_max = max_layers
	visible = current > 0
	queue_redraw()

func _draw() -> void:
	if _max <= 0:
		return
	var origin := Vector2(-BAR_WIDTH * 0.5, OFFSET_Y)
	# Background
	draw_rect(Rect2(origin, Vector2(BAR_WIDTH, BAR_HEIGHT)), SHIELD_BG)
	# Segments
	var seg_width: float = (BAR_WIDTH - SEGMENT_GAP * (_max - 1)) / _max
	for i in range(_max):
		if i < _current:
			var seg_x := origin.x + i * (seg_width + SEGMENT_GAP)
			draw_rect(Rect2(Vector2(seg_x, origin.y), Vector2(seg_width, BAR_HEIGHT)), SHIELD_COLOR)
	# Border
	draw_rect(Rect2(origin, Vector2(BAR_WIDTH, BAR_HEIGHT)), BORDER_COLOR, false, 1.0)
