## TowerAmmoResetTest — 关卡结束后弹药重置测试
##
## 测试目标：
##   1. 验证 Bug：旧 _reset_all_tower_ammo 只改 tower.ammo，不重置 ammo_queue/ammo_cursor
##   2. 验证 Fix：tower.reset_ammo() 正确恢复 ammo_queue 和 ammo_cursor
##   3. 覆盖：有限弹药、无限弹药、波次结束完整场景

class_name TowerAmmoResetTest extends GdUnitTestSuite

const AmmoItemClass = preload("res://entities/bullets/ammo_item.gd")
const TestTowerData  = preload("res://resources/simple_emitter.tres")  # initial_ammo = 10
const TowerScene     = preload("res://entities/towers/tower.tscn")

var _nodes_to_free: Array[Node] = []

func before_test() -> void:
	_nodes_to_free.clear()

func after_test() -> void:
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()

func _make_tower(td: TowerData = null) -> Node:
	var tower = TowerScene.instantiate()
	if td:
		tower.data = td
	get_tree().root.add_child(tower)
	_nodes_to_free.append(tower)
	return tower

# ═══════════════════════════════════════════════════════════════════════════════
# 内联逻辑测试（不依赖节点，纯验证 ammo_queue / ammo_cursor 语义）
# ═══════════════════════════════════════════════════════════════════════════════

## 验证 has_ammo() 的语义：ammo 字段不是 0/-1 的情况下，仍依赖 cursor < queue.size()
func test_has_ammo_depends_on_queue_not_ammo_field() -> void:
	# 模拟有限弹药内部状态
	var ammo: int = 0  # 有限弹药标志位（_apply_data 最终将其置 0）
	var ammo_queue: Array = []
	var ammo_cursor: int = 0

	# 初始：3 发弹药
	for _i in range(3):
		ammo_queue.append(AmmoItemClass.new())

	# has_ammo() 等效逻辑
	var has_ammo_fn = func(): return ammo == -1 or ammo_cursor < ammo_queue.size()

	assert_bool(has_ammo_fn.call()).is_true()

	# 消耗全部
	ammo_cursor = 3
	assert_bool(has_ammo_fn.call()).is_false()

	# 旧 Bug 重现：只改 ammo 字段，不碰 queue/cursor
	ammo = 3  # 模拟旧 _reset_all_tower_ammo 的行为
	assert_bool(has_ammo_fn.call()).is_false()  # 仍然没弹药 —— Bug！

	# 正确修复：重置 queue 和 cursor
	ammo_queue.clear()
	ammo_cursor = 0
	for _i in range(3):
		ammo_queue.append(AmmoItemClass.new())
	ammo = 0  # 有限弹药标志位
	assert_bool(has_ammo_fn.call()).is_true()  # 弹药恢复

## 验证 ammo_count() 在消耗后的计算
func test_ammo_count_after_consume() -> void:
	var ammo_queue: Array = []
	var ammo_cursor: int = 0

	for _i in range(5):
		ammo_queue.append(AmmoItemClass.new())

	var ammo_count_fn = func(): return ammo_queue.size() - ammo_cursor

	assert_int(ammo_count_fn.call()).is_equal(5)

	ammo_cursor = 5
	assert_int(ammo_count_fn.call()).is_equal(0)

	# 旧 Bug：ammo 设为 5 后，ammo_count() 还是 0（cursor 没动）
	# 注意：tower.gd 中 ammo_count() 不看 ammo 字段，看 queue.size()-cursor
	assert_int(ammo_count_fn.call()).is_equal(0)  # Bug 仍在

	# 修复后
	ammo_queue.clear()
	ammo_cursor = 0
	for _i in range(5):
		ammo_queue.append(AmmoItemClass.new())
	assert_int(ammo_count_fn.call()).is_equal(5)

## 无限弹药不受 reset 影响
func test_infinite_ammo_unaffected_by_reset() -> void:
	var ammo: int = -1
	var ammo_queue: Array = []
	var ammo_cursor: int = 0

	var has_ammo_fn = func(): return ammo == -1 or ammo_cursor < ammo_queue.size()

	assert_bool(has_ammo_fn.call()).is_true()

	# 模拟 reset：无限弹药时 ammo 保持 -1
	ammo_queue.clear()
	ammo_cursor = 0
	assert_bool(has_ammo_fn.call()).is_true()

# ═══════════════════════════════════════════════════════════════════════════════
# 节点级集成测试：tower.reset_ammo() 方法
# ═══════════════════════════════════════════════════════════════════════════════

## 有限弹药塔：消耗完后调用 reset_ammo() 应恢复满弹
func test_finite_tower_reset_ammo_restores_full_ammo() -> void:
	var tower = _make_tower(TestTowerData)
	await get_tree().process_frame  # 等待 _ready

	# 验证初始状态
	var initial = tower.ammo_count()  # 应为 10
	assert_int(initial).is_equal(TestTowerData.initial_ammo)

	# 消耗全部弹药
	for _i in range(initial):
		tower.consume_ammo()

	assert_int(tower.ammo_count()).is_equal(0)
	assert_bool(tower.has_ammo()).is_false()

	# 调用重置
	tower.reset_ammo()

	# 弹药应完全恢复
	assert_int(tower.ammo_count()).is_equal(TestTowerData.initial_ammo)
	assert_bool(tower.has_ammo()).is_true()

## 部分消耗后 reset_ammo() 也应恢复到满弹
func test_partial_consume_reset_ammo_restores_full() -> void:
	var tower = _make_tower(TestTowerData)
	await get_tree().process_frame

	# 消耗部分
	tower.consume_ammo()
	tower.consume_ammo()
	tower.consume_ammo()

	assert_int(tower.ammo_count()).is_equal(TestTowerData.initial_ammo - 3)

	tower.reset_ammo()

	assert_int(tower.ammo_count()).is_equal(TestTowerData.initial_ammo)

## 无限弹药塔调用 reset_ammo() 后仍保持无限
func test_infinite_tower_reset_ammo_stays_infinite() -> void:
	var td = TowerData.new()
	td.initial_ammo = -1
	td.firing_rate = 1.0

	var tower = _make_tower(td)
	await get_tree().process_frame

	assert_bool(tower.has_ammo()).is_true()
	assert_int(tower.ammo_count()).is_equal(-1)

	tower.reset_ammo()

	assert_bool(tower.has_ammo()).is_true()
	assert_int(tower.ammo_count()).is_equal(-1)

## 验证 reset_ammo() 后 ammo_cursor 归零（不会带入旧的游标）
func test_reset_ammo_clears_cursor() -> void:
	var tower = _make_tower(TestTowerData)
	await get_tree().process_frame

	# 消耗 5 发
	for _i in range(5):
		tower.consume_ammo()

	assert_int(tower.ammo_cursor).is_greater(0)

	tower.reset_ammo()

	assert_int(tower.ammo_cursor).is_equal(0)

## add_ammo 后再 reset_ammo 应回到 initial_ammo（不应包含波次中途新增的弹药）
func test_reset_ammo_ignores_runtime_additions() -> void:
	var tower = _make_tower(TestTowerData)
	await get_tree().process_frame

	# 波次中途通过补充效果额外加了弹药
	tower.add_ammo(5)

	var before_reset = tower.ammo_count()
	assert_int(before_reset).is_equal(TestTowerData.initial_ammo + 5)

	tower.reset_ammo()

	# reset 应回到 initial_ammo，不带上运行时额外弹药
	assert_int(tower.ammo_count()).is_equal(TestTowerData.initial_ammo)
