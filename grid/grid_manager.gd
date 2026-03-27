extends Control

signal enemy_breached_grid()  # 敌人触碰边界cell信号

const CELL_COLOR = Color("#F2EAE0")
var cell_script = preload("res://grid/cell.gd") # 提前加载脚本

func _ready():
	# 获取 GridContainer
	var grid = $Grid
	if not grid:
		return
	
	# 配置网格列数
	grid.columns = 5
	
	grid.layout_mode = 1
	grid.anchors_preset = 8  # center
	
	call_deferred("_center_grid")

func _center_grid():
	var grid = $Grid
	if grid:
		# 计算网格的最小宽度（25个单元格，每个80px，加上GridContainer的间距）
		# 等待一帧确保尺寸正确计算
		await get_tree().process_frame
		var grid_size = grid.get_combined_minimum_size()
		grid.position = Vector2(-grid_size.x / 2, 0)
	
	# 创建 5x5 = 25 个单元格
	var grid_size_2d = 5
	for i in range(25):
		var cell = PanelContainer.new()
		cell.clip_contents = true # 启用裁剪，防止内容溢出
		cell.set_script(cell_script) # 重要：给生成的节点挂载脚本
		cell.custom_minimum_size = Vector2(80, 80)
		# Note: mouse_filter is set to MOUSE_FILTER_STOP in cell.gd's _ready()
		cell.set_meta("index", i)
		
		# 计算行列位置
		var row = i / grid_size_2d
		var col = i % grid_size_2d
		
		# 判断是否是最外圈的cell
		var is_border = (row == 0 or row == grid_size_2d - 1 or col == 0 or col == grid_size_2d - 1)
		
		if is_border:
			cell.set_meta("is_border_cell", true)
			# 添加边界hitbox
			_add_border_hitbox(cell)
		
		grid.add_child(cell)

func _add_border_hitbox(cell: Control):
	"""为边界cell添加Area2D hitbox，用于检测敌人碰撞"""
	var hitbox = Area2D.new()
	hitbox.name = "BorderHitbox"
	hitbox.collision_layer = Layers.GRID_BORDER
	hitbox.collision_mask = Layers.ENEMY
	hitbox.monitoring = true
	hitbox.monitorable = true
	
	# 将hitbox位置设置为cell中心（相对于cell的左上角）
	var cell_size = cell.custom_minimum_size
	hitbox.position = cell_size / 2  # (40, 40) - cell中心
	
	# 创建碰撞形状，覆盖整个cell
	var collision_shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = cell_size
	collision_shape.shape = rectangle
	# collision_shape位置保持(0,0)，因为hitbox已经在cell中心了
	
	hitbox.add_child(collision_shape)
	cell.add_child(hitbox)
	
	# 连接信号
	hitbox.area_entered.connect(_on_border_hitbox_area_entered.bind(cell))

func _on_border_hitbox_area_entered(area: Area2D, _cell: Control):
	"""当敌人触碰边界cell时触发"""
	var parent = area.get_parent()
	if is_instance_valid(parent) and parent.is_in_group("enemies"):
		parent.destroy()
		enemy_breached_grid.emit()

