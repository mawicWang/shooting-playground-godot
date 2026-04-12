class_name TowerData extends Resource

enum Variant {
	FALSE = 0,
	TRUE = 1,
}

@export var tower_name: String = ""
@export var sprite: Texture2D
@export var icon: Texture2D
@export var firing_rate: float = 1.0
@export var barrel_directions: PackedVector2Array = PackedVector2Array([Vector2(0, -1)])
## 初始弹药数量。-1 表示无限；0 或正整数为有限弹药。
@export var initial_ammo: int = 3
## 自定义炮塔场景。null 时使用默认 tower.tscn。
@export var scene: PackedScene
## 炮塔变体：FALSE（蓝）或 TRUE（红）。子弹必须匹配变体才能击中。
@export var variant: Variant = Variant.FALSE
