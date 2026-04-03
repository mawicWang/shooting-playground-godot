# Integration Test Suite
# Tests the full deploy -> fire -> hit -> verify flow
#
# Uses auto_free() + add_child() since add_child_autofree() is not available in GdUnit4 v5.0.3

class_name IntegrationTest
extends GdUnitTestSuite

const TestTowerData := preload("res://resources/simple_emitter.tres")

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


func test_tower_fires_bullet() -> void:
	"""Tower should fire bullets when start_firing() is called"""
	var tower_scene := load("res://entities/towers/tower.tscn")
	var tower: Node2D = tower_scene.instantiate()
	_add_child(tower)
	await await_idle_frame()

	tower.data = TestTowerData
	tower.ammo = -1
	tower.set_initial_direction(1)  # RIGHT

	tower.start_firing()
	await await_idle_frame()

	# Wait for CD (1.0s) to expire
	await get_tree().create_timer(1.5).timeout

	var bullets := get_tree().get_nodes_in_group("bullets")
	print("Bullets fired: ", bullets.size())
	assert_int(bullets.size()).is_greater(0)


func test_bullet_hits_enemy() -> void:
	"""enemy_hit fires when bullet area enters enemy hitbox (direct callback test)"""
	var enemy_scene := load("res://entities/enemies/enemy.tscn")
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	_add_child(enemy)
	await await_idle_frame()

	var hit_count := [0]
	enemy.enemy_hit.connect(func(_body: Node, _e: Node) -> void:
		hit_count[0] += 1
	)

	# Simulate a bullet entering the enemy's area by directly calling the handler.
	# This tests the signal-chain (area_entered → enemy_hit) without depending on
	# CharacterBody2D physics, which is unreliable in the GdUnit4 test environment.
	var bullet_scene := load("res://entities/bullets/bullet.tscn")
	var bullet: Node2D = bullet_scene.instantiate()
	_add_child(bullet)
	bullet.data = BulletData.new()
	bullet.reset()
	await await_idle_frame()

	var bullet_hitbox := bullet.get_node("Hitbox") as Area2D
	enemy._on_hitbox_area_entered(bullet_hitbox)

	assert_int(hit_count[0]).is_greater(0)


func test_enemy_takes_damage() -> void:
	"""Enemy should take damage when hit by bullet"""
	var tower_scene := load("res://entities/towers/tower.tscn")
	var tower: Node2D = tower_scene.instantiate()
	_add_child(tower)

	var enemy_scene := load("res://entities/enemies/enemy.tscn")
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	_add_child(enemy)

	await await_idle_frame()

	tower.data = TestTowerData
	tower.ammo = -1
	tower.set_initial_direction(1)
	tower.global_position = Vector2(200, 400)
	enemy.global_position = Vector2(260, 400)

	await await_idle_frame()

	var initial_health: float = enemy.current_health

	# Simulate EnemyManager damage handling
	enemy.enemy_hit.connect(func(body: Node, e: Node) -> void:
		if body.is_in_group("bullets") and is_instance_valid(e):
			var bullet_data: Variant = body.get("data")
			var attack := 1.0
			if bullet_data != null:
				attack = bullet_data.attack
			e.take_damage(attack, bullet_data)
	)

	tower.start_firing()
	await get_tree().create_timer(2.0).timeout

	var final_health: float = enemy.current_health
	print("Health: ", initial_health, " -> ", final_health)
	assert_float(final_health).is_less(initial_health)


func test_enemy_destroyed_after_3_hits() -> void:
	"""Enemy is destroyed after taking 3 × 1 damage (max_health = 3)"""
	var enemy_scene := load("res://entities/enemies/enemy.tscn")
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	_add_child(enemy)
	await await_idle_frame()

	var destroyed := [false]
	enemy.enemy_destroyed.connect(func(_e: Node) -> void:
		destroyed[0] = true
	)

	var bd := BulletData.new()
	enemy.take_damage(1.0, bd)
	assert_bool(destroyed[0]).is_false()

	enemy.take_damage(1.0, bd)
	assert_bool(destroyed[0]).is_false()

	enemy.take_damage(1.0, bd)
	assert_bool(destroyed[0]).is_true()


func test_tower_ammo_decreases() -> void:
	"""Tower ammo should decrease when firing"""
	var tower_scene := load("res://entities/towers/tower.tscn")
	var tower: Node2D = tower_scene.instantiate()
	_add_child(tower)

	await await_idle_frame()

	tower.data = TestTowerData
	tower.ammo = 5
	tower.set_initial_direction(1)

	await await_idle_frame()

	var initial_ammo: int = tower.ammo

	tower.start_firing()
	await get_tree().create_timer(2.0).timeout

	var final_ammo: int = tower.ammo
	print("Ammo: ", initial_ammo, " -> ", final_ammo)
	assert_int(final_ammo).is_less(initial_ammo)


func test_multiple_bullets_over_time() -> void:
	"""Tower should fire multiple bullets over time"""
	var tower_scene := load("res://entities/towers/tower.tscn")
	var tower: Node2D = tower_scene.instantiate()
	_add_child(tower)

	await await_idle_frame()

	tower.data = TestTowerData
	tower.ammo = -1
	tower.set_initial_direction(1)

	await await_idle_frame()

	tower.start_firing()

	# CD ~1s, wait 5 seconds for ~5 bullets
	await get_tree().create_timer(5.0).timeout

	var bullets := get_tree().get_nodes_in_group("bullets")
	print("Multiple bullets: ", bullets.size())
	assert_int(bullets.size()).is_greater(1)
