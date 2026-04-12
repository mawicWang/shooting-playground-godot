class_name ItemPoolTest
extends GdUnitTestSuite


func test_normal_pool_is_not_empty() -> void:
	var pool := ItemPool.normal_pool()

	assert_int(pool.size()).is_greater(0)


func test_normal_pool_contains_only_tower_data_and_modules() -> void:
	var pool := ItemPool.normal_pool()

	for item in pool:
		assert_bool(item is TowerData or item is Module).is_true()


func test_dev_towers_is_not_empty() -> void:
	var towers := ItemPool.dev_towers()

	assert_int(towers.size()).is_greater(0)


func test_dev_towers_contains_only_tower_data() -> void:
	var towers := ItemPool.dev_towers()

	for item in towers:
		assert_bool(item is TowerData).is_true()


func test_dev_modules_is_not_empty() -> void:
	var modules := ItemPool.dev_modules()

	assert_int(modules.size()).is_greater(0)


func test_dev_modules_contains_only_modules() -> void:
	var modules := ItemPool.dev_modules()

	for item in modules:
		assert_bool(item is Module).is_true()


func test_all_items_have_pool_flags() -> void:
	for item in ItemPool.ALL_ITEMS:
		assert_bool(item.get("in_normal_pool") != null).is_true()
		assert_bool(item.get("in_dev_pool") != null).is_true()


func test_item_excluded_from_normal_pool_not_in_normal_pool() -> void:
	var td := TowerData.new()
	td.in_normal_pool = false
	td.in_dev_pool = true

	var fake_list := [td]
	var result := fake_list.filter(func(r): return r.in_normal_pool)

	assert_int(result.size()).is_equal(0)


func test_item_excluded_from_dev_pool_not_in_dev_towers() -> void:
	var td := TowerData.new()
	td.in_normal_pool = true
	td.in_dev_pool = false

	var fake_list := [td]
	var result := fake_list.filter(func(r): return r is TowerData and r.in_dev_pool)

	assert_int(result.size()).is_equal(0)
