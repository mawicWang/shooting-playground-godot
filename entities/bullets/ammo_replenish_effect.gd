class_name AmmoReplenishEffect extends BulletHitEffect

@export var ammo_amount: int = 1

func apply(_bullet_data: BulletData, target_tower: Node) -> void:
	if target_tower.has_method("add_ammo"):
		target_tower.add_ammo(ammo_amount)
