extends Node2D

const ENEMY_SCENE = preload("res://enemy.tscn")
const ENEMY_COUNT = 8  # 生成的敌人数量
const SPAWN_MARGIN = 60.0  # 生成位置距离屏幕边缘的距离

var grid_rect: Rect2 = Rect2()
var grid_cell_size: float = 80.0
var active_enemies: Array = []

func _ready():
	pass

func set_grid_info(rect: Rect2, cell_size: float):
	grid_rect = rect
	grid_cell_size = cell_size

func spawn_enemies():
	# 清除现有敌人
	clear_enemies()
	
	if grid_rect.size == Vector2.ZERO:
		push_error("Grid rect not set!")
		return
	
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
	
	# 随机选择要生成的行/列，不是所有都生成
	var spawned_count = 0
	var attempts = 0
	var max_attempts = ENEMY_COUNT * 10
	
	while spawned_count < ENEMY_COUNT and attempts < max_attempts:
		attempts += 1
		
		var direction = directions[randi() % directions.size()]
		var enemy = ENEMY_SCENE.instantiate()
		
		var spawn_pos = Vector2.ZERO
		var target_grid_pos = Vector2.ZERO
		
		if direction == Vector2(0, 1):  # 从上往下
			# 随机选择一列
			var col = randi() % cols
			var x = grid_rect.position.x + col * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(x, -SPAWN_MARGIN)
			target_grid_pos = Vector2(x, grid_rect.position.y + grid_cell_size / 2)
			
		elif direction == Vector2(0, -1):  # 从下往上
			var col = randi() % cols
			var x = grid_rect.position.x + col * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(x, viewport_size.y + SPAWN_MARGIN)
			target_grid_pos = Vector2(x, grid_rect.position.y + grid_rect.size.y - grid_cell_size / 2)
			
		elif direction == Vector2(1, 0):  # 从左往右
			var row = randi() % rows
			var y = grid_rect.position.y + row * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(-SPAWN_MARGIN, y)
			target_grid_pos = Vector2(grid_rect.position.x + grid_cell_size / 2, y)
			
		elif direction == Vector2(-1, 0):  # 从右往左
			var row = randi() % rows
			var y = grid_rect.position.y + row * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(viewport_size.x + SPAWN_MARGIN, y)
			target_grid_pos = Vector2(grid_rect.position.x + grid_rect.size.x - grid_cell_size / 2, y)
		
		enemy.set_grid_aligned_position(spawn_pos)
		enemy.set_direction(direction)
		
		# 连接碰撞信号
		enemy.enemy_hit.connect(_on_enemy_hit)
		
		# 添加到场景
		get_tree().root.add_child(enemy)
		active_enemies.append(enemy)
		
		spawned_count += 1
		print("[ENEMY] Spawned enemy #", spawned_count, " at ", spawn_pos, " direction: ", direction)
	
	print("[ENEMY] Total enemies spawned: ", spawned_count)

func _on_enemy_hit(body: Node2D, enemy: CharacterBody2D):
	# 检查是否是子弹（通过脚本路径或名称）
	var is_bullet = false
	if body.get_script() != null and body.get_script().resource_path.ends_with("bullet.gd"):
		is_bullet = true
	elif body.name.to_lower().begins_with("bullet"):
		is_bullet = true
	
	if is_bullet:
		print("[ENEMY] Enemy hit by bullet!")
		if is_instance_valid(body):
			body.queue_free()  # 销毁子弹
		if enemy in active_enemies:
			active_enemies.erase(enemy)
		enemy.destroy()  # 销毁敌人
		return
	
	# 检查是否触碰网格（通过检查body是否在grid_cells组中）
	if body.is_in_group("grid_cells"):
		print("[ENEMY] Enemy reached the grid at cell: ", body.name, "! Game Over!")
		if enemy in active_enemies:
			active_enemies.erase(enemy)
		enemy.destroy()
		return
	
	# 检查是否触碰grid容器本身
	if body.name == "Grid":
		print("[ENEMY] Enemy reached the grid container! Game Over!")
		if enemy in active_enemies:
			active_enemies.erase(enemy)
		enemy.destroy()

func clear_enemies():
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	print("[ENEMY] All enemies cleared")

func _exit_tree():
	clear_enemies()
