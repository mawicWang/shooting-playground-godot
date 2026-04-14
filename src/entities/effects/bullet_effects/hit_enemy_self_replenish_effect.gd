class_name HitEnemySelfReplenishEffect extends BulletEffect

## 子弹击中敌人时，补充发射该子弹的炮塔的弹药

@export var ammo_amount: int = 1

func on_hit_enemy(bullet_data: BulletData, _enemy: Node) -> void:
	if bullet_data.transmission_chain.is_empty():
		return
	var source_tower = bullet_data.transmission_chain[0]
	if is_instance_valid(source_tower) and source_tower.has_method("add_ammo"):
		source_tower.add_ammo(ammo_amount)
