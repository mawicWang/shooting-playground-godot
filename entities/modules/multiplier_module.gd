class_name MultiplierModule extends Module

@export var multiplier: float = 1.5

func _init() -> void:
	module_name = "乘法器"
	category = Category.COMPUTATIONAL
	description = "子弹能量 ×%.1f" % multiplier
	slot_color = Color(1.0, 0.6, 0.1)  # 橙色

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.energy *= multiplier
	return bullet_data
