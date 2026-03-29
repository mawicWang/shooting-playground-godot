class_name CdReduceOnHitTowerEffect extends BulletEffect

## 子弹击中炮塔时，减少发射该子弹的炮塔（来源方）的 CD

var reduction: float = 0.5

func on_hit_tower(bullet_data: BulletData, _hit_tower: Node) -> void:
	if bullet_data.transmission_chain.is_empty():
		return
	var source_tower = bullet_data.transmission_chain[0]
	if is_instance_valid(source_tower) and source_tower.has_method("reduce_cooldown"):
		source_tower.reduce_cooldown(reduction)
