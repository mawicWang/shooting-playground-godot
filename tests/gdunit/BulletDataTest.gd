# GdUnit4 Test Suite for BulletData
# 测试 BulletData 的复制和修改逻辑

class_name BulletDataTest
extends GdUnitTestSuite


func test_duplicate_copies_all_values() -> void:
	"""测试 duplicate_with_mods 复制所有值"""
	var original := BulletData.new()
	original.attack = 5.0
	original.speed = 300.0
	original.chain_count = 2
	original.knockback = 200.0
	
	var copy := original.duplicate_with_mods({})
	
	assert_that(copy.attack).is_equal(5.0)
	assert_that(copy.speed).is_equal(300.0)
	assert_that(copy.chain_count).is_equal(2)
	assert_that(copy.knockback).is_equal(200.0)


func test_duplicate_creates_independent_copy() -> void:
	"""测试复制后的对象独立于原对象"""
	var original := BulletData.new()
	original.attack = 5.0
	
	var copy := original.duplicate_with_mods({})
	
	# 修改原对象不应影响副本
	original.attack = 10.0
	assert_that(copy.attack).is_equal(5.0)


func test_duplicate_with_mods_applies_modifications() -> void:
	"""测试 duplicate_with_mods 应用修改"""
	var original := BulletData.new()
	original.attack = 1.0
	original.speed = 200.0
	
	var mods := {"attack": 99.0, "speed": 999.0}
	var copy := original.duplicate_with_mods(mods)
	
	assert_that(copy.attack).is_equal(99.0)
	assert_that(copy.speed).is_equal(999.0)


func test_duplicate_preserves_transmission_chain() -> void:
	"""测试复制保留 transmission_chain"""
	var original := BulletData.new()
	original.transmission_chain = [self, "test_value"]
	
	var copy := original.duplicate_with_mods({})
	
	assert_array(copy.transmission_chain).has_size(2)
	assert_that(copy.transmission_chain[0]).is_same(self)


func test_duplicate_preserves_effects() -> void:
	"""测试复制保留 effects 数组"""
	var original := BulletData.new()
	var effect = load("res://entities/effects/bullet_effects/hit_tower_target_replenish_effect.gd").new()
	original.effects.append(effect)
	
	var copy := original.duplicate_with_mods({})
	
	assert_array(copy.effects).has_size(1)


func test_default_values() -> void:
	"""测试默认值"""
	var bd := BulletData.new()
	
	assert_that(bd.attack).is_equal(1.0)
	assert_that(bd.speed).is_equal(200.0)
	assert_that(bd.chain_count).is_equal(0)
	assert_that(bd.knockback).is_equal(150.0)
	assert_that(bd.tower_body_mask).is_equal(32)
