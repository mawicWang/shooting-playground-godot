# CharacterPassiveTest — tower stat application with character passives
# Covers ACs: 14, 15, 16, 17, 18

class_name CharacterPassiveTest extends GdUnitTestSuite

const VERA: CharacterData = preload("res://src/resources/characters/vera.tres")
const TowerScene := preload("res://src/entities/towers/tower.tscn")
const ShadowTowerScene := preload("res://src/entities/towers/shadow_tower.tscn")
const TestTowerData := preload("res://src/resources/simple_emitter.tres")  # firing_rate=1.0
const RateBoostModule := preload("res://src/resources/module_data/rate_boost.tres")

var _nodes_to_free: Array[Node] = []

func before_test() -> void:
	_nodes_to_free.clear()

func after_test() -> void:
	GameState.character = null
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()

func _make_tower(td: TowerData = null) -> Node:
	var tower := TowerScene.instantiate()
	if td:
		tower.data = td
	get_tree().root.add_child(tower)
	_nodes_to_free.append(tower)
	return tower

func _make_shadow_tower(td: TowerData = null) -> Node:
	var tower := ShadowTowerScene.instantiate()
	if td:
		tower.data = td
	get_tree().root.add_child(tower)
	_nodes_to_free.append(tower)
	return tower

# ── Vera: damage multiplier 2x (AC 14) ─────────────────────────────────────────

func test_vera_doubles_bullet_attack_stat() -> void:
	# Arrange
	GameState.character = VERA

	# Act
	var tower := _make_tower(TestTowerData)
	await get_tree().process_frame

	# Assert — base is 1.0, vera multiplier is 2.0
	assert_float(tower._bullet_attack_stat.get_value()).is_equal_approx(2.0, 0.001)

# ── Vera: fire rate 0.5x → CD 2x (AC 15) ──────────────────────────────────────

func test_vera_doubles_cooldown_stat() -> void:
	# Arrange — simple_emitter has firing_rate=1.0, so base_cd=1.0
	GameState.character = VERA

	# Act
	var tower := _make_tower(TestTowerData)
	await get_tree().process_frame

	# Assert — base_cd=1.0, vera cd_multiplier=1/0.5=2.0 → 2.0
	assert_float(tower._cd_stat.get_value()).is_equal_approx(2.0, 0.001)

# ── Vera + rate_boost module: module first, character last (AC 16) ──────────────

func test_vera_with_rate_boost_cd_is_module_first_then_character() -> void:
	# Arrange
	GameState.character = VERA
	var tower := _make_tower(TestTowerData)
	await get_tree().process_frame

	# Act — install rate_boost (-0.3 ADDITIVE to CD)
	var module := RateBoostModule
	tower.install_module(module)

	# Assert — (1.0 - 0.3) * 2.0 = 1.4
	assert_float(tower._cd_stat.get_value()).is_equal_approx(1.4, 0.001)

# ── Shadow tower inherits character passives (AC 17) ───────────────────────────

func test_shadow_tower_inherits_vera_damage_multiplier() -> void:
	GameState.character = VERA

	var shadow := _make_shadow_tower(TestTowerData)
	await get_tree().process_frame

	assert_float(shadow._bullet_attack_stat.get_value()).is_equal_approx(2.0, 0.001)

func test_shadow_tower_inherits_vera_cd_multiplier() -> void:
	GameState.character = VERA

	var shadow := _make_shadow_tower(TestTowerData)
	await get_tree().process_frame

	assert_float(shadow._cd_stat.get_value()).is_equal_approx(2.0, 0.001)

# ── Neutral character: stats at baseline (AC 18) ───────────────────────────────

func test_neutral_character_leaves_attack_at_baseline() -> void:
	GameState.character = null  # get_character() returns neutral

	var tower := _make_tower(TestTowerData)
	await get_tree().process_frame

	assert_float(tower._bullet_attack_stat.get_value()).is_equal_approx(1.0, 0.001)

func test_neutral_character_leaves_cd_at_baseline() -> void:
	GameState.character = null

	var tower := _make_tower(TestTowerData)
	await get_tree().process_frame

	# simple_emitter firing_rate=1.0, base_cd=1.0; neutral multiplier=1.0 → 1.0
	assert_float(tower._cd_stat.get_value()).is_equal_approx(1.0, 0.001)
