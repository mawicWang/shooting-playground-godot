extends Node2D

const CooldownOverlayScript = preload("res://entities/towers/cooldown_overlay.gd")

@export var data: TowerData

## 实体标识：与储备区图标绑定，拖拽来回保持不变
var entity_id: int = -1
var source_icon: Node = null  # 指向储备区中对应的 tower_icon 节点

@onready var fire_timer: Timer = $FireTimer  # 保留节点引用，但不再驱动开火逻辑
@onready var _click_area: Area2D = $Area2D
@onready var _click_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var _tower_visual: Node2D = $TowerVisual
@onready var sprite: Sprite2D = $TowerVisual/Sprite2D

var modules: Array = []   # Array[Module]，每个是 duplicate() 后的独立副本
var max_slots: int = 4    # 槽位上限，未来可根据稀有度随机生成

var fire_effects: Array[FireEffect] = []
var tower_effects: Array[TowerEffect] = []
var bullet_effects: Array[BulletEffect] = []

## 弹药系统：-1 = 无限弹药；0 = 有限弹药（由 ammo_queue 管理）
var ammo: int = 0
var ammo_queue: Array = []   # Array[AmmoItem]
var ammo_cursor: int = 0
var bullet_effect_max_chain: int = 1   # 本 tower 的 bullet_effects 在链上最多触发次数
var tower_effect_max_chain: int = 1    # 本 tower 的 tower_effects 在链上最多触发次数
var _ammo_label: Label = null

## 炮塔实体 Hitbox（供子弹碰撞检测）
var _tower_body: Area2D = null

## 炮塔属性（StatAttribute，供模块通过 StatModifier 修改）
var _cd_stat: StatAttribute
var _bullet_speed_stat: StatAttribute
var _bullet_attack_stat: StatAttribute
var _ammo_extra_stat: StatAttribute

## 冷却驱动开火
var _cooldown_remaining: float = 0.0    # 当前剩余 CD；0 = 可发射
var _current_full_cooldown: float = 1.0 # 本次 CD 总时长（用于进度比例计算）
var _is_firing: bool = false            # 是否处于开火状态（RUNNING 阶段）
var _cd_overlay: CooldownOverlay = null # WoW 风格 CD 遮罩

# Speed boost state
var _boost_time_remaining: float = 0.0
const _boost_k: float = 2.0
var _boost_overlay: Node2D  # BoostOverlay node (created in _ready)

# Flying / anti-air flags (set by modules)
var is_flying: bool = false
var has_anti_air: bool = false

# CD countdown label
var _cd_label: Label

signal module_installed(module: Resource)
signal module_uninstalled(index: int)

# Rotation state
enum Direction { UP = 0, RIGHT = 1, DOWN = 2, LEFT = 3 }
var current_rotation_index: int = Direction.UP
var is_rotating: bool = false
var _hit_tween: Tween = null
const ROTATION_DURATION: float = 0.15

func _ready():
	add_to_group("towers")
	_create_ammo_label()
	_apply_data()
	_setup_click_area()
	_setup_tower_body()
	_create_cd_overlay()
	_create_cd_label()
	var overlay_scene = load("res://entities/towers/boost_overlay.tscn")
	if overlay_scene:
		_boost_overlay = overlay_scene.instantiate()
		add_child(_boost_overlay)
		_boost_overlay.set_tower(self)
	set_process(false)  # 默认关闭，start_firing() 时启用

func _apply_data():
	ammo_queue.clear()
	ammo_cursor = 0
	var base_cd := 1.0 / maxf(data.firing_rate if data else 1.0, 0.01)
	_cd_stat           = StatAttribute.new(base_cd)
	_bullet_speed_stat = StatAttribute.new(200.0)
	_bullet_attack_stat = StatAttribute.new(1.0)
	_ammo_extra_stat   = StatAttribute.new(0.0)
	if data:
		if data.sprite:
			sprite.texture = data.sprite
		ammo = data.initial_ammo
	else:
		ammo = 3
	# 有限弹药：初始化队列（无限弹药跳过，_do_fire 会即时创建空 AmmoItem）
	if ammo >= 0:
		for _i in range(ammo):
			ammo_queue.append(AmmoItem.new())
		ammo = 0  # 有限弹药由队列管理，ammo 只保留 -1（无限）标志位
	_update_ammo_label()

func _get_effective_cd() -> float:
	return maxf(0.1, _cd_stat.get_value())

func get_stat(stat: TowerStatModifierRes.Stat) -> StatAttribute:
	match stat:
		TowerStatModifierRes.Stat.CD:            return _cd_stat
		TowerStatModifierRes.Stat.BULLET_SPEED:  return _bullet_speed_stat
		TowerStatModifierRes.Stat.BULLET_ATTACK: return _bullet_attack_stat
		TowerStatModifierRes.Stat.AMMO_EXTRA:    return _ammo_extra_stat
	push_error("Tower.get_stat: unknown stat %d" % stat)
	return null

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

	var start_rotation := _tower_visual.rotation_degrees
	var target_rotation := current_rotation_index * 90.0

	if target_rotation < start_rotation:
		target_rotation += 360.0

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_rotation_clockwise, start_rotation, target_rotation, ROTATION_DURATION)
	tween.tween_callback(_on_rotation_complete)

func _set_rotation_clockwise(degrees: float):
	_tower_visual.rotation_degrees = fmod(degrees, 360.0)

func set_initial_direction(direction_index: int):
	current_rotation_index = direction_index % 4
	if is_instance_valid(_tower_visual):
		_tower_visual.rotation_degrees = current_rotation_index * 90.0

func _on_rotation_complete():
	is_rotating = false

# ── 冷却驱动开火 ──────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _is_firing:
		return

	var effective_delta := delta
	if _boost_time_remaining > 0.0:
		_boost_time_remaining -= delta
		if _boost_time_remaining < 0.0:
			_boost_time_remaining = 0.0
		effective_delta = delta * _boost_k

	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= effective_delta
		_update_cd_overlay()
		if _cd_label:
			if _cooldown_remaining > 0.0 and _is_firing:
				_cd_label.text = "%.1f" % _cooldown_remaining
			else:
				_cd_label.text = ""
		return
	# CD 归零：更新 label 并尝试发射
	if _cd_label:
		_cd_label.text = ""
	if has_ammo():
		_do_fire()
	else:
		# 无弹药：CD 停在 0，关闭 process 节省性能。
		# 注意：_process 目前只做计时开火，若将来在此添加其他逻辑，
		# 需评估无弹药时是否仍需保持 process 开启。
		set_process(false)

func start_firing() -> void:
	_is_firing = true
	var cd := _get_effective_cd()
	_cooldown_remaining = cd
	_current_full_cooldown = cd
	_update_cd_overlay()
	set_process(true)

func stop_firing() -> void:
	_is_firing = false
	if is_instance_valid(_cd_overlay):
		_cd_overlay.progress = 1.0
	if _cd_label:
		_cd_label.text = ""
	set_process(false)

# ── Speed Boost ───────────────────────────────────────────────

func apply_speed_boost(duration: float) -> void:
	_boost_time_remaining += duration

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

# ── 弹药系统 ─────────────────────────────────────────────────

func has_ammo() -> bool:
	return ammo == -1 or ammo_cursor < ammo_queue.size()

func ammo_count() -> int:
	if ammo == -1:
		return -1
	return ammo_queue.size() - ammo_cursor

func consume_ammo() -> void:
	if ammo == -1:
		return
	ammo_cursor += 1
	# 定期清理已消费项，防止长时间运行后内存堆积
	if ammo_cursor > 200:
		ammo_queue = ammo_queue.slice(ammo_cursor)
		ammo_cursor = 0
	_update_ammo_label()

## 全新弹药（空链）：初始弹药、击杀敌人奖励等来源
func add_ammo(amount: int) -> void:
	if ammo == -1:
		return
	for _i in range(amount):
		ammo_queue.append(AmmoItem.new())
	_update_ammo_label()
	# CD 已归零且正在开火阶段：重启 process，下一帧统一检查并发射
	if _is_firing and _cooldown_remaining <= 0.0:
		set_process(true)

## 链式弹药：继承当前子弹的链追踪状态，用于炮塔间弹药传递
func add_ammo_from_chain(amount: int, bullet_data: BulletData) -> void:
	if ammo == -1:
		return
	for _i in range(amount):
		var item := AmmoItem.new()
		item.effect_contribution_counts = bullet_data.effect_contribution_counts.duplicate()
		item.tower_effect_trigger_counts = bullet_data.tower_effect_trigger_counts.duplicate()
		ammo_queue.append(item)
	_update_ammo_label()
	if _is_firing and _cooldown_remaining <= 0.0:
		set_process(true)

func _create_cd_overlay() -> void:
	_cd_overlay = CooldownOverlayScript.new()
	_cd_overlay.name = "CooldownOverlay"
	_cd_overlay.z_index = 1
	add_child(_cd_overlay)
	call_deferred("_init_cd_overlay_size")

func _init_cd_overlay_size() -> void:
	if is_instance_valid(sprite) and sprite.texture:
		_cd_overlay.radius = sprite.texture.get_size().x * 0.4

func _update_cd_overlay() -> void:
	if not is_instance_valid(_cd_overlay):
		return
	if _current_full_cooldown <= 0.0:
		_cd_overlay.progress = 1.0
		return
	_cd_overlay.progress = 1.0 - clamp(_cooldown_remaining / _current_full_cooldown, 0.0, 1.0)

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
	_ammo_label.text = "∞" if ammo == -1 else str(ammo_count())

func _create_cd_label() -> void:
	_cd_label = Label.new()
	_cd_label.name = "CDLabel"
	_cd_label.position = Vector2(-60, -70)  # top-left corner
	_cd_label.size = Vector2(50, 28)
	var settings = LabelSettings.new()
	settings.font_size = 40
	settings.font_color = Color.AQUA
	settings.shadow_color = Color.BLACK
	settings.outline_size = 2
	settings.outline_color = Color(0, 0, 0)
	_cd_label.label_settings = settings
	_cd_label.text = ""
	add_child(_cd_label)

# ── 被击中处理 ───────────────────────────────────────────────

## 果冻弹性受击动画
func play_hit_effect() -> void:
	var target_scale = (FlyingModule.FLYING_SCALE_MULTIPLIER * Vector2.ONE) if is_flying else Vector2.ONE

	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()

	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "scale", target_scale * Vector2(1.3, 0.75), 0.05)
	_hit_tween.tween_property(sprite, "scale", target_scale * Vector2(0.85, 1.2), 0.09)
	_hit_tween.tween_property(sprite, "scale", target_scale, 0.12)

## 减少当前剩余 CD。
## 若减少量不足以归零，直接缩短剩余 CD；
## 若超过剩余 CD，触发发射并将溢出量带入下一轮，可能触发多次。
## 公式：超出量 / 最大CD = 额外触发次数 … 余 = 新剩余CD
func reduce_cooldown(amount: float) -> void:
	if not _is_firing or amount <= 0.0:
		return

	if _cooldown_remaining > amount:
		# 未归零：直接缩短，不触发发射
		_cooldown_remaining -= amount
		_update_cd_overlay()
		return

	# 剩余 CD ≤ 减少量：至少触发一次发射
	var cycle := _get_effective_cd()
	var excess := amount - _cooldown_remaining
	var additional_fires := int(excess / cycle)
	var leftover := fmod(excess, cycle)
	# leftover == 0 表示恰好整除，新一轮从满 CD 开始
	var new_remaining := (cycle - leftover) if leftover > 0.0 else cycle

	var total_fires := 1 + additional_fires
	for i in range(total_fires):
		if has_ammo():
			_do_fire()
		else:
			# 弹药耗尽，停止并冻结 CD 显示
			set_process(false)
			_cooldown_remaining = 0.0
			_current_full_cooldown = cycle
			_update_cd_overlay()
			return

	# 发射完毕，设置进位后的剩余 CD
	_cooldown_remaining = new_remaining
	_current_full_cooldown = cycle
	_update_cd_overlay()

## 被子弹击中时调用（由 bullet.gd 负责调用）。触发 tower_effects。
func on_bullet_hit(bullet_data: BulletData) -> void:
	play_hit_effect()
	for te in tower_effects:
		te.on_receive_bullet_hit(bullet_data, self)

# ── 开火逻辑 ─────────────────────────────────────────────────

func _do_fire() -> void:
	# 取当前弹药项（无限弹药每次创建空 AmmoItem，保持全新链）
	var ammo_item: AmmoItem
	if ammo == -1:
		ammo_item = AmmoItem.new()
	else:
		ammo_item = ammo_queue[ammo_cursor]
	consume_ammo()

	# 额外弹药消耗（由 ammo_extra_stat 驱动，如重弹头模块）
	var extra := int(_ammo_extra_stat.get_value())
	for _i in range(extra):
		consume_ammo()

	var bd := BulletData.new()
	bd.attack = _bullet_attack_stat.get_value()
	bd.speed  = _bullet_speed_stat.get_value()
	bd.transmission_chain = [self]  # 仅防自碰，与链计数无关

	# 触发 FireEffect（开火时效果，如影子炮塔生成）
	for effect in fire_effects:
		effect.apply(self, bd)

	# 从弹药项继承链追踪状态
	bd.effect_contribution_counts = ammo_item.effect_contribution_counts.duplicate()
	bd.tower_effect_trigger_counts = ammo_item.tower_effect_trigger_counts.duplicate()

	# 检查本 tower 是否还能贡献 bullet_effects 和基础弹药传递
	var contrib_count = bd.effect_contribution_counts.get(entity_id, 0)
	if contrib_count < bullet_effect_max_chain:
		bd.effects.append_array(bullet_effects)
		bd.effect_contribution_counts[entity_id] = contrib_count + 1
		# default_replenish 也受链次数限制，与 bullet_effects 共享同一计数
		var default_replenish := HitTowerTargetReplenishEffect.new()
		bd.effects.append(default_replenish)

	# 设置子弹碰撞层以反映飞行/反空状态
	if is_flying:
		bd.tower_body_mask = Layers.AIR_TOWER_BODY
	elif has_anti_air:
		bd.tower_body_mask = Layers.TOWER_BODY | Layers.AIR_TOWER_BODY

	var cd := _get_effective_cd()
	_cooldown_remaining = cd
	_current_full_cooldown = cd
	_update_cd_overlay()

	var parent := get_tree().get_first_node_in_group("bullet_layer")
	if not is_instance_valid(parent):
		parent = get_tree().root

	var directions: PackedVector2Array
	if data and data.barrel_directions.size() > 0:
		directions = data.barrel_directions
	else:
		directions = PackedVector2Array([Vector2(0, -1)])

	for local_dir in directions:
		BulletPool.spawn(parent, global_position, local_dir.rotated(_tower_visual.rotation), bd)

	EventManager.notify_bullet_fired(bd, self)
