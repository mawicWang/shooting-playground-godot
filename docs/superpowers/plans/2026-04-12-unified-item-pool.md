# Unified Item Pool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace three separate hardcoded resource lists with a single `ItemPool` registry and per-resource pool flags, so adding a new tower or module only requires one edit in one place.

**Architecture:** Add `in_normal_pool` / `in_dev_pool` export booleans to `TowerData` and `Module`. Create `item_pool.gd` (class_name `ItemPool`) as the single preload list with three static filter methods. Both `reward_popup.gd` and `main.gd` query `ItemPool` instead of their own constants.

**Tech Stack:** GDScript 4.4, GdUnit4 test suite

**Spec:** `docs/superpowers/specs/2026-04-12-unified-item-pool-design.md`

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Modify | `resources/TowerData.gd` | Add `in_normal_pool`, `in_dev_pool` fields |
| Modify | `entities/modules/module.gd` | Add `in_normal_pool`, `in_dev_pool` fields |
| Create | `resources/item_pool.gd` | Unified registry — `ALL_ITEMS` + filter methods |
| Create | `tests/gdunit/ItemPoolTest.gd` | GdUnit4 tests for `ItemPool` |
| Modify | `ui/popups/reward_popup.gd` | Replace `REWARD_POOL` const with `ItemPool.normal_pool()` |
| Modify | `main.gd` | Replace `_DEV_ALL_TOWERS`/`_DEV_ALL_MODULES` + remove variant-filter config logic |
| Modify | `autoload/GameState.gd` | Remove unused `enable_dev_mode_all_variants` / `include_true_variants_in_dev` flags |

---

## Task 1: Add pool flags to TowerData and Module

**Files:**
- Modify: `resources/TowerData.gd`
- Modify: `entities/modules/module.gd`

- [ ] **Step 1: Add flags to TowerData**

Open `resources/TowerData.gd`. After the existing `@export var scene: PackedScene` line, append:

```gdscript
## 是否出现在普通模式奖励池（三选一弹窗）
@export var in_normal_pool: bool = true
## 是否出现在开发者模式侧边栏
@export var in_dev_pool: bool = true
```

Final file (`resources/TowerData.gd`):

```gdscript
class_name TowerData extends Resource

enum Variant {
	NEGATIVE = 0,
	POSITIVE = 1,
}

@export var tower_name: String = ""
@export var sprite: Texture2D
@export var icon: Texture2D
@export var firing_rate: float = 1.0
@export var barrel_directions: PackedVector2Array = PackedVector2Array([Vector2(0, -1)])
## 初始弹药数量。-1 表示无限；0 或正整数为有限弹药。
@export var initial_ammo: int = 3
## 炮塔变体标识。子弹 bullet_type 必须与此匹配才能触发交互。
@export var variant: Variant = Variant.NEGATIVE
## 自定义炮塔场景。null 时使用默认 tower.tscn。
@export var scene: PackedScene
## 是否出现在普通模式奖励池（三选一弹窗）
@export var in_normal_pool: bool = true
## 是否出现在开发者模式侧边栏
@export var in_dev_pool: bool = true
```

- [ ] **Step 2: Add flags to Module**

Open `entities/modules/module.gd`. After `@export var slot_color: Color = Color(0.5, 0.5, 0.5)` (line 9), insert:

```gdscript
## 是否出现在普通模式奖励池（三选一弹窗）
@export var in_normal_pool: bool = true
## 是否出现在开发者模式侧边栏
@export var in_dev_pool: bool = true
```

The top of the file should now look like:

```gdscript
class_name Module extends Resource

enum Category { COMPUTATIONAL, LOGICAL, SPECIAL }

@export var module_name: String = ""
@export var category: Category = Category.COMPUTATIONAL
@export var description: String = ""
@export var icon: Texture2D
@export var slot_color: Color = Color(0.5, 0.5, 0.5)
## 是否出现在普通模式奖励池（三选一弹窗）
@export var in_normal_pool: bool = true
## 是否出现在开发者模式侧边栏
@export var in_dev_pool: bool = true
```

- [ ] **Step 3: Commit**

```bash
git add resources/TowerData.gd entities/modules/module.gd
git commit -m "feat: add in_normal_pool and in_dev_pool flags to TowerData and Module"
```

---

## Task 2: Create ItemPool registry

**Files:**
- Create: `resources/item_pool.gd`

- [ ] **Step 1: Create the file**

Create `resources/item_pool.gd` with this exact content:

```gdscript
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
	return ALL_ITEMS.filter(func(r): return r.in_normal_pool)

## 开发者模式侧边栏中显示的炮塔。
static func dev_towers() -> Array:
	return ALL_ITEMS.filter(func(r): return r is TowerData and r.in_dev_pool)

## 开发者模式侧边栏中显示的模块。
static func dev_modules() -> Array:
	return ALL_ITEMS.filter(func(r): return r is Module and r.in_dev_pool)
```

- [ ] **Step 2: Commit**

```bash
git add resources/item_pool.gd
git commit -m "feat: add ItemPool unified resource registry"
```

---

## Task 3: Write and run ItemPool tests

**Files:**
- Create: `tests/gdunit/ItemPoolTest.gd`

- [ ] **Step 1: Create the test file**

Create `tests/gdunit/ItemPoolTest.gd`:

```gdscript
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
	# Create a temporary TowerData with in_normal_pool = false to verify filtering
	var td := TowerData.new()
	td.in_normal_pool = false
	td.in_dev_pool = true

	# The filter logic: only items where in_normal_pool == true
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
```

- [ ] **Step 2: Run the tests in Godot Editor**

In the Godot Editor: GdUnit4 panel → right-click `tests/gdunit/ItemPoolTest.gd` → Run Tests.

Expected: all 8 tests pass.

- [ ] **Step 3: Commit**

```bash
git add tests/gdunit/ItemPoolTest.gd
git commit -m "test: add ItemPool unit tests"
```

---

## Task 4: Update reward_popup.gd

**Files:**
- Modify: `ui/popups/reward_popup.gd`

- [ ] **Step 1: Replace REWARD_POOL with ItemPool.normal_pool()**

In `ui/popups/reward_popup.gd`:

Delete lines 8–43 (the entire `const REWARD_POOL: Array = [...]` block).

Then in `show_rewards()` (was line 91), change:

```gdscript
var pool := REWARD_POOL.duplicate()
```

to:

```gdscript
var pool := ItemPool.normal_pool()
```

The full updated `show_rewards()` function:

```gdscript
func show_rewards():
	var pool := ItemPool.normal_pool()
	var choices: Array = []
	for i in min(3, pool.size()):
		var total_weight := 0
		for item in pool:
			total_weight += _get_weight(item)
		var roll := randi() % total_weight
		var cumulative := 0
		for j in pool.size():
			cumulative += _get_weight(pool[j])
			if roll < cumulative:
				choices.append(pool[j])
				pool.remove_at(j)
				break

	for child in _cards_row.get_children():
		child.free()

	for reward in choices:
		_cards_row.add_child(_make_card(reward))

	visible = true
	get_tree().paused = true
```

- [ ] **Step 2: Run tests in Godot Editor**

Run the full GdUnit4 suite (GdUnit4 → Run All Tests). All existing tests must still pass.

- [ ] **Step 3: Commit**

```bash
git add ui/popups/reward_popup.gd
git commit -m "refactor: reward_popup uses ItemPool.normal_pool() instead of hardcoded REWARD_POOL"
```

---

## Task 5: Update main.gd

**Files:**
- Modify: `main.gd`

- [ ] **Step 1: Remove _DEV_ALL_TOWERS and _DEV_ALL_MODULES constants**

Delete lines 19–60 in `main.gd` (the two `const` blocks):

```gdscript
# 开发者模式用：全量炮塔 & 模块资源
const _DEV_ALL_TOWERS := [
    ...
]
const _DEV_ALL_MODULES := [
    ...
]
```

Remove both constants entirely.

- [ ] **Step 2: Replace the dev panel tower loop**

Find the `_setup_dev_panel` function. The current code (around line 300–343) has:

```gdscript
# 根据配置标志过滤炮塔
var show_all_variants = GameState.get_config_flag("enable_dev_mode_all_variants")
var include_true_variants = GameState.get_config_flag("include_true_variants_in_dev")

for tower_data in _DEV_ALL_TOWERS:
    # 如果配置要求不显示所有变体，只显示NEGATIVE变体
    if not show_all_variants and tower_data.variant == TowerData.Variant.POSITIVE:
        continue

    # 如果配置要求不包含POSITIVE变体，跳过POSITIVE变体
    if not include_true_variants and tower_data.variant == TowerData.Variant.POSITIVE:
        continue
    
    var icon := TextureRect.new()
    ...
```

Replace those lines with:

```gdscript
for tower_data in ItemPool.dev_towers():
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 110)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.set_script(TowerIconScript)
	icon.tower_data = tower_data
	icon.entity_id = -1  # 每次拖拽动态生成
	hbox.add_child(icon)
```

- [ ] **Step 3: Replace the dev panel module loop**

Find the module loop:

```gdscript
for mod_data in _DEV_ALL_MODULES:
```

Replace with:

```gdscript
for mod_data in ItemPool.dev_modules():
```

The rest of the loop body is unchanged.

- [ ] **Step 4: Run tests in Godot Editor**

Run the full GdUnit4 suite. All tests must pass.

- [ ] **Step 5: Commit**

```bash
git add main.gd
git commit -m "refactor: main.gd uses ItemPool.dev_towers/dev_modules instead of hardcoded constants"
```

---

## Task 6: Clean up GameState config flags

**Files:**
- Modify: `autoload/GameState.gd`

- [ ] **Step 1: Remove unused config flags**

In `autoload/GameState.gd`, find the `config_flags` dict (around line 112):

```gdscript
var config_flags := {
    # 是否在开发者模式中显示所有炮塔变体
    "enable_dev_mode_all_variants": true,
    # 是否在开发者模式中包含TRUE变体
    "include_true_variants_in_dev": true,
}
```

Delete both entries. The dict becomes empty. If no other flags remain, delete the dict, `set_config_flag`, and `get_config_flag` functions entirely.

Check for any remaining callers:

```bash
grep -rn "get_config_flag\|set_config_flag\|config_flags" --include="*.gd" .
```

If the grep returns no results other than `GameState.gd` itself, delete the three config-flag methods (`config_flags`, `set_config_flag`, `get_config_flag`) from `GameState.gd`.

If other callers exist, only remove the two specific keys and leave the infrastructure in place.

- [ ] **Step 2: Run tests in Godot Editor**

Run the full GdUnit4 suite. All tests must pass.

- [ ] **Step 3: Commit**

```bash
git add autoload/GameState.gd
git commit -m "refactor: remove variant config flags superseded by ItemPool in_dev_pool"
```

---

## Task 7: Update documentation

**Files:**
- Modify: `docs/DOC_INDEX.md`
- Create or modify the relevant doc in `docs/content/`

- [ ] **Step 1: Check if a reward pool doc exists**

```bash
grep -ri "reward\|item.pool\|pool" docs/DOC_INDEX.md
```

- [ ] **Step 2: Create or update the doc**

If no reward/pool doc exists, create `docs/content/item-pool.md`:

```markdown
# Item Pool

All towers and modules available in the game are registered in `resources/item_pool.gd` (`class_name ItemPool`).

## Adding a new tower or module

1. Create the `.tres` resource file.
2. Set `in_normal_pool` and `in_dev_pool` in the Godot Editor Inspector.
3. Add one `preload(...)` line to `ALL_ITEMS` in `resources/item_pool.gd`.

No other files need updating.

## Pool flags

| Flag | Controls |
|------|----------|
| `in_normal_pool` | Appears in the wave-end reward popup (3-choice selection) |
| `in_dev_pool` | Appears in the developer mode sidebar |

Both flags default to `true`, so new resources are visible in both modes unless explicitly excluded.

## API

| Method | Returns |
|--------|---------|
| `ItemPool.normal_pool()` | All items with `in_normal_pool = true` |
| `ItemPool.dev_towers()` | All `TowerData` with `in_dev_pool = true` |
| `ItemPool.dev_modules()` | All `Module` with `in_dev_pool = true` |
```

- [ ] **Step 3: Update DOC_INDEX.md**

Add an entry for the new doc:

```markdown
- [Item Pool](content/item-pool.md) — unified tower/module registry; how to add new items
```

- [ ] **Step 4: Commit**

```bash
git add docs/content/item-pool.md docs/DOC_INDEX.md
git commit -m "docs: document ItemPool registry and new-item workflow"
```
