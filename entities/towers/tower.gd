extends Node2D

@export var data: TowerData

const BulletScene := preload("res://entities/bullets/bullet.tscn")
@onready var fire_timer: Timer = $FireTimer
@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var firing_rate_stat: StatAttribute

# Rotation state
enum Direction { UP = 0, RIGHT = 1, DOWN = 2, LEFT = 3 }
var current_rotation_index: int = Direction.UP
var is_rotating: bool = false
const ROTATION_DURATION: float = 0.15

func _ready():
	_apply_data()
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	_setup_area2d()
	area.input_event.connect(_on_area_input_event)

func _apply_data():
	if data:
		firing_rate_stat = StatAttribute.new(data.firing_rate)
		if data.sprite:
			sprite.texture = data.sprite
	else:
		firing_rate_stat = StatAttribute.new(1.0)
	fire_timer.wait_time = 1.0 / firing_rate_stat.get_value()

func _setup_area2d():
	call_deferred("_init_collision_shape")
	area.collision_layer = 1
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = true

func _init_collision_shape():
	if is_instance_valid(sprite) and sprite.texture:
		var tex_size = sprite.texture.get_size()
		var rectangle = RectangleShape2D.new()
		rectangle.size = tex_size * 0.8
		collision_shape.shape = rectangle
		collision_shape.position = tex_size / 2

func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_rotating:
			_rotate_90_degrees()

func _rotate_90_degrees():
	is_rotating = true
	current_rotation_index = (current_rotation_index + 1) % 4

	var start_rotation := rotation_degrees
	var target_rotation := current_rotation_index * 90.0

	if target_rotation < start_rotation:
		target_rotation += 360.0

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_rotation_clockwise, start_rotation, target_rotation, ROTATION_DURATION)
	tween.tween_callback(_on_rotation_complete)

func _set_rotation_clockwise(degrees: float):
	rotation_degrees = fmod(degrees, 360.0)

func set_initial_direction(direction_index: int):
	current_rotation_index = direction_index % 4
	rotation_degrees = current_rotation_index * 90.0

func _on_rotation_complete():
	is_rotating = false

func start_firing():
	if is_instance_valid(fire_timer):
		# Refresh wait_time in case stat was modified
		fire_timer.wait_time = 1.0 / firing_rate_stat.get_value()
		fire_timer.start()

func stop_firing():
	if is_instance_valid(fire_timer):
		fire_timer.stop()

func _on_fire_timer_timeout():
	var bullet = BulletScene.instantiate()
	var canvas_layer = get_tree().get_first_node_in_group("bullet_layer")
	if is_instance_valid(canvas_layer):
		canvas_layer.add_child(bullet)
	else:
		get_tree().root.add_child(bullet)
	bullet.global_position = global_position
	var forward_vector = Vector2(0, -1).rotated(rotation)
	bullet.set_direction(forward_vector)
