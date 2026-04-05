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
