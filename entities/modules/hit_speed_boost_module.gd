class_name HitSpeedBoostModule extends Module

## 击中加速 — 子弹击中炮塔时，使对方获得1秒加速（CD速度×2，可叠加）

var _effect: HitSpeedBoostEffect

func _init() -> void:
	module_name = "击中加速"
	category = Category.LOGICAL
	description = "击中炮塔时\n对方加速+1s"
	slot_color = Color(1.0, 0.85, 0.1)  # 金黄色
	_effect = HitSpeedBoostEffect.new()
	# _effect.speed_bonus = 1.0

func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	bullet_data.effects.append(_effect)
	return bullet_data
