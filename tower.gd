extends Node2D

@export var firing_rate: float = 1.0 # Bullets per second
var bullet_scene = preload("res://bullet.tscn")
@onready var fire_timer = $FireTimer

func _ready():
	fire_timer.wait_time = 1.0 / firing_rate
	fire_timer.timeout.connect(Callable(self, "_on_fire_timer_timeout"))

func start_firing():
	if is_instance_valid(fire_timer):
		fire_timer.start()

func stop_firing():
	if is_instance_valid(fire_timer):
		fire_timer.stop()

func _on_fire_timer_timeout():
	var bullet = bullet_scene.instantiate()
	# Add bullet to CanvasLayer so it renders above the grid
	var canvas_layer = get_node_or_null("/root/main/CanvasLayer")
	if is_instance_valid(canvas_layer):
		canvas_layer.add_child(bullet)
	else:
		get_tree().root.add_child(bullet)
	bullet.global_position = global_position
	# Assuming the tower faces right by default (rotation 0), adjust as needed
	var forward_vector = Vector2(0, -1).rotated(rotation)
	bullet.set_direction(forward_vector)
