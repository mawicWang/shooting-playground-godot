extends Node2D

# 四个死亡区域（上下左右）
var zones: Array[Area2D] = []

func _ready():
	_create_zones()
	# 监听视窗大小变化
	get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _create_zones():
	# 清除旧区域
	for zone in zones:
		if is_instance_valid(zone):
			zone.queue_free()
	zones.clear()

	var viewport_size = get_viewport_rect().size
	var viewport_center = viewport_size / 2

	var margin = 50.0  # 边距大小（始终为正数）
	var extend = 100.0  # 向外延伸的距离

	# 上（在屏幕上方外面）
	_create_zone("Top",
		Vector2(viewport_center.x, -extend + margin/2),
		Vector2(viewport_size.x + extend * 2, margin))

	# 下（在屏幕下方外面）
	_create_zone("Bottom",
		Vector2(viewport_center.x, viewport_size.y + extend - margin/2),
		Vector2(viewport_size.x + extend * 2, margin))

	# 左（在屏幕左方外面）
	_create_zone("Left",
		Vector2(-extend + margin/2, viewport_center.y),
		Vector2(margin, viewport_size.y + extend * 2))

	# 右（在屏幕右方外面）
	_create_zone("Right",
		Vector2(viewport_size.x + extend - margin/2, viewport_center.y),
		Vector2(margin, viewport_size.y + extend * 2))

func _create_zone(name: String, position: Vector2, size: Vector2):
	var final_size = Vector2(abs(size.x), abs(size.y))

	var area = Area2D.new()
	area.name = "DeadZone" + name						
	area.position = position
	area.collision_layer = 8  # 墙壁/障碍物层（第4层）
	area.collision_mask = 4   # 只检测子弹层（第3层）
	area.monitoring = true    # 必须开启才能检测进入的物体
	area.monitorable = true   # 必须开启才能被检测
	
	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = final_size
	collision_shape.shape = rectangle
	
	# 添加调试可视化
	var debug_visual = _create_debug_visual(size, name)
	area.add_child(debug_visual)
	
	area.add_child(collision_shape)
	add_child(area)
	
	# 连接信号
	area.body_entered.connect(_on_body_entered)
	
	zones.append(area)

func _create_debug_visual(size: Vector2, name: String) -> Node2D:
	var visual = Node2D.new()
	visual.name = "DebugVisual"
	
	# 使用 ColorRect 作为背景
	var color_rect = ColorRect.new()
	color_rect.size = size
	color_rect.position = -size / 2  # 居中
	
	# 根据位置设置不同颜色
	var color: Color
	match name:
		"Top":
			color = Color(1, 0, 0, 0.3)  # 红色
		"Bottom":
			color = Color(0, 1, 0, 0.3)  # 绿色
		"Left":
			color = Color(0, 0, 1, 0.3)  # 蓝色
		"Right":
			color = Color(1, 1, 0, 0.3)  # 黄色
		_:
			color = Color(1, 0, 1, 0.3)  # 紫色
	
	color_rect.color = color
	visual.add_child(color_rect)
	
	# 添加边框
	var border = ReferenceRect.new()
	border.size = size
	border.position = -size / 2
	border.editor_only = false  # 在游戏时也显示
	border.border_color = color.lightened(0.3)
	border.border_width = 2.0
	visual.add_child(border)
	
	return visual

func _on_body_entered(body: Node2D):
	if body.is_in_group("bullets"):
		BulletPool.release(body)

func _on_viewport_size_changed():
	_create_zones()

func clear_all():
	# 清除所有死亡区域（用于游戏停止时）
	for zone in zones:
		if is_instance_valid(zone):
			zone.queue_free()
	zones.clear()
