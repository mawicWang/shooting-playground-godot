class_name CdOnHitTowerSelfModule extends Module

## 连接自减速 — 子弹击中友方炮塔时，发射炮塔（自身）CD -0.5s

var _effect: CdReduceOnHitTowerEffect

func _init() -> void:
	module_name = "连接自减速"
	category = Category.LOGICAL
	description = "击中炮塔时\n自身 CD -0.5s"
	slot_color = Color(0.3, 0.8, 1.0)  # 浅蓝
	_effect = CdReduceOnHitTowerEffect.new()
	_effect.reduction = 0.5

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.effects.append(_effect)
	return bullet_data
