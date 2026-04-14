class_name StatModifier extends RefCounted

enum Type { ADDITIVE, MULTIPLICATIVE }

var value: float
var type: Type
var source: Object

func _init(p_value: float, p_type: Type, p_source: Object) -> void:
	value = p_value
	type = p_type
	source = p_source
