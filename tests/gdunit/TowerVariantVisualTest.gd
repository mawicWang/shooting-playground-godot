class_name TowerVariantVisualTest
extends GdUnitTestSuite

const TowerScene := preload("res://entities/towers/tower.tscn")

var _nodes_to_free: Array[Node] = []


func after_test() -> void:
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()


func _add_child(node: Node) -> Node:
	get_tree().root.add_child(node)
	_nodes_to_free.append(node)
	return node


func test_negative_variant_tower_has_shader_material_with_blue_tint() -> void:
	var td := TowerData.new()
	td.sprite = load("res://assets/tower1000.svg")
	td.firing_rate = 1.0
	td.variant = TowerData.Variant.NEGATIVE

	var tower: Node2D = TowerScene.instantiate()
	tower.data = td
	_add_child(tower)
	await await_idle_frame()

	var sprite: Sprite2D = tower.get_node("TowerVisual/Sprite2D")
	assert_object(sprite.material).is_not_null()
	assert_bool(sprite.material is ShaderMaterial) \
		.override_failure_message("sprite.material should be a ShaderMaterial").is_true()
	var mat := sprite.material as ShaderMaterial
	var color := mat.get_shader_parameter("color") as Color
	assert_that(color).is_equal(Color.BLUE)


func test_positive_variant_tower_has_shader_material_with_red_tint() -> void:
	var td := TowerData.new()
	td.sprite = load("res://assets/tower1000.svg")
	td.firing_rate = 1.0
	td.variant = TowerData.Variant.POSITIVE

	var tower: Node2D = TowerScene.instantiate()
	tower.data = td
	_add_child(tower)
	await await_idle_frame()

	var sprite: Sprite2D = tower.get_node("TowerVisual/Sprite2D")
	assert_bool(sprite.material is ShaderMaterial).is_true()
	var mat := sprite.material as ShaderMaterial
	var color := mat.get_shader_parameter("color") as Color
	assert_that(color).is_equal(Color.RED)


func test_two_towers_have_independent_materials() -> void:
	var td_neg := TowerData.new()
	td_neg.sprite = load("res://assets/tower1000.svg")
	td_neg.firing_rate = 1.0
	td_neg.variant = TowerData.Variant.NEGATIVE

	var td_pos := TowerData.new()
	td_pos.sprite = load("res://assets/tower1000.svg")
	td_pos.firing_rate = 1.0
	td_pos.variant = TowerData.Variant.POSITIVE

	var tower_a: Node2D = TowerScene.instantiate()
	tower_a.data = td_neg
	_add_child(tower_a)

	var tower_b: Node2D = TowerScene.instantiate()
	tower_b.data = td_pos
	_add_child(tower_b)
	await await_idle_frame()

	var sprite_a: Sprite2D = tower_a.get_node("TowerVisual/Sprite2D")
	var sprite_b: Sprite2D = tower_b.get_node("TowerVisual/Sprite2D")

	assert_bool(sprite_a.material == sprite_b.material) \
		.override_failure_message("Two towers must not share a ShaderMaterial instance").is_false()


func test_neutral_variant_tower_has_shader_material_with_white_tint() -> void:
	var td := TowerData.new()
	td.sprite = load("res://assets/tower1000.svg")
	td.firing_rate = 1.0
	td.variant = TowerData.Variant.NEUTRAL

	var tower: Node2D = TowerScene.instantiate()
	tower.data = td
	_add_child(tower)
	await await_idle_frame()

	var sprite: Sprite2D = tower.get_node("TowerVisual/Sprite2D")
	assert_object(sprite.material).is_not_null()
	assert_bool(sprite.material is ShaderMaterial).is_true()
	var mat := sprite.material as ShaderMaterial
	var color := mat.get_shader_parameter("color") as Color
	assert_that(color).is_equal(Color.WHITE)
