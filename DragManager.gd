extends Node

# Rotation constants (for Godot's CCW rotation, where 0 is visually UP)
const PI = 3.14159
const ROT_UP = 0.0          # Asset default direction (0 degrees)
const ROT_RIGHT = PI / 2.0 # Rotate CW 90 degrees from UP
const ROT_DOWN = PI         # Rotate 180 degrees from UP
const ROT_LEFT = -PI / 2.0   # Rotate CCW 90 degrees from UP

var _drag_preview_node: Control = null
var _drag_texture_rect: TextureRect = null
var _drag_source_node: Node = null # Reference to the node that initiated the drag (cell or tower_icon)
var hovered_valid_cell: Node = null # Reference to the currently hovered valid cell
var last_known_drag_rotation = ROT_UP # Stores the last calculated rotation

func _ready():
	set_process(false) # Start with process disabled

func _process(_delta):
	if _drag_preview_node and _drag_source_node:
		# Update position of the custom drag preview
		_drag_preview_node.global_position = get_viewport().get_mouse_position() - Vector2(30, 30) # Offset to center
		
		# Get rotation from the source node
		var current_rotation = ROT_UP # Default if source is invalid
		# Check if source_node is valid AND has the method
		if is_instance_valid(_drag_source_node) and _drag_source_node.has_method("get_current_drag_rotation"):
			current_rotation = _drag_source_node.get_current_drag_rotation()
			# print("DragManager: Getting rotation from ", _drag_source_node.name, ": ", rad_to_deg(current_rotation), " degrees") # Debug log
		# else: current_rotation remains ROT_UP

		# Apply rotation to the preview texture and store it
		if _drag_texture_rect:
			_drag_texture_rect.rotation = current_rotation # Rotation in radians
			last_known_drag_rotation = current_rotation # Cache the last known rotation

func start_drag(texture: Texture2D, source_node: Node):
	# Clear any existing preview and reset state
	end_drag() # Ensure any previous drag is ended cleanly

	if not texture or not is_instance_valid(source_node):
		printerr("DragManager: Cannot start drag with null texture or invalid source_node.")
		return

	# print("DragManager: Starting drag from node: ", source_node.name) # Debug log

	# Create the custom drag preview node
	_drag_preview_node = Control.new()
	_drag_preview_node.name = "CustomDragPreview"
	
	_drag_texture_rect = TextureRect.new()
	_drag_texture_rect.texture = texture
	_drag_preview_node.add_child(_drag_texture_rect) # Add texture to the preview container

	# Set properties for the TextureRect preview
	_drag_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_drag_texture_rect.custom_minimum_size = Vector2(60, 60)
	_drag_texture_rect.modulate.a = 0.6
	_drag_texture_rect.pivot_offset = Vector2(30,30) # Set pivot for rotation

	# Add to the root of the scene tree (Viewport) to float above all UI
	get_viewport().add_child(_drag_preview_node)
	
	_drag_source_node = source_node # Store the node that initiated the drag
	set_process(true) # Enable _process to update preview position and rotation

func end_drag():
	if _drag_preview_node:
		_drag_preview_node.queue_free()
		_drag_preview_node = null
	if _drag_texture_rect:
		_drag_texture_rect = null # Clear texture rect reference

	_drag_source_node = null # IMPORTANT: Clear source node reference
	hovered_valid_cell = null # Clear hovered cell reference
	set_process(false) # Disable _process
	# print("DragManager: Drag ended.") # Debug log

# Public getter for the current drag rotation (delegates to source_node)
func get_current_drag_rotation() -> float:
	# Return the last known rotation, as _drag_source_node might be nullified by the time drop occurs
	return last_known_drag_rotation

# NEW: Set the currently hovered valid cell
func set_hovered_valid_cell(cell: Node):
	hovered_valid_cell = cell

# NEW: Clear the currently hovered valid cell
func clear_hovered_valid_cell():
	hovered_valid_cell = null
