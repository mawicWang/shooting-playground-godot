class_name SpawnShadowTowerEffect extends FireEffect

## 静态字典：按起源炮塔追踪子弹计数
var _bullet_counters: Dictionary = {}  # origin_entity_id -> count

## 起源炮塔的 entity_id（安装时设置）
var origin_entity_id: int = -1

func on_module_install(tower: Node) -> void:
	origin_entity_id = tower.entity_id

func apply(tower: Node, _bd: BulletData) -> void:
	# 初始化计数器（如果需要）
	if not _bullet_counters.has(origin_entity_id):
		_bullet_counters[origin_entity_id] = 0

	# 递增计数
	_bullet_counters[origin_entity_id] += 1

	# 每5发触发一次
	if _bullet_counters[origin_entity_id] % 5 == 0:
		_try_spawn_shadow(tower)

func _try_spawn_shadow(parent_tower: Node) -> void:
	# 获取父炮塔所在单元格
	var parent_cell: Node = _find_parent_cell(parent_tower)
	if not parent_cell:
		return

	# 获取相邻空单元格
	var empty_cells: Array[Node] = _get_adjacent_empty_cells(parent_cell, parent_tower)
	if empty_cells.is_empty():
		return

	# 随机选择一个并生成影子炮塔
	var target_cell: Node = empty_cells.pick_random()
	_spawn_shadow_at_cell(parent_tower, target_cell)

func _find_parent_cell(tower: Node) -> Node:
	# 查找包含此炮塔的单元格
	for cell in tower.get_tree().get_nodes_in_group("grid_cells"):
		if cell.has_method("get_deployed_tower") and cell.get_deployed_tower() == tower:
			return cell
	return null

func _get_adjacent_empty_cells(parent_cell: Node, tower: Node) -> Array[Node]:
	var empty_cells: Array[Node] = []
	var grid_cells: Array[Node] = []
	for cell in tower.get_tree().get_nodes_in_group("grid_cells"):
		grid_cells.append(cell)

	# 获取父单元格在网格中的索引
	var parent_index: int = parent_cell.get_meta("index", -1)
	if parent_index == -1:
		return []

	var parent_row := parent_index / 5
	var parent_col := parent_index % 5

	# 检查3x3区域（排除中心）
	for row_offset in range(-1, 2):
		for col_offset in range(-1, 2):
			if row_offset == 0 and col_offset == 0:
				continue  # 跳过中心单元格

			var target_row := parent_row + row_offset
			var target_col := parent_col + col_offset

			# 检查是否在网格范围内
			if target_row < 0 or target_row >= 5 or target_col < 0 or target_col >= 5:
				continue

			var target_index := target_row * 5 + target_col
			# 找到对应单元格
			for cell in grid_cells:
				if cell.get_meta("index", -1) == target_index:
					if not cell.has_method("is_occupied") or not cell.is_occupied:
						empty_cells.append(cell)
					break

	return empty_cells

func _spawn_shadow_at_cell(parent_tower: Node, target_cell: Node) -> void:
	var shadow_scene := load("res://entities/towers/shadow_tower.tscn")
	if not shadow_scene:
		push_error("Failed to load shadow tower scene")
		return

	var shadow_tower: Node = shadow_scene.instantiate()

	# 在 add_child 前设置 data 和 entity_id，确保 _ready()/_apply_data() 和 on_module_install 都能拿到正确值
	shadow_tower.data = parent_tower.data
	shadow_tower.shadow_team_id = origin_entity_id
	shadow_tower.entity_id = GameState.generate_entity_id()

	# add_child 触发 _ready() 和 _apply_data()，精灵纹理已就绪
	target_cell.add_child(shadow_tower)

	# 修正位置和缩放（必须在 add_child 后，cell.size 和纹理才可用）
	target_cell._setup_tower_visuals(shadow_tower)

	# 标记格子已占用，防止重复生成
	target_cell.is_occupied = true
	target_cell.tower_node = shadow_tower

	# 安装模块，跳过含有 SpawnShadowTowerEffect 的模块（防止影子炮塔递归生成，
	# 同时避免 on_module_install 覆写共享 effect 的 origin_entity_id）
	for module: Module in parent_tower.modules:
		var skip := false
		for e in module.fire_effects:
			if e is SpawnShadowTowerEffect:
				skip = true
				break
		if not skip:
			shadow_tower.install_module(module)

	# 方向跟随本体
	shadow_tower.set_initial_direction(parent_tower.current_rotation_index)

	# 游戏运行中则立即开火
	if GameState.is_running():
		shadow_tower.start_firing()
