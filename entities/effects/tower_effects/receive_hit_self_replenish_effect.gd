class_name ReceiveHitSelfReplenishEffect extends TowerEffect

## 炮塔被子弹击中时，补充自身弹药

@export var ammo_amount: int = 1

func on_receive_bullet_hit(_bullet_data: BulletData, tower: Node) -> void:
	if tower.has_method("add_ammo"):
		tower.add_ammo(ammo_amount)
