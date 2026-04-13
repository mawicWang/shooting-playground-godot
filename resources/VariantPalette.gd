## 变体颜色配置资源。将 TowerData.Variant 映射到用于炮塔 Sprite 着色的颜色。
class_name VariantPalette extends Resource

## NEUTRAL 变体炮塔的着色颜色（白色=无染色）
@export var neutral_color: Color = Color.WHITE
## NEGATIVE 变体炮塔的着色颜色（默认蓝色）
@export var negative_color: Color = Color.BLUE
## POSITIVE 变体炮塔的着色颜色（默认红色）
@export var positive_color: Color = Color.RED

## 根据变体返回对应颜色。
func get_color(variant: TowerData.Variant) -> Color:
	match variant:
		TowerData.Variant.NEGATIVE: return negative_color
		TowerData.Variant.POSITIVE: return positive_color
		_: return neutral_color
