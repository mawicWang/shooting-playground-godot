class_name VariantPalette extends Resource

## 变体颜色配置资源
## 用于为不同变体的炮塔提供视觉区分

@export var false_color: Color = Color(0.2, 0.4, 1.0)  # 蓝色
@export var true_color: Color = Color(1.0, 0.3, 0.3)   # 红色

## 根据变体返回对应的颜色
func get_color(variant: TowerData.Variant) -> Color:
	return false_color if variant == TowerData.Variant.FALSE else true_color