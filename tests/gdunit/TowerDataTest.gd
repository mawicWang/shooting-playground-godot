# GdUnit4 — Tower Data Contract Tests
# 验证所有 tower .tres 满足基本字段契约，并验证每个塔的具体期望值
# 知识库参考：docs/content/towers.md

class_name TowerDataTest
extends GdUnitTestSuite

const TOWER_DIR := "res://resources/"


## 自动扫描 res://resources/ 中所有 tower*.tres 文件
func _get_tower_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(TOWER_DIR)
	if not dir:
		return paths
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("tower") and fname.ends_with(".tres"):
			paths.append(TOWER_DIR + fname)
		fname = dir.get_next()
	dir.list_dir_end()
	return paths


## 所有塔必须通过基本字段合约
func test_all_towers_satisfy_invariants() -> void:
	var paths := _get_tower_paths()
	assert_array(paths).is_not_empty()

	for path in paths:
		var td := load(path) as TowerData
		if td == null:
			assert_object(td).override_failure_message("Failed to load: %s" % path).is_not_null()
			continue
		assert_str(td.tower_name).override_failure_message("%s: tower_name empty" % path).is_not_empty()
		assert_object(td.sprite).override_failure_message("%s: sprite null" % path).is_not_null()
		assert_object(td.icon).override_failure_message("%s: icon null" % path).is_not_null()
		assert_float(td.firing_rate).override_failure_message("%s: firing_rate <= 0" % path).is_greater(0.0)
		assert_bool(td.barrel_directions.size() >= 1).override_failure_message("%s: no barrel_directions" % path).is_true()
		assert_bool(td.initial_ammo >= -1).override_failure_message("%s: invalid initial_ammo" % path).is_true()


## 双向炮 (tower1010) 具体值验证
func test_tower1010_shuangxiang_pao() -> void:
	var td := load("res://resources/tower1010.tres") as TowerData
	assert_object(td).is_not_null()
	assert_str(td.tower_name).is_equal("双向炮")
	assert_float(td.firing_rate).is_equal(1.0)
	assert_int(td.barrel_directions.size()).is_equal(2)
	assert_int(td.initial_ammo).is_equal(10)


## 直角炮 (tower1100) 具体值验证
func test_tower1100_zhijiao_pao() -> void:
	var td := load("res://resources/tower1100.tres") as TowerData
	assert_object(td).is_not_null()
	assert_str(td.tower_name).is_equal("直角炮")
	assert_float(td.firing_rate).is_equal(1.0)
	assert_int(td.barrel_directions.size()).is_equal(2)
	assert_int(td.initial_ammo).is_equal(3)


## 三向炮 (tower1110) 具体值验证
func test_tower1110_sanxiang_pao() -> void:
	var td := load("res://resources/tower1110.tres") as TowerData
	assert_object(td).is_not_null()
	assert_str(td.tower_name).is_equal("三向炮")
	assert_float(td.firing_rate).is_equal(1.0)
	assert_int(td.barrel_directions.size()).is_equal(3)
	assert_int(td.initial_ammo).is_equal(3)


## 四向炮 (tower1111) 具体值验证
func test_tower1111_sixiang_pao() -> void:
	var td := load("res://resources/tower1111.tres") as TowerData
	assert_object(td).is_not_null()
	assert_str(td.tower_name).is_equal("四向炮")
	assert_float(td.firing_rate).is_equal(1.0)
	assert_int(td.barrel_directions.size()).is_equal(4)
	assert_int(td.initial_ammo).is_equal(0)


func test_all_towers_have_variant_field() -> void:
	var paths := _get_tower_paths()
	assert_array(paths).is_not_empty()

	for path in paths:
		var td := load(path) as TowerData
		if td == null:
			assert_object(td).override_failure_message("Failed to load: %s" % path).is_not_null()
			continue
		# Variant must be a valid enum value: 0 (FALSE) or 1 (TRUE)
		assert_bool(td.variant == TowerData.Variant.FALSE or td.variant == TowerData.Variant.TRUE) \
			.override_failure_message("%s: variant must be FALSE or TRUE" % path) \
			.is_true()


func test_tower_variant_enum_values() -> void:
	assert_int(TowerData.Variant.FALSE).is_equal(0)
	assert_int(TowerData.Variant.TRUE).is_equal(1)


func test_default_variant_is_false() -> void:
	var td := TowerData.new()
	assert_int(td.variant).is_equal(TowerData.Variant.FALSE)
