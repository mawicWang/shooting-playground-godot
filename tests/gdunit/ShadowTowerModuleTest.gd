extends GdUnitTestSuite

func test_shadow_tower_body_layer_constant_exists() -> void:
    # This will fail until we add the constant
    assert_int(Layers.SHADOW_TOWER_BODY).is_equal(128)
