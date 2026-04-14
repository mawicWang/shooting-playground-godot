class_name HitTowerTargetReplenishEffect extends BulletEffect

## 子弹击中炮塔时补充弹药（链式传递：继承当前子弹的链追踪状态）

@export var ammo_amount: int = 1

func on_hit_tower(bullet_data: BulletData, tower: Node) -> void:
	if not tower.has_method("add_ammo_from_chain"):
		return
	tower.add_ammo_from_chain(ammo_amount, bullet_data)
