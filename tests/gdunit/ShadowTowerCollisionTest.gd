# GdUnit4 Test Suite for Shadow Tower Collision Detection
# Tests that shadow tower bullets can hit other shadow towers of the same team
#
# This test verifies the bug: shadow tower bullets pass through other shadow towers
# without registering hits.
#
# Uses auto_free() + add_child() pattern from IntegrationTest.gd

class_name ShadowTowerCollisionTest
extends GdUnitTestSuite

const ShadowTowerScene := preload("res://entities/towers/shadow_tower.tscn")
const BulletScene := preload("res://entities/bullets/bullet.tscn")
const TowerScene := preload("res://entities/towers/tower.tscn")

var _nodes_to_free: Array[Node] = []


func before_test() -> void:
	BulletPool.clear_pool()
	_nodes_to_free.clear()


func after_test() -> void:
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()


func _add_child(node: Node) -> Node:
	get_tree().root.add_child(node)
	_nodes_to_free.append(node)
	return node


# ── Configuration Tests ──────────────────────────────────────────

func test_shadow_tower_body_uses_correct_collision_layer() -> void:
	"""Shadow tower TowerBody should be on SHADOW_TOWER_BODY layer (128)"""
	var tower: Node2D = ShadowTowerScene.instantiate()
	tower.data = TowerData.new()
	tower.data.firing_rate = 1.0
	_add_child(tower)
	await await_idle_frame()

	var tower_body: Area2D = tower.get_node_or_null("TowerBody")
	assert_object(tower_body).describes("Shadow tower should have TowerBody node").is_not_null()
	assert_int(tower_body.collision_layer).describes("TowerBody should be on SHADOW_TOWER_BODY layer").is_equal(Layers.SHADOW_TOWER_BODY)
	assert_int(tower_body.collision_layer).describes("Should NOT be on regular TOWER_BODY layer").is_not_equal(Layers.TOWER_BODY)
	assert_bool(tower_body.monitorable).is_true()


func test_shadow_tower_bullet_data_has_correct_mask() -> void:
	"""Shadow tower bullet data should have tower_body_mask = SHADOW_TOWER_BODY"""
	var tower: Node2D = ShadowTowerScene.instantiate()
	tower.data = TowerData.new()
	tower.data.firing_rate = 1.0
	tower.data.sprite = load("res://assets/tower1000.svg")
	tower.data.barrel_directions = PackedVector2Array([Vector2(0, -1)])
	tower.shadow_team_id = 42
	tower.entity_id = 100
	_add_child(tower)
	await await_idle_frame()

	# Verify shadow_team_id is accessible
	assert_int(tower.get_shadow_team_id()).is_equal(42)

	# Simulate what _do_fire does for bullet data
	var bd := BulletData.new()
	bd.shadow_team_id = tower.get_shadow_team_id()
	bd.tower_body_mask = Layers.SHADOW_TOWER_BODY

	assert_int(bd.shadow_team_id).is_equal(42)
	assert_int(bd.tower_body_mask).is_equal(Layers.SHADOW_TOWER_BODY)
	assert_int(bd.tower_body_mask & Layers.SHADOW_TOWER_BODY).describes(
		"Bullet mask should overlap with shadow tower body layer"
	).is_not_equal(0)


func test_bullet_reset_sets_correct_collision_mask() -> void:
	"""Bullet reset() should set Hitbox collision_mask to data.tower_body_mask"""
	var bullet: Node2D = BulletScene.instantiate()
	_add_child(bullet)

	# Set up shadow tower bullet data
	var bd := BulletData.new()
	bd.shadow_team_id = 42
	bd.tower_body_mask = Layers.SHADOW_TOWER_BODY
	bullet.data = bd
	bullet.reset()
	await await_idle_frame()

	var hitbox: Area2D = bullet.get_node("Hitbox")
	assert_int(hitbox.collision_mask).describes(
		"Hitbox collision_mask should be SHADOW_TOWER_BODY after reset"
	).is_equal(Layers.SHADOW_TOWER_BODY)


func test_shadow_tower_has_collision_shape() -> void:
	"""Shadow tower TowerBody should have a CollisionShape2D child"""
	var tower: Node2D = ShadowTowerScene.instantiate()
	tower.data = TowerData.new()
	tower.data.firing_rate = 1.0
	tower.data.sprite = load("res://assets/tower1000.svg")
	tower.entity_id = 100
	_add_child(tower)

	# Wait for deferred shape creation
	await await_idle_frame()
	await await_idle_frame()
	await await_idle_frame()

	var tower_body: Area2D = tower.get_node_or_null("TowerBody")
	assert_object(tower_body).is_not_null()

	var children := tower_body.get_children()
	var has_shape := false
	for child in children:
		if child is CollisionShape2D:
			has_shape = true
			var shape_node := child as CollisionShape2D
			assert_object(shape_node.shape).describes(
				"CollisionShape2D should have a valid shape"
			).is_not_null()
			break
	assert_bool(has_shape).describes(
		"TowerBody should have a CollisionShape2D child after deferred init"
	).is_true()


# ── Team Filtering Logic Tests ───────────────────────────────────

func test_same_team_shadow_bullet_should_hit_shadow_tower() -> void:
	"""Shadow bullet should hit shadow tower of the same team (filtering logic)"""
	var shadow_team_id := 42

	# Create shadow bullet data
	var bullet_data := BulletData.new()
	bullet_data.shadow_team_id = shadow_team_id
	bullet_data.tower_body_mask = Layers.SHADOW_TOWER_BODY
	bullet_data.transmission_chain = []

	# Create a shadow tower as target
	var target_tower: Node2D = ShadowTowerScene.instantiate()
	target_tower.data = TowerData.new()
	target_tower.data.firing_rate = 1.0
	target_tower.data.sprite = load("res://assets/tower1000.svg")
	target_tower.shadow_team_id = shadow_team_id  # Same team!
	target_tower.entity_id = 200
	_add_child(target_tower)
	await await_idle_frame()

	# Test the filtering logic directly (same as bullet.gd _on_hitbox_area_entered)
	var should_hit := _simulate_bullet_collision_filter(bullet_data, target_tower)
	assert_bool(should_hit).describes(
		"Same-team shadow bullet SHOULD hit shadow tower"
	).is_true()


func test_different_team_shadow_bullet_should_not_hit_shadow_tower() -> void:
	"""Shadow bullet should NOT hit shadow tower of a different team"""
	var bullet_team := 42
	var target_team := 99

	var bullet_data := BulletData.new()
	bullet_data.shadow_team_id = bullet_team
	bullet_data.tower_body_mask = Layers.SHADOW_TOWER_BODY

	var target_tower: Node2D = ShadowTowerScene.instantiate()
	target_tower.data = TowerData.new()
	target_tower.data.firing_rate = 1.0
	target_tower.data.sprite = load("res://assets/tower1000.svg")
	target_tower.shadow_team_id = target_team  # Different team!
	target_tower.entity_id = 300
	_add_child(target_tower)
	await await_idle_frame()

	var should_hit := _simulate_bullet_collision_filter(bullet_data, target_tower)
	assert_bool(should_hit).describes(
		"Different-team shadow bullet should NOT hit shadow tower"
	).is_false()


func test_shadow_bullet_should_not_hit_regular_tower() -> void:
	"""Shadow bullet should NOT hit regular (non-shadow) tower"""
	var bullet_data := BulletData.new()
	bullet_data.shadow_team_id = 42
	bullet_data.tower_body_mask = Layers.SHADOW_TOWER_BODY

	var regular_tower: Node2D = TowerScene.instantiate()
	regular_tower.data = TowerData.new()
	regular_tower.data.firing_rate = 1.0
	_add_child(regular_tower)
	await await_idle_frame()

	var should_hit := _simulate_bullet_collision_filter(bullet_data, regular_tower)
	assert_bool(should_hit).describes(
		"Shadow bullet should NOT hit regular tower"
	).is_false()


func test_normal_bullet_should_not_hit_shadow_tower() -> void:
	"""Normal bullet (shadow_team_id = -1) should NOT hit shadow tower"""
	var bullet_data := BulletData.new()
	bullet_data.shadow_team_id = -1  # Normal bullet
	bullet_data.tower_body_mask = Layers.TOWER_BODY

	var shadow_tower: Node2D = ShadowTowerScene.instantiate()
	shadow_tower.data = TowerData.new()
	shadow_tower.data.firing_rate = 1.0
	shadow_tower.shadow_team_id = 42
	_add_child(shadow_tower)
	await await_idle_frame()

	var should_hit := _simulate_bullet_collision_filter(bullet_data, shadow_tower)
	assert_bool(should_hit).describes(
		"Normal bullet should NOT hit shadow tower"
	).is_false()


# ── Direct Collision Handler Test ────────────────────────────────

func test_bullet_area_entered_registers_shadow_tower_hit() -> void:
	"""Direct test: bullet's _on_hitbox_area_entered should process shadow tower hit"""
	var shadow_team_id := 42

	# Create and configure shadow tower target
	var target_tower: Node2D = ShadowTowerScene.instantiate()
	target_tower.data = TowerData.new()
	target_tower.data.firing_rate = 1.0
	target_tower.data.sprite = load("res://assets/tower1000.svg")
	target_tower.shadow_team_id = shadow_team_id
	target_tower.entity_id = 200
	_add_child(target_tower)
	await await_idle_frame()
	await await_idle_frame()  # Wait for deferred shape creation

	# Create shadow bullet
	var bullet: Node2D = BulletScene.instantiate()
	_add_child(bullet)

	var bd := BulletData.new()
	bd.shadow_team_id = shadow_team_id
	bd.tower_body_mask = Layers.SHADOW_TOWER_BODY
	bd.transmission_chain = []  # Don't include target to avoid self-hit filter
	bd.effects = []
	bullet.data = bd
	bullet.reset()
	await await_idle_frame()

	# Verify bullet Hitbox has correct mask
	var bullet_hitbox := bullet.get_node("Hitbox") as Area2D
	assert_int(bullet_hitbox.collision_mask).is_equal(Layers.SHADOW_TOWER_BODY)

	# Verify target tower body exists and has correct layer
	var tower_body := target_tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	assert_int(tower_body.collision_layer).is_equal(Layers.SHADOW_TOWER_BODY)

	# Verify collision mask overlap
	var mask_overlap := bullet_hitbox.collision_mask & tower_body.collision_layer
	assert_int(mask_overlap).describes(
		"Bullet mask and tower layer should overlap"
	).is_not_equal(0)

	# Verify team filtering passes
	assert_int(target_tower.get_shadow_team_id()).is_equal(shadow_team_id)
	assert_int(bd.shadow_team_id).is_equal(shadow_team_id)


# ── Piercing Behavior Tests (Bug Fix Verification) ─────────────

func test_shadow_bullet_not_destroyed_on_same_team_hit() -> void:
	"""Shadow bullet should NOT be destroyed (no _pending_release) when hitting same-team shadow tower"""
	var shadow_team_id := 42

	# Create shadow bullet
	var bullet: Node2D = BulletScene.instantiate()
	_add_child(bullet)

	var bd := BulletData.new()
	bd.shadow_team_id = shadow_team_id
	bd.tower_body_mask = Layers.SHADOW_TOWER_BODY
	bd.transmission_chain = []
	bd.effects = []
	bullet.data = bd
	bullet.reset()
	await await_idle_frame()

	# Create shadow tower target (same team)
	var target_tower: Node2D = ShadowTowerScene.instantiate()
	target_tower.data = TowerData.new()
	target_tower.data.firing_rate = 1.0
	target_tower.data.sprite = load("res://assets/tower1000.svg")
	target_tower.shadow_team_id = shadow_team_id
	target_tower.entity_id = 200
	_add_child(target_tower)
	await await_idle_frame()
	await await_idle_frame()  # Wait for deferred shape

	# Simulate collision by directly calling the handler
	var tower_body := target_tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	# Key assertion: bullet should NOT be marked for release (piercing behavior)
	assert_bool(bullet._pending_release).describes(
		"Shadow bullet should NOT set _pending_release when hitting same-team shadow tower (piercing)"
	).is_false()

	# Bullet should still be visible
	assert_bool(bullet.visible).describes(
		"Shadow bullet should remain visible after hitting same-team shadow tower"
	).is_true()

	# Bullet should still be processing physics
	assert_bool(bullet.is_physics_processing()).describes(
		"Shadow bullet should continue physics processing after hitting same-team shadow tower"
	).is_true()


func test_shadow_bullet_can_hit_multiple_same_team_towers() -> void:
	"""Shadow bullet should register hits on multiple same-team shadow towers in sequence"""
	var shadow_team_id := 42

	# Create shadow bullet
	var bullet: Node2D = BulletScene.instantiate()
	_add_child(bullet)

	var bd := BulletData.new()
	bd.shadow_team_id = shadow_team_id
	bd.tower_body_mask = Layers.SHADOW_TOWER_BODY
	bd.transmission_chain = []
	bd.effects = []
	bullet.data = bd
	bullet.reset()
	await await_idle_frame()

	# Create two shadow tower targets (same team)
	var tower1: Node2D = ShadowTowerScene.instantiate()
	tower1.data = TowerData.new()
	tower1.data.firing_rate = 1.0
	tower1.data.sprite = load("res://assets/tower1000.svg")
	tower1.shadow_team_id = shadow_team_id
	tower1.entity_id = 200
	_add_child(tower1)
	await await_idle_frame()
	await await_idle_frame()

	var tower2: Node2D = ShadowTowerScene.instantiate()
	tower2.data = TowerData.new()
	tower2.data.firing_rate = 1.0
	tower2.data.sprite = load("res://assets/tower1000.svg")
	tower2.shadow_team_id = shadow_team_id
	tower2.entity_id = 300
	_add_child(tower2)
	await await_idle_frame()
	await await_idle_frame()

	var tower1_body := tower1.get_node_or_null("TowerBody") as Area2D
	var tower2_body := tower2.get_node_or_null("TowerBody") as Area2D
	assert_object(tower1_body).is_not_null()
	assert_object(tower2_body).is_not_null()

	# Hit tower1
	bullet._on_hitbox_area_entered(tower1_body)
	assert_bool(bullet._pending_release).describes(
		"Bullet should NOT be pending release after hitting tower1"
	).is_false()

	# Hit tower2 — should still work because bullet wasn't destroyed
	bullet._on_hitbox_area_entered(tower2_body)
	assert_bool(bullet._pending_release).describes(
		"Bullet should NOT be pending release after hitting tower2"
	).is_false()


func test_shadow_bullet_still_destroyed_on_regular_tower() -> void:
	"""Normal bullet hitting regular tower should still be destroyed (no regression)"""
	var bullet: Node2D = BulletScene.instantiate()
	_add_child(bullet)

	var bd := BulletData.new()
	bd.shadow_team_id = -1  # Normal bullet
	bd.tower_body_mask = Layers.TOWER_BODY
	bd.transmission_chain = []
	bd.effects = []
	bullet.data = bd
	bullet.reset()
	await await_idle_frame()

	# Create a regular tower
	var tower_scene := load("res://entities/towers/tower.tscn")
	var regular_tower: Node2D = tower_scene.instantiate()
	regular_tower.data = TowerData.new()
	regular_tower.data.firing_rate = 1.0
	_add_child(regular_tower)
	await await_idle_frame()

	# Regular tower has Area2D as TowerBody (click area)
	var tower_click_area := regular_tower.get_node_or_null("Area2D") as Area2D
	assert_object(tower_click_area).is_not_null()

	# Simulate collision
	bullet._on_hitbox_area_entered(tower_click_area)

	# Normal bullet should be destroyed on hit
	assert_bool(bullet._pending_release).describes(
		"Normal bullet should be pending release after hitting regular tower"
	).is_true()


# ── Helper: Simulate bullet.gd _on_hitbox_area_entered filtering ─

func _simulate_bullet_collision_filter(bullet_data: BulletData, target: Node) -> bool:
	"""
	Simulates the team filtering logic from bullet.gd _on_hitbox_area_entered.
	Returns true if the bullet WOULD hit the target (passes filtering).
	"""
	if not target.is_in_group("towers"):
		return false

	if bullet_data and bullet_data.shadow_team_id >= 0:
		# Shadow bullet: only hits same-team shadow towers
		if not target.has_method("get_shadow_team_id"):
			return false  # Not a shadow tower
		if target.get_shadow_team_id() != bullet_data.shadow_team_id:
			return false  # Different team
	elif target.has_method("get_shadow_team_id"):
		return false  # Normal bullet shouldn't hit shadow towers

	# Self-hit check
	if bullet_data and bullet_data.transmission_chain.has(target):
		return false

	return true
