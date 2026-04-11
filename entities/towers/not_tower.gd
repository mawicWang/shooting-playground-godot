extends "res://entities/towers/tower.gd"

## NOT Tower：所有链式弹药补充均翻转子弹类型（0↔1）

func _ready() -> void:
	super._ready()
	sprite.modulate = Color(0.6, 0.2, 0.8, 1.0)

## 拦截所有 add_ammo_from_chain，强制翻转 bullet_type
## HitTowerTargetReplenishEffect 调用此方法时会自动获得翻转后的类型，无需额外加弹
func add_ammo_from_chain(amount: int, bullet_data: BulletData, _override_bullet_type: int = -1) -> void:
	super.add_ammo_from_chain(amount, bullet_data, 1 - bullet_data.bullet_type)
