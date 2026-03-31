# GdUnit4 Test Suite for StatAttribute
# 测试 StatAttribute 的计算逻辑

class_name StatAttributeTest
extends GdUnitTestSuite


func test_base_value() -> void:
	"""测试基础值"""
	var attr := StatAttribute.new(100.0)
	assert_that(attr.get_value()).is_equal(100.0)


func test_additive_modifier() -> void:
	"""测试加性修饰符"""
	var attr := StatAttribute.new(100.0)
	var mod := StatModifier.new(10.0, StatModifier.Type.ADDITIVE, self)
	attr.add_modifier(mod)
	assert_that(attr.get_value()).is_equal(110.0)


func test_multiplicative_modifier() -> void:
	"""测试乘性修饰符"""
	var attr := StatAttribute.new(100.0)
	var mod := StatModifier.new(1.5, StatModifier.Type.MULTIPLICATIVE, self)
	attr.add_modifier(mod)
	assert_that(attr.get_value()).is_equal(150.0)


func test_combined_modifiers() -> void:
	"""测试加性和乘性修饰符组合"""
	var attr := StatAttribute.new(100.0)
	var add_mod := StatModifier.new(10.0, StatModifier.Type.ADDITIVE, self)
	var mult_mod := StatModifier.new(1.5, StatModifier.Type.MULTIPLICATIVE, self)
	
	attr.add_modifier(add_mod)
	attr.add_modifier(mult_mod)
	
	# (100 + 10) * 1.5 = 165
	assert_that(attr.get_value()).is_equal(165.0)


func test_modifier_cleanup() -> void:
	"""测试修饰符清理"""
	var attr := StatAttribute.new(100.0)
	var mod := StatModifier.new(50.0, StatModifier.Type.ADDITIVE, self)
	
	attr.add_modifier(mod)
	assert_that(attr.get_value()).is_equal(150.0)
	
	attr.remove_modifiers_from(self)
	assert_that(attr.get_value()).is_equal(100.0)


func test_multiple_additive_modifiers() -> void:
	"""测试多个加性修饰符"""
	var attr := StatAttribute.new(100.0)
	attr.add_modifier(StatModifier.new(10.0, StatModifier.Type.ADDITIVE, self))
	attr.add_modifier(StatModifier.new(20.0, StatModifier.Type.ADDITIVE, self))
	attr.add_modifier(StatModifier.new(30.0, StatModifier.Type.ADDITIVE, self))
	
	# 100 + 10 + 20 + 30 = 160
	assert_that(attr.get_value()).is_equal(160.0)


func test_multiple_multiplicative_modifiers() -> void:
	"""测试多个乘性修饰符"""
	var attr := StatAttribute.new(100.0)
	attr.add_modifier(StatModifier.new(1.5, StatModifier.Type.MULTIPLICATIVE, self))
	attr.add_modifier(StatModifier.new(2.0, StatModifier.Type.MULTIPLICATIVE, self))
	
	# 100 * 1.5 * 2.0 = 300
	assert_that(attr.get_value()).is_equal(300.0)


func test_complex_modifier_combination() -> void:
	"""测试复杂的修饰符组合"""
	var attr := StatAttribute.new(100.0)
	
	# 添加混合修饰符
	attr.add_modifier(StatModifier.new(50.0, StatModifier.Type.ADDITIVE, self))      # +50
	attr.add_modifier(StatModifier.new(2.0, StatModifier.Type.MULTIPLICATIVE, self))  # *2
	attr.add_modifier(StatModifier.new(10.0, StatModifier.Type.ADDITIVE, self))       # +10
	attr.add_modifier(StatModifier.new(1.5, StatModifier.Type.MULTIPLICATIVE, self))  # *1.5
	
	# (100 + 50 + 10) * 2.0 * 1.5 = 160 * 3 = 480
	assert_that(attr.get_value()).is_equal(480.0)
