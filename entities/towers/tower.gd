extends Node2D

@export var data: TowerData

@onready var fire_timer: Timer = $FireTimer
@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var firing_rate_stat: StatAttribute
var modules: Array = []   # Array[Module]，每个是 duplicate() 后的独立副本
var max_slots: int = 4    # 槽位上限，未来可根据稀有度随机生成

signal module_installed(module: Resource)
signal module_uninstalled(index: int)

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
		if not is_rotating and GameState.is_deployment():
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

func install_module(mod: Module) -> bool:
	if modules.size() >= max_slots:
		return false
	var instance: Module = mod.duplicate()
	modules.append(instance)
	instance.on_install(self)
	module_installed.emit(instance)
	return true

func uninstall_module(index: int) -> void:
	if index < 0 or index >= modules.size():
		return
	var mod: Module = modules[index]
	mod.on_uninstall(self)
	modules.remove_at(index)
	module_uninstalled.emit(index)

func get_module_count() -> int:
	return modules.size()

func _apply_modules(bullet_data: BulletData) -> BulletData:
	var bd := bullet_data
	for mod in modules:
		bd = mod.apply_effect(self, bd)
	return bd

func _on_fire_timer_timeout():
	var bd := BulletData.new()
	bd.transmission_chain = [self]
	bd = _apply_modules(bd)

	var parent := get_tree().get_first_node_in_group("bullet_layer")
	if not is_instance_valid(parent):
		parent = get_tree().root
	var forward_vector := Vector2(0, -1).rotated(rotation)
	BulletPool.spawn(parent, global_position, forward_vector, bd)
	EventManager.notify_bullet_fired(bd, self)
