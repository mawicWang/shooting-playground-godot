extends Node2D

const ENEMY_SCENE = preload("res://entities/enemies/enemy.tscn")
const WARNING_SCENE = preload("res://entities/enemies/enemy_warning.tscn")
var enemy_count: int = 1  # 当前波次的敌人数量（由外部设置）
const SPAWN_MARGIN = 60.0  # 生成位置距离屏幕边缘的距离
const WARNING_DISTANCE = 60.0  # 警告图标距离grid的距离（大半个cell）

var grid_rect: Rect2 = Rect2()
var grid_cell_size: float = 80.0
var active_enemies: Array = []
var active_warnings: Array = []

# 预生成的敌人信息
var pending_enemies: Array = []

# 普通模式：传入已占用的位置键，生成时跳过这些位置
var excluded_pos_keys: Array = []

func _ready():
	pass

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
	
	var viewport_size = get_viewport_rect().size
	
	# 计算网格的行列数
	var cols = int(grid_rect.size.x / grid_cell_size)
	var rows = int(grid_rect.size.y / grid_cell_size)
	
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
	
	# 随机选择要生成的行/列
	var spawned_count = 0
	var attempts = 0
	var max_attempts = enemy_count * 10

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
			var x = grid_rect.position.x + col * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(x, -SPAWN_MARGIN)
			warning_pos = Vector2(x, grid_rect.position.y - WARNING_DISTANCE)
			pos_key = "top_" + str(col)
			
		elif direction == Vector2(0, -1):  # 从下往上
			col = randi() % cols
			var x = grid_rect.position.x + col * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(x, viewport_size.y + SPAWN_MARGIN)
			warning_pos = Vector2(x, grid_rect.position.y + grid_rect.size.y + WARNING_DISTANCE)
			pos_key = "bottom_" + str(col)
			
		elif direction == Vector2(1, 0):  # 从左往右
			row = randi() % rows
			var y = grid_rect.position.y + row * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(-SPAWN_MARGIN, y)
			warning_pos = Vector2(grid_rect.position.x - WARNING_DISTANCE, y)
			pos_key = "left_" + str(row)
			
		elif direction == Vector2(-1, 0):  # 从右往左
			row = randi() % rows
			var y = grid_rect.position.y + row * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(viewport_size.x + SPAWN_MARGIN, y)
			warning_pos = Vector2(grid_rect.position.x + grid_rect.size.x + WARNING_DISTANCE, y)
			pos_key = "right_" + str(row)
		
		# 检查这个位置是否已被使用
		if used_positions.has(pos_key):
			continue
		
		# 标记位置为已使用
		used_positions[pos_key] = true
		
		# 保存敌人信息
		var enemy_info = {
			"spawn_pos": spawn_pos,
			"warning_pos": warning_pos,
			"direction": direction,
			"pos_key": pos_key
		}
		pending_enemies.append(enemy_info)
		
		# 创建警告图标
		var warning = WARNING_SCENE.instantiate()
		warning.set_grid_aligned_position(warning_pos)
		warning.set_direction(direction)
		get_tree().root.add_child(warning)
		active_warnings.append(warning)
		
		spawned_count += 1

	return pending_enemies.duplicate()

# 实际生成敌人（游戏开始时调用）
func spawn_enemies():
	# 清除警告
	clear_warnings()
	
	# 清除现有敌人
	clear_enemies()
	
	# 根据预存的信息生成敌人
	for enemy_info in pending_enemies:
		var enemy = ENEMY_SCENE.instantiate()
		enemy.set_grid_aligned_position(enemy_info["spawn_pos"])
		enemy.set_direction(enemy_info["direction"])
		
		# 连接碰撞信号
		enemy.enemy_hit.connect(_on_enemy_hit)
		enemy.enemy_destroyed.connect(_on_enemy_destroyed)
		
		# 添加到场景
		get_tree().root.add_child(enemy)
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
		var enemy = ENEMY_SCENE.instantiate()
		enemy.set_grid_aligned_position(enemy_info["spawn_pos"])
		enemy.set_direction(enemy_info["direction"])
		
		# 连接碰撞信号
		enemy.enemy_hit.connect(_on_enemy_hit)
		enemy.enemy_destroyed.connect(_on_enemy_destroyed)
		
		# 添加到场景
		get_tree().root.add_child(enemy)
		active_enemies.append(enemy)
	

# 普通模式：为已有敌人数据补充显示警告（不重新生成位置）
func show_warnings_for_existing(enemy_data: Array):
	for enemy_info in enemy_data:
		var warning = WARNING_SCENE.instantiate()
		warning.set_grid_aligned_position(enemy_info["warning_pos"])
		warning.set_direction(enemy_info["direction"])
		get_tree().root.add_child(warning)
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
		if active_enemies.size() == 0:
			all_enemies_defeated.emit()

func _exit_tree():
	clear_warnings()
	clear_enemies()
