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

func _ready():
	# 监听窗口大小变化
	get_tree().root.size_changed.connect(_on_window_resize)
	_on_window_resize()
	
	start_stop_button.connect("pressed", Callable(self, "_on_start_stop_button_pressed"))
	update_button_text()

	# Connect to existing cells
	await grid_root.ready
	for cell in grid_container.get_children():
		if cell.has_method("tower_deployed"):
			cell.tower_deployed.connect(Callable(self, "_on_tower_deployed"))
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower):
				_on_tower_deployed(tower)

func _on_window_resize():
	var window_size = get_viewport_rect().size
	var target_width = min(window_size.x, MAX_WIDTH)
	
	# 计算水平边距
	var margin_left = (window_size.x - target_width) / 2
	var margin_right = margin_left
	
	# 调整内部 UI 元素的边距来模拟限宽效果
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
	dead_zone_manager.set_script(load("res://dead_zone_manager.gd"))
	add_child(dead_zone_manager)

func _remove_dead_zones():
	if is_instance_valid(dead_zone_manager):
		dead_zone_manager.clear_all()
		dead_zone_manager.queue_free()
		dead_zone_manager = null

func _create_enemy_manager():
	if is_instance_valid(enemy_manager):
		enemy_manager.queue_free()
	enemy_manager = Node2D.new()
	enemy_manager.name = "EnemyManager"
	enemy_manager.set_script(load("res://enemy_manager.gd"))
	add_child(enemy_manager)
	
	# 设置网格信息
	var grid_rect = grid_container.get_global_rect()
	enemy_manager.set_grid_info(grid_rect, 80.0)
	
	# 生成敌人
	enemy_manager.spawn_enemies()

func _remove_enemy_manager():
	if is_instance_valid(enemy_manager):
		enemy_manager.clear_enemies()
		enemy_manager.queue_free()
		enemy_manager = null

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
