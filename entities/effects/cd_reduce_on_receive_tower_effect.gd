class_name CdReduceOnReceiveTowerEffect extends TowerEffect

@export var reduction: float = 0.5

func on_receive_bullet_hit(_bullet_data: BulletData, tower: Node) -> void:
	if tower.has_method("reduce_cooldown"):
		tower.reduce_cooldown(reduction)
