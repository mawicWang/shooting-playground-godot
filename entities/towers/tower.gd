extends Node2D

@export var data: TowerData

## 实体标识：与储备区图标绑定，拖拽来回保持不变
var entity_id: int = -1
var source_icon: Node = null  # 指向储备区中对应的 tower_icon 节点

@onready var fire_timer: Timer = $FireTimer  # 保留节点引用，但不再驱动开火逻辑
@onready var _click_area: Area2D = $Area2D
@onready var _click_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var modules: Array = []   # Array[Module]，每个是 duplicate() 后的独立副本
var max_slots: int = 4    # 槽位上限，未来可根据稀有度随机生成

## 弹药系统：-1 = 无限，≥0 = 有限弹药
var ammo: int = 0
var _ammo_label: Label = null

## 炮塔实体 Hitbox（供子弹碰撞检测）
var _tower_body: Area2D = null

## 冷却驱动开火
var _base_cooldown: float = 1.0       # 由 TowerData.firing_rate 派生
var _cooldown_remaining: float = 0.0  # 当前剩余 CD；0 = 可发射
var _is_firing: bool = false          # 是否处于开火状态（RUNNING 阶段）

signal module_installed(module: Resource)
signal module_uninstalled(index: int)

# Rotation state
enum Direction { UP = 0, RIGHT = 1, DOWN = 2, LEFT = 3 }
var current_rotation_index: int = Direction.UP
var is_rotating: bool = false
const ROTATION_DURATION: float = 0.15

func _ready():
	add_to_group("towers")
	_create_ammo_label()
	_ammo_label.rotation = -rotation
	_apply_data()
	_setup_click_area()
	_setup_tower_body()
	set_process(false)  # 默认关闭，start_firing() 时启用

func _apply_data():
	if data:
		_base_cooldown = 1.0 / maxf(data.firing_rate, 0.01)
		if data.sprite:
			sprite.texture = data.sprite
		ammo = data.initial_ammo
	else:
		_base_cooldown = 1.0
		ammo = 3
	_update_ammo_label()

# ── 碰撞区域设置 ──────────────────────────────────────────────

## 鼠标点击旋转用 Area2D（独立于子弹碰撞层）
func _setup_click_area():
	_click_area.collision_layer = Layers.TOWER_CLICK
	_click_area.collision_mask = 0
	_click_area.monitoring = false
	_click_area.monitorable = false
	_click_area.input_event.connect(_on_area_input_event)
	call_deferred("_init_click_shape")

func _init_click_shape():
	if is_instance_valid(sprite) and sprite.texture:
		var tex_size = sprite.texture.get_size()
		var rect = RectangleShape2D.new()
		rect.size = tex_size * 0.8
		_click_shape.shape = rect
		_click_shape.position = Vector2.ZERO

## 子弹碰撞检测用 Area2D（独立层，monitorable）
func _setup_tower_body():
	_tower_body = Area2D.new()
	_tower_body.name = "TowerBody"
	_tower_body.collision_layer = Layers.TOWER_BODY
	_tower_body.collision_mask = 0
	_tower_body.monitoring = false
	_tower_body.monitorable = true
	add_child(_tower_body)
	call_deferred("_init_tower_body_shape")

func _init_tower_body_shape():
	if is_instance_valid(sprite) and sprite.texture:
		var tex_size = sprite.texture.get_size()
		var rect = RectangleShape2D.new()
		rect.size = tex_size * 0.8
		var shape_node = CollisionShape2D.new()
		shape_node.shape = rect
		shape_node.position = Vector2.ZERO
		_tower_body.add_child(shape_node)

# ── 鼠标旋转 ─────────────────────────────────────────────────

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
	if is_instance_valid(_ammo_label):
		_ammo_label.rotation = -rotation

func set_initial_direction(direction_index: int):
	current_rotation_index = direction_index % 4
	rotation_degrees = current_rotation_index * 90.0
	if is_instance_valid(_ammo_label):
		_ammo_label.rotation = -rotation

func _on_rotation_complete():
	is_rotating = false

# ── 冷却驱动开火 ──────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _is_firing:
		return
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		return
	# CD 归零：尝试发射
	if has_ammo():
		_do_fire()
	else:
		# 无弹药：CD 停在 0，关闭 process 节省性能。
		# 注意：_process 目前只做计时开火，若将来在此添加其他逻辑，
		# 需评估无弹药时是否仍需保持 process 开启。
		set_process(false)

func start_firing() -> void:
	_is_firing = true
	_cooldown_remaining = _base_cooldown
	set_process(true)

func stop_firing() -> void:
	_is_firing = false
	set_process(false)

# ── 模组系统 ─────────────────────────────────────────────────

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

# ── 弹药系统 ─────────────────────────────────────────────────

func has_ammo() -> bool:
	return ammo == -1 or ammo > 0

func consume_ammo() -> void:
	if ammo == -1:
		return
	ammo = max(0, ammo - 1)
	_update_ammo_label()

func add_ammo(amount: int) -> void:
	if ammo == -1:
		return
	ammo += amount
	_update_ammo_label()
	# CD 已归零且正在开火阶段：弹药补充后立即发射
	if _is_firing and _cooldown_remaining <= 0.0:
		_do_fire()
		set_process(true)

func _create_ammo_label() -> void:
	_ammo_label = Label.new()
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ammo_label.z_index = 2
	_ammo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ammo_label.add_theme_font_size_override("font_size", 70)
	_ammo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_ammo_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_ammo_label.add_theme_constant_override("outline_size", 8)
	_ammo_label.size = Vector2(80, 60)
	_ammo_label.position = Vector2(-40, -30)
	_ammo_label.pivot_offset = Vector2(40, 30)
	add_child(_ammo_label)

func _update_ammo_label() -> void:
	if not is_instance_valid(_ammo_label):
		return
	_ammo_label.text = "∞" if ammo == -1 else str(ammo)

# ── 被击中处理 ───────────────────────────────────────────────

## 果冻弹性受击动画
func play_hit_effect() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.75), 0.05)
	tween.tween_property(sprite, "scale", Vector2(0.85, 1.2), 0.09)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.12)

## 被子弹击中时调用（由 bullet.gd 负责调用）。触发 on_tower_hit 效果。
func on_bullet_hit(bullet_data: BulletData) -> void:
	play_hit_effect()
	for effect in bullet_data.effects:
		effect.on_tower_hit(bullet_data, self)

# ── 开火逻辑 ─────────────────────────────────────────────────

func _do_fire() -> void:
	consume_ammo()

	var bd := BulletData.new()
	bd.cooldown = _base_cooldown
	bd.attack = 1.0
	bd.transmission_chain = [self]
	bd = _apply_modules(bd)

	# 使用模块修改后的 cooldown 作为下次 CD
	_cooldown_remaining = bd.cooldown

	var parent := get_tree().get_first_node_in_group("bullet_layer")
	if not is_instance_valid(parent):
		parent = get_tree().root

	var directions: PackedVector2Array
	if data and data.barrel_directions.size() > 0:
		directions = data.barrel_directions
	else:
		directions = PackedVector2Array([Vector2(0, -1)])

	for local_dir in directions:
		BulletPool.spawn(parent, global_position, local_dir.rotated(rotation), bd)

	EventManager.notify_bullet_fired(bd, self)
