class_name SpawnShadowTowerEffect extends FireEffect

## 影子炮塔最大生成深度：0=父塔，1=第一代
## 值为 N 表示第 N 代影子炮塔仍会安装 ShadowTowerModule，第 N+1 代不再安装
const MAX_SHADOW_GENERATION := 1

## 静态字典：按起源炮塔追踪子弹计数
var _bullet_counters: Dictionary = {}  # origin_entity_id -> count

## 起源炮塔的 entity_id（安装时设置）
var origin_entity_id: int = -1

## 是否启用生成能力（gen=0 塔为 true，gen=1 塔为 false，视觉上仍显示模块）
var enabled: bool = true

func on_module_install(tower: Node) -> void:
	# 只在初次安装时写入；影子炮塔继承本模块时不覆盖，保持同一 team 的 origin_entity_id
	if origin_entity_id == -1:
		origin_entity_id = tower.entity_id

func apply(tower: Node, _bd: BulletData) -> void:
	if not enabled:
		return
	# 只有 gen=0 的原始炮塔才能生成影子（防御性检查，防止共享 effect 实例时误触）
	var tower_gen: int = 0
	if tower.has_meta("shadow_generation"):
		tower_gen = tower.get_meta("shadow_generation")
	var tower_eid: int = tower.entity_id if tower.has_method("get_entity_id") or "entity_id" in tower else -1
	if tower_gen > 0:
		print("[SHADOW_COUNT] SKIP gen=%s tower_eid=%s (non-gen0 tower firing)" % [tower_gen, tower_eid])
		return
	# 初始化计数器（如果需要）
	if not _bullet_counters.has(origin_entity_id):
		_bullet_counters[origin_entity_id] = 0

	# 递增计数
	_bullet_counters[origin_entity_id] += 1
	var count: int = _bullet_counters[origin_entity_id]

	print("[SHADOW_COUNT] tower_eid=%s origin=%s count=%s (mod5=%s)" % [tower_eid, origin_entity_id, count, count % 5])

	# 每5发触发一次
	if count % 5 == 0:
		print("[SHADOW_COUNT] TRIGGER spawn for tower_eid=%s" % tower_eid)
		_try_spawn_shadow(tower)

func _try_spawn_shadow(parent_tower: Node) -> void:
	# 只有 gen=0 的原始炮塔才能生成影子塔
	var parent_gen: int = 0
	if parent_tower.has_meta("shadow_generation"):
		parent_gen = parent_tower.get_meta("shadow_generation")
	if parent_gen > 0:
		return

	# 获取父炮塔所在单元格
	var parent_cell: Node = _find_parent_cell(parent_tower)
	if not parent_cell:
		print("[SHADOW_SPAWN] FAIL: parent_cell NOT FOUND for tower_eid=%s" % parent_tower.entity_id)
		return

	# 获取相邻空单元格
	var empty_cells: Array[Node] = _get_adjacent_empty_cells(parent_cell, parent_tower)
	if empty_cells.is_empty():
		print("[SHADOW_SPAWN] FAIL: NO empty cells around parent_cell index=%s" % parent_cell.get_meta("index"))
		return

	# 随机选择一个并生成影子炮塔
	var target_cell: Node = empty_cells.pick_random()
	print("[SHADOW_SPAWN] SUCCESS: picking cell index=%s from %d candidates" % [target_cell.get_meta("index"), empty_cells.size()])
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
	var parent_index: int = -1
	if parent_cell.has_meta("index"):
		parent_index = parent_cell.get_meta("index")
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
				var cell_index: int = -1
				if cell.has_meta("index"):
					cell_index = cell.get_meta("index")
				if cell_index == target_index:
					if not cell.is_occupied:
						empty_cells.append(cell)
					break

	return empty_cells

func _spawn_shadow_at_cell(parent_tower: Node, target_cell: Node) -> void:
	# 二次检查：防止多塔同时开火时快照过期导致的重复占用
	if target_cell.is_occupied:
		print("[SHADOW_SPAWN] ABORT: cell index=%s already occupied (stale snapshot)" % target_cell.get_meta("index"))
		return

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

	# 生成深度 = 父塔深度 + 1（普通炮塔的 shadow_generation 默认为 0）
	var _parent_generation: int = 0
	if parent_tower.has_meta("shadow_generation"):
		_parent_generation = parent_tower.get_meta("shadow_generation")
	shadow_tower.shadow_generation = _parent_generation + 1
	# 同步写入 meta，确保子代读取正确
	shadow_tower.set_meta("shadow_generation", shadow_tower.shadow_generation)

	# ── Deep copy 父塔生成瞬间的弹药状态 ──
	var _parent_ammo: int = parent_tower.ammo
	var _parent_cursor: int = parent_tower.ammo_cursor
	var _parent_queue: Array = parent_tower.ammo_queue
	if _parent_ammo == -1:
		# 父塔无限弹药：影子塔也无限
		shadow_tower.ammo = -1
		shadow_tower.ammo_queue.clear()
		shadow_tower.ammo_cursor = 0
	else:
		# 父塔有限弹药：deep copy 剩余未消费的弹药项
		var _remaining := _parent_queue.size() - _parent_cursor
		if _remaining > 0:
			var _copy_queue: Array = []
			for _i in range(_parent_cursor, _parent_queue.size()):
				var _src: AmmoItem = _parent_queue[_i]
				var _copy := AmmoItem.new()
				_copy.effect_contribution_counts = _src.effect_contribution_counts.duplicate()
				_copy.tower_effect_trigger_counts = _src.tower_effect_trigger_counts.duplicate()
				_copy_queue.append(_copy)
			shadow_tower.ammo_queue = _copy_queue
		shadow_tower.ammo_cursor = 0
		shadow_tower.ammo = 0  # 有限弹药标记
	shadow_tower._update_ammo_label()

	# 安装模块：
	# - 不含 SpawnShadowTowerEffect 的模块：直接安装
	# - 含 SpawnShadowTowerEffect 的模块（ShadowTowerModule）：
	#     始终安装（视觉上槽位显示满），apply() 内通过 generation 检查阻止非 gen=0 生成
	for module: Module in parent_tower.modules:
		var has_shadow_effect := false
		for e in module.fire_effects:
			if e is SpawnShadowTowerEffect:
				has_shadow_effect = true
				break
		if has_shadow_effect:
			if shadow_tower.shadow_generation <= MAX_SHADOW_GENERATION:
				shadow_tower.install_module(module)
		else:
			shadow_tower.install_module(module)

	# 刷新格子槽位颜色（Bug2 修复：程序化放置后 cell 不会自动刷新 slot dots）
	target_cell._refresh_slot_dots()

	# 方向跟随本体
	shadow_tower.set_initial_direction(parent_tower.current_rotation_index)

	# 游戏运行中则立即开火
	if GameState.is_running():
		shadow_tower.start_firing()
