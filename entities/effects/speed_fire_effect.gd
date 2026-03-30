class_name SpeedFireEffect extends FireEffect

@export var bonus: float = 150.0

func apply(tower: Node, bd: BulletData) -> void:
	super.apply(tower, bd)
	bd.speed += bonus
