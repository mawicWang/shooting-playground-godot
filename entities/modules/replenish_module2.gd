class_name ReplenishModule2 extends Module

## 补充2 — 子弹每次击中友方炮塔时补充 2 弹药

var _effect: ReplenishEffect

func _init() -> void:
	module_name = "补充+2"
	category = Category.LOGICAL
	description = "子弹击中炮塔时\n补充弹药 +2"
	slot_color = Color(0.1, 0.65, 0.95)  # 蓝色
	_effect = ReplenishEffect.new()
	_effect.ammo_amount = 2

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.effects.append(_effect)
	return bullet_data
