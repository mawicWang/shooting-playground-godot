# GdUnit4 Test Suite for Module Testing
# 运行方式: 在 Godot 编辑器中点击 GdUnit 面板运行，或使用命令行:
# godot --headless --script addons/gdUnit4/runtest.gd --path . -s tests/gdunit/ModuleTest.gd

class_name ModuleTest
extends GdUnitTestSuite

const MODULE_DATA_DIR := "res://resources/module_data/"

# 扫描到的模块列表
var _module_names: Array[String] = []

# 已测试的模块列表（用于验证覆盖率）
var _tested_modules: Array[String] = []


func before() -> void:
	# 扫描所有模块资源
	_module_names = _scan_modules()
	print("Found %d modules: %s" % [_module_names.size(), ", ".join(_module_names)])


func after() -> void:
	# 验证所有模块都被测试了
	_tested_modules.sort()
	_module_names.sort()
	
	print("\n=== Coverage Check ===")
	print("Modules in directory: %d" % _module_names.size())
	print("Modules tested: %d" % _tested_modules.size())
	
	# 使用 GdUnit 断言验证覆盖率
	assert_int(_tested_modules.size()).is_equal(_module_names.size())
	
	for i in range(_module_names.size()):
		assert_str(_tested_modules[i]).is_equal(_module_names[i])


func _scan_modules() -> Array[String]:
	var names: Array[String] = []
	var dir := DirAccess.open(MODULE_DATA_DIR)
	if dir:
		dir.list_dir_begin()
		var file := dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				names.append(file.get_basename())
			file = dir.get_next()
		dir.list_dir_end()
	names.sort()
	return names


func _record_tested(module_name: String) -> void:
	if not _tested_modules.has(module_name):
		_tested_modules.append(module_name)


# ═══════════════════════════════════════════════════════════════════════════════
# 基础资源加载测试 - 为每个模块自动生成
# ═══════════════════════════════════════════════════════════════════════════════

func test_all_modules_can_be_loaded() -> void:
	"""验证所有模块资源可以被加载"""
	for module_name in _module_names:
		var module := load(MODULE_DATA_DIR + module_name + ".tres") as Module
		assert_object(module).is_not_null()
		_record_tested(module_name)


func test_all_modules_have_valid_names() -> void:
	"""验证所有模块有有效的名称"""
	for module_name in _module_names:
		var module := load(MODULE_DATA_DIR + module_name + ".tres") as Module
		assert_that(module.module_name).is_not_empty()
		assert_that(module.module_name).is_not_null()
		_record_tested(module_name)


func test_all_modules_have_descriptions() -> void:
	"""验证所有模块有描述"""
	for module_name in _module_names:
		var module := load(MODULE_DATA_DIR + module_name + ".tres") as Module
		assert_that(module.description).is_not_null()
		_record_tested(module_name)


func test_all_modules_have_custom_colors() -> void:
	"""验证所有模块有自定义颜色（不是默认灰色）"""
	var default_color := Color(0.5, 0.5, 0.5)
	for module_name in _module_names:
		var module := load(MODULE_DATA_DIR + module_name + ".tres") as Module
		assert_that(module.slot_color).is_not_equal(default_color)
		_record_tested(module_name)


func test_all_modules_have_valid_categories() -> void:
	"""验证所有模块有有效的 category 值"""
	for module_name in _module_names:
		var module := load(MODULE_DATA_DIR + module_name + ".tres") as Module
		var valid := module.category >= 0 and module.category <= 2
		assert_bool(valid).is_true()
		_record_tested(module_name)


# ═══════════════════════════════════════════════════════════════════════════════
# 特定模块详细测试
# ═══════════════════════════════════════════════════════════════════════════════

func test_accelerator_module() -> void:
	"""加速器模块：子弹速度 +150"""
	var module := load(MODULE_DATA_DIR + "accelerator.tres") as Module
	
	assert_that(module.module_name).is_equal("加速器")
	assert_that(module.category).is_equal(Module.Category.COMPUTATIONAL)
	
	# 验证 stat_modifiers
	assert_array(module.stat_modifiers).has_size(1)
	var mod := module.stat_modifiers[0]
	assert_that(mod.stat).is_equal(TowerStatModifierRes.Stat.BULLET_SPEED)
	assert_that(mod.value).is_equal(150.0)
	assert_that(mod.modifier_type).is_equal(StatModifier.Type.ADDITIVE)
	
	_record_tested("accelerator")


func test_multiplier_module() -> void:
	"""乘法器模块：攻击力 ×1.2"""
	var module := load(MODULE_DATA_DIR + "multiplier.tres") as Module
	
	assert_that(module.module_name).is_equal("乘法器")
	
	# 验证 stat_modifiers
	if module.stat_modifiers.size() > 0:
		var mod := module.stat_modifiers[0]
		assert_that(mod.stat).is_equal(TowerStatModifierRes.Stat.BULLET_ATTACK)
		assert_that(mod.modifier_type).is_equal(StatModifier.Type.MULTIPLICATIVE)
	
	_record_tested("multiplier")


func test_flying_module() -> void:
	"""飞行器模块：使炮塔进入飞行状态"""
	var module := load(MODULE_DATA_DIR + "flying.tres") as Module
	
	assert_that(module.module_name).is_equal("飞行器")
	assert_that(module.category).is_equal(Module.Category.SPECIAL)
	
	# 验证脚本类
	var script := load("res://entities/modules/flying_module.gd") as GDScript
	var instance = script.new()
	assert_object(instance).is_instanceof(Module)
	
	_record_tested("flying")


func test_anti_air_module() -> void:
	"""防空炮模块：可以攻击飞行单位"""
	var module := load(MODULE_DATA_DIR + "anti_air.tres") as Module
	
	assert_that(module.module_name).is_equal("防空炮")
	
	# 验证脚本类
	var script := load("res://entities/modules/anti_air_module.gd") as GDScript
	var instance = script.new()
	assert_object(instance).is_instanceof(Module)
	
	_record_tested("anti_air")


func test_cd_on_hit_modules() -> void:
	"""CD 触发类模块：击中时减少 CD"""
	var cd_modules := ["cd_on_hit_enemy", "cd_on_hit_tower_self", "cd_on_hit_tower_target", "cd_on_receive_hit"]
	
	for module_name in cd_modules:
		if not _module_names.has(module_name):
			continue
			
		var module := load(MODULE_DATA_DIR + module_name + ".tres") as Module
		
		# 至少有一个效果数组不为空
		var has_effects := module.fire_effects.size() > 0 or module.bullet_effects.size() > 0 or module.tower_effects.size() > 0
		assert_bool(has_effects).is_true().override_failure_message("Module %s should have effects" % module_name)
		
		_record_tested(module_name)


func test_replenish_modules() -> void:
	"""补充模块：补充弹药"""
	var replenish_modules := ["replenish1", "replenish2"]
	
	for module_name in replenish_modules:
		if not _module_names.has(module_name):
			continue
			
		var module := load(MODULE_DATA_DIR + module_name + ".tres") as Module
		var expected_name := "补充+1" if module_name == "replenish1" else "补充+2"
		assert_that(module.module_name).is_equal(expected_name)
		
		_record_tested(module_name)


# ═══════════════════════════════════════════════════════════════════════════════
# Module 生命周期测试（使用 MockTower）
# ═══════════════════════════════════════════════════════════════════════════════

func test_module_install_adds_effects_to_tower() -> void:
	"""验证模块安装时 effects 被添加到炮塔"""
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		skip("MockTower not available")
		return
	
	var tower = MockTowerScript.new()
	var module := load(MODULE_DATA_DIR + "accelerator.tres") as Module
	
	# 安装前
	var initial_speed := tower.get_bullet_speed()
	assert_that(initial_speed).is_equal(200.0)
	
	# 安装模块
	var success := tower.install_module(module)
	assert_bool(success).is_true()
	
	# 验证速度增加
	var new_speed := tower.get_bullet_speed()
	assert_that(new_speed).is_equal(350.0)  # 200 + 150
	
	_record_tested("accelerator")


func test_module_uninstall_removes_effects_from_tower() -> void:
	"""验证模块卸载时 effects 从炮塔移除"""
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		skip("MockTower not available")
		return
	
	var tower = MockTowerScript.new()
	var module := load(MODULE_DATA_DIR + "accelerator.tres") as Module
	
	var initial_speed := tower.get_bullet_speed()
	
	// 安装然后卸载
	tower.install_module(module)
	tower.uninstall_module(0)
	
	// 验证速度恢复
	var final_speed := tower.get_bullet_speed()
	assert_that(final_speed).is_equal(initial_speed)
	
	_record_tested("accelerator")


func test_multiple_modules_stacking() -> void:
	"""验证多个模块效果可以叠加"""
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		skip("MockTower not available")
		return
	
	var tower = MockTowerScript.new()
	var module := load(MODULE_DATA_DIR + "multiplier.tres") as Module
	
	var initial_attack := tower.get_bullet_attack()
	
	// 安装两个乘法器
	tower.install_module(module)
	tower.install_module(module.duplicate())
	
	// 验证叠加: 1.0 * 1.2 * 1.2 = 1.44
	var final_attack := tower.get_bullet_attack()
	assert_that(final_attack).is_equal(1.44)
	
	_record_tested("multiplier")


func test_module_slot_limit() -> void:
	"""验证炮塔最多只能安装 4 个模块"""
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		skip("MockTower not available")
		return
	
	var tower = MockTowerScript.new()
	var module := load(MODULE_DATA_DIR + "multiplier.tres") as Module
	
	// 安装 4 个模块
	for i in range(4):
		var success := tower.install_module(module.duplicate())
		assert_bool(success).is_true()
	
	assert_that(tower.get_module_count()).is_equal(4)
	
	// 第 5 个应该失败
	var fail_result := tower.install_module(module.duplicate())
	assert_bool(fail_result).is_false()
	assert_that(tower.get_module_count()).is_equal(4)
	
	_record_tested("multiplier")
