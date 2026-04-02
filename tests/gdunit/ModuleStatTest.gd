# GdUnit4 — Module Stat Modifier Tests
# 验证 COMPUTATIONAL 模块安装后 StatAttribute 数值变化，以及卸载后回滚
# 知识库参考：docs/content/modules.md

class_name ModuleStatTest
extends GdUnitTestSuite

const MODULE_DIR := "res://resources/module_data/"


## 加速器：BULLET_SPEED +150 (ADDITIVE)
## 200.0 + 150.0 = 350.0
func test_accelerator_increases_bullet_speed() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "accelerator.tres") as Module
	assert_object(module).is_not_null()

	var before := tower.get_stat(TowerStatModifierRes.Stat.BULLET_SPEED).get_value()
	assert_float(before).is_equal(200.0)

	tower.install_module(module)
	var after := tower.get_stat(TowerStatModifierRes.Stat.BULLET_SPEED).get_value()
	assert_float(after).is_equal(350.0)


## 加速器：卸载后 BULLET_SPEED 回滚
func test_accelerator_reverts_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "accelerator.tres") as Module

	var before := tower.get_stat(TowerStatModifierRes.Stat.BULLET_SPEED).get_value()
	tower.install_module(module)
	tower.uninstall_module(0)
	var after := tower.get_stat(TowerStatModifierRes.Stat.BULLET_SPEED).get_value()
	assert_float(after).is_equal(before)


## 乘法器：BULLET_ATTACK ×1.2 (MULTIPLICATIVE)
## 1.0 × 1.2 = 1.2
func test_multiplier_scales_bullet_attack() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "multiplier.tres") as Module
	assert_object(module).is_not_null()

	var before := tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()
	assert_float(before).is_equal(1.0)

	tower.install_module(module)
	var after := tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()
	assert_float(after).is_equal_approx(1.2, 0.001)


## 乘法器：卸载后 BULLET_ATTACK 回滚
func test_multiplier_reverts_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "multiplier.tres") as Module

	tower.install_module(module)
	tower.uninstall_module(0)
	assert_float(tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()).is_equal(1.0)


## 加速射击：CD -0.3 (ADDITIVE)
## 默认 MockTower firing_rate=1.0 → base_cd=1.0；安装后 1.0 + (-0.3) = 0.7
func test_rate_boost_reduces_cd() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "rate_boost.tres") as Module
	assert_object(module).is_not_null()

	var before := tower.get_stat(TowerStatModifierRes.Stat.CD).get_value()
	assert_float(before).is_equal(1.0)

	tower.install_module(module)
	var after := tower.get_stat(TowerStatModifierRes.Stat.CD).get_value()
	assert_float(after).is_equal_approx(0.7, 0.001)


## 加速射击：卸载后 CD 回滚
func test_rate_boost_reverts_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "rate_boost.tres") as Module

	tower.install_module(module)
	tower.uninstall_module(0)
	assert_float(tower.get_stat(TowerStatModifierRes.Stat.CD).get_value()).is_equal(1.0)


## 重弹头：BULLET_ATTACK ×1.8 (MULTIPLICATIVE)
## 1.0 × 1.8 = 1.8
## 注意：AMMO_EXTRA modifier 在 .tres 中 stat=4（超出枚举范围），被 Module.on_install 静默跳过
## 该 bug 在 Task 8 中修复
func test_heavy_ammo_scales_bullet_attack() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "heavy_ammo.tres") as Module
	assert_object(module).is_not_null()

	tower.install_module(module)
	var attack := tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()
	assert_float(attack).is_equal_approx(1.8, 0.001)


## 重弹头：卸载后 BULLET_ATTACK 回滚
func test_heavy_ammo_reverts_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "heavy_ammo.tres") as Module

	tower.install_module(module)
	tower.uninstall_module(0)
	assert_float(tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()).is_equal(1.0)


## 重弹头修复后：AMMO_EXTRA +1.0 生效
## 此测试在 Task 8 修复 heavy_ammo.tres stat=4→3 之前会失败，修复后应通过
func test_heavy_ammo_ammo_extra_after_fix() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "heavy_ammo.tres") as Module

	tower.install_module(module)
	var ammo_extra := tower.get_stat(TowerStatModifierRes.Stat.AMMO_EXTRA).get_value()
	assert_float(ammo_extra).is_equal_approx(1.0, 0.001)
