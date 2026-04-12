class_name VariantPalette extends Resource

@export var negative_color: Color = Color.BLUE
@export var positive_color: Color = Color.RED

func get_color(variant: TowerData.Variant) -> Color:
	return negative_color if variant == TowerData.Variant.NEGATIVE else positive_color
