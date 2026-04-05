extends Node

## GameLoopManager.gd - 游戏循环管理
## 负责游戏状态转换和核心游戏逻辑

const DeadZoneManager = preload("res://core/dead_zone_manager.gd")
const EnemyManager = preload("res://entities/enemies/enemy_manager.gd")

const CELL_SIZE = 80.0

signal tower_deployed(tower: Node)
signal all_enemies_defeated

var _grid_container: Control
var _dead_zone_manager: Node = null
var _enemy_manager: Node = null
var _pending_enemy_data: Array = []
# 普通模式：跨波次累积的敌人位置（下一波保留这些并追加新敌人）
var _accumulated_enemy_data: Array = []

## 已完成的波次数（0 = 还未完成任何波次，下一波是第1关）
var current_wave: int = 0

func setup(grid_container: Control):
	_grid_container = grid_container

	# 监听游戏状态变化
	SignalBus.game_started.connect(_on_game_started)
	SignalBus.game_stopped.connect(_on_game_stopped)

func start_game():
	GameState.start_game()

func stop_game():
	GameState.stop_game()

func _on_game_started():
	_set_drag_enabled(false)
	_create_dead_zones()
	_create_enemy_manager()
	_start_all_towers()
	SignalBus.wave_started.emit(current_wave + 1)

func _on_game_stopped():
	_stop_all_towers()
	_reset_all_tower_ammo()
	_clear_all_bullets()
	_remove_dead_zones()
	_remove_enemy_manager()
	_set_drag_enabled(true)
	# 注意：prepare_enemy_warnings() 由 main.gd 在合适时机显式调用

func _set_drag_enabled(enabled: bool):
	for cell in _grid_container.get_children():
		if cell.has_method("set_drag_enabled"):
			cell.set_drag_enabled(enabled)

func _start_all_towers():
	for cell in _grid_container.get_children():
		if cell.has_method("get_deployed_tower"):
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower) and tower.has_method("start_firing"):
				tower.start_firing()

func _stop_all_towers():
	for cell in _grid_container.get_children():
		if cell.has_method("get_deployed_tower"):
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower) and tower.has_method("stop_firing"):
				tower.stop_firing()

func _reset_all_tower_ammo():
	for cell in _grid_container.get_children():
		if cell.has_method("get_deployed_tower"):
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower) and tower.has_method("reset_ammo"):
				tower.reset_ammo()

func _create_dead_zones():
	if is_instance_valid(_dead_zone_manager):
		_dead_zone_manager.queue_free()
	_dead_zone_manager = DeadZoneManager.new()
	_dead_zone_manager.name = "DeadZoneManager"
	add_child(_dead_zone_manager)

func _remove_dead_zones():
	if is_instance_valid(_dead_zone_manager):
		_dead_zone_manager.clear_all()
		_dead_zone_manager.queue_free()
		_dead_zone_manager = null

func prepare_enemy_warnings():
	if not is_instance_valid(_grid_container):
		push_error("[GameLoopManager] Grid container not valid!")
		return

	var grid_rect = _grid_container.get_global_rect()
	if grid_rect.size == Vector2.ZERO:
		# Grid 还没准备好，延迟重试
		await get_tree().create_timer(0.1).timeout
		call_deferred("prepare_enemy_warnings")
		return

	if is_instance_valid(_enemy_manager):
		_enemy_manager.queue_free()

	_enemy_manager = EnemyManager.new()
	_enemy_manager.name = "EnemyManager"
	add_child(_enemy_manager)

	_enemy_manager.set_grid_info(grid_rect, CELL_SIZE)
	_enemy_manager.current_wave = current_wave

	var new_enemy_count = current_wave + 1  # 第N关 = N个敌人

	if GameState.is_dev_mode():
		# Dev mode: always 1 enemy, fully random position, no accumulation
		_enemy_manager.excluded_pos_keys = []
		_enemy_manager.enemy_count = 1
		_pending_enemy_data = _enemy_manager.prepare_enemies()
	elif GameState.game_mode == GameState.GameMode.NORMAL and _accumulated_enemy_data.size() > 0:
		# 普通模式：保留上一波敌人位置，只新增差额
		_pending_enemy_data = _accumulated_enemy_data.duplicate()
		var additional_count = new_enemy_count - _accumulated_enemy_data.size()
		if additional_count > 0:
			# 排除已有位置，只随机生成新增部分
			_enemy_manager.excluded_pos_keys = []
			for info in _accumulated_enemy_data:
				_enemy_manager.excluded_pos_keys.append(info["pos_key"])
			_enemy_manager.enemy_count = additional_count
			var new_data = _enemy_manager.prepare_enemies()
			_pending_enemy_data.append_array(new_data)
			# 为已有敌人补充显示警告
			_enemy_manager.show_warnings_for_existing(_accumulated_enemy_data)
		else:
			# 敌人数未增加，为所有已有敌人显示警告
			_enemy_manager.show_warnings_for_existing(_accumulated_enemy_data)
	else:
		# 混乱模式（或普通模式首波）：完全随机生成
		_enemy_manager.excluded_pos_keys = []
		_enemy_manager.enemy_count = new_enemy_count
		_pending_enemy_data = _enemy_manager.prepare_enemies()

	_accumulated_enemy_data = _pending_enemy_data.duplicate()
	_apply_danger_to_warnings()

func _create_enemy_manager():
	if is_instance_valid(_enemy_manager):
		_enemy_manager.queue_free()

	_enemy_manager = EnemyManager.new()
	_enemy_manager.name = "EnemyManager"
	add_child(_enemy_manager)

	var grid_rect = _grid_container.get_global_rect()
	_enemy_manager.set_grid_info(grid_rect, CELL_SIZE)
	_enemy_manager.spawn_enemies_from_data(_pending_enemy_data)

	_enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)

func _remove_enemy_manager():
	if is_instance_valid(_enemy_manager):
		_enemy_manager.clear_enemies()
		_enemy_manager.queue_free()
		_enemy_manager = null

func _clear_all_bullets():
	var bullets = get_tree().get_nodes_in_group("bullets")
	for bullet in bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()

func _on_all_enemies_defeated():
	current_wave += 1
	all_enemies_defeated.emit()

func reset_wave():
	current_wave = 0
	_accumulated_enemy_data.clear()

func get_current_wave() -> int:
	return current_wave

func get_pending_enemy_data() -> Array:
	return _pending_enemy_data

## 收集所有已部署炮塔当前世界空间炮管方向（归一化到4个基本方向）
func _get_covered_directions() -> Array:
	var covered: Array = []
	for cell in _grid_container.get_children():
		if not cell.has_method("get_deployed_tower"):
			continue
		var tower = cell.get_deployed_tower()
		if not is_instance_valid(tower):
			continue
		var rotation_rad := deg_to_rad(float(tower.current_rotation_index) * 90.0)
		var barrel_dirs: PackedVector2Array
		if tower.data and tower.data.barrel_directions.size() > 0:
			barrel_dirs = tower.data.barrel_directions
		else:
			barrel_dirs = PackedVector2Array([Vector2(0, -1)])
		for local_dir in barrel_dirs:
			var world_dir: Vector2 = local_dir.rotated(rotation_rad)
			covered.append(_snap_cardinal(world_dir))
	return covered

## 将任意向量吸附到最近的4个基本方向之一
func _snap_cardinal(dir: Vector2) -> Vector2:
	if abs(dir.x) >= abs(dir.y):
		return Vector2(sign(dir.x), 0)
	else:
		return Vector2(0, sign(dir.y))

## 根据覆盖方向集合，为每个 active warning 设置 danger 状态
func _apply_danger_to_warnings() -> void:
	if not is_instance_valid(_enemy_manager):
		return
	var covered := _get_covered_directions()
	for warning in _enemy_manager.active_warnings:
		if not is_instance_valid(warning):
			continue
		# 敌人从 warning.direction 方向移动过来
		# 炮塔需指向 -warning.direction 才能覆盖该方向
		var needed_dir: Vector2 = -(warning.direction as Vector2)
		var is_covered: bool = needed_dir in covered
		warning.set_danger(not is_covered)
