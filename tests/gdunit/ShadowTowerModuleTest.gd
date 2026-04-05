# GdUnit4 Test Suite for Shadow Tower Module
class_name ShadowTowerModuleTest
extends GdUnitTestSuite

const MODULE_PATH := "res://resources/module_data/shadow_tower_module.tres"

func test_shadow_tower_body_layer_constant_exists() -> void:
    # This will fail until we add the constant
    assert_int(Layers.SHADOW_TOWER_BODY).is_equal(128)
