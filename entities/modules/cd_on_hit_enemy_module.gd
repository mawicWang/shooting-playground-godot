class_name CdOnHitEnemyModule extends Module

## 击敌减速 — 子弹击中敌人时，发射炮塔 CD -0.5s

var _effect: CdReduceOnEnemyEffect

func _init() -> void:
	module_name = "击敌减速"
	category = Category.LOGICAL
	description = "击中敌人时\n自身 CD -0.5s"
	slot_color = Color(1.0, 0.8, 0.1)  # 黄
	_effect = CdReduceOnEnemyEffect.new()
	_effect.reduction = 0.5

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.effects.append(_effect)
	return bullet_data
