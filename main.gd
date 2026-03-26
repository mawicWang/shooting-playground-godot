extends Control

const MAX_WIDTH = 720.0

var game_started = false
@onready var game_content = $GameContent
@onready var start_stop_button = $GameContent/PanelContainer/StartStopButton
@onready var grid_root = $GameContent/CenterContainer/GridRoot
@onready var grid_container = $GameContent/CenterContainer/GridRoot/Grid
@onready var removal_zone = $GameContent/RemovalZonePanel

var dead_zone_manager: Node = null
var enemy_manager: Node = null
var pending_enemy_data: Array = []  # 存储预生成的敌人数据
var game_over_popup: Control = null

# 游戏状态追踪
var enemy_breached_grid: bool = false  # 是否有敌人触碰过grid

func _ready():
	# 监听窗口大小变化
	get_tree().root.size_changed.connect(_on_window_resize)
	_on_window_resize()
	
	start_stop_button.connect("pressed", Callable(self, "_on_start_stop_button_pressed"))
	update_button_text()

	# Connect to existing cells
	print("[MAIN] connecting to cells...")
	for cell in grid_container.get_children():
		if cell.has_method("tower_deployed"):
			cell.tower_deployed.connect(Callable(self, "_on_tower_deployed"))
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower):
				_on_tower_deployed(tower)
	
	# 连接grid_manager的敌人触碰信号
	var grid_manager = grid_root.get_script()
	if grid_root.has_signal("enemy_breached_grid"):
		grid_root.enemy_breached_grid.connect(_on_enemy_breached_grid)
	
	# 游戏开始前准备敌人（显示警告）
	# 使用 call_deferred 确保 grid 的 rect 已正确计算
	call_deferred("_prepare_enemy_warnings")
	
	# 创建游戏结束弹窗
	_create_game_over_popup()

# 响应式布局核心：窗口大小变化时重新计算
func _on_window_resize():
	var window_size = get_viewport_rect().size
	# 设定内容最大宽度为 720px (MAX_WIDTH)
	var target_width = min(window_size.x, MAX_WIDTH)
	
	# 计算水平边距，确保内容居中
	var margin_left = (window_size.x - target_width) / 2
	var margin_right = margin_left
	
	# 动态调整 GameContent 下各面板的 anchor 和 offset
	# 这种方式可以在不使用复杂容器嵌套的情况下实现“限宽居中”效果

	# 顶部面板
	var panel = $GameContent/PanelContainer
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.offset_left = margin_left
	panel.offset_right = -margin_right
	
	# 中间网格容器
	var center = $GameContent/CenterContainer
	center.anchor_left = 0.0
	center.anchor_right = 1.0
	center.offset_left = margin_left
	center.offset_right = -margin_right
	
	# 底部商店
	var removal = $GameContent/RemovalZonePanel
	removal.anchor_left = 0.0
	removal.anchor_right = 1.0
	removal.offset_left = margin_left
	removal.offset_right = -margin_right
	
	print("Window: ", window_size, " Content width: ", target_width, " Margins: ", margin_left)

func _on_start_stop_button_pressed():
	game_started = not game_started
	
	# 重置敌人触碰状态
	if game_started:
		enemy_breached_grid = false
	
	update_button_text()

	if game_started:
		_set_drag_enabled(false)
		_create_dead_zones()
		_create_enemy_manager()
		_start_all_towers()
	else:
		_stop_all_towers()
		_clear_all_bullets()
		_remove_dead_zones()
		_remove_enemy_manager()
		_set_drag_enabled(true)
		# 停止后重新准备警告，为下一次游戏做准备
		_prepare_enemy_warnings()

func _set_drag_enabled(enabled: bool):
	for cell in grid_container.get_children():
		if cell.has_method("set_drag_enabled"):
			cell.set_drag_enabled(enabled)
	
	if is_instance_valid(removal_zone) and removal_zone.has_method("set_drag_enabled"):
		removal_zone.set_drag_enabled(enabled)
	
	if is_instance_valid(removal_zone):
		var hbox = removal_zone.get_node_or_null("HBoxContainer")
		if is_instance_valid(hbox):
			for child in hbox.get_children():
				if child.has_method("set_drag_enabled"):
					child.set_drag_enabled(enabled)

func _start_all_towers():
	for cell in grid_container.get_children():
		if cell.has_method("get_deployed_tower"):
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower) and tower.has_method("start_firing"):
				tower.start_firing()

func _stop_all_towers():
	for cell in grid_container.get_children():
		if cell.has_method("get_deployed_tower"):
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower) and tower.has_method("stop_firing"):
				tower.stop_firing()

func _create_dead_zones():
	if is_instance_valid(dead_zone_manager):
		dead_zone_manager.queue_free()
	dead_zone_manager = Node2D.new()
	dead_zone_manager.name = "DeadZoneManager"
	dead_zone_manager.set_script(load("res://core/dead_zone_manager.gd"))
	add_child(dead_zone_manager)

func _remove_dead_zones():
	if is_instance_valid(dead_zone_manager):
		dead_zone_manager.clear_all()
		dead_zone_manager.queue_free()
		dead_zone_manager = null

func _prepare_enemy_warnings():
	print("[MAIN] Preparing enemy warnings...")
	
	# 检查 grid 是否就绪
	if not is_instance_valid(grid_container):
		push_error("[MAIN] Grid container not valid!")
		return
	
	var grid_rect = grid_container.get_global_rect()
	print("[MAIN] Grid rect: ", grid_rect)
	
	if grid_rect.size == Vector2.ZERO:
		push_error("[MAIN] Grid rect size is zero, retrying...")
		# 如果 rect 还没准备好，延迟再试
		await get_tree().create_timer(0.1).timeout
		call_deferred("_prepare_enemy_warnings")
		return
	
	# 创建敌人管理器用于准备警告
	if is_instance_valid(enemy_manager):
		enemy_manager.queue_free()
	enemy_manager = Node2D.new()
	enemy_manager.name = "EnemyManager"
	enemy_manager.set_script(load("res://entities/enemies/enemy_manager.gd"))
	add_child(enemy_manager)
	
	# 设置网格信息
	enemy_manager.set_grid_info(grid_rect, 80.0)
	
	# 准备敌人（显示警告，但不生成敌人）
	pending_enemy_data = enemy_manager.prepare_enemies()
	print("[MAIN] Enemy warnings prepared: ", pending_enemy_data.size())

func _create_enemy_manager():
	# 游戏开始时，创建管理器并生成敌人
	if is_instance_valid(enemy_manager):
		enemy_manager.queue_free()
	
	enemy_manager = Node2D.new()
	enemy_manager.name = "EnemyManager"
	enemy_manager.set_script(load("res://entities/enemies/enemy_manager.gd"))
	add_child(enemy_manager)
	
	var grid_rect = grid_container.get_global_rect()
	enemy_manager.set_grid_info(grid_rect, 80.0)
	
	# 使用预存的数据生成敌人
	enemy_manager.spawn_enemies_from_data(pending_enemy_data)
	
	# 连接敌人管理器的信号
	enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)

func _remove_enemy_manager():
	if is_instance_valid(enemy_manager):
		enemy_manager.clear_enemies()
		enemy_manager.queue_free()
		enemy_manager = null

func _create_game_over_popup():
	if is_instance_valid(game_over_popup):
		game_over_popup.queue_free()
	game_over_popup = load("res://ui/popups/game_over_popup.tscn").instantiate()
	game_over_popup.popup_closed.connect(_on_game_over_popup_closed)
	add_child(game_over_popup)

func _on_game_over_popup_closed():
	# 弹窗关闭后，完全重置游戏状态
	print("[MAIN] Popup closed, resetting game state...")
	
	# 确保游戏停止
	game_started = false
	update_button_text()
	
	# 清理所有游戏对象
	_stop_all_towers()
	_clear_all_bullets()
	_remove_dead_zones()
	_remove_enemy_manager()
	
	# 清理敌人数据
	pending_enemy_data.clear()
	enemy_breached_grid = false
	
	# 重置游戏内容位置（防止屏幕抖动残留）
	_reset_game_content_position()
	
	# 启用拖拽
	_set_drag_enabled(true)
	
	# 重新准备新的警告（生成新的随机敌人位置）
	call_deferred("_prepare_enemy_warnings")

func _reset_game_content_position():
	"""重置游戏内容位置，取消任何正在进行的抖动"""
	# 停止所有正在进行的tween
	var tree = get_tree()
	if tree:
		# 杀死所有tween
		tree.create_tween().kill()
	
	# 重置位置
	game_content.position = Vector2.ZERO
	print("[MAIN] Game content position reset")

func _clear_all_bullets():
	var bullets_to_remove = []
	
	var find_bullets = func(node, self_func):
		for child in node.get_children():
			if child.get_script() != null:
				var script_path = child.get_script().resource_path
				if script_path.ends_with("bullet.gd"):
					bullets_to_remove.append(child)
			elif child.name.to_lower().begins_with("bullet"):
				bullets_to_remove.append(child)
			self_func.call(child, self_func)
	
	find_bullets.call(get_tree().root, find_bullets)
	
	print("Found ", bullets_to_remove.size(), " bullets to clear")
	
	for bullet in bullets_to_remove:
		if is_instance_valid(bullet):
			bullet.queue_free()
	
	print("Cleared all bullets")

func _on_tower_deployed(tower_instance):
	if is_instance_valid(tower_instance) and tower_instance.has_method("start_firing") and tower_instance.has_method("stop_firing"):
		if game_started:
			tower_instance.start_firing()
		else:
			tower_instance.stop_firing()

var is_screen_shaking: bool = false  # 屏幕是否正在抖动

func _on_enemy_breached_grid():
	"""敌人触碰grid边界"""
	print("[MAIN] Enemy breached grid!")
	enemy_breached_grid = true
	
	# 触发屏幕抖动
	if not is_screen_shaking:
		is_screen_shaking = true
		var tween = _trigger_screen_shake()
		if tween:
			await tween.finished
		is_screen_shaking = false

func _trigger_screen_shake() -> Tween:
	"""触发屏幕抖动"""
	var game_content = $GameContent
	var original_position = game_content.position
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	for i in range(8):
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		tween.tween_property(game_content, "position", original_position + offset, 0.05)
	
	tween.tween_property(game_content, "position", original_position, 0.05)
	return tween

func _on_all_enemies_defeated():
	"""所有敌人被消灭，检查游戏结果"""
	print("[MAIN] All enemies defeated! Breached: ", enemy_breached_grid)
	
	# 等待屏幕抖动完成
	while is_screen_shaking:
		await get_tree().process_frame
	
	if not game_started:
		return
	
	if enemy_breached_grid:
		# 有敌人触碰过grid - 失败
		game_over_popup.show_defeat()
	else:
		# 完美防守 - 胜利
		game_over_popup.show_victory()
	
	# 停止游戏
	_stop_all_towers()
	_clear_all_bullets()
	_remove_dead_zones()
	game_started = false
	update_button_text()

func update_button_text():
	if game_started:
		start_stop_button.text = "停止"
	else:
		start_stop_button.text = "开始"
	
	# Create base StyleBoxFlat with 2px black border
	var style_box = StyleBoxFlat.new()
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.BLACK
	
	if game_started:
		# Red background when game is running
		style_box.bg_color = Color(0.9, 0.2, 0.2, 1.0)
	else:
		# Green background when game is stopped
		style_box.bg_color = Color(0.2, 0.8, 0.2, 1.0)
	
	# Apply normal style
	start_stop_button.add_theme_stylebox_override("normal", style_box)
	
	# Create hover style (lightened version)
	var hover_style = style_box.duplicate()
	hover_style.bg_color = style_box.bg_color.lightened(0.1)
	start_stop_button.add_theme_stylebox_override("hover", hover_style)
	
	# Create pressed style (darkened version)
	var pressed_style = style_box.duplicate()
	pressed_style.bg_color = style_box.bg_color.darkened(0.1)
	start_stop_button.add_theme_stylebox_override("pressed", pressed_style)
