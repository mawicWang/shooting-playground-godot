extends Node2D
class_name BoostOverlay

const CELL_SIZE := 80.0
const LINE_SPEED := 120.0  # pixels per second upward
const LINE_COUNT := 4
const LINE_HEIGHT := 18.0
const LINE_WIDTH := 2.5

var _tower: Node = null
var _line_offsets: Array[float] = []
var _visible_alpha: float = 0.0  # for fade in/out

func _ready() -> void:
	z_index = 1  # above sprite (0), below labels (2+)
	_line_offsets.resize(LINE_COUNT)
	for i in LINE_COUNT:
		_line_offsets[i] = (CELL_SIZE / LINE_COUNT) * i * (CELL_SIZE / LINE_HEIGHT)
	visible = false

func set_tower(tower: Node) -> void:
	_tower = tower

func _process(delta: float) -> void:
	if _tower == null:
		return

	var boosted: bool = _tower._boost_time_remaining > 0.0

	# Fade in/out
	if boosted:
		_visible_alpha = minf(_visible_alpha + delta * 4.0, 1.0)
	else:
		_visible_alpha = maxf(_visible_alpha - delta * 4.0, 0.0)

	visible = _visible_alpha > 0.01

	if visible:
		# Advance line positions upward
		for i in LINE_COUNT:
			_line_offsets[i] -= LINE_SPEED * delta
			if _line_offsets[i] < -LINE_HEIGHT:
				_line_offsets[i] += CELL_SIZE + LINE_HEIGHT
		queue_redraw()

func _draw() -> void:
	if _tower == null or _visible_alpha <= 0.0:
		return

	var half := CELL_SIZE / 2.0

	# Blue background tint (very low alpha)
	draw_rect(
		Rect2(-half, -half, CELL_SIZE, CELL_SIZE),
		Color(0.3, 0.7, 1.0, 0.12 * _visible_alpha),
		true
	)

	# Upward-sweeping lines
	var x_spacing := CELL_SIZE / LINE_COUNT
	for i in LINE_COUNT:
		var x := -half + x_spacing * i + x_spacing * 0.5
		var y_top := -half + _line_offsets[i]
		var alpha := 0.6 * _visible_alpha

		# Fade line near edges for a softer look
		var line_color := Color(0.5, 0.9, 1.0, alpha)
		draw_rect(
			Rect2(x - LINE_WIDTH / 2.0, y_top, LINE_WIDTH, LINE_HEIGHT),
			line_color,
			true
		)

		# Brighter core
		draw_rect(
			Rect2(x - 0.5, y_top + 2, 1.0, LINE_HEIGHT - 4),
			Color(0.8, 1.0, 1.0, alpha * 0.8),
			true
		)

	# Thin border glow
	draw_rect(
		Rect2(-half, -half, CELL_SIZE, CELL_SIZE),
		Color(0.4, 0.8, 1.0, 0.25 * _visible_alpha),
		false,
		1.5
	)
