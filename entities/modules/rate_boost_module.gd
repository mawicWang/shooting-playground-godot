class_name RateBoostModule extends Module

## 加速射击 — 降低射击冷却时间

@export var cooldown_reduction: float = 0.3  # 减少的 CD 秒数

func _init() -> void:
	module_name = "加速射击"
	category = Category.COMPUTATIONAL
	description = "射击冷却 -%.1f 秒" % cooldown_reduction
	slot_color = Color(1.0, 0.35, 0.1)  # 橙红色

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.cooldown = maxf(0.1, bullet_data.cooldown - cooldown_reduction)
	return bullet_data
