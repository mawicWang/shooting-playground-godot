# GdUnit4 Test Suite for Full Chain Testing
# 测试完整链条：安装模块 -> 发射子弹 -> 击中目标 -> 触发效果

class_name FullChainTest
extends GdUnitTestSuite

const MODULE_DATA_DIR := "res://resources/module_data/"

class TestTower extends Node:
	"""用于测试的 Tower 模拟类，提供 Effect 所需的所有方法"""
	var ammo: int = 5
	var cd: float = 2.0
	var reduce_cooldown_calls: Array = []
	var add_ammo_calls: Array = []
	var bullet_effects: Array = []
	var tower_effects: Array = []

	func reduce_cooldown(amount: float) -> void:
		reduce_cooldown_calls.append(amount)
		cd = max(0, cd - amount)

	func add_ammo(amount: int) -> void:
		add_ammo_calls.append(amount)
		ammo += amount

	func install_module(module: Module) -> void:
		# 模拟模块安装：直接添加 effects（不做 duplicate）
		for effect in module.bullet_effects:
			bullet_effects.append(effect)
		for effect in module.tower_effects:
			tower_effects.append(effect)


func before() -> void:
	# 在每个测试前重置
	pass


func test_cd_reduce_on_enemy_full_chain() -> void:
	"""测试完整链条：安装 cd_on_hit_enemy 模块 -> 发射子弹 -> 击中敌人 -> 减少 CD"""
	var module := load(MODULE_DATA_DIR + "cd_on_hit_enemy.tres") as Module
	assert_object(module).is_not_null()

	# 创建测试塔
	var tower: TestTower = auto_free(TestTower.new())

	# 安装模块
	tower.install_module(module)

	# 验证 bullet_effects 已安装
	assert_array(tower.bullet_effects).is_not_empty()

	# 获取 effect
	var effect = tower.bullet_effects[0]
	assert_object(effect).is_not_null()

	# 创建 BulletData 并设置 transmission_chain
	var bd := BulletData.new()
	bd.transmission_chain = [tower]

	# 创建模拟敌人
	var enemy: Node = auto_free(Node.new())

	# 记录初始状态
	var initial_cd: float = tower.cd

	# 触发 effect
	effect.on_hit_enemy(bd, enemy)

	# 验证 reduce_cooldown 被调用
	assert_array(tower.reduce_cooldown_calls).has_size(1)
	assert_float(tower.reduce_cooldown_calls[0]).is_equal(0.5)

	# 验证 CD 实际减少
	assert_float(tower.cd).is_equal(initial_cd - 0.5)


func test_replenish_effect_full_chain() -> void:
	"""测试完整链条：安装 replenish 模块 -> 发射子弹 -> 击中塔 -> 补充弹药"""
	var module := load(MODULE_DATA_DIR + "replenish1.tres") as Module
	assert_object(module).is_not_null()

	var tower: TestTower = auto_free(TestTower.new())
	tower.ammo = 3

	tower.install_module(module)

	# 验证 bullet_effects 已安装
	assert_array(tower.bullet_effects).is_not_empty()

	var effect = tower.bullet_effects[0]
	assert_object(effect).is_not_null()

	var bd := BulletData.new()
	bd.transmission_chain = [tower]

	# 创建目标塔（会被子弹击中的塔）
	var target_tower: TestTower = auto_free(TestTower.new())
	target_tower.ammo = 3

	# 触发 effect
	effect.on_hit_tower(bd, target_tower)

	# 验证 add_ammo 被调用
	assert_array(target_tower.add_ammo_calls).has_size(1)
	assert_int(target_tower.add_ammo_calls[0]).is_equal(1)

	# 验证弹药实际增加
	assert_int(target_tower.ammo).is_equal(4)


func test_module_install_adds_stat_modifiers() -> void:
	"""测试安装模块时 stat_modifiers 被正确应用"""
	var module := load(MODULE_DATA_DIR + "accelerator.tres") as Module
	assert_object(module).is_not_null()

	# 使用 MockTower
	var MockTowerScript = load("res://tests/mock_tower.gd")
	assert_object(MockTowerScript).is_not_null()

	var tower = auto_free(MockTowerScript.new())

	# 记录初始速度
	var initial_speed: float = tower.get_bullet_speed()

	# 安装模块
	var success: bool = tower.install_module(module)
	assert_bool(success).is_true()

	# 验证速度增加
	var new_speed: float = tower.get_bullet_speed()
	assert_float(new_speed).is_equal(initial_speed + 150.0)

	# 验证模块计数
	assert_int(tower.get_module_count()).is_equal(1)


func test_bullet_carries_effects_from_tower() -> void:
	"""测试子弹从塔继承 effects"""
	var module := load(MODULE_DATA_DIR + "cd_on_hit_enemy.tres") as Module
	assert_object(module).is_not_null()

	var tower: TestTower = auto_free(TestTower.new())
	tower.install_module(module)

	# 模拟塔发射子弹：子弹应携带塔的 effects
	var bd := BulletData.new()
	bd.effects = tower.bullet_effects.duplicate()
	bd.transmission_chain = [tower]

	# 验证子弹有 effects
	assert_array(bd.effects).is_not_empty()

	# 验证 transmission_chain 正确设置
	assert_array(bd.transmission_chain).has_size(1)
	assert_object(bd.transmission_chain[0]).is_same(tower)


func test_multiple_effects_in_chain() -> void:
	"""测试多个 effects 在链条中正确触发"""
	var module1 := load(MODULE_DATA_DIR + "cd_on_hit_enemy.tres") as Module
	var module2 := load(MODULE_DATA_DIR + "replenish1.tres") as Module

	assert_object(module1).is_not_null()
	assert_object(module2).is_not_null()

	var tower: TestTower = auto_free(TestTower.new())
	tower.ammo = 5

	# 安装两个模块
	tower.install_module(module1)
	tower.install_module(module2)

	# 验证两个 effects 都添加了
	assert_array(tower.bullet_effects).has_size(2)

	# 创建子弹数据
	var bd := BulletData.new()
	bd.effects = tower.bullet_effects
	bd.transmission_chain = [tower]

	# 创建目标塔
	var target_tower: TestTower = auto_free(TestTower.new())
	target_tower.ammo = 3

	# 创建敌人
	var enemy: Node = auto_free(Node.new())

	# 使用 call 方法触发 effects（绕过 has_method 检查）
	for effect in bd.effects:
		if effect is CdReduceOnEnemyEffect:
			effect.on_hit_enemy(bd, enemy)
		elif effect is ReplenishEffect:
			effect.on_hit_tower(bd, target_tower)

	# 验证两个 effects 都触发了
	assert_array(tower.reduce_cooldown_calls).has_size(1)
	assert_array(target_tower.add_ammo_calls).has_size(1)


func test_effect_cleanup_on_module_uninstall() -> void:
	"""测试模块卸载时 effects 被正确清理"""
	var MockTowerScript = load("res://tests/mock_tower.gd")
	assert_object(MockTowerScript).is_not_null()

	var tower = auto_free(MockTowerScript.new())
	var module := load(MODULE_DATA_DIR + "accelerator.tres") as Module

	# 安装前
	var initial_effects_count: int = tower.bullet_effects.size()
	var initial_speed: float = tower.get_bullet_speed()

	# 安装模块
	tower.install_module(module)
	assert_array(tower.bullet_effects).has_size(initial_effects_count + module.bullet_effects.size())
	assert_float(tower.get_bullet_speed()).is_greater(initial_speed)

	# 卸载模块
	tower.uninstall_module(0)

	# 验证 effects 被移除
	assert_array(tower.bullet_effects).has_size(initial_effects_count)

	# 验证速度恢复
	assert_float(tower.get_bullet_speed()).is_equal(initial_speed)
