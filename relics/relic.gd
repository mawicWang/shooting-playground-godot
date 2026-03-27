class_name Relic extends Resource

@export var relic_name: String = ""
@export var description: String = ""
@export var rarity: int = 1  # 1-4

## 每次炮塔发射子弹时调用（EventManager 分发）
func on_bullet_fired(_bullet_data: BulletData, _tower: Node) -> void:
	pass

## 每波开始时调用
func on_wave_start() -> void:
	pass
