class_name HitSpeedBoostEffect extends BulletEffect

## 击中炮塔时，使被击中炮塔获得加速（持续 duration 秒，CD 冷却速度 ×K，可叠加）

@export var duration: float = 1.0

func on_hit_tower(_bullet_data: BulletData, hit_tower: Node) -> void:
	if is_instance_valid(hit_tower) and hit_tower.has_method("apply_speed_boost"):
		hit_tower.apply_speed_boost(duration)
