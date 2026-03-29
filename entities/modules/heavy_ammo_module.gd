class_name HeavyAmmoModule extends Module

## 重弹头 — 每次发射额外消耗 1 弹药，但攻击力 ×1.8

@export var ammo_extra: int = 1
@export var attack_multiplier: float = 1.8

func _init() -> void:
	module_name = "重弹头"
	category = Category.COMPUTATIONAL
	description = "发射额外消耗 %d 弹药\n攻击力 ×%.1f" % [ammo_extra, attack_multiplier]
	slot_color = Color(0.8, 0.2, 0.2)  # 深红

func apply_effect(tower: Node, bullet_data: BulletData) -> BulletData:
	# 额外消耗弹药
	for i in range(ammo_extra):
		tower.consume_ammo()
	bullet_data.attack *= attack_multiplier
	return bullet_data
