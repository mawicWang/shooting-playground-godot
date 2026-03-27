class_name AcceleratorModule extends Module

@export var speed_bonus: float = 150.0

func _init() -> void:
	module_name = "加速器"
	category = Category.COMPUTATIONAL
	description = "子弹速度 +%.0f" % speed_bonus
	slot_color = Color(0.1, 0.9, 1.0)  # 青色

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.speed += speed_bonus
	return bullet_data
