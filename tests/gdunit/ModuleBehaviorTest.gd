# GdUnit4 — Module Trigger Behavior Tests
# 验证 LOGICAL 模块触发后的实际结果（弹药量、CD调用值、加速调用值）
# 知识库参考：docs/content/modules.md

class_name ModuleBehaviorTest
extends GdUnitTestSuite

const MODULE_DIR := "res://resources/module_data/"


## 辅助：从塔的 bullet_effects 中触发 on_hit_tower
func _trigger_bullet_hit_tower(source: MockTower, target: MockTower) -> void:
	var bd := BulletData.new()
	bd.transmission_chain = [source]
	for effect in source.bullet_effects:
		if effect.has_method("on_hit_tower"):
			effect.on_hit_tower(bd, target)


## 辅助：从塔的 bullet_effects 中触发 on_hit_enemy
func _trigger_bullet_hit_enemy(source: MockTower, enemy: Node) -> void:
	var bd := BulletData.new()
	bd.transmission_chain = [source]
	for effect in source.bullet_effects:
		if effect.has_method("on_hit_enemy"):
			effect.on_hit_enemy(bd, enemy)


## 辅助：从塔的 bullet_effects 中触发 on_killed_enemy
func _trigger_bullet_killed_enemy(source: MockTower, enemy: Node) -> void:
	var bd := BulletData.new()
	bd.transmission_chain = [source]
	for effect in source.bullet_effects:
		if effect.has_method("on_killed_enemy"):
			effect.on_killed_enemy(bd, enemy)


## 辅助：从塔的 tower_effects 中触发 on_receive_bullet_hit
func _trigger_receive_hit(tower: MockTower) -> void:
	var bd := BulletData.new()
	for effect in tower.tower_effects:
		if effect.has_method("on_receive_bullet_hit"):
			effect.on_receive_bullet_hit(bd, tower)


# ──────────────────────────────────────────────
# cd_on_hit_tower_self：子弹击中炮塔，来源塔自身 CD 减少
# ──────────────────────────────────────────────

func test_cd_on_hit_tower_self_reduces_source_cd() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_hit_tower_self.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	assert_array(source.bullet_effects).is_not_empty()

	_trigger_bullet_hit_tower(source, target)

	assert_array(source.reduce_cooldown_calls).has_size(1)
	assert_float(source.reduce_cooldown_calls[0]).is_equal(0.5)


func test_cd_on_hit_tower_self_does_not_affect_target() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_hit_tower_self.tres") as Module

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(target.reduce_cooldown_calls).is_empty()


# ──────────────────────────────────────────────
# cd_on_hit_tower_target：子弹击中炮塔，目标塔 CD 减少
# ──────────────────────────────────────────────

func test_cd_on_hit_tower_target_reduces_target_cd() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_hit_tower_target.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(target.reduce_cooldown_calls).has_size(1)
	assert_float(target.reduce_cooldown_calls[0]).is_equal(0.5)


func test_cd_on_hit_tower_target_does_not_affect_source() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_hit_tower_target.tres") as Module

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(source.reduce_cooldown_calls).is_empty()


# ──────────────────────────────────────────────
# cd_on_receive_hit：被子弹击中，自身 CD 减少
# ──────────────────────────────────────────────

func test_cd_on_receive_hit_reduces_self_cd_by_half() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_receive_hit.tres") as Module
	assert_object(module).is_not_null()

	tower.install_module(module)
	assert_array(tower.tower_effects).is_not_empty()

	_trigger_receive_hit(tower)

	assert_array(tower.reduce_cooldown_calls).has_size(1)
	assert_float(tower.reduce_cooldown_calls[0]).is_equal(0.5)


# ──────────────────────────────────────────────
# replenish2：补充目标塔弹药 +2
# ──────────────────────────────────────────────

func test_replenish2_adds_two_ammo_to_target() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	target.ammo = 5
	var module := load(MODULE_DIR + "replenish2.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_int(target.ammo).is_equal(7)
	assert_int(target.ammo_added).is_equal(2)


func test_replenish2_does_not_add_to_infinite_ammo_tower() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	target.ammo = -1  # infinite
	var module := load(MODULE_DIR + "replenish2.tres") as Module

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_int(target.ammo).is_equal(-1)
	assert_int(target.ammo_added).is_equal(0)


# ──────────────────────────────────────────────
# speed_boost (击杀加速)：击杀敌人时，来源塔触发加速 1s
# ──────────────────────────────────────────────

func test_speed_boost_calls_apply_speed_boost_on_kill() -> void:
	var source := auto_free(MockTower.new())
	var enemy := auto_free(Node.new())
	var module := load(MODULE_DIR + "speed_boost.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	assert_array(source.bullet_effects).is_not_empty()

	_trigger_bullet_killed_enemy(source, enemy)

	assert_array(source.speed_boost_calls).has_size(1)
	assert_float(source.speed_boost_calls[0]).is_equal(1.0)


# ──────────────────────────────────────────────
# hit_speed_boost (击中加速)：击中炮塔时，目标塔触发加速 1s
# ──────────────────────────────────────────────

func test_hit_speed_boost_calls_apply_speed_boost_on_target() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "hit_speed_boost.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(target.speed_boost_calls).has_size(1)
	assert_float(target.speed_boost_calls[0]).is_equal(1.0)


func test_hit_speed_boost_does_not_affect_source() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "hit_speed_boost.tres") as Module

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(source.speed_boost_calls).is_empty()
