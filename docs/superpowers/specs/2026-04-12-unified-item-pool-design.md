# Unified Item Pool Design

**Date:** 2026-04-12  
**Status:** Approved

## Problem

The codebase maintains three separate hardcoded resource lists:

- `main.gd / _DEV_ALL_TOWERS` — dev mode sidebar towers
- `main.gd / _DEV_ALL_MODULES` — dev mode sidebar modules
- `reward_popup.gd / REWARD_POOL` — normal mode reward selection

Adding a new tower or module requires updating multiple lists. The lists have overlapping but diverging contents, leading to drift.

## Solution

Unify all items into a single registry (`item_pool.gd`) and encode pool membership as flags on each resource.

## Architecture

### 1. Flags on resource classes

Add to `TowerData.gd` and `Module.gd`:

```gdscript
## 是否出现在普通模式奖励池（三选一弹窗）
@export var in_normal_pool: bool = true
## 是否出现在开发者模式侧边栏
@export var in_dev_pool: bool = true
```

Default is `true` for both — new resources are visible everywhere unless explicitly excluded.

### 2. Single registry: `res://resources/item_pool.gd`

```gdscript
# item_pool.gd — 唯一资源注册处
# 新增资源时：在 ALL_ITEMS 加一行，在 .tres 中设好 flag，完毕。

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

static func normal_pool() -> Array:
    return ALL_ITEMS.filter(func(r): return r.in_normal_pool)

static func dev_towers() -> Array:
    return ALL_ITEMS.filter(func(r): return r is TowerData and r.in_dev_pool)

static func dev_modules() -> Array:
    return ALL_ITEMS.filter(func(r): return r is Module and r.in_dev_pool)
```

### 3. Consumer changes

| File | Before | After |
|------|--------|-------|
| `reward_popup.gd` | `const REWARD_POOL` + `REWARD_POOL.duplicate()` | `ItemPool.normal_pool()` |
| `main.gd` | `_DEV_ALL_TOWERS` const + loop | `ItemPool.dev_towers()` |
| `main.gd` | `_DEV_ALL_MODULES` const + loop | `ItemPool.dev_modules()` |

### 4. Removed config flags

`GameState.config_flags` entries removed:
- `enable_dev_mode_all_variants`
- `include_true_variants_in_dev`

The variant filtering logic in `main.gd` (lines ~304–314) is deleted. Visibility is now controlled entirely by `in_dev_pool` on the resource.

### 5. .tres flag values

All existing resources: `in_normal_pool = true`, `in_dev_pool = true` (both flags default to true, so no `.tres` file needs editing beyond the class change).

## Workflow for adding new items

1. Create the `.tres` resource file
2. Set `in_normal_pool` and `in_dev_pool` as desired in the Godot Editor
3. Add one `preload(...)` line to `ALL_ITEMS` in `item_pool.gd`

No other files need updating.

## Testing

- Existing reward pool tests remain valid (pool contents unchanged)
- Dev mode sidebar shows same items as before
- Add a unit test asserting `ItemPool.normal_pool()` and `ItemPool.dev_towers()` / `ItemPool.dev_modules()` return non-empty arrays of the correct types
