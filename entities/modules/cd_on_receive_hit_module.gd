class_name CdOnReceiveHitModule extends Module

## 受击减速 — 被子弹击中时，自身 CD -0.5s

@export var reduction: float = 0.5

func _init() -> void:
	module_name = "受击减CD"
	category = Category.LOGICAL
	description = "被子弹击中时\n自身 CD -0.5s"
	slot_color = Color(1.0, 0.4, 0.8)  # 粉红

func on_receive_bullet_hit(tower: Node, _bullet_data: BulletData) -> void:
	if tower.has_method("reduce_cooldown"):
		tower.reduce_cooldown(reduction)
