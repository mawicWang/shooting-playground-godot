extends Node2D

var game_started = false
@onready var start_stop_button = $CanvasLayer/PanelContainer/StartStopButton
@onready var grid_root = $CanvasLayer/CenterContainer/GridRoot
@onready var grid_container = $CanvasLayer/CenterContainer/GridRoot/Grid
@onready var canvas_layer = $CanvasLayer

var dead_zone_manager: Node = null

func _ready():
	start_stop_button.connect("pressed", Callable(self, "_on_start_stop_button_pressed"))
	update_button_text()

	# Connect to existing cells
	await grid_root.ready # Ensure grid_root is ready and populated
	for cell in grid_container.get_children():
		if cell.has_method("tower_deployed"):
			cell.tower_deployed.connect(Callable(self, "_on_tower_deployed"))
			# If a tower is already deployed, set its initial state
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower):
				_on_tower_deployed(tower)

func _on_start_stop_button_pressed():
	game_started = not game_started
	update_button_text()

	if game_started:
		# Start game: disable dragging, start firing, create dead zones
		_set_drag_enabled(false)
		_create_dead_zones()
		_start_all_towers()
	else:
		# Stop game: stop firing, clear bullets, remove dead zones, enable dragging
		_stop_all_towers()
		_clear_all_bullets()
		_remove_dead_zones()
		_set_drag_enabled(true)

func _set_drag_enabled(enabled: bool):
	# Disable/enable all cells
	for cell in grid_container.get_children():
		if cell.has_method("set_drag_enabled"):
			cell.set_drag_enabled(enabled)
	
	# Disable/enable removal zone
	var removal_zone = canvas_layer.get_node_or_null("RemovalZonePanel")
	if is_instance_valid(removal_zone) and removal_zone.has_method("set_drag_enabled"):
		removal_zone.set_drag_enabled(enabled)
	
	# Disable/enable tower icons in shop
	if is_instance_valid(removal_zone):
		var hbox = removal_zone.get_node_or_null("HBoxContainer")
		if is_instance_valid(hbox):
			for child in hbox.get_children():
				if child.has_method("set_drag_enabled"):
					child.set_drag_enabled(enabled)

func _start_all_towers():
	var cell_count = 0
	var tower_count = 0
	for cell in grid_container.get_children():
		cell_count += 1
		if cell.has_method("get_deployed_tower"):
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower) and tower.has_method("start_firing"):
				tower_count += 1
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
	# Find and remove all bullets in the scene by checking their script
	var bullets_to_remove = []
	
	# Recursive function to find all bullets
	var find_bullets = func(node, self_func):
		for child in node.get_children():
			# Check if it's a bullet by script name or type
			if child.get_script() != null:
				var script_path = child.get_script().resource_path
				if script_path.ends_with("bullet.gd"):
					bullets_to_remove.append(child)
			# Also check by name (case insensitive)
			elif child.name.to_lower().begins_with("bullet"):
				bullets_to_remove.append(child)
			# Recursively check children
			self_func.call(child, self_func)
	
	# Search from root
	find_bullets.call(get_tree().root, find_bullets)
	
	print("Found ", bullets_to_remove.size(), " bullets to clear")
	
	for bullet in bullets_to_remove:
		if is_instance_valid(bullet):
			bullet.queue_free()
	
	print("Cleared all bullets")

func _on_tower_deployed(tower_instance):
	# When a new tower is deployed, set its firing state immediately
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
