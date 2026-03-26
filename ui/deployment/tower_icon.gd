# tower_icon.gd
extends TextureRect

@export var tower_scene: PackedScene = preload("res://entities/towers/tower.tscn") # Your tower prefab

# Rotation constants are now defined in DragManager.gd

var current_drag_rotation = DragManager.ROT_UP # Stores the calculated rotation for current drag (default to UP)
var is_dragging_initiated = false # Flag to know if this icon started a drag
var drag_enabled = true # 是否允许拖拽

func set_drag_enabled(enabled: bool):
	drag_enabled = enabled
	# Visual feedback: reduce opacity when disabled
	modulate.a = 1.0 if enabled else 0.5

func _process(_delta):
	# Only calculate rotation if this icon is the current drag source, and drag is active
	if is_dragging_initiated and is_instance_valid(DragManager.get_drag_source_node()) and DragManager.get_drag_source_node() == self:
		_update_drag_rotation()

# Calculate and update the current_drag_rotation based on mouse movement relative to icon center
func _update_drag_rotation():
	var target_center = get_global_rect().position + size / 2 # Default to icon center
	
	# If a valid cell is hovered, use its center for rotation calculation
	if is_instance_valid(DragManager.get_hovered_valid_cell()):
		target_center = DragManager.get_hovered_valid_cell().get_global_center()
		# print("TowerIcon: Using HOVERED cell center for rotation.") # Debug
	else:
		# print("TowerIcon: Falling back to OWN icon center for rotation.") # Debug
		pass

	var mouse_pos = get_global_mouse_position()
	var offset = mouse_pos - target_center

	var angle = DragManager.ROT_UP # Default to UP when mouse is near center or no valid hover
	var direction_string = "UP (Default)"

	if offset.length() < 3: # If mouse is very close to center, keep default (UP)
		angle = DragManager.ROT_UP
		direction_string = "UP (Near Center)"
	elif abs(offset.x) > abs(offset.y): # Horizontal dominance
		if offset.x > 0: # Mouse is to the right
			angle = DragManager.ROT_RIGHT # Right
			direction_string = "RIGHT"
		else: # Mouse is to the left
			angle = DragManager.ROT_LEFT # Left
			direction_string = "LEFT"
	else: # Vertical dominance (or equal)
		if offset.y > 0: # Mouse is downwards (screen Y increases downwards)
			angle = DragManager.ROT_DOWN # Down
			direction_string = "DOWN"
		else: # Mouse is upwards
			angle = DragManager.ROT_UP # Up
			direction_string = "UP"
	
	current_drag_rotation = angle
	#print("TowerIcon - Drag Rotation: ", direction_string, " (", rad_to_deg(current_drag_rotation), " degrees)") # Debug log

# This method will be called by DragManager to get the current rotation
func get_current_drag_rotation() -> float:
	return current_drag_rotation # Return directly, no correction needed

func _get_drag_data(_at_position):
	if not drag_enabled:
		return null
	
	# Set flag for new drag
	is_dragging_initiated = true # Mark that this icon started a drag

	# Calculate initial rotation when drag starts
	_update_drag_rotation()

	# Inform DragManager to start custom drag preview
	# Pass self as the source node, so DragManager can query its rotation
	DragManager.start_drag(texture, self) # 'texture' is inherited from TextureRect

	# Prepare data for drop. Note: "rotation" here is initial, DragManager handles real-time updates.
	var data = {"scene": tower_scene, "icon": texture, "is_moving": false, "rotation": current_drag_rotation}
	
	return data

func _input(event):
	# Listen for global drag end event to reset is_dragging_initiated
	# and signal DragManager to stop
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging_initiated:
			is_dragging_initiated = false
			# Inform DragManager that drag has ended
			DragManager.end_drag()
