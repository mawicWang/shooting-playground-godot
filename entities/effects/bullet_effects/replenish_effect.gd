class_name ReplenishEffect extends BulletEffect

## 子弹击中炮塔时补充弹药

@export var ammo_amount: int = 1

func on_hit_tower(_bullet_data: BulletData, tower: Node) -> void:
	if not tower.has_method("add_ammo"):
		return
	tower.add_ammo(ammo_amount)
