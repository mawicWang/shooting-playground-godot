class_name HeavyAmmoFireEffect extends FireEffect

@export var ammo_extra: int = 1
@export var attack_multiplier: float = 1.8

func apply(tower: Node, bd: BulletData) -> void:
	super.apply(tower, bd)
	for i in range(ammo_extra):
		tower.consume_ammo()
	bd.attack *= attack_multiplier
