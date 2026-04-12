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
## 炮塔变体标识。子弹 bullet_type 必须与此匹配才能触发交互。
@export var variant: Variant = Variant.FALSE
## 自定义炮塔场景。null 时使用默认 tower.tscn。
@export var scene: PackedScene
