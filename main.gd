extends Control

const MAX_WIDTH = 720.0

var game_started = false
@onready var game_content = $GameContent
@onready var start_stop_button = $GameContent/CanvasLayer/PanelContainer/StartStopButton
@onready var grid_root = $GameContent/CanvasLayer/CenterContainer/GridRoot
@onready var grid_container = $GameContent/CanvasLayer/CenterContainer/GridRoot/Grid
@onready var canvas_layer = $GameContent/CanvasLayer

var dead_zone_manager: Node = null

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
	var target_height = window_size.y
	
	# 设置 GameContent 大小（白色背景区域）
	game_content.size = Vector2(target_width, target_height)
	
	

func _on_start_stop_button_pressed():
	game_started = not game_started
	update_button_text()

	if game_started:
		_set_drag_enabled(false)
		_create_dead_zones()
		_start_all_towers()
	else:
		_stop_all_towers()
		_clear_all_bullets()
		_remove_dead_zones()
		_set_drag_enabled(true)

func _set_drag_enabled(enabled: bool):
	for cell in grid_container.get_children():
		if cell.has_method("set_drag_enabled"):
			cell.set_drag_enabled(enabled)
	
	var removal_zone = canvas_layer.get_node_or_null("RemovalZonePanel")
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
