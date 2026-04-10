extends Node2D

const WARNING_SCENE = preload("res://entities/enemies/enemy_warning.tscn")
var enemy_count: int = 1  # 当前波次的敌人数量（由外部设置）
var current_wave: int = 1   # 当前波次（影响敌人生成权重）
const SPAWN_MARGIN = 240.0  # 生成位置距离 Grid 边缘的距离（3 个 Cell）
const WARNING_DISTANCE = 50.0  # 警告图标距离 Grid 边缘的距离（贴近格子）

var grid_rect: Rect2 = Rect2()
var grid_cell_size: float = 80.0
var active_enemies: Array = []
var active_warnings: Array = []
var spawn_parent: Node = null  # 敌人和警告的父节点（BattlefieldContainer or root）

func _get_spawn_parent() -> Node:
	if is_instance_valid(spawn_parent):
		return spawn_parent
	return get_tree().root

# 预生成的敌人信息
var pending_enemies: Array = []

# 普通模式：传入已占用的位置键，生成时跳过这些位置
var excluded_pos_keys: Array = []

# Dev mode: stores the single spawn position for infinite respawn
var dev_spawn_info: Dictionary = {}

# 延迟生成的敌人计数（防止 all_enemies_defeated 提前触发）
var _pending_delayed_count: int = 0

func _ready():
	pass

## 根据当前波次权重，随机选择敌人场景
func _pick_enemy_scene() -> PackedScene:
	return EnemySpawnPicker.pick(current_wave)

## 根据 enemy_info 加载敌人场景（优先使用存储的路径，兼容旧数据）
func _load_enemy_scene(enemy_info: Dictionary) -> PackedScene:
	if enemy_info.has("enemy_scene_path") and enemy_info["enemy_scene_path"] != "":
		return load(enemy_info["enemy_scene_path"])
	return _pick_enemy_scene()

## 延迟生成敌人
func _spawn_delayed(scene: PackedScene, enemy_info: Dictionary, delay: float):
	# 先增加计数，确保 all_enemies_defeated 不会提前触发
	_pending_delayed_count += 1
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(func():
		_pending_delayed_count -= 1
		if not is_instance_valid(self) or not GameState.is_running():
			if _pending_delayed_count <= 0 and active_enemies.size() == 0:
				all_enemies_defeated.emit()
			return
		var enemy = scene.instantiate()
		enemy.set_direction(enemy_info["direction"])
		enemy.enemy_hit.connect(_on_enemy_hit)
		enemy.enemy_destroyed.connect(_on_enemy_destroyed)
		_get_spawn_parent().add_child(enemy)
		enemy.set_grid_aligned_position(enemy_info["spawn_pos"])
		active_enemies.append(enemy)
	)

func set_grid_info(rect: Rect2, cell_size: float):
	grid_rect = rect
	grid_cell_size = cell_size

# 预生成敌人信息并显示警告（游戏开始前调用）
# 返回敌人数据数组，供 main.gd 存储
func prepare_enemies() -> Array:
	# 清除之前的警告
	clear_warnings()
	pending_enemies.clear()
	
	if grid_rect.size == Vector2.ZERO:
		push_error("Grid rect not set!")
		return []
	
	# 计算网格的行列数
	var cols = int(grid_rect.size.x / grid_cell_size)
	var rows = int(grid_rect.size.y / grid_cell_size)
	# 计算实际格子步长（含 GridContainer separation）
	var cell_step_x: float = grid_cell_size if cols <= 1 else (grid_rect.size.x - grid_cell_size) / float(cols - 1)
	var cell_step_y: float = grid_cell_size if rows <= 1 else (grid_rect.size.y - grid_cell_size) / float(rows - 1)
	
	# 四个方向：上、下、左、右
	var directions = [
		Vector2(0, 1),   # 上 -> 下
		Vector2(0, -1),  # 下 -> 上
		Vector2(1, 0),   # 左 -> 右
		Vector2(-1, 0)   # 右 -> 左
	]
	
	# 追踪已使用的生成位置，避免重叠（含外部排除键）
	var used_positions = {}
	for key in excluded_pos_keys:
		used_positions[key] = true
	
	# 计算总共有多少个独立位置
	var total_positions = (cols + rows) * 2  # 上cols + 下cols + 左rows + 右rows
	var unique_excluded = {}
	for key in excluded_pos_keys:
		unique_excluded[key] = true
	var available_unique = total_positions - unique_excluded.size()

	# 随机选择要生成的行/列
	var spawned_count = 0
	var attempts = 0
	var max_attempts = enemy_count * 10
	# 当独立位置用完时，允许重复位置
	var allow_duplicate = available_unique <= 0

	while spawned_count < enemy_count and attempts < max_attempts:
		attempts += 1

		var direction = directions[randi() % directions.size()]

		var spawn_pos = Vector2.ZERO
		var warning_pos = Vector2.ZERO
		var pos_key = ""
		var col = 0
		var row = 0

		if direction == Vector2(0, 1):  # 从上往下
			col = randi() % cols
			var x = grid_rect.position.x + col * cell_step_x + grid_cell_size / 2
			spawn_pos = Vector2(x, grid_rect.position.y - SPAWN_MARGIN)
			warning_pos = Vector2(x, grid_rect.position.y - WARNING_DISTANCE)
			pos_key = "top_" + str(col)

		elif direction == Vector2(0, -1):  # 从下往上
			col = randi() % cols
			var x = grid_rect.position.x + col * cell_step_x + grid_cell_size / 2
			spawn_pos = Vector2(x, grid_rect.position.y + grid_rect.size.y + SPAWN_MARGIN)
			warning_pos = Vector2(x, grid_rect.position.y + grid_rect.size.y + WARNING_DISTANCE)
			pos_key = "bottom_" + str(col)

		elif direction == Vector2(1, 0):  # 从左往右
			row = randi() % rows
			var y = grid_rect.position.y + row * cell_step_y + grid_cell_size / 2
			spawn_pos = Vector2(grid_rect.position.x - SPAWN_MARGIN, y)
			warning_pos = Vector2(grid_rect.position.x - WARNING_DISTANCE, y)
			pos_key = "left_" + str(row)

		elif direction == Vector2(-1, 0):  # 从右往左
			row = randi() % rows
			var y = grid_rect.position.y + row * cell_step_y + grid_cell_size / 2
			spawn_pos = Vector2(grid_rect.position.x + grid_rect.size.x + SPAWN_MARGIN, y)
			warning_pos = Vector2(grid_rect.position.x + grid_rect.size.x + WARNING_DISTANCE, y)
			pos_key = "right_" + str(row)

		# 检查这个位置是否已被使用
		if not allow_duplicate and used_positions.has(pos_key):
			continue

		# 标记位置为已使用
		if not used_positions.has(pos_key):
			used_positions[pos_key] = true

		# 计算该位置上第几个敌人（用于延迟生成）
		var spawn_delay = 0.0
		var pos_count = 0
		for existing in pending_enemies:
			if existing["pos_key"] == pos_key:
				pos_count += 1
		# 也要统计 excluded 中同位置的（已有的累积敌人）
		for key in excluded_pos_keys:
			if key == pos_key:
				pos_count += 1
		if pos_count > 0:
			spawn_delay = pos_count * 2.0  # 每多一个敌人延迟2秒

		# 保存敌人信息（含场景路径，保证跨波次敌人类型不变）
		var enemy_scene = _pick_enemy_scene()
		var enemy_info = {
			"spawn_pos": spawn_pos,
			"warning_pos": warning_pos,
			"direction": direction,
			"pos_key": pos_key,
			"enemy_scene_path": enemy_scene.resource_path,
			"spawn_delay": spawn_delay
		}
		pending_enemies.append(enemy_info)

		# 创建警告图标（重复位置不重复创建警告）
		if pos_count == 0:
			var warning = WARNING_SCENE.instantiate()
			warning.set_direction(direction)
			_get_spawn_parent().add_child(warning)
			warning.set_grid_aligned_position(warning_pos)
			active_warnings.append(warning)

		spawned_count += 1

		# 当刚好用完所有独立位置时，切换为允许重复
		if not allow_duplicate:
			available_unique -= 1
			if available_unique <= 0:
				allow_duplicate = true

	return pending_enemies.duplicate()

# 实际生成敌人（游戏开始时调用）
func spawn_enemies():
	# 清除警告
	clear_warnings()

	# 清除现有敌人
	clear_enemies()

	# 根据预存的信息生成敌人
	for enemy_info in pending_enemies:
		var scene = _load_enemy_scene(enemy_info)
		var delay = enemy_info.get("spawn_delay", 0.0)
		if delay > 0.0:
			_spawn_delayed(scene, enemy_info, delay)
		else:
			var enemy = scene.instantiate()
			enemy.set_direction(enemy_info["direction"])
			enemy.enemy_hit.connect(_on_enemy_hit)
			enemy.enemy_destroyed.connect(_on_enemy_destroyed)
			_get_spawn_parent().add_child(enemy)
			enemy.set_grid_aligned_position(enemy_info["spawn_pos"])
			active_enemies.append(enemy)

	# 清空预存信息
	pending_enemies.clear()

# 使用外部数据生成敌人
func spawn_enemies_from_data(enemy_data: Array):
	# 清除警告
	clear_warnings()

	# 清除现有敌人
	clear_enemies()

	# 根据传入的数据生成敌人
	for enemy_info in enemy_data:
		var scene = _load_enemy_scene(enemy_info)
		var delay = enemy_info.get("spawn_delay", 0.0)
		if delay > 0.0:
			_spawn_delayed(scene, enemy_info, delay)
		else:
			var enemy = scene.instantiate()
			enemy.set_direction(enemy_info["direction"])
			enemy.enemy_hit.connect(_on_enemy_hit)
			enemy.enemy_destroyed.connect(_on_enemy_destroyed)
			_get_spawn_parent().add_child(enemy)
			enemy.set_grid_aligned_position(enemy_info["spawn_pos"])
			active_enemies.append(enemy)

	# Dev mode: store the first spawn position for infinite respawn
	if GameState.is_dev_mode() and enemy_data.size() > 0:
		dev_spawn_info = enemy_data[0].duplicate()


# 普通模式：为已有敌人数据补充显示警告（不重新生成位置，同位置只显示一个警告）
func show_warnings_for_existing(enemy_data: Array):
	var shown_keys = {}
	for enemy_info in enemy_data:
		var key = enemy_info["pos_key"]
		if shown_keys.has(key):
			continue
		shown_keys[key] = true
		var warning = WARNING_SCENE.instantiate()
		warning.set_direction(enemy_info["direction"])
		_get_spawn_parent().add_child(warning)
		warning.set_grid_aligned_position(enemy_info["warning_pos"])
		active_warnings.append(warning)

func clear_warnings():
	for warning in active_warnings:
		if is_instance_valid(warning):
			warning.queue_free()
	active_warnings.clear()

func clear_enemies():
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

signal all_enemies_defeated()  # 所有敌人被消灭信号

func _on_enemy_hit(body: Node2D, enemy: CharacterBody2D):
	if not body.is_in_group("bullets"):
		return
	if not is_instance_valid(body) or not is_instance_valid(enemy):
		return

	# 保存子弹数据（BulletPool.release 后仍需使用）
	var bullet_data: BulletData = body.data if body.data != null else null
	var attack := 1.0
	var knockback := 180.0
	var knockback_decay := 7.0
	var bullet_dir := Vector2.ZERO
	if bullet_data:
		attack = bullet_data.attack
		knockback = bullet_data.knockback
		knockback_decay = bullet_data.knockback_decay
		bullet_dir = body.direction

	# 1. 子弹击中敌人时
	if bullet_data:
		for effect in bullet_data.effects:
			effect.on_hit_enemy(bullet_data, enemy)

	# 碰撞特效 + 回收子弹
	var impact := BulletImpact.new()
	get_tree().root.add_child(impact)
	impact.spawn(body.global_position)
	BulletPool.release(body)

	if not is_instance_valid(enemy):
		return

	# 2. 子弹造成伤害时
	if bullet_data:
		for effect in bullet_data.effects:
			effect.on_deal_damage(bullet_data, enemy, attack)

	# 实际造成伤害（enemy.take_damage 内部处理 on_killed_enemy）
	enemy.take_damage(attack, bullet_data)
	if knockback > 0.0 and bullet_dir != Vector2.ZERO:
		if is_instance_valid(enemy):
			enemy.apply_knockback(bullet_dir * knockback, knockback_decay)

func _on_enemy_destroyed(enemy: CharacterBody2D):
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		GameState.add_coins(1)  # 每击杀一个敌人获得 1 金币（×难度系数，当前固定为1）

		if GameState.is_dev_mode() and GameState.is_running() and not dev_spawn_info.is_empty():
			# Dev mode: immediately respawn a new enemy at the same position
			var new_enemy = EnemySpawnPicker.pick_for_dev().instantiate()
			new_enemy.set_direction(dev_spawn_info["direction"])
			new_enemy.enemy_hit.connect(_on_enemy_hit)
			new_enemy.enemy_destroyed.connect(_on_enemy_destroyed)
			_get_spawn_parent().add_child(new_enemy)
			new_enemy.set_grid_aligned_position(dev_spawn_info["spawn_pos"])
			active_enemies.append(new_enemy)
		elif active_enemies.size() == 0 and _pending_delayed_count <= 0:
			all_enemies_defeated.emit()

func _exit_tree():
	clear_warnings()
	clear_enemies()
