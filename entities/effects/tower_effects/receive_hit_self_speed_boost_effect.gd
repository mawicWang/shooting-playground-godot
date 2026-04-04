class_name ReceiveHitSelfSpeedBoostEffect extends TowerEffect

## 炮塔被子弹击中时，为自身触发速度提升

@export var duration: float = 1.0

func on_receive_bullet_hit(_bullet_data: BulletData, tower: Node) -> void:
	if tower.has_method("apply_speed_boost"):
		tower.apply_speed_boost(duration)
