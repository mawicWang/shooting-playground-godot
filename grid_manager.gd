extends Control

const CELL_COLOR = Color("#F2EAE0")
var cell_script = preload("res://cell.gd") # 提前加载脚本

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
	for i in range(25):
		var cell = PanelContainer.new()
		cell.clip_contents = true # 启用裁剪，防止内容溢出
		cell.set_script(cell_script) # 重要：给生成的节点挂载脚本
		cell.custom_minimum_size = Vector2(80, 80)
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		cell.set_meta("index", i)
		
		grid.add_child(cell)
