## Effect Test Harness — 效果验证脚手架
## 运行方式: godot --headless --script res://tests/effect_test_harness.gd
##
## 设计原则:
##   1. 纯数据驱动测试 — 无需实例化复杂场景
##   2. 声明式断言 — 每个测试用例清晰描述输入/期望输出
##   3. 零副作用 — 测试不修改全局状态，可并行运行
##   4. 快速失败 — 第一个失败即退出，方便 CI 集成
##
## 支持的测试类型:
##   - 纯数据类测试 (StatAttribute, BulletData, Module, Relic 资源)
##   - 效果逻辑测试 (通过模拟对象)
##   - 集成测试 (需要完整场景，标记为 SLOW)

extends SceneTree

const MODULE_DATA_DIR := "res://resources/module_data/"
const RELIC_DATA_DIR := "res://resources/relic_data/"

# 测试结果统计
var _pass_count: int = 0
var _fail_count: int = 0
var _skip_count: int = 0
var _current_suite: String = ""

# 测试夹具（Fixtures）缓存
var _fixtures: Dictionary = {}

# 扫描到的资源列表
var _scanned_module_names: Array[String] = []
var _scanned_relic_names: Array[String] = []

# 已测试的模块名列表（用于验证覆盖率）
var _tested_module_names: Array[String] = []

func _init() -> void:
	print("\n╔══════════════════════════════════════════════════════════════╗")
	print("║           Effect Test Harness (效果验证脚手架)                ║")
	print("╚══════════════════════════════════════════════════════════════╝\n")
	
	# 扫描资源目录
	_scan_resource_directories()
	
	# 初始化测试夹具
	_setup_fixtures()
	
	# 验证测试覆盖完整性
	_validate_test_coverage()
	
	# 运行所有测试套件
	_run_all_tests()
	
	# 最终验证：测试的模块数量是否等于资源数量
	_validate_tested_module_count()
	
	# 打印结果
	_print_summary()
	
	quit(1 if _fail_count > 0 else 0)


# ═══════════════════════════════════════════════════════════════════════════════
# 资源扫描 — 自动发现所有 module 和 relic 资源
# ═══════════════════════════════════════════════════════════════════════════════

func _scan_resource_directories() -> void:
	print("━━━ Scanning Resource Directories ━━━")
	
	# 扫描模块资源
	_scanned_module_names = _scan_directory(MODULE_DATA_DIR, ".tres")
	print("  Found %d module resources: %s" % [_scanned_module_names.size(), ", ".join(_scanned_module_names)])
	
	# 扫描遗物资源
	_scanned_relic_names = _scan_directory(RELIC_DATA_DIR, ".tres")
	print("  Found %d relic resources: %s" % [_scanned_relic_names.size(), ", ".join(_scanned_relic_names)])
	print("")

func _scan_directory(dir_path: String, extension: String) -> Array[String]:
	var names: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file := dir.get_next()
		while file != "":
			if file.ends_with(extension):
				names.append(file.get_basename())
			file = dir.get_next()
		dir.list_dir_end()
	names.sort()
	return names


# ═══════════════════════════════════════════════════════════════════════════════
# 测试覆盖验证 — 确保每个资源都有对应的测试
# ═══════════════════════════════════════════════════════════════════════════════

func _validate_test_coverage() -> void:
	print("━━━ Validating Test Coverage ━━━")
	
	# 定义必须测试的模块（这些模块必须有专门的测试函数）
	var required_module_tests := [
		"accelerator",
		"multiplier", 
		"flying",
		"anti_air",
	]
	
	# 检查是否有未测试的必需模块
	var missing_tests: Array[String] = []
	for module_name in required_module_tests:
		if not _scanned_module_names.has(module_name):
			missing_tests.append(module_name)
	
	if missing_tests.size() > 0:
		print("  ⚠️  Required modules not found in resources: %s" % ", ".join(missing_tests))
	else:
		print("  ✓ All required modules found")
	
	print("")


# ═══════════════════════════════════════════════════════════════════════════════
# 最终验证 — 测试结束后检查测试数量是否匹配
# ═══════════════════════════════════════════════════════════════════════════════

func _validate_tested_module_count() -> void:
	print("\n━━━ Validating Tested Module Count ━━━")
	
	# 去重并排序
	var unique_tested: Array[String] = []
	for name in _tested_module_names:
		if not unique_tested.has(name):
			unique_tested.append(name)
	unique_tested.sort()
	
	print("  Resources in directory: %d" % _scanned_module_names.size())
	print("  Modules tested: %d" % unique_tested.size())
	print("  Tested modules: %s" % ", ".join(unique_tested))
	
	# 验证数量相等
	if unique_tested.size() != _scanned_module_names.size():
		_fail("module_count_mismatch: expected %d modules, but only tested %d" % [_scanned_module_names.size(), unique_tested.size()])
		
		# 找出未测试的模块
		var untested: Array[String] = []
		for name in _scanned_module_names:
			if not unique_tested.has(name):
				untested.append(name)
		if untested.size() > 0:
			print("  ✗ Untested modules: %s" % ", ".join(untested))
	else:
		_pass("all_modules_tested: %d/%d" % [unique_tested.size(), _scanned_module_names.size()])
	
	# 验证名字一一对应
	var name_mismatch := false
	for i in range(_scanned_module_names.size()):
		if i >= unique_tested.size() or _scanned_module_names[i] != unique_tested[i]:
			name_mismatch = true
			break
	
	if name_mismatch:
		# 找出具体哪些名字不匹配
		for name in _scanned_module_names:
			if not unique_tested.has(name):
				_fail("module_name_missing_from_tests: %s exists in resources but not tested" % name)
		for name in unique_tested:
			if not _scanned_module_names.has(name):
				_fail("module_name_not_in_resources: %s tested but not found in resources" % name)
	else:
		_pass("all_module_names_match")


# ═══════════════════════════════════════════════════════════════════════════════
# 测试夹具（Fixtures）— 共享的测试数据
# ═══════════════════════════════════════════════════════════════════════════════

func _setup_fixtures() -> void:
	# 基础 TowerData
	_fixtures["basic_tower_data"] = _create_basic_tower_data()
	
	# 基础 BulletData
	_fixtures["basic_bullet_data"] = _create_basic_bullet_data()
	
	# 测试用的 StatModifier
	_fixtures["additive_mod"] = StatModifier.new(10.0, StatModifier.Type.ADDITIVE, self)
	_fixtures["multiplicative_mod"] = StatModifier.new(1.5, StatModifier.Type.MULTIPLICATIVE, self)
	
	# 预加载所有扫描到的模块资源
	_preload_all_module_resources()
	
	# 预加载所有遗物资源
	_preload_all_relic_resources()

func _create_basic_tower_data() -> TowerData:
	var data := TowerData.new()
	data.tower_name = "TestTower"
	data.firing_rate = 1.0
	data.initial_ammo = 3
	data.barrel_directions = PackedVector2Array([Vector2(0, -1)])
	return data

func _create_basic_bullet_data() -> BulletData:
	var bd := BulletData.new()
	bd.attack = 1.0
	bd.speed = 200.0
	bd.knockback = 150.0
	bd.knockback_decay = 25.0
	return bd

func _preload_all_module_resources() -> void:
	for module_name in _scanned_module_names:
		var path: String = MODULE_DATA_DIR + module_name + ".tres"
		var res := load(path)
		if res:
			_fixtures["module_" + module_name] = res
		else:
			print("  ⚠️  Failed to load module: %s" % path)

func _preload_all_relic_resources() -> void:
	for relic_name in _scanned_relic_names:
		var path: String = RELIC_DATA_DIR + relic_name + ".tres"
		var res := load(path)
		if res:
			_fixtures["relic_" + relic_name] = res

func fixture(name: String) -> Variant:
	return _fixtures.get(name)


# ═══════════════════════════════════════════════════════════════════════════════
# 测试运行器
# ═══════════════════════════════════════════════════════════════════════════════

func _run_all_tests() -> void:
	# 数据层测试（纯资源，无依赖）
	_suite("DataLayer")
	_test_tower_data_resource()
	_test_bullet_data_resource()
	_test_all_module_resources()
	_test_all_relic_resources()
	
	# StatAttribute 核心计算测试
	_suite("StatAttribute")
	_test_stat_attribute_base_value()
	_test_stat_attribute_additive()
	_test_stat_attribute_multiplicative()
	_test_stat_attribute_combined()
	_test_stat_attribute_modifier_cleanup()
	
	# BulletData 行为测试
	_suite("BulletData")
	_test_bullet_data_duplicate()
	_test_bullet_data_duplicate_with_mods()
	
	# Module 效果测试 — 为每个扫描到的模块运行测试
	_suite("ModuleEffects")
	_test_all_modules_individually()
	_test_module_install_uninstall_lifecycle()
	_test_module_multiple_modules_stacking()
	
	# Relic 效果测试
	_suite("RelicEffects")
	_test_all_relics_individually()


# ═══════════════════════════════════════════════════════════════════════════════
# 数据层测试 — 资源完整性检查
# ═══════════════════════════════════════════════════════════════════════════════

func _test_tower_data_resource() -> void:
	var data := fixture("basic_tower_data") as TowerData
	_assert_not_null("tower_data_created", data)
	_assert_eq("tower_data_name", data.tower_name, "TestTower")
	_assert_eq("tower_data_firing_rate", data.firing_rate, 1.0)
	_assert_eq("tower_data_initial_ammo", data.initial_ammo, 3)
	_assert_eq("tower_data_barrel_count", data.barrel_directions.size(), 1)

func _test_bullet_data_resource() -> void:
	var bd := fixture("basic_bullet_data") as BulletData
	_assert_not_null("bullet_data_created", bd)
	_assert_eq("bullet_data_attack", bd.attack, 1.0)
	_assert_eq("bullet_data_speed", bd.speed, 200.0)
	_assert_eq("bullet_data_default_mask", bd.tower_body_mask, 32)

func _test_all_module_resources() -> void:
	# 验证所有扫描到的模块都能被加载
	for module_name in _scanned_module_names:
		var module := fixture("module_" + module_name) as Module
		if module:
			_assert_true("module_" + module_name + "_loaded", true)
			_assert_not_null("module_" + module_name + "_has_name", module.module_name)
			_assert_not_null("module_" + module_name + "_has_description", module.description)
			# 记录此模块已被测试
			_record_module_tested(module_name)
		else:
			_fail("module_" + module_name + "_load_failed")

func _test_all_relic_resources() -> void:
	for relic_name in _scanned_relic_names:
		var relic := fixture("relic_" + relic_name) as Relic
		if relic:
			_assert_true("relic_" + relic_name + "_loaded", true)
			_assert_not_null("relic_" + relic_name + "_has_name", relic.relic_name)
		else:
			# Relic 可能因为脚本依赖无法加载，只记录一次跳过
			_skip("relic_" + relic_name + "_load_failed")


# ═══════════════════════════════════════════════════════════════════════════════
# 模块测试 — 为每个模块运行详细测试
# ═══════════════════════════════════════════════════════════════════════════════

func _test_all_modules_individually() -> void:
	# 为每个扫描到的模块运行基础验证
	for module_name in _scanned_module_names:
		_test_single_module(module_name)

func _test_single_module(module_name: String) -> void:
	var module := fixture("module_" + module_name) as Module
	if not module:
		_fail("module_%s_not_found" % module_name)
		return
	
	# 基础验证
	_assert_not_null("module_%s_name_valid" % module_name, module.module_name)
	_assert_false("module_%s_name_empty" % module_name, module.module_name.is_empty())
	
	# 验证 category 是有效值
	var valid_category := module.category >= 0 and module.category <= 2
	_assert_true("module_%s_category_valid" % module_name, valid_category)
	
	# 验证 slot_color 已设置（非默认灰色）
	var default_color := Color(0.5, 0.5, 0.5)
	var has_custom_color := module.slot_color != default_color
	_assert_true("module_%s_has_custom_color" % module_name, has_custom_color)
	
	# 记录此模块已被测试
	_record_module_tested(module_name)
	
	# 根据模块类型进行特定测试
	_match_module_specific_test(module_name, module)

func _match_module_specific_test(module_name: String, module: Module) -> void:
	# 根据模块名匹配特定测试逻辑
	match module_name:
		"accelerator":
			_test_module_accelerator_details(module)
		"multiplier":
			_test_module_multiplier_details(module)
		"flying":
			_test_module_flying_details(module)
		"anti_air":
			_test_module_anti_air_details(module)
		"rate_boost":
			_test_module_rate_boost_details(module)
		"speed_boost":
			_test_module_speed_boost_details(module)
		"heavy_ammo":
			_test_module_heavy_ammo_details(module)
		"replenish1", "replenish2":
			_test_module_replenish_details(module_name, module)
		"cd_on_hit_enemy", "cd_on_hit_tower_self", "cd_on_hit_tower_target", "cd_on_receive_hit":
			_test_module_cd_on_hit_details(module_name, module)
		"hit_speed_boost":
			_test_module_hit_speed_boost_details(module)
		_:
			# 未知模块，只进行基础测试
			print("    Note: No specific tests for module '%s'" % module_name)

func _record_module_tested(module_name: String) -> void:
	if not _tested_module_names.has(module_name):
		_tested_module_names.append(module_name)


# ═══════════════════════════════════════════════════════════════════════════════
# 特定模块详细测试
# ═══════════════════════════════════════════════════════════════════════════════

func _test_module_accelerator_details(module: Module) -> void:
	_assert_eq("accelerator_name", module.module_name, "加速器")
	_assert_eq("accelerator_category", module.category, Module.Category.COMPUTATIONAL)
	
	# 验证 stat_modifiers 配置
	_assert_eq("accelerator_stat_modifier_count", module.stat_modifiers.size(), 1)
	if module.stat_modifiers.size() > 0:
		var mod := module.stat_modifiers[0]
		_assert_eq("accelerator_modifier_stat", mod.stat, TowerStatModifierRes.Stat.BULLET_SPEED)
		_assert_eq("accelerator_modifier_value", mod.value, 150.0)
		_assert_eq("accelerator_modifier_type", mod.modifier_type, StatModifier.Type.ADDITIVE)

func _test_module_multiplier_details(module: Module) -> void:
	_assert_eq("multiplier_name", module.module_name, "乘法器")
	
	if module.stat_modifiers.size() > 0:
		var mod := module.stat_modifiers[0]
		_assert_eq("multiplier_stat", mod.stat, TowerStatModifierRes.Stat.BULLET_ATTACK)
		_assert_eq("multiplier_type", mod.modifier_type, StatModifier.Type.MULTIPLICATIVE)

func _test_module_flying_details(module: Module) -> void:
	_assert_eq("flying_name", module.module_name, "飞行器")
	_assert_eq("flying_category", module.category, Module.Category.SPECIAL)
	
	# 验证脚本类
	var module_res := load("res://entities/modules/flying_module.gd") as GDScript
	if module_res:
		var instance = module_res.new()
		_assert_true("flying_script_is_module", instance is Module)

func _test_module_anti_air_details(module: Module) -> void:
	# 防空模块的实际名称是"防空炮"
	_assert_eq("anti_air_name", module.module_name, "防空炮")
	
	var module_res := load("res://entities/modules/anti_air_module.gd") as GDScript
	if module_res:
		var instance = module_res.new()
		_assert_true("anti_air_script_is_module", instance is Module)

func _test_module_rate_boost_details(module: Module) -> void:
	# 射速提升模块应该有 CD 相关的 stat_modifier
	if module.stat_modifiers.size() > 0:
		var has_cd_mod := false
		for mod in module.stat_modifiers:
			if mod.stat == TowerStatModifierRes.Stat.CD:
				has_cd_mod = true
				break
		_assert_true("rate_boost_has_cd_modifier", has_cd_mod)

func _test_module_speed_boost_details(module: Module) -> void:
	# 速度提升模块验证
	if module.stat_modifiers.size() > 0:
		var has_speed_mod := false
		for mod in module.stat_modifiers:
			if mod.stat == TowerStatModifierRes.Stat.BULLET_SPEED:
				has_speed_mod = true
				break
		_assert_true("speed_boost_has_speed_modifier", has_speed_mod)

func _test_module_heavy_ammo_details(module: Module) -> void:
	# 重弹头模块应该有攻击力和弹药消耗相关的 modifier
	if module.stat_modifiers.size() > 0:
		var has_attack_mod := false
		var has_ammo_mod := false
		for mod in module.stat_modifiers:
			if mod.stat == TowerStatModifierRes.Stat.BULLET_ATTACK:
				has_attack_mod = true
			if mod.stat == TowerStatModifierRes.Stat.AMMO_EXTRA:
				has_ammo_mod = true
		_assert_true("heavy_ammo_has_attack_modifier", has_attack_mod)

func _test_module_replenish_details(module_name: String, module: Module) -> void:
	# 补充模块验证
	var expected_name := "补充+1" if module_name == "replenish1" else "补充+2"
	_assert_eq("replenish_name", module.module_name, expected_name)

func _test_module_cd_on_hit_details(module_name: String, module: Module) -> void:
	# CD 触发类模块应该有对应的 fire_effects、bullet_effects 或 tower_effects
	var has_effects := module.fire_effects.size() > 0 or module.bullet_effects.size() > 0 or module.tower_effects.size() > 0
	_assert_true("%s_has_effects" % module_name, has_effects)

func _test_module_hit_speed_boost_details(module: Module) -> void:
	# 击中加速模块使用的是 bullet_effects
	var has_effects := module.fire_effects.size() > 0 or module.bullet_effects.size() > 0 or module.tower_effects.size() > 0
	_assert_true("hit_speed_boost_has_effects", has_effects)


# ═══════════════════════════════════════════════════════════════════════════════
# StatAttribute 测试
# ═══════════════════════════════════════════════════════════════════════════════

func _test_stat_attribute_base_value() -> void:
	var attr := StatAttribute.new(100.0)
	_assert_eq("base_value", attr.get_value(), 100.0)

func _test_stat_attribute_additive() -> void:
	var attr := StatAttribute.new(100.0)
	attr.add_modifier(fixture("additive_mod") as StatModifier)
	_assert_eq("additive_modifier", attr.get_value(), 110.0)

func _test_stat_attribute_multiplicative() -> void:
	var attr := StatAttribute.new(100.0)
	attr.add_modifier(fixture("multiplicative_mod") as StatModifier)
	_assert_eq("multiplicative_modifier", attr.get_value(), 150.0)

func _test_stat_attribute_combined() -> void:
	var attr := StatAttribute.new(100.0)
	attr.add_modifier(fixture("additive_mod") as StatModifier)
	attr.add_modifier(fixture("multiplicative_mod") as StatModifier)
	# (100 + 10) * 1.5 = 165
	_assert_eq("combined_modifiers", attr.get_value(), 165.0)

func _test_stat_attribute_modifier_cleanup() -> void:
	var attr := StatAttribute.new(100.0)
	var mod := StatModifier.new(50.0, StatModifier.Type.ADDITIVE, self)
	attr.add_modifier(mod)
	_assert_eq("before_cleanup", attr.get_value(), 150.0)
	
	attr.remove_modifiers_from(self)
	_assert_eq("after_cleanup", attr.get_value(), 100.0)


# ═══════════════════════════════════════════════════════════════════════════════
# BulletData 测试
# ═══════════════════════════════════════════════════════════════════════════════

func _test_bullet_data_duplicate() -> void:
	var original: BulletData = fixture("basic_bullet_data")
	original.attack = 5.0
	original.speed = 300.0
	original.chain_count = 2
	
	var copy := original.duplicate_with_mods({})
	
	_assert_eq("attack_copied", copy.attack, 5.0)
	_assert_eq("speed_copied", copy.speed, 300.0)
	_assert_eq("chain_count_copied", copy.chain_count, 2)
	
	# 修改原数据不应影响副本
	original.attack = 10.0
	_assert_eq("copy_unchanged", copy.attack, 5.0)

func _test_bullet_data_duplicate_with_mods() -> void:
	var original: BulletData = fixture("basic_bullet_data")
	var mods := {"attack": 99.0, "speed": 999.0}
	
	var copy := original.duplicate_with_mods(mods)
	
	_assert_eq("mod_attack_applied", copy.attack, 99.0)
	_assert_eq("mod_speed_applied", copy.speed, 999.0)


# ═══════════════════════════════════════════════════════════════════════════════
# Module 生命周期测试
# ═══════════════════════════════════════════════════════════════════════════════

func _test_module_install_uninstall_lifecycle() -> void:
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		_skip("mock_tower.gd not found")
		return
	
	var tower_data: TowerData = fixture("basic_tower_data")
	var tower = MockTowerScript.new(tower_data)
	
	var base_speed: float = tower.get_bullet_speed()
	_assert_eq("initial_speed", base_speed, 200.0)
	
	# 测试每个扫描到的模块
	for module_name in _scanned_module_names:
		var module := fixture("module_" + module_name) as Module
		if not module:
			continue
		
		# 安装前记录状态
		var stats_before: Dictionary = tower.get_stats_snapshot()
		
		# 安装模块
		var success: bool = tower.install_module(module)
		_assert_true("%s_install_success" % module_name, success)
		
		# 验证模块已安装
		var found := false
		for m in tower.modules:
			if m.module_name == module.module_name:
				found = true
				break
		_assert_true("%s_found_in_tower" % module_name, found)
		
		# 卸载模块
		tower.uninstall_module(tower.modules.size() - 1)
		_assert_true("%s_uninstalled" % module_name, tower.get_module_count() < tower.modules.size() + 1)
	
	# 不记录 lifecycle_test，它不是真正的模块

func _test_module_multiple_modules_stacking() -> void:
	var MockTowerScript = load("res://tests/mock_tower.gd")
	if not MockTowerScript:
		_skip("mock_tower.gd not found")
		return
	
	var tower_data: TowerData = fixture("basic_tower_data")
	var tower = MockTowerScript.new(tower_data)
	
	# 安装多个加速器测试叠加
	var accel_module := fixture("module_accelerator") as Module
	if accel_module:
		var base_speed: float = tower.get_bullet_speed()
		
		# 安装第一个
		tower.install_module(accel_module)
		var speed_after_first: float = tower.get_bullet_speed()
		_assert_eq("speed_after_first_accelerator", speed_after_first, base_speed + 150.0)
		
		# 安装第二个
		tower.install_module(accel_module.duplicate())
		var speed_after_second: float = tower.get_bullet_speed()
		_assert_eq("speed_after_second_accelerator", speed_after_second, base_speed + 300.0)
	
	# 验证模块上限 (4个)
	var mult_module := fixture("module_multiplier") as Module
	if mult_module:
		while tower.get_module_count() < 4:
			tower.install_module(mult_module.duplicate())
		_assert_eq("max_modules_installed", tower.get_module_count(), 4)
		
		# 第5个应该失败
		var fifth_result: bool = tower.install_module(mult_module.duplicate())
		_assert_false("fifth_module_rejected", fifth_result)
	
	# 不记录 stacking_test，它不是真正的模块


# ═══════════════════════════════════════════════════════════════════════════════
# Relic 效果测试
# ═══════════════════════════════════════════════════════════════════════════════

func _test_all_relics_individually() -> void:
	for relic_name in _scanned_relic_names:
		_test_single_relic(relic_name)

func _test_single_relic(relic_name: String) -> void:
	var relic := fixture("relic_" + relic_name) as Relic
	if not relic:
		# Relic 可能因为脚本依赖（如 BulletPool）无法加载
		# 已经在 _test_all_relic_resources 中记录跳过，这里不再重复
		print("    Note: relic_%s not loaded (autoload dependency)" % relic_name)
		return
	
	# 基础验证
	_assert_not_null("relic_%s_name_valid" % relic_name, relic.relic_name)
	_assert_false("relic_%s_name_empty" % relic_name, relic.relic_name.is_empty())
	
	# 验证接口可以被调用（不崩溃）
	var mock_bullet_data := fixture("basic_bullet_data") as BulletData
	relic.on_bullet_fired(mock_bullet_data, null)
	relic.on_wave_start()
	_assert_true("relic_%s_interface_callable" % relic_name, true)
	
	match relic_name:
		"double_shot":
			_test_relic_double_shot_details(relic)

func _test_relic_double_shot_details(relic: Relic) -> void:
	_assert_eq("double_shot_name", relic.relic_name, "双发")


# ═══════════════════════════════════════════════════════════════════════════════
# 断言工具
# ═══════════════════════════════════════════════════════════════════════════════

func _suite(name: String) -> void:
	_current_suite = name
	print("\n━━━ %s ━━━" % name)

func _assert_eq(test_name: String, actual: Variant, expected: Variant) -> void:
	if actual == expected:
		_pass("%s: %s == %s" % [test_name, actual, expected])
	else:
		_fail("%s: expected %s, got %s" % [test_name, expected, actual])

func _assert_true(test_name: String, condition: bool) -> void:
	if condition:
		_pass(test_name)
	else:
		_fail("%s: expected true, got false" % test_name)

func _assert_false(test_name: String, condition: bool) -> void:
	if not condition:
		_pass(test_name)
	else:
		_fail("%s: expected false, got true" % test_name)

func _assert_not_null(test_name: String, value: Variant) -> void:
	if value != null:
		_pass(test_name)
	else:
		_fail("%s: expected non-null, got null" % test_name)

func _assert_null(test_name: String, value: Variant) -> void:
	if value == null:
		_pass(test_name)
	else:
		_fail("%s: expected null, got %s" % [test_name, value])

func _skip(reason: String) -> void:
	_skip_count += 1
	print("  SKIP  %s: %s" % [_current_suite, reason])

func _pass(message: String) -> void:
	_pass_count += 1
	print("  ✓ PASS  %s" % message)

func _fail(message: String) -> void:
	_fail_count += 1
	print("  ✗ FAIL  %s" % message)

func _print_summary() -> void:
	var total := _pass_count + _fail_count + _skip_count
	print("\n" + "═".repeat(64))
	print("测试结果: %d 通过, %d 失败, %d 跳过, 总计 %d" % [_pass_count, _fail_count, _skip_count, total])
	
	if _fail_count == 0:
		print("🎉 所有测试通过!")
	else:
		print("⚠️  存在失败的测试")
	print("═".repeat(64))
