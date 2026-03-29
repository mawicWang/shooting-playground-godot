class_name CdOnHitTowerTargetModule extends Module

## 连接减速 — 子弹击中友方炮塔时，使被击中炮塔 CD -0.5s

var _effect: CdReduceTargetTowerEffect

func _init() -> void:
	module_name = "连接减CD"
	category = Category.LOGICAL
	description = "击中炮塔时\n对方 CD -0.5s"
	slot_color = Color(0.5, 0.3, 1.0)  # 紫
	_effect = CdReduceTargetTowerEffect.new()
	_effect.reduction = 0.5

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.effects.append(_effect)
	return bullet_data
