# GdUnit4 — Special Module Tests
# 验证 SPECIAL 模块（FlyingModule、AntiAirModule）的安装/卸载状态变化
# 知识库参考：docs/content/modules.md
#
# 注意：FlyingModule.on_install 会访问 tower.sprite.scale（MockTower 已添加 sprite 属性）
# 并尝试通过 tower.get_node_or_null("TowerBody") 切换碰撞层（返回 null，安全跳过）
# 以及通过 tower.create_tween() 启动动画（MockTower 不在场景树，create_tween 失败，
# _start_animation 内先用 get_node_or_null("TowerVisual/Sprite2D") 检查，返回 null 则提前退出）

class_name ModuleSpecialTest
extends GdUnitTestSuite

const MODULE_DIR := "res://resources/module_data/"


# ──────────────────────────────────────────────
# flying — 飞行器
# ──────────────────────────────────────────────

func test_flying_sets_is_flying_true_on_install() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "flying.tres") as Module
	assert_object(module).is_not_null()

	assert_bool(tower.is_flying).is_false()
	tower.install_module(module)
	assert_bool(tower.is_flying).is_true()


func test_flying_clears_is_flying_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "flying.tres") as Module

	tower.install_module(module)
	assert_bool(tower.is_flying).is_true()

	tower.uninstall_module(0)
	assert_bool(tower.is_flying).is_false()


func test_flying_restores_sprite_scale_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var original_scale := tower.sprite.scale
	var module := load(MODULE_DIR + "flying.tres") as Module

	tower.install_module(module)
	# FlyingModule 放大 sprite scale ×1.5
	assert_bool(tower.sprite.scale.length() > original_scale.length()).is_true()

	tower.uninstall_module(0)
	assert_float(tower.sprite.scale.x).is_equal_approx(original_scale.x, 0.001)
	assert_float(tower.sprite.scale.y).is_equal_approx(original_scale.y, 0.001)


# ──────────────────────────────────────────────
# anti_air — 防空炮
# ──────────────────────────────────────────────

func test_anti_air_sets_has_anti_air_true_on_install() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "anti_air.tres") as Module
	assert_object(module).is_not_null()

	assert_bool(tower.has_anti_air).is_false()
	tower.install_module(module)
	assert_bool(tower.has_anti_air).is_true()


func test_anti_air_clears_has_anti_air_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "anti_air.tres") as Module

	tower.install_module(module)
	assert_bool(tower.has_anti_air).is_true()

	tower.uninstall_module(0)
	assert_bool(tower.has_anti_air).is_false()
