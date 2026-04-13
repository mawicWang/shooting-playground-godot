class_name VariantPaletteTest
extends GdUnitTestSuite


func test_get_color_returns_negative_color_for_negative_variant() -> void:
	var palette := VariantPalette.new()
	palette.negative_color = Color.BLUE
	palette.positive_color = Color.RED

	var result := palette.get_color(TowerData.Variant.NEGATIVE)

	assert_that(result).is_equal(Color.BLUE)


func test_get_color_returns_positive_color_for_positive_variant() -> void:
	var palette := VariantPalette.new()
	palette.negative_color = Color.BLUE
	palette.positive_color = Color.RED

	var result := palette.get_color(TowerData.Variant.POSITIVE)

	assert_that(result).is_equal(Color.RED)


func test_default_colors_are_blue_and_red() -> void:
	var palette := VariantPalette.new()

	assert_that(palette.negative_color).is_equal(Color.BLUE)
	assert_that(palette.positive_color).is_equal(Color.RED)


func test_preloaded_palette_tres_loads() -> void:
	var palette := load("res://resources/variant_palette.tres") as VariantPalette

	assert_object(palette).is_not_null()
	assert_that(palette.negative_color).is_equal(Color.BLUE)
	assert_that(palette.positive_color).is_equal(Color.RED)
	assert_that(palette.neutral_color).is_equal(Color.WHITE)


func test_get_color_returns_white_for_neutral_variant() -> void:
	var palette := VariantPalette.new()
	palette.neutral_color = Color.WHITE

	var result := palette.get_color(TowerData.Variant.NEUTRAL)

	assert_that(result).is_equal(Color.WHITE)


func test_default_neutral_color_is_white() -> void:
	var palette := VariantPalette.new()

	assert_that(palette.neutral_color).is_equal(Color.WHITE)
