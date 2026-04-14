extends Node2D

# 四个死亡区域（上下左右）
var zones: Array[Area2D] = []

var _grid_rect: Rect2 = Rect2()
var _battlefield_cells: int = 12
var _cell_size: float = 80.0

## 设置战场参数（由 GameLoopManager 调用）
func setup(grid_rect: Rect2, cell_size: float, battlefield_cells: int) -> void:
	_grid_rect = grid_rect
	_cell_size = cell_size
	_battlefield_cells = battlefield_cells

func _ready():
	if _grid_rect.size != Vector2.ZERO:
		_create_zones()

func create_zones_from_setup() -> void:
	_create_zones()

func _create_zones():
	for zone in zones:
		if is_instance_valid(zone):
			zone.queue_free()
	zones.clear()

	# 计算战场范围（以 Grid 中心为基准）
	var grid_center := _grid_rect.get_center()
	var bf_half := _battlefield_cells * _cell_size / 2.0
	var margin := 50.0

	# 战场边界坐标
	var bf_top := grid_center.y - bf_half
	var bf_bottom := grid_center.y + bf_half
	var bf_left := grid_center.x - bf_half
	var bf_right := grid_center.x + bf_half
	var bf_width := bf_right - bf_left
	var bf_height := bf_bottom - bf_top

	# 上（在战场顶部外侧）
	_create_zone("Top",
		Vector2(grid_center.x, bf_top - margin / 2),
		Vector2(bf_width + margin * 2, margin))

	# 下（在战场底部外侧）
	_create_zone("Bottom",
		Vector2(grid_center.x, bf_bottom + margin / 2),
		Vector2(bf_width + margin * 2, margin))

	# 左（在战场左侧外侧）
	_create_zone("Left",
		Vector2(bf_left - margin / 2, grid_center.y),
		Vector2(margin, bf_height + margin * 2))

	# 右（在战场右侧外侧）
	_create_zone("Right",
		Vector2(bf_right + margin / 2, grid_center.y),
		Vector2(margin, bf_height + margin * 2))

func _create_zone(zone_name: String, pos: Vector2, size: Vector2):
	var final_size = Vector2(abs(size.x), abs(size.y))

	var area = Area2D.new()
	area.name = "DeadZone" + zone_name
	area.collision_layer = Layers.DEAD_ZONE
	area.collision_mask = Layers.BULLET
	area.monitoring = true
	area.monitorable = true

	var collision_shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = final_size
	collision_shape.shape = rectangle

	var debug_visual = _create_debug_visual(size, zone_name)
	area.add_child(debug_visual)

	area.add_child(collision_shape)
	add_child(area)
	area.global_position = pos

	area.area_entered.connect(_on_area_entered)

	zones.append(area)

func _create_debug_visual(size: Vector2, zone_name: String) -> Node2D:
	var visual = Node2D.new()
	visual.name = "DebugVisual"

	var color_rect = ColorRect.new()
	color_rect.size = size
	color_rect.position = -size / 2

	var color: Color
	match zone_name:
		"Top":
			color = Color(1, 0, 0, 0.3)
		"Bottom":
			color = Color(0, 1, 0, 0.3)
		"Left":
			color = Color(0, 0, 1, 0.3)
		"Right":
			color = Color(1, 1, 0, 0.3)
		_:
			color = Color(1, 0, 1, 0.3)

	color_rect.color = color
	visual.add_child(color_rect)

	var border = ReferenceRect.new()
	border.size = size
	border.position = -size / 2
	border.editor_only = false
	border.border_color = color.lightened(0.3)
	border.border_width = 2.0
	visual.add_child(border)

	return visual

func _on_area_entered(area: Area2D):
	var bullet = area.get_parent()
	if is_instance_valid(bullet) and bullet.is_in_group("bullets"):
		BulletPool.release(bullet)

func clear_all():
	for zone in zones:
		if is_instance_valid(zone):
			zone.queue_free()
	zones.clear()
