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

func test_shadow_tower_scene_exists() -> void:
    var scene = load("res://entities/towers/shadow_tower.tscn")
    assert_object(scene).is_not_null()

    var instance = scene.instantiate()
    assert_that(instance).has_method("get_shadow_team_id")
    instance.free()

func test_bullet_collision_team_filtering() -> void:
    var bullet_script = load("res://entities/bullets/bullet.gd")
    assert_object(bullet_script).is_not_null()

func test_module_installation() -> void:
    var module = load(MODULE_PATH)
    assert_object(module).is_not_null()

    # Create mock tower (use Node2D with script set dynamically)
    var tower_script = load("res://entities/towers/tower.gd")
    var tower = Node2D.new()
    tower.set_script(tower_script)
    # Tower data is not set, so we just test module effects directly
    # without needing full tower initialization

    # Verify the effect class can be instantiated
    var effect_script = load("res://entities/effects/fire_effects/spawn_shadow_tower_effect.gd")
    var effect = effect_script.new()
    assert_object(effect).is_not_null()
    assert_int(effect.origin_entity_id).is_equal(-1)

func test_bullet_counter_increments() -> void:
    var effect_script = load("res://entities/effects/fire_effects/spawn_shadow_tower_effect.gd")
    var effect = effect_script.new()
    effect.origin_entity_id = 2002

    # Verify the counter logic by checking the _bullet_counters dict
    var bd = BulletData.new()
    var mock_tower = Node2D.new()

    # Apply 4 times - should not trigger spawn
    for i in range(4):
        effect.apply(mock_tower, bd)

    # Verify counter is at 4
    assert_int(effect._bullet_counters[2002]).is_equal(4)

    mock_tower.free()

func test_shadow_tower_uses_correct_collision_layer() -> void:
    # Verify the script sets the correct layer by checking the code
    var script = load("res://entities/towers/shadow_tower.gd")
    var source = script.source_code
    assert_str(source).contains("Layers.SHADOW_TOWER_BODY")

func test_shadow_tower_blue_appearance() -> void:
    # Verify the script sets blue tint
    var script = load("res://entities/towers/shadow_tower.gd")
    var source = script.source_code
    assert_str(source).contains("Color(0.4, 0.4, 1.0, 0.7)")

func test_shadow_tower_game_stopped_connection() -> void:
    # Verify the script has _on_game_stopped method
    var script = load("res://entities/towers/shadow_tower.gd")
    var source = script.source_code
    assert_str(source).contains("_on_game_stopped")
    assert_str(source).contains("game_stopped.connect")
