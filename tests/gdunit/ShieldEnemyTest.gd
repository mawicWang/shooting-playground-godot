# GdUnit4 — Shield Enemy Tests
# 验证护盾敌人的核心机制：护盾吸收伤害、破盾动画、破盾后正常受伤

class_name ShieldEnemyTest
extends GdUnitTestSuite

const SHIELD_ENEMY_SCENE := preload("res://entities/enemies/shield_enemy.tscn")

var _nodes_to_free: Array[Node] = []


func before_test() -> void:
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


func _make_shield_enemy() -> CharacterBody2D:
	var enemy: CharacterBody2D = SHIELD_ENEMY_SCENE.instantiate()
	_add_child(enemy)
	return enemy


## 护盾敌人初始属性正确
func test_shield_enemy_initial_properties() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	assert_int(enemy.shield_layers).is_equal(2)
	assert_int(enemy.max_shield_layers).is_equal(2)
	assert_float(enemy.max_health).is_equal(4.0)
	assert_float(enemy.current_health).is_equal(4.0)
	assert_float(enemy.speed).is_equal(25.0)


## 有护盾时受击不扣血，只消耗 1 层护盾
func test_shield_absorbs_damage_without_hp_loss() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	var initial_health: float = enemy.current_health
	var bd := BulletData.new()
	enemy.take_damage(1.0, bd)

	assert_float(enemy.current_health).is_equal(initial_health)
	assert_int(enemy.shield_layers).is_equal(1)


## 高伤害也只消耗 1 层护盾
func test_shield_absorbs_high_damage_as_one_layer() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	var bd := BulletData.new()
	bd.attack = 999.0
	enemy.take_damage(999.0, bd)

	assert_float(enemy.current_health).is_equal(4.0)
	assert_int(enemy.shield_layers).is_equal(1)


## 连续两次攻击消耗全部护盾
func test_two_hits_break_all_shields() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	var bd := BulletData.new()
	enemy.take_damage(1.0, bd)
	enemy.take_damage(1.0, bd)

	assert_int(enemy.shield_layers).is_equal(0)
	assert_float(enemy.current_health).is_equal(4.0)


## 破盾后进入短暂僵直（_is_stunned = true, speed = 0）
func test_stun_on_shield_break() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	var bd := BulletData.new()
	enemy.take_damage(1.0, bd)  # shield 2 -> 1
	enemy.take_damage(1.0, bd)  # shield 1 -> 0, break

	assert_bool(enemy._is_stunned).is_true()
	assert_float(enemy.speed).is_equal(0.0)


## 僵直结束后恢复移动
func test_stun_recovery() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	var bd := BulletData.new()
	enemy.take_damage(1.0, bd)
	enemy.take_damage(1.0, bd)

	# 等待僵直恢复 (0.25s + buffer)
	await get_tree().create_timer(0.4).timeout

	assert_bool(enemy._is_stunned).is_false()
	assert_float(enemy.speed).is_equal(25.0)


## 护盾消耗完后，正常受伤
func test_damage_after_shields_gone() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	var bd := BulletData.new()
	# 消耗全部护盾
	enemy.take_damage(1.0, bd)
	enemy.take_damage(1.0, bd)

	# 等僵直结束
	await get_tree().create_timer(0.4).timeout

	# 现在应该正常受伤
	enemy.take_damage(1.0, bd)
	assert_float(enemy.current_health).is_equal(3.0)

	enemy.take_damage(1.0, bd)
	assert_float(enemy.current_health).is_equal(2.0)


## 护盾消耗完后，敌人可被击杀
func test_enemy_dies_after_shields_and_hp_depleted() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	var destroyed := [false]
	enemy.enemy_destroyed.connect(func(_e: Node) -> void:
		destroyed[0] = true
	)

	var bd := BulletData.new()
	# 2 hits for shields
	enemy.take_damage(1.0, bd)
	enemy.take_damage(1.0, bd)

	await get_tree().create_timer(0.4).timeout

	# 4 hits for HP (max_health = 4)
	enemy.take_damage(1.0, bd)
	assert_bool(destroyed[0]).is_false()
	enemy.take_damage(1.0, bd)
	assert_bool(destroyed[0]).is_false()
	enemy.take_damage(1.0, bd)
	assert_bool(destroyed[0]).is_false()
	enemy.take_damage(1.0, bd)
	assert_bool(destroyed[0]).is_true()


## 僵直期间受击无效
func test_damage_ignored_during_stun() -> void:
	var enemy := _make_shield_enemy()
	await await_idle_frame()

	var bd := BulletData.new()
	enemy.take_damage(1.0, bd)
	enemy.take_damage(1.0, bd)  # breaks shield, stunned

	# 僵直中再受击，不应扣血
	enemy.take_damage(1.0, bd)
	assert_float(enemy.current_health).is_equal(4.0)
