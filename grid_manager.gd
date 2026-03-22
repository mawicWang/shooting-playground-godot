extends Control

const CELL_COLOR = Color("#F2EAE0")

func _ready():
	print("GridManager ready!")
	
	# 获取 GridContainer
	var grid = $Grid
	if not grid:
		print("Error: GridContainer not found!")
		return
	
	print("GridContainer found!")
	
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
	for i in range(25):
		var cell = PanelContainer.new()
		cell.custom_minimum_size = Vector2(80, 80)
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		cell.set_meta("index", i)
		
		# 集中配置样式
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = CELL_COLOR
		style_box.set_border_width_all(5)
		style_box.border_color = Color.BLACK
		# 如果想要圆角，开启下面这行
		# style_box.set_corner_radius_all(4) 
		
		# 抗锯齿，让边框更平滑
		style_box.anti_aliasing = true 
		
		cell.add_theme_stylebox_override("panel", style_box)
		
		# 信号连接（确保 _on_cell_input 接收两个参数：event 和 index）
		cell.gui_input.connect(_on_cell_input.bind(i))
		
		grid.add_child(cell)
		print("Added cell ", i)


	print("Grid setup complete! Total cells: ", grid.get_child_count())

func _on_cell_input(event, cell_index):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("click ", cell_index)
		var cell = $Grid.get_child(cell_index) as PanelContainer
		# 切换单元格颜色（模拟射击效果）
		if cell:
			var new_color = Color.RED  # 红色表示击中
			# 同步更新 stylebox 的背景色
			var style_box = cell.get_theme_stylebox("panel") as StyleBoxFlat
			print(style_box)
			if style_box:
				style_box.bg_color = new_color
			print("Cell %d clicked!" % cell_index)
			# 0.2秒后恢复
			await get_tree().create_timer(0.2).timeout
			if style_box:
				style_box.bg_color = CELL_COLOR
