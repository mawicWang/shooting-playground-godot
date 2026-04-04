class_name HitTowerTargetCdReduceEffect extends BulletEffect

## 子弹击中炮塔时，减少被击中炮塔（目标方）的 CD

@export var reduction: float = 0.5

func on_hit_tower(_bullet_data: BulletData, hit_tower: Node) -> void:
	if is_instance_valid(hit_tower) and hit_tower.has_method("reduce_cooldown"):
		hit_tower.reduce_cooldown(reduction)
