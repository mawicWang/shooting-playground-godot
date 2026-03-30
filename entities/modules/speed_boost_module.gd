class_name SpeedBoostModule extends Module

## 击杀加速 — 子弹击杀敌人时，发射炮塔触发速度提升

var _effect: KillBoostEffect

func _init() -> void:
	module_name = "击杀加速"
	category = Category.LOGICAL
	description = "击杀敌人时\n炮塔速度提升 1s"
	slot_color = Color(1.0, 0.4, 0.1)  # 橙红色
	_effect = KillBoostEffect.new()
	_effect.boost_duration = 1.0

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.effects.append(_effect)
	return bullet_data
