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
var _battlefield_container: Node2D = null
var _pending_enemy_data: Array = []
# 普通模式：跨波次累积的敌人位置（下一波保留这些并追加新敌人）
var _accumulated_enemy_data: Array = []

## 已完成的波次数（0 = 还未完成任何波次，下一波是第1关）
var current_wave: int = 0

func setup(grid_container: Control, battlefield_container: Node2D = null):
	_grid_container = grid_container
	_battlefield_container = battlefield_container

	# 监听游戏状态变化
	SignalBus.game_started.connect(_on_game_started)
	SignalBus.game_stopped.connect(_on_game_stopped)

func _process(_delta: float) -> void:
	# 部署阶段实时更新警告危险状态（炮塔旋转/移动时同步）
	if GameState.is_deployment() and is_instance_valid(_enemy_manager):
		_apply_danger_to_warnings()

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
	var grid_rect := _grid_container.get_global_rect()
	_dead_zone_manager.setup(grid_rect, CELL_SIZE, _get_battlefield_cells())
	if is_instance_valid(_battlefield_container):
		_battlefield_container.add_child(_dead_zone_manager)
	else:
		add_child(_dead_zone_manager)
	_dead_zone_manager.create_zones_from_setup()

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
	if is_instance_valid(_battlefield_container):
		_battlefield_container.add_child(_enemy_manager)
	else:
		add_child(_enemy_manager)
	_enemy_manager.spawn_parent = _battlefield_container

	_enemy_manager.set_grid_info(grid_rect, CELL_SIZE)

	var new_enemy_count = current_wave + 1  # 第N关 = N个敌人
	_enemy_manager.current_wave = current_wave  # 同步波次给敌人生成权重

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
	if is_instance_valid(_battlefield_container):
		_battlefield_container.add_child(_enemy_manager)
	else:
		add_child(_enemy_manager)
	_enemy_manager.spawn_parent = _battlefield_container

	var grid_rect = _grid_container.get_global_rect()
	_enemy_manager.set_grid_info(grid_rect, CELL_SIZE)
	_enemy_manager.current_wave = current_wave
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

func _get_battlefield_cells() -> int:
	if is_instance_valid(_battlefield_container):
		return _battlefield_container.battlefield_cells
	return 12

## 将任意向量吸附到最近的4个基本方向之一
func _snap_cardinal(dir: Vector2) -> Vector2:
	if abs(dir.x) >= abs(dir.y):
		return Vector2(sign(dir.x), 0)
	else:
		return Vector2(0, sign(dir.y))

## 根据行/列和炮弹遮挡，为每个 active warning 设置 danger 状态
func _apply_danger_to_warnings() -> void:
	if not is_instance_valid(_enemy_manager):
		return

	var grid_rect := _grid_container.get_global_rect()
	if grid_rect.size == Vector2.ZERO:
		return

	var cells := _grid_container.get_children()
	var cols: int = int(round(grid_rect.size.x / CELL_SIZE))
	var rows: int = int(round(grid_rect.size.y / CELL_SIZE))

	# 构建二维炮塔地图 tower_grid[row][col]
	var tower_grid: Array = []
	for r in range(rows):
		tower_grid.append([])
		for c in range(cols):
			tower_grid[r].append(null)
	for i in range(cells.size()):
		var cell = cells[i]
		if not cell.has_method("get_deployed_tower"):
			continue
		var tower = cell.get_deployed_tower()
		if not is_instance_valid(tower):
			continue
		var r: int = i / cols
		var c: int = i % cols
		if r < rows and c < cols:
			tower_grid[r][c] = tower

	for warning in _enemy_manager.active_warnings:
		if not is_instance_valid(warning):
			continue
		var needed_dir: Vector2 = -(warning.direction as Vector2)
		var is_covered := false

		if abs(needed_dir.x) > 0:
			# 左右方向：检查同行
			var warning_row: int = int((warning.global_position.y - grid_rect.position.y) / CELL_SIZE)
			if warning_row >= 0 and warning_row < rows:
				is_covered = _row_has_unblocked_barrel(tower_grid, warning_row, cols, needed_dir)
		else:
			# 上下方向：检查同列
			var warning_col: int = int((warning.global_position.x - grid_rect.position.x) / CELL_SIZE)
			if warning_col >= 0 and warning_col < cols:
				is_covered = _col_has_unblocked_barrel(tower_grid, rows, warning_col, needed_dir)

		warning.set_danger(not is_covered)

## 检查某行是否有炮管朝 needed_dir 且炮弹路径无其他炮塔遮挡
func _row_has_unblocked_barrel(tower_grid: Array, row: int, cols: int, needed_dir: Vector2) -> bool:
	var step: int = int(needed_dir.x)  # +1=右, -1=左
	for c in range(cols):
		var tower = tower_grid[row][c]
		if tower == null or not _tower_has_barrel(tower, needed_dir):
			continue
		# 检查该炮塔到边缘方向是否有其他炮塔遮挡
		var blocked := false
		if step > 0:
			for cc in range(c + 1, cols):
				if tower_grid[row][cc] != null:
					blocked = true
					break
		else:
			for cc in range(0, c):
				if tower_grid[row][cc] != null:
					blocked = true
					break
		if not blocked:
			return true
	return false

## 检查某列是否有炮管朝 needed_dir 且炮弹路径无其他炮塔遮挡
func _col_has_unblocked_barrel(tower_grid: Array, rows: int, col: int, needed_dir: Vector2) -> bool:
	var step: int = int(needed_dir.y)  # -1=上, +1=下
	for r in range(rows):
		var tower = tower_grid[r][col]
		if tower == null or not _tower_has_barrel(tower, needed_dir):
			continue
		var blocked := false
		if step < 0:
			for rr in range(0, r):
				if tower_grid[rr][col] != null:
					blocked = true
					break
		else:
			for rr in range(r + 1, rows):
				if tower_grid[rr][col] != null:
					blocked = true
					break
		if not blocked:
			return true
	return false

## 检查炮塔是否有炮管朝向 dir（世界空间）
func _tower_has_barrel(tower: Node, dir: Vector2) -> bool:
	var rotation_rad := deg_to_rad(float(tower.current_rotation_index) * 90.0)
	var barrel_dirs: PackedVector2Array
	if tower.data and tower.data.barrel_directions.size() > 0:
		barrel_dirs = tower.data.barrel_directions
	else:
		barrel_dirs = PackedVector2Array([Vector2(0, -1)])
	for local_dir in barrel_dirs:
		var world_dir: Vector2 = local_dir.rotated(rotation_rad)
		if _snap_cardinal(world_dir) == dir:
			return true
	return false
