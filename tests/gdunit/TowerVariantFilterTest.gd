# GdUnit4 — Tower Variant Filter Tests
# Verifies that bullets only interact with towers of matching variant.
# Uses direct _on_hitbox_area_entered() calls (same pattern as ShadowTowerCollisionTest).

class_name TowerVariantFilterTest
extends GdUnitTestSuite

const TowerScene := preload("res://entities/towers/tower.tscn")
const BulletScene := preload("res://entities/bullets/bullet.tscn")

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


## Creates a tower instance with the given variant. entity_id avoids self-hit filter.
func _make_tower(variant: TowerData.Variant, entity_id: int) -> Node2D:
	var td := TowerData.new()
	td.sprite = load("res://assets/tower1000.svg")
	td.firing_rate = 1.0
	td.barrel_directions = PackedVector2Array([Vector2(0, -1)])
	td.initial_ammo = -1  # 无限弹药，避免触发弹药耗尽信号干扰测试
	td.variant = variant
	var tower: Node2D = TowerScene.instantiate()
	tower.data = td
	tower.entity_id = entity_id
	return tower


## Creates a bullet with the given bullet_type.
func _make_bullet(bullet_type: TowerData.Variant) -> Node2D:
	var bullet: Node2D = BulletScene.instantiate()
	var bd := BulletData.new()
	bd.bullet_type = bullet_type
	bd.shadow_team_id = -1  # Normal bullet
	bd.tower_body_mask = Layers.TOWER_BODY
	bd.transmission_chain = []
	bd.effects = []
	bullet.data = bd
	return bullet


# ── Matching variant: bullet SHOULD interact ─────────────────────

func test_negative_bullet_hits_negative_tower() -> void:
	var tower := _make_tower(TowerData.Variant.NEGATIVE, 100)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()  # deferred TowerBody shape

	var bullet := _make_bullet(TowerData.Variant.NEGATIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("NEGATIVE bullet SHOULD hit NEGATIVE tower") \
		.is_true()


func test_positive_bullet_hits_positive_tower() -> void:
	var tower := _make_tower(TowerData.Variant.POSITIVE, 101)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.POSITIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("POSITIVE bullet SHOULD hit POSITIVE tower") \
		.is_true()


# ── Non-matching variant: bullet MUST NOT interact ────────────────

func test_positive_bullet_does_not_hit_negative_tower() -> void:
	var tower := _make_tower(TowerData.Variant.NEGATIVE, 102)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.POSITIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("POSITIVE bullet must NOT hit NEGATIVE tower") \
		.is_false()
	assert_bool(bullet.visible) \
		.override_failure_message("Bullet should remain visible after mismatch") \
		.is_true()
	assert_bool(bullet.is_physics_processing()) \
		.override_failure_message("Bullet should keep moving after mismatch") \
		.is_true()


func test_negative_bullet_does_not_hit_positive_tower() -> void:
	var tower := _make_tower(TowerData.Variant.POSITIVE, 103)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.NEGATIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("NEGATIVE bullet must NOT hit POSITIVE tower") \
		.is_false()
	assert_bool(bullet.visible).is_true()
	assert_bool(bullet.is_physics_processing()).is_true()


# ── NEUTRAL variant: accepts all bullet types ─────────────────────

func test_negative_bullet_hits_neutral_tower() -> void:
	var tower := _make_tower(TowerData.Variant.NEUTRAL, 200)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.NEGATIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("NEGATIVE bullet SHOULD hit NEUTRAL tower") \
		.is_true()


func test_positive_bullet_hits_neutral_tower() -> void:
	var tower := _make_tower(TowerData.Variant.NEUTRAL, 201)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.POSITIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("POSITIVE bullet SHOULD hit NEUTRAL tower") \
		.is_true()


# ── Null data guard ───────────────────────────────────────────────

func test_tower_with_null_data_is_not_filtered() -> void:
	var tower: Node2D = TowerScene.instantiate()
	tower.data = null
	tower.entity_id = 104
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.NEGATIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()

	bullet._on_hitbox_area_entered(tower_body)
	assert_bool(bullet._pending_release) \
		.override_failure_message("null-data tower should not be filtered — bullet should be consumed") \
		.is_true()
