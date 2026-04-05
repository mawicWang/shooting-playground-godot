# GdUnit4 Test Suite for Shadow Tower Module
class_name ShadowTowerModuleTest
extends GdUnitTestSuite

const MODULE_PATH := "res://resources/module_data/shadow_tower_module.tres"

func test_shadow_tower_body_layer_constant_exists() -> void:
    # This will fail until we add the constant
    assert_int(Layers.SHADOW_TOWER_BODY).is_equal(128)

func test_bullet_data_has_shadow_team_id_field() -> void:
    var bd := BulletData.new()
    # Default should be -1 (normal bullet)
    assert_int(bd.shadow_team_id).is_equal(-1)

    # Should be settable
    bd.shadow_team_id = 123
    assert_int(bd.shadow_team_id).is_equal(123)

func test_spawn_shadow_tower_effect_class_exists() -> void:
    var effect_script = load("res://entities/effects/fire_effects/spawn_shadow_tower_effect.gd")
    assert_object(effect_script).is_not_null()

func test_shadow_tower_module_resource_exists() -> void:
    var module = load(MODULE_PATH)
    assert_object(module).is_not_null()
    assert_str(module.module_name).is_equal("幻影炮塔")
    assert_int(module.category).is_equal(2)  # SPECIAL
    assert_str(module.description).contains("5")
    assert_that(module.slot_color).is_equal(Color(0.2, 0.2, 0.8, 1))
    assert_int(module.fire_effects.size()).is_equal(1)

func test_shadow_tower_script_exists() -> void:
    var script = load("res://entities/towers/shadow_tower.gd")
    assert_object(script).is_not_null()
    # Check it extends tower.gd by looking at instance
    var tower = Node2D.new()
    tower.set_script(script)
    assert_that(tower).has_method("get_shadow_team_id")
    assert_int(tower.get_shadow_team_id()).is_equal(-1)
    tower.free()
