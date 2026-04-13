class_name ItemPool

## item_pool.gd — 全局资源池，所有炮塔/模块的唯一注册处。
## 新增资源时：在 ALL_ITEMS 加一行，在 .tres 中设好 flag，完毕。

const ALL_ITEMS: Array = [
	preload("res://resources/simple_emitter.tres"),
	preload("res://resources/simple_emitter_true.tres"),
	preload("res://resources/tower1010.tres"),
	preload("res://resources/tower1010_true.tres"),
	preload("res://resources/tower1100.tres"),
	preload("res://resources/tower1100_true.tres"),
	preload("res://resources/tower1110.tres"),
	preload("res://resources/tower1110_true.tres"),
	preload("res://resources/tower1111.tres"),
	preload("res://resources/tower1111_true.tres"),
	preload("res://resources/not_tower.tres"),
	preload("res://resources/not_tower_true.tres"),
	preload("res://resources/module_data/accelerator.tres"),
	preload("res://resources/module_data/multiplier.tres"),
	preload("res://resources/module_data/rate_boost.tres"),
	preload("res://resources/module_data/replenish1.tres"),
	preload("res://resources/module_data/replenish2.tres"),
	preload("res://resources/module_data/heavy_ammo.tres"),
	preload("res://resources/module_data/cd_on_hit_enemy.tres"),
	preload("res://resources/module_data/cd_on_hit_tower_self.tres"),
	preload("res://resources/module_data/cd_on_hit_tower_target.tres"),
	preload("res://resources/module_data/cd_on_receive_hit.tres"),
	preload("res://resources/module_data/speed_boost.tres"),
	preload("res://resources/module_data/flying.tres"),
	preload("res://resources/module_data/anti_air.tres"),
	preload("res://resources/module_data/hit_speed_boost.tres"),
	preload("res://resources/module_data/hit_enemy_replenish1.tres"),
	preload("res://resources/module_data/hit_enemy_replenish2.tres"),
	preload("res://resources/module_data/hit_enemy_speed_boost.tres"),
	preload("res://resources/module_data/receive_hit_replenish1.tres"),
	preload("res://resources/module_data/receive_hit_replenish2.tres"),
	preload("res://resources/module_data/receive_hit_speed_boost.tres"),
	preload("res://resources/module_data/deal_damage_cd_reduce.tres"),
	preload("res://resources/module_data/deal_damage_replenish1.tres"),
	preload("res://resources/module_data/deal_damage_speed_boost.tres"),
	preload("res://resources/module_data/chain_module.tres"),
	preload("res://resources/module_data/shadow_tower_module.tres"),
]

## 普通模式奖励池：三选一弹窗可选的全部条目。
static func normal_pool() -> Array:
	return ALL_ITEMS.filter(func(r): return (r is TowerData or r is Module) and r.in_normal_pool)

## 开发者模式侧边栏中显示的炮塔。
static func dev_towers() -> Array:
	return ALL_ITEMS.filter(func(r): return r is TowerData and r.in_dev_pool)

## 开发者模式侧边栏中显示的模块。
static func dev_modules() -> Array:
	return ALL_ITEMS.filter(func(r): return r is Module and r.in_dev_pool)
