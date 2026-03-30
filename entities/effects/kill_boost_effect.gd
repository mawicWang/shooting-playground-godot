class_name KillBoostEffect extends BulletEffect

## 击杀触发速度提升效果
## 子弹击杀敌人时，通知发射该子弹的炮塔触发速度加成

var boost_duration: float = 1.0

func on_enemy_died(bullet_data: BulletData, _enemy: Node) -> void:
	if bullet_data.transmission_chain.is_empty():
		return
	var source_tower = bullet_data.transmission_chain[0]
	if is_instance_valid(source_tower) and source_tower.has_method("apply_speed_boost"):
		source_tower.apply_speed_boost(boost_duration)
