# cell.gd
extends PanelContainer

const COLOR_NORMAL = Color("#F2EAE0")       # 默认色
const COLOR_OCCUPIED = Color(0, 0.7, 0, 0.8) # 已放置炮塔的绿色
const COLOR_VALID = Color(0, 1, 0, 0.5)      # 拖拽可放置的高亮（半透明绿）
const COLOR_INVALID = Color(1, 0, 0, 0.5)    # 拖拽不可放置的高亮（半透明红）

# Rotation constants are now defined in DragManager.gd

var is_occupied = false
var is_drag_active = false
var is_being_dragged_from = false # 标记是否是当前拖拽的发源地
var drag_rotation_offset = DragManager.ROT_UP # Default rotation to UP when not hovering over a valid cell

var style_box: StyleBoxFlat
var tower_node: Node = null

func _ready():
	style_box = StyleBoxFlat.new()
	style_box.bg_color = COLOR_NORMAL
	style_box.set_border_width_all(5)
	style_box.border_color = Color.BLACK
	style_box.anti_aliasing = true
	add_theme_stylebox_override("panel", style_box)
	# Connect mouse_exited to clear hovered_valid_cell in DragManager
	mouse_exited.connect(self._on_mouse_exited)

func _on_mouse_exited():
	# Only clear if this cell was the one being hovered
	if is_instance_valid(DragManager.hovered_valid_cell) and DragManager.hovered_valid_cell == self:
		DragManager.clear_hovered_valid_cell()

func _notification(what):
	match what:
		NOTIFICATION_DRAG_BEGIN:
			is_drag_active = true
			# print("Drag BEGIN on cell ", get_meta("index")) # Debug log
		NOTIFICATION_DRAG_END:
			is_drag_active = false
			# print("Drag END on cell ", get_meta("index")) # Debug log
			# If drag ends, reset being_dragged_from flag
			if is_being_dragged_from:
				is_being_dragged_from = false
			# Restore visibility if tower was hidden and drag failed/cancelled
			if is_instance_valid(tower_node) and tower_node.visible == false:
				tower_node.visible = true
			
			# Ensure visual state is updated after drag ends
			call_deferred("_update_visuals")
			# Inform DragManager that drag has ended
			DragManager.end_drag()

func _process(_delta):
	# Update visuals continuously while dragging
	if is_drag_active:
		# Only update rotation if this cell is the current drag source, OR if it's the hovered target
		if is_being_dragged_from or (is_instance_valid(DragManager.hovered_valid_cell) and DragManager.hovered_valid_cell == self):
			_update_drag_rotation() # Calculate and update rotation
	_update_visuals() # Update background color based on state

# This method will be called by DragManager to get the current rotation
func get_current_drag_rotation() -> float:
	return drag_rotation_offset # Return directly, no correction needed

# Calculate and update the drag_rotation_offset based on mouse movement relative to cell center
func _update_drag_rotation():
	if not is_drag_active or not is_being_dragged_from:
		return

	var mouse_pos = get_global_mouse_position()
	var target_center = get_global_center() # Default to self center
	var current_source_node = DragManager._drag_source_node # Get the actual node that initiated the drag

	# Use the hovered valid cell's center if available and it's the current drag source
	if is_instance_valid(DragManager.hovered_valid_cell) and is_instance_valid(current_source_node) and current_source_node == self:
		target_center = DragManager.hovered_valid_cell.get_global_center()
		# print("Cell ", get_meta("index"), ": Using HOVERED cell center for rotation.") # Debug
	elif is_instance_valid(current_source_node) and current_source_node.has_method("get_global_center"):
		target_center = current_source_node.get_global_center() # Use the drag source's center if no valid hovered cell
		# print("Cell ", get_meta("index"), ": Using DRAG SOURCE cell center for rotation.") # Debug
	else:
		# Fallback to current cell's center if no valid source/hovered
		target_center = get_global_center()
		# print("Cell ", get_meta("index"), ": Falling back to OWN cell center for rotation.") # Debug

	var offset = mouse_pos - target_center
	
	var angle = DragManager.ROT_UP # Default to UP when mouse is near center or no valid hover
	var direction_string = "UP (Default)"

	# Quadrant-based snapping logic (dividing by diagonals)
	if offset.length() < 20: # If mouse is very close to center, keep default (UP)
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
	
	drag_rotation_offset = angle
	print( "Cell ", get_meta("index"), " - Drag Rotation: ", direction_string, " (", rad_to_deg(drag_rotation_offset), " degrees)") # Debug log

# Update the cell's background color
func _update_visuals():
	if is_drag_active:
		# When dragging, always use DragManager.hovered_valid_cell's color if valid
		if is_instance_valid(DragManager.hovered_valid_cell) and DragManager.hovered_valid_cell == self:
			# Mouse is over this cell and it's a valid drop target
			if not is_occupied or is_being_dragged_from:
				style_box.bg_color = COLOR_VALID
			else:
				style_box.bg_color = COLOR_INVALID
		else:
			# Drag is active, but mouse is not over this cell (or it's not a valid target)
			style_box.bg_color = COLOR_OCCUPIED if is_occupied else COLOR_NORMAL
	else:
		# No active drag, show normal state
		style_box.bg_color = COLOR_OCCUPIED if is_occupied else COLOR_NORMAL

# --- Receiving Drag (Drop) ---

func _can_drop_data(_at_position, data):
	var can_drop_from_store = typeof(data) == TYPE_DICTIONARY and data.has("scene") and not data.get("is_moving", false)
	var can_drop_from_grid = typeof(data) == TYPE_DICTIONARY and data.has("is_moving") and data.is_moving
	
	var is_valid_drop_target = false
	if can_drop_from_store:
		is_valid_drop_target = not is_occupied # Only allow dropping new towers into empty cells
	elif can_drop_from_grid:
		# Allow dropping if it's from us OR if the cell is empty
		is_valid_drop_target = not is_occupied or data.get("source_cell") == self
	
	# Inform DragManager if this is a valid drop target
	if is_valid_drop_target:
		DragManager.set_hovered_valid_cell(self)
	else:
		# If this is not a valid drop target, ensure it's cleared from DragManager if it was set to this cell
		if is_instance_valid(DragManager.hovered_valid_cell) and DragManager.hovered_valid_cell == self:
			DragManager.clear_hovered_valid_cell()
	
	return is_valid_drop_target

func _drop_data(_at_position, data):
	# print("Drop data received on cell ", get_meta("index"), ": ", data) # Debug log

	var tower
	var source_cell_instance = data.get("source_cell", null) # The original cell that initiated the drag
	
	var final_rotation = DragManager.ROT_UP # Initialize with default rotation (Up)

	if data.has("is_moving") and data.is_moving:
		# Moving an existing tower from a cell
		tower = data.tower_instance
		# Use the rotation calculated during THIS drag operation by the SOURCE cell
		if is_instance_valid(source_cell_instance):
			final_rotation = source_cell_instance.drag_rotation_offset
		else:
			# Fallback if source_cell is null, try DragManager or default
			final_rotation = DragManager.get_current_drag_rotation() 
			
		if is_instance_valid(source_cell_instance) and source_cell_instance != self: # Only clean up if moving from a different cell
			source_cell_instance.remove_tower_reference() # Remove reference from old cell
			if is_instance_valid(tower) and tower.get_parent() == source_cell_instance: # Ensure it's still parented by the source_cell
				source_cell_instance.remove_child(tower)
	else:
		# Dragging a new tower from the store
		var tower_scene = data["scene"]
		tower = tower_scene.instantiate()
		# Get rotation from DragManager, as it tracks the source (tower_icon) rotation
		final_rotation = DragManager.get_current_drag_rotation()
	
	# Add the tower to this cell
	add_child(tower)
	_setup_tower_visuals(tower) # Apply position, scale, and ensure visibility
	
	# Update cell state
	is_occupied = true
	tower_node = tower
	is_being_dragged_from = false # Reset flag after drop
	
	# Apply the rotation determined (no correction needed here now)
	print("  Applying final_rotation: ", rad_to_deg(final_rotation), " degrees to tower.")
	if is_instance_valid(tower) and tower.has_method("_apply_rotation"):
		tower._apply_rotation(final_rotation)
	elif is_instance_valid(tower) and tower is Node2D:
		tower.rotation_degrees = rad_to_deg(final_rotation) # Node2D uses degrees
	elif is_instance_valid(tower) and tower is Control:
		# For Control nodes, rotation might need to be handled differently if they are UI elements
		# Assuming for now towers are Node2D or have a Node2D child for rotation
		pass 

	_update_visuals() # Update cell color to occupied green

func _setup_tower_visuals(tower):
	tower.visible = true # Ensure it's visible
	if is_instance_valid(tower) and tower is Node2D:
		tower.position = size / 2
		var sprite = tower if tower is Sprite2D else tower.get_node_or_null("Sprite2D")
		if is_instance_valid(sprite) and sprite.texture:
			var tex_size = sprite.texture.get_size()
			var target_size = size * 0.8 # Use 80% of cell size
			var scale_f = min(target_size.x / tex_size.x, target_size.y / tex_size.y)
			tower.scale = Vector2(scale_f, scale_f)
	elif is_instance_valid(tower) and tower is Control:
		tower.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		tower.custom_minimum_size = size * 0.8 # Limit control size

# --- Initiating Drag (Drag) ---

func _get_drag_data(_at_position):
	if not is_occupied or not is_instance_valid(tower_node):
		return null
	
	# Mark this cell as the source of the drag
	is_being_dragged_from = true
	# Reset rotation before starting a new drag
	drag_rotation_offset = DragManager.ROT_UP # Default rotation to UP when starting drag

	# Inform DragManager to start custom drag preview
	var texture_to_drag: Texture2D = null
	if is_instance_valid(tower_node) and tower_node.has_node("Sprite2D"):
		texture_to_drag = (tower_node.get_node("Sprite2D") as Sprite2D).texture
	
	if is_instance_valid(texture_to_drag):
		DragManager.start_drag(texture_to_drag, self) # Pass self as source_node
	else:
		printerr("Cell: Could not find Sprite2D texture to start drag. Aborting drag.")
		is_being_dragged_from = false # Reset flag if drag couldn't start
		return null # Cannot start drag without texture

	var data = {
		"is_moving": true,
		"tower_instance": tower_node,
		"scene": load("res://tower.tscn"), # Load scene for compatibility if needed
		"source_cell": self,
		"rotation": drag_rotation_offset # This will be the initial rotation (UP), actual rotation is applied on drop.
	}
	
	# Temporarily hide the original tower node to simulate it being picked up
	if is_instance_valid(tower_node):
		tower_node.visible = false
	
	return data # Return data for Godot's internal drop handling

# --- Utility functions for managing cell state ---

func remove_tower_reference():
	# Called by the drop target (another cell or removal zone)
	is_occupied = false
	tower_node = null
	is_being_dragged_from = false # Reset if it was being dragged from
	drag_rotation_offset = DragManager.ROT_UP    # Reset rotation to default (UP)
	_update_visuals() # Update visuals to normal/empty state

# Helper to get the global center of the control
func get_global_center():
	return get_global_rect().position + size / 2

# --- Handling drag failure/cancellation ---
# This is called by Godot's drag-and-drop system if the drag is cancelled
# (e.g., mouse leaves window, or Esc is pressed).
# The _notification(NOTIFICATION_DRAG_END) should handle restoring visibility.
# If more specific failure handling is needed, we might need to track state.
