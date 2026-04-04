class_name DealDamageSelfSpeedBoostEffect extends BulletEffect

## 子弹造成伤害时，为发射该子弹的炮塔触发速度提升

@export var duration: float = 1.0

func on_deal_damage(bullet_data: BulletData, _target: Node, _damage: float) -> void:
	if bullet_data.transmission_chain.is_empty():
		return
	var source_tower = bullet_data.transmission_chain[0]
	if is_instance_valid(source_tower) and source_tower.has_method("apply_speed_boost"):
		source_tower.apply_speed_boost(duration)
