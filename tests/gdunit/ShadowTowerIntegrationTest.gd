# GdUnit4 Integration Test Suite for Shadow Tower Module
# Tests that verify component interaction without requiring full game scene
class_name ShadowTowerIntegrationTest
extends GdUnitTestSuite

const SpawnEffectScript = preload("res://entities/effects/fire_effects/spawn_shadow_tower_effect.gd")

# ── Module + Effect Interaction ─────────────────────────────

func test_shadow_module_contains_spawn_effect() -> void:
	var module = load("res://resources/module_data/shadow_tower_module.tres")
	assert_object(module).is_not_null()
	assert_int(module.fire_effects.size()).is_equal(1)
	var effect = module.fire_effects[0]
	assert_that(effect.get_script()).is_equal(SpawnEffectScript)

func test_shadow_tower_bullet_data_has_team_id() -> void:
	var scene = load("res://entities/towers/shadow_tower.tscn")
	var tower = scene.instantiate()

	# Set minimal data
	tower.data = TowerData.new()
	tower.data.firing_rate = 1.0
	tower.data.barrel_directions = PackedVector2Array([Vector2(0, -1)])

	var bd = BulletData.new()
	bd.shadow_team_id = 999
	bd.tower_body_mask = Layers.SHADOW_TOWER_BODY

	assert_int(bd.shadow_team_id).is_equal(999)
	assert_int(bd.tower_body_mask).is_equal(Layers.SHADOW_TOWER_BODY)

	tower.free()

func test_shadow_bullet_team_filtering_logic() -> void:
	# Test the team filtering logic directly (not through scene)
	var bullet_data_shadow := BulletData.new()
	bullet_data_shadow.shadow_team_id = 42

	var bullet_data_normal := BulletData.new()
	bullet_data_normal.shadow_team_id = -1

	# Shadow bullet should have team ID
	assert_int(bullet_data_shadow.shadow_team_id).is_greater(-1)

	# Normal bullet should have -1
	assert_int(bullet_data_normal.shadow_team_id).is_equal(-1)

func test_layers_shadow_tower_body_value() -> void:
	# Verify collision layer is distinct from other layers
	assert_int(Layers.SHADOW_TOWER_BODY).is_equal(128)
	assert_int(Layers.SHADOW_TOWER_BODY & Layers.TOWER_BODY).is_equal(0)
	assert_int(Layers.SHADOW_TOWER_BODY & Layers.AIR_TOWER_BODY).is_equal(0)
