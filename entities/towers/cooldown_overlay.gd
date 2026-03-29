class_name CooldownOverlay
extends Node2D

## WoW 风格冷却转圈遮罩
## progress 0.0 = 刚发射（完全遮盖），1.0 = 已就绪（不显示）
var progress: float = 1.0:
	set(v):
		progress = clamp(v, 0.0, 1.0)
		queue_redraw()

var radius: float = 32.0

const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const ARC_POINTS := 64

func _draw() -> void:
	if progress >= 1.0:
		return

	var remaining := 1.0 - progress
	var angle_span := remaining * TAU
	var start_angle := -PI * 0.5  # 从 12 点钟位置开始

	var n: int = max(int(ceil(ARC_POINTS * remaining)), 2)
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)  # 圆心

	for i in range(n + 1):
		var angle := start_angle + (float(i) / float(n)) * angle_span
		pts.append(Vector2(cos(angle), sin(angle)) * radius)

	draw_colored_polygon(pts, OVERLAY_COLOR)
