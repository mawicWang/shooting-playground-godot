class_name DealDamageSelfCdReduceEffect extends BulletEffect

## 子弹造成伤害时，减少发射该子弹的炮塔的 CD

@export var reduction: float = 0.5

func on_deal_damage(bullet_data: BulletData, _target: Node, _damage: float) -> void:
	if bullet_data.transmission_chain.is_empty():
		return
	var source_tower = bullet_data.transmission_chain[0]
	if is_instance_valid(source_tower) and source_tower.has_method("reduce_cooldown"):
		source_tower.reduce_cooldown(reduction)
