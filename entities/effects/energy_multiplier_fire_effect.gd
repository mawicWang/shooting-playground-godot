class_name EnergyMultiplierFireEffect extends FireEffect

@export var multiplier: float = 1.2

func apply(tower: Node, bd: BulletData) -> void:
	super.apply(tower, bd)
	bd.energy *= multiplier
	bd.attack *= multiplier
