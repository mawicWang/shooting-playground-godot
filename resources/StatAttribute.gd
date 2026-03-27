class_name StatAttribute extends RefCounted

var base_value: float
var _modifiers: Array[StatModifier] = []

func _init(p_base: float = 0.0) -> void:
	base_value = p_base

func get_value() -> float:
	var total := base_value
	var mult := 1.0
	for m in _modifiers:
		if m.type == StatModifier.Type.ADDITIVE:
			total += m.value
		else:
			mult *= m.value
	return total * mult

func add_modifier(mod: StatModifier) -> void:
	_modifiers.append(mod)

func remove_modifiers_from(source: Object) -> void:
	_modifiers = _modifiers.filter(func(m): return m.source != source)
