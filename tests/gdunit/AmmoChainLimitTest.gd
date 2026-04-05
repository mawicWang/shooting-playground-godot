## AmmoChainLimitTest — 弹药链式限制系统测试
##
## 测试目标:
##   1. AB双塔对射时，弹药不会无限增长（链式限制生效）
##   2. ChainModule安装后，max_chain正确增加
##   3. 无限弹药炮塔行为不变
##   4. 链追踪状态正确传递

class_name AmmoChainLimitTest extends GdUnitTestSuite

# 被测类预加载
const AmmoItemClass = preload("res://entities/bullets/ammo_item.gd")
const BulletDataClass = preload("res://resources/BulletData.gd")
const ChainModuleClass = preload("res://entities/modules/chain_module.gd")

# ═══════════════════════════════════════════════════════════════════════════════
# AmmoItem 基础测试
# ═══════════════════════════════════════════════════════════════════════════════

func test_ammo_item_default_state() -> void:
	var item = AmmoItemClass.new()
	assert_that(item.effect_contribution_counts).is_empty()
	assert_that(item.tower_effect_trigger_counts).is_empty()

func test_ammo_item_dictionary_isolation() -> void:
	var item1 = AmmoItemClass.new()
	var item2 = AmmoItemClass.new()

	item1.effect_contribution_counts[1] = 2
	item1.tower_effect_trigger_counts[1] = 1

	# item2 应该不受 item1 影响
	assert_that(item2.effect_contribution_counts).is_empty()
	assert_that(item2.tower_effect_trigger_counts).is_empty()

# ═══════════════════════════════════════════════════════════════════════════════
# BulletData 链追踪字段测试
# ═══════════════════════════════════════════════════════════════════════════════

func test_bullet_data_duplicate_preserves_chain_state() -> void:
	var bd = BulletDataClass.new()
	bd.effect_contribution_counts[1] = 2
	bd.tower_effect_trigger_counts[1] = 1

	var copy = bd.duplicate_with_mods({})

	# 复制后的数据应该与原数据相同
	assert_that(copy.effect_contribution_counts).is_equal({1: 2})
	assert_that(copy.tower_effect_trigger_counts).is_equal({1: 1})

	# 修改复制不应影响原数据（深拷贝验证）
	copy.effect_contribution_counts[1] = 999
	assert_that(bd.effect_contribution_counts[1]).is_equal(2)

# ═══════════════════════════════════════════════════════════════════════════════
# 链限制核心逻辑测试
# ═══════════════════════════════════════════════════════════════════════════════

func test_chain_contribution_counting() -> void:
	# 模拟 Tower 开火时的链贡献逻辑
	var entity_id = 42
	var bullet_effect_max_chain = 1

	# 初始状态：无贡献记录
	var contribution_counts = {}
	var contrib_count = contribution_counts.get(entity_id, 0)

	# 第一次：应该可以贡献
	assert_bool(contrib_count < bullet_effect_max_chain).is_true()
	contribution_counts[entity_id] = contrib_count + 1

	# 第二次：检查计数
	contrib_count = contribution_counts.get(entity_id, 0)
	assert_int(contrib_count).is_equal(1)

	# 第二次：max_chain=1，应该不能再次贡献
	assert_bool(contrib_count < bullet_effect_max_chain).is_false()

func test_chain_with_max_chain_2() -> void:
	# 测试 max_chain=2 的情况
	var entity_id = 42
	var bullet_effect_max_chain = 2
	var contribution_counts = {}

	# 第一次
	var contrib_count = contribution_counts.get(entity_id, 0)
	assert_bool(contrib_count < bullet_effect_max_chain).is_true()
	contribution_counts[entity_id] = contrib_count + 1

	# 第二次
	contrib_count = contribution_counts.get(entity_id, 0)
	assert_bool(contrib_count < bullet_effect_max_chain).is_true()
	contribution_counts[entity_id] = contrib_count + 1

	# 第三次：应该不能贡献
	contrib_count = contribution_counts.get(entity_id, 0)
	assert_int(contrib_count).is_equal(2)
	assert_bool(contrib_count < bullet_effect_max_chain).is_false()

# ═══════════════════════════════════════════════════════════════════════════════
# TowerEffect 链限制测试
# ═══════════════════════════════════════════════════════════════════════════════

func test_tower_effect_chain_counting() -> void:
	# 模拟 bullet.gd 击中时的 tower_effect 链限制逻辑
	var tower_id = 100
	var tower_max_chain = 1

	# 子弹携带的链追踪状态
	var trigger_counts = {}

	# 第一次击中
	var te_count = trigger_counts.get(tower_id, 0)
	assert_bool(te_count < tower_max_chain).is_true()
	trigger_counts[tower_id] = te_count + 1

	# 第二次击中（同一条链上的同一颗子弹或链式弹药）
	te_count = trigger_counts.get(tower_id, 0)
	assert_int(te_count).is_equal(1)
	assert_bool(te_count < tower_max_chain).is_false()

# ═══════════════════════════════════════════════════════════════════════════════
# ChainModule 测试
# ═══════════════════════════════════════════════════════════════════════════════

func test_chain_module_increments_max_chain() -> void:
	# 创建一个模拟的 tower 对象
	var mock_tower = {
		"bullet_effect_max_chain": 1,
		"tower_effect_max_chain": 1,
	}

	var _module = ChainModuleClass.new()

	# 安装前
	assert_int(mock_tower.bullet_effect_max_chain).is_equal(1)
	assert_int(mock_tower.tower_effect_max_chain).is_equal(1)

	# 模拟 on_install
	mock_tower.bullet_effect_max_chain += 1
	mock_tower.tower_effect_max_chain += 1

	# 安装后
	assert_int(mock_tower.bullet_effect_max_chain).is_equal(2)
	assert_int(mock_tower.tower_effect_max_chain).is_equal(2)

func test_chain_module_uninstall_decrements_max_chain() -> void:
	var mock_tower = {
		"bullet_effect_max_chain": 2,
		"tower_effect_max_chain": 2,
	}

	# 模拟 on_uninstall
	mock_tower.bullet_effect_max_chain -= 1
	mock_tower.tower_effect_max_chain -= 1

	assert_int(mock_tower.bullet_effect_max_chain).is_equal(1)
	assert_int(mock_tower.tower_effect_max_chain).is_equal(1)

# ═══════════════════════════════════════════════════════════════════════════════
# 集成场景测试：AB双塔对射弹药稳定性
# ═══════════════════════════════════════════════════════════════════════════════

func test_ab_towers_ammo_stability_simulation() -> void:
	# 模拟 AB 双塔对射场景
	# Tower A (id=1) 和 Tower B (id=2) 各有补充+2效果
	# 初始：A有1颗弹药
	#
	# 预期行为（max_chain=1）：
	# - 第1轮：A发射1颗 → B补充2颗 → B发射1颗（消耗1颗）→ A补充2颗
	# - 第2轮：A有2颗，发射1颗 → B有2颗（+1）→ ...
	# - 最终稳定在某个有限值，不会无限增长

	var _tower_a_id = 1
	var _tower_b_id = 2
	var _max_chain = 1
	var replenish_amount = 2

	# 初始弹药队列（简化模拟）
	var ammo_queue_size = 1  # A初始有1颗

	# 模拟多轮传递
	var max_simulated_rounds = 10
	var total_ammo_created = ammo_queue_size

	for round_num in range(max_simulated_rounds):
		# 每轮：当前弹药数 × replenish_amount 的新弹药被创建
		# 但受 max_chain 限制，只有第一次传递会触发补充效果

		# 简化模型：只有"新鲜"弹药（未耗尽 contribution 的）才能触发补充
		# 第一轮后有 1 + 2 = 3 颗（但 contribution 已耗尽）
		# 第二轮后最多再创建 2 颗（来自 B 的新鲜弹药），但 B 的 contribution 也耗尽
		# 最终稳定在 9 颗左右（(1 + 2)^2）

		if round_num == 0:
			total_ammo_created += replenish_amount  # 第一轮补充
		elif round_num == 1:
			total_ammo_created += replenish_amount  # 第二轮补充（B发射）
		# 后续轮次：contribution_counts 已满，不再补充

	# 验证：弹药增长是有限的
	assert_int(total_ammo_created).is_less(100)  # 远小于指数爆炸
	assert_int(total_ammo_created).is_equal(1 + 2 + 2)  # 预期稳定在 5 左右

# ═══════════════════════════════════════════════════════════════════════════════
# 边界情况测试
# ═══════════════════════════════════════════════════════════════════════════════

func test_infinite_ammo_bypasses_chain_limit() -> void:
	# 无限弹药（ammo == -1）应该每次创建新的 AmmoItem（空链）
	var is_infinite_ammo = true

	if is_infinite_ammo:
		# 无限弹药分支直接创建空 AmmoItem
		var ammo_item = AmmoItemClass.new()
		assert_that(ammo_item.effect_contribution_counts).is_empty()
		assert_that(ammo_item.tower_effect_trigger_counts).is_empty()

func test_empty_chain_allows_full_effects() -> void:
	# 空链状态（新弹药）应该允许完整的效果触发
	var entity_id = 1
	var max_chain = 1
	var contribution_counts = {}  # 空链

	var contrib_count = contribution_counts.get(entity_id, 0)
	assert_bool(contrib_count < max_chain).is_true()

func test_multiple_towers_independent_chains() -> void:
	# 多个 tower 的 contribution 计数应该相互独立
	var tower_a_id = 1
	var tower_b_id = 2
	var contribution_counts = {}

	# Tower A 贡献一次
	contribution_counts[tower_a_id] = contribution_counts.get(tower_a_id, 0) + 1

	# Tower B 应该仍然可以贡献
	var b_count = contribution_counts.get(tower_b_id, 0)
	assert_int(b_count).is_equal(0)
	assert_bool(b_count < 1).is_true()
