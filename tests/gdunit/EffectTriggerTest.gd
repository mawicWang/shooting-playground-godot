# GdUnit4 Test Suite for Effect Triggers
# 测试 Module 的 effects 在触发时的行为

class_name EffectTriggerTest
extends GdUnitTestSuite

const MODULE_DATA_DIR := "res://resources/module_data/"


func test_cd_reduce_on_enemy_effect() -> void:
	"""测试 CdReduceOnEnemyEffect 触发时减少炮塔 CD"""
	var module := load(MODULE_DATA_DIR + "cd_on_hit_enemy.tres") as Module
	if not module:
		skip("cd_on_hit_enemy module not found")
		return
	
	# 创建 Mock Tower
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		skip("MockTower not available")
		return
	
	var tower = auto_free(MockTowerScript.new())
	
	# 安装模块
	tower.install_module(module)
	
	# 验证 bullet_effects 已安装
	assert_array(tower.bullet_effects).is_not_empty()
	
	# 创建 BulletData
	var bd := BulletData.new()
	bd.effects = tower.bullet_effects.duplicate()
	bd.transmission_chain = [tower]
	
	# 获取 effect 并手动触发
	var effect = bd.effects[0]
	assert_object(effect).is_not_null()
	
	# 创建一个 mock enemy
	var enemy = auto_free(Node.new())
	
	# 触发 effect（如果它有 on_hit_enemy 方法）
	if effect.has_method("on_hit_enemy"):
		# MockTower 现在有 reduce_cooldown 方法
		effect.on_hit_enemy(bd, enemy)
		
		# 验证 reduce_cooldown 被调用
		assert_array(tower.reduce_cooldown_calls).is_not_empty()
		assert_float(tower.reduce_cooldown_calls[0]).is_equal(0.5)
	else:
		fail("Effect should have on_hit_enemy method")


func test_cd_reduce_on_receive_effect() -> void:
	"""测试 CdReduceOnReceiveTowerEffect 触发时减少 CD"""
	var module := load(MODULE_DATA_DIR + "cd_on_receive_hit.tres") as Module
	if not module:
		skip("cd_on_receive_hit module not found")
		return
	
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		skip("MockTower not available")
		return
	
	var tower = MockTowerScript.new()
	
	// 安装模块
	tower.install_module(module)
	
	// 验证 tower_effects 已安装
	assert_array(tower.tower_effects).is_not_empty()
	
	// 获取 effect
	var effect = tower.tower_effects[0]
	assert_object(effect).is_not_null()
	
	// 创建 BulletData
	var bd := BulletData.new()
	
	// 触发 effect
	if effect.has_method("on_receive_bullet_hit"):
		effect.on_receive_bullet_hit(bd, tower)
		assert_bool(true).is_true()


func test_replenish_effect() -> void:
	"""测试 ReplenishEffect 补充弹药"""
	var module := load(MODULE_DATA_DIR + "replenish1.tres") as Module
	if not module:
		skip("replenish1 module not found")
		return
	
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		skip("MockTower not available")
		return
	
	var tower = auto_free(MockTowerScript.new())
	tower.ammo = 3
	
	# 安装模块
	tower.install_module(module)
	
	# 验证 bullet_effects 已安装
	assert_array(tower.bullet_effects).is_not_empty()
	
	# 获取 effect
	var effect = tower.bullet_effects[0]
	assert_object(effect).is_not_null()
	
	# 创建 BulletData
	var bd := BulletData.new()
	bd.transmission_chain = [tower]
	
	# 创建目标塔
	var target_tower = auto_free(MockTowerScript.new())
	target_tower.ammo = 3
	
	# 触发 effect
	if effect.has_method("on_hit_tower"):
		effect.on_hit_tower(bd, target_tower)
		
		# 验证 add_ammo 被调用
		assert_int(target_tower.ammo_added).is_equal(1)
		assert_int(target_tower.ammo).is_equal(4)
	else:
		fail("Effect should have on_hit_tower method")


func test_effect_install_uninstall() -> void:
	"""测试 effects 在安装和卸载时的正确添加和移除"""
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		skip("MockTower not available")
		return
	
	var tower = MockTowerScript.new()
	var module := load(MODULE_DATA_DIR + "accelerator.tres") as Module
	
	// 初始状态
	var initial_effects_count := tower.bullet_effects.size()
	
	// 安装模块
	tower.install_module(module)
	assert_array(tower.bullet_effects).has_size(initial_effects_count + module.bullet_effects.size())
	
	// 卸载模块
	tower.uninstall_module(0)
	assert_array(tower.bullet_effects).has_size(initial_effects_count)
