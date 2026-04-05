# tests/gdunit/DevModeRespawnTest.gd
class_name DevModeRespawnTest
extends GdUnitTestSuite

var _nodes_to_free: Array[Node] = []

func before_test() -> void:
	_nodes_to_free.clear()
	GameState.game_mode = GameState.GameMode.DEV

func after_test() -> void:
	GameState.game_mode = GameState.GameMode.CHAOS
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()

func _add(node: Node) -> Node:
	get_tree().root.add_child(node)
	_nodes_to_free.append(node)
	return node

# Test: in dev mode, destroying the single enemy does NOT emit all_enemies_defeated
func test_dev_mode_no_all_enemies_defeated_signal() -> void:
	GameState.start_game()
	var em: Node2D = load("res://entities/enemies/enemy_manager.gd").new()
	em.name = "EnemyManagerTest"
	_add(em)
	await await_idle_frame()

	# Set a fake grid rect so spawn math doesn't crash
	em.set_grid_info(Rect2(100, 100, 400, 400), 80.0)

	var spawn_info := {
		"spawn_pos": Vector2(300, 50),
		"warning_pos": Vector2(300, 40),
		"direction": Vector2(0, 1),
		"pos_key": "top_2"
	}
	em.spawn_enemies_from_data([spawn_info])
	await await_idle_frame()

	# Use array to track signal (array is reference type, captures correctly in lambdas)
	var fired := [false]
	em.all_enemies_defeated.connect(func(): fired[0] = true)

	assert_int(em.active_enemies.size()).is_equal(1)
	var enemy = em.active_enemies[0]
	em._on_enemy_destroyed(enemy)
	await await_idle_frame()

	assert_bool(fired[0]).is_false()
	GameState.stop_game()

# Test: in dev mode, a new enemy is spawned after the old one is destroyed
func test_dev_mode_enemy_respawns_after_death() -> void:
	GameState.start_game()
	var em: Node2D = load("res://entities/enemies/enemy_manager.gd").new()
	em.name = "EnemyManagerTest2"
	_add(em)
	await await_idle_frame()

	em.set_grid_info(Rect2(100, 100, 400, 400), 80.0)

	var spawn_info := {
		"spawn_pos": Vector2(300, 50),
		"warning_pos": Vector2(300, 40),
		"direction": Vector2(0, 1),
		"pos_key": "top_2"
	}
	em.spawn_enemies_from_data([spawn_info])
	await await_idle_frame()

	var first_enemy = em.active_enemies[0]
	em._on_enemy_destroyed(first_enemy)
	await await_idle_frame()

	# A new enemy should have been added
	assert_int(em.active_enemies.size()).is_equal(1)
	assert_bool(em.active_enemies[0] != first_enemy).is_true()
	GameState.stop_game()

# Test: in normal mode, all_enemies_defeated IS emitted when last enemy dies
func test_normal_mode_all_enemies_defeated_signal() -> void:
	GameState.game_mode = GameState.GameMode.CHAOS
	GameState.start_game()
	var em: Node2D = load("res://entities/enemies/enemy_manager.gd").new()
	em.name = "EnemyManagerTest3"
	_add(em)
	await await_idle_frame()

	em.set_grid_info(Rect2(100, 100, 400, 400), 80.0)

	var spawn_info := {
		"spawn_pos": Vector2(300, 50),
		"warning_pos": Vector2(300, 40),
		"direction": Vector2(0, 1),
		"pos_key": "top_2"
	}
	em.spawn_enemies_from_data([spawn_info])
	await await_idle_frame()

	var fired := [false]
	em.all_enemies_defeated.connect(func(): fired[0] = true)

	var enemy = em.active_enemies[0]
	em._on_enemy_destroyed(enemy)
	await await_idle_frame()

	assert_bool(fired[0]).is_true()
	GameState.stop_game()
