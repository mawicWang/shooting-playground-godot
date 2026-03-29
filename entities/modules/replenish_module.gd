class_name ReplenishModule extends Module

## 补充1 — 子弹每次击中友方炮塔时补充 1 弹药

var _effect: ReplenishEffect

func _init() -> void:
	module_name = "补充1"
	category = Category.LOGICAL
	description = "子弹击中炮塔时\n补充 1 弹药"
	slot_color = Color(0.2, 0.85, 0.45)  # 绿色
	_effect = ReplenishEffect.new()
	_effect.ammo_amount = 1

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.effects.append(_effect)
	return bullet_data
