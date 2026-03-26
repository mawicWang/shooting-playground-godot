extends Node2D

@export var firing_rate: float = 1.0 # Bullets per second
const BulletScene := preload("res://entities/bullets/bullet.tscn")
var bullet_scene = BulletScene
@onready var fire_timer = $FireTimer
@onready var area = $Area2D
@onready var collision_shape = $Area2D/CollisionShape2D
@onready var sprite = $Sprite2D

# Rotation state
enum Direction { UP = 0, RIGHT = 1, DOWN = 2, LEFT = 3 }
var current_rotation_index: int = Direction.UP  # 0=UP, 1=RIGHT, 2=DOWN, 3=LEFT
var is_rotating: bool = false
const ROTATION_ANGLES = [
	0.0,                              # UP (0 degrees)
	deg_to_rad(90),                   # RIGHT (90 degrees)
	deg_to_rad(180),                  # DOWN (180 degrees)
	deg_to_rad(270)                   # LEFT (270 degrees)
]
const ROTATION_DURATION: float = 0.15  # Duration of rotation animation in seconds

func _ready():
	fire_timer.wait_time = 1.0 / firing_rate
	fire_timer.timeout.connect(Callable(self, "_on_fire_timer_timeout"))
	
	# Setup Area2D for click detection
	_setup_area2d()
	
	# Connect Area2D input event
	area.input_event.connect(_on_area_input_event)

func _setup_area2d():
	# Wait for sprite texture to be loaded, then set collision shape
	# Use call_deferred to ensure sprite is ready
	call_deferred("_init_collision_shape")
	
	# Configure Area2D collision layers for proper input detection
	# Layer 1: Default objects, Mask 1: Detect default objects
	area.collision_layer = 1
	area.collision_mask = 1
	
	# Ensure Area2D can receive input events
	area.monitoring = true
	area.monitorable = true

func _init_collision_shape():
	if is_instance_valid(sprite) and sprite.texture:
		var tex_size = sprite.texture.get_size()
		var rectangle = RectangleShape2D.new()
		rectangle.size = tex_size * 0.8  # Use 80% of texture size for better feel
		collision_shape.shape = rectangle
		collision_shape.position = tex_size / 2

func _is_drag_enabled() -> bool:
	# Check if drag is enabled by looking at parent cell
	var parent = get_parent()
	if parent and parent.has_method("get_drag_enabled"):
		return parent.get_drag_enabled()
	return false

func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Allow rotation in any state (deployment mode or game running)
		if not is_rotating:
			_rotate_90_degrees()

func _rotate_90_degrees():
	is_rotating = true
	current_rotation_index = (current_rotation_index + 1) % 4
	
	# Calculate target rotation in degrees
	var start_rotation = rotation_degrees
	var target_rotation = current_rotation_index * 90.0
	
	# Ensure clockwise rotation by going through 360 instead of backwards
	# If target is 0 and start is 270, we want to go 270 -> 360, not 270 -> 0
	if target_rotation < start_rotation:
		target_rotation += 360.0
	
	# Create smooth rotation tween using custom method to ensure clockwise rotation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# Use tween_method with custom interpolation to handle the 360 wrap properly
	tween.tween_method(_set_rotation_clockwise, start_rotation, target_rotation, ROTATION_DURATION)
	tween.tween_callback(_on_rotation_complete)

# Custom setter for clockwise rotation interpolation
func _set_rotation_clockwise(degrees: float):
	# Normalize to 0-360 range for display
	rotation_degrees = fmod(degrees, 360.0)

# Set initial rotation based on placement direction (called by cell when tower is deployed)
func set_initial_direction(direction_index: int):
	current_rotation_index = direction_index % 4
	rotation_degrees = current_rotation_index * 90.0

func _on_rotation_complete():
	is_rotating = false

func start_firing():
	if is_instance_valid(fire_timer):
		fire_timer.start()

func stop_firing():
	if is_instance_valid(fire_timer):
		fire_timer.stop()

func _on_fire_timer_timeout():
	var bullet = bullet_scene.instantiate()
	# Add bullet to CanvasLayer so it renders above the grid
	var canvas_layer = get_tree().get_first_node_in_group("bullet_layer")
	if is_instance_valid(canvas_layer):
		canvas_layer.add_child(bullet)
	else:
		get_tree().root.add_child(bullet)
	bullet.global_position = global_position
	# Assuming the tower faces right by default (rotation 0), adjust as needed
	var forward_vector = Vector2(0, -1).rotated(rotation)
	bullet.set_direction(forward_vector)
