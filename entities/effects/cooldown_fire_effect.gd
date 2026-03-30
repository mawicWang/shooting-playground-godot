class_name CooldownFireEffect extends FireEffect

@export var reduction: float = 0.3

func apply(tower: Node, bd: BulletData) -> void:
	super.apply(tower, bd)
	bd.cooldown = maxf(0.1, bd.cooldown - reduction)
