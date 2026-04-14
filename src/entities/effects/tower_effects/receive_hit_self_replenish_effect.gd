class_name ReceiveHitSelfReplenishEffect extends TowerEffect

## 炮塔被子弹击中时，补充自身弹药（链式传递：继承当前子弹的链追踪状态）

@export var ammo_amount: int = 1

func on_receive_bullet_hit(bullet_data: BulletData, tower: Node) -> void:
	if not tower.has_method("add_ammo_from_chain"):
		return
	tower.add_ammo_from_chain(ammo_amount, bullet_data)
