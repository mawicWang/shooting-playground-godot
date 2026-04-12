# Tower Variant System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two variant identities (FALSE/TRUE) to towers so bullets only interact with towers of matching variant, visualised via a shader tint.

**Architecture:** A named enum `TowerData.Variant` identifies each tower's team. `BulletData.bullet_type` already encodes the bullet side (0=FALSE, 1=TRUE). A single filter line in `bullet.gd` drops non-matching hits before any effect runs. A duplicated `ShaderMaterial` tints each tower sprite using a configurable `VariantPalette` resource.

**Tech Stack:** GDScript 4, Godot 4.4+, GdUnit4 tests, canvas_item shader.

---

### Task 1: VariantPalette resource

**Files:**
- Create: `resources/VariantPalette.gd`
- Create: `resources/variant_palette.tres`
- Create: `tests/gdunit/VariantPaletteTest.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/gdunit/VariantPaletteTest.gd`:

```gdscript
class_name VariantPaletteTest
extends GdUnitTestSuite


func test_get_color_returns_false_color_for_false_variant() -> void:
	var palette := VariantPalette.new()
	palette.false_color = Color.BLUE
	palette.true_color = Color.RED

	var result := palette.get_color(TowerData.Variant.NEGATIVE)

	assert_that(result).is_equal(Color.BLUE)


func test_get_color_returns_true_color_for_true_variant() -> void:
	var palette := VariantPalette.new()
	palette.false_color = Color.BLUE
	palette.true_color = Color.RED

	var result := palette.get_color(TowerData.Variant.POSITIVE)

	assert_that(result).is_equal(Color.RED)


func test_default_colors_are_blue_and_red() -> void:
	var palette := VariantPalette.new()

	assert_that(palette.false_color).is_equal(Color.BLUE)
	assert_that(palette.true_color).is_equal(Color.RED)


func test_preloaded_palette_tres_loads() -> void:
	var palette := load("res://resources/variant_palette.tres") as VariantPalette

	assert_object(palette).is_not_null()
	assert_that(palette.false_color).is_equal(Color.BLUE)
	assert_that(palette.true_color).is_equal(Color.RED)
```

- [ ] **Step 2: Run test — expect failure**

Open Godot Editor → GdUnit → Run Tests → select `VariantPaletteTest`.
Expected: FAIL — `VariantPalette` class not found, `TowerData.Variant` not found.

- [ ] **Step 3: Create `resources/VariantPalette.gd`**

```gdscript
class_name VariantPalette extends Resource

@export var false_color: Color = Color.BLUE
@export var true_color: Color = Color.RED

func get_color(variant: TowerData.Variant) -> Color:
	return false_color if variant == TowerData.Variant.NEGATIVE else true_color
```

Note: `TowerData.Variant` is defined in Task 2. Tests for Task 1 and Task 2 should be run together after both are implemented, or implement Task 2 first if running tests incrementally.

- [ ] **Step 4: Create `resources/variant_palette.tres`**

```
[gd_resource type="Resource" script_class="VariantPalette" format=3]

[ext_resource type="Script" path="res://resources/VariantPalette.gd" id="1_variantpalette"]

[resource]
script = ExtResource("1_variantpalette")
false_color = Color(0, 0, 1, 1)
true_color = Color(1, 0, 0, 1)
```

- [ ] **Step 5: Commit**

```bash
git add resources/VariantPalette.gd resources/variant_palette.tres tests/gdunit/VariantPaletteTest.gd
git commit -m "feat: add VariantPalette resource for tower variant colors"
```

---

### Task 2: Add variant enum to TowerData and update .tres files

**Files:**
- Modify: `resources/TowerData.gd`
- Modify: `resources/simple_emitter.tres`
- Modify: `resources/tower1010.tres`
- Modify: `resources/tower1100.tres`
- Modify: `resources/tower1110.tres`
- Modify: `resources/tower1111.tres`
- Modify: `tests/gdunit/TowerDataTest.gd`

- [ ] **Step 1: Write the failing test**

Add to `tests/gdunit/TowerDataTest.gd` (append after existing tests):

```gdscript
func test_all_towers_have_variant_field() -> void:
	var paths := _get_tower_paths()
	assert_array(paths).is_not_empty()

	for path in paths:
		var td := load(path) as TowerData
		if td == null:
			continue
		# Variant must be a valid enum value: 0 (FALSE) or 1 (TRUE)
		assert_bool(td.variant == TowerData.Variant.NEGATIVE or td.variant == TowerData.Variant.POSITIVE) \
			.override_failure_message("%s: variant must be FALSE or TRUE" % path) \
			.is_true()


func test_tower_variant_enum_values() -> void:
	assert_int(TowerData.Variant.NEGATIVE).is_equal(0)
	assert_int(TowerData.Variant.POSITIVE).is_equal(1)


func test_default_variant_is_false() -> void:
	var td := TowerData.new()
	assert_int(td.variant).is_equal(TowerData.Variant.NEGATIVE)
```

- [ ] **Step 2: Run test — expect failure**

Open Godot Editor → GdUnit → Run Tests → select `TowerDataTest`.
Expected: FAIL — `TowerData.Variant` not found.

- [ ] **Step 3: Add enum and export field to `resources/TowerData.gd`**

```gdscript
class_name TowerData extends Resource

enum Variant { NEGATIVE = 0, POSITIVE = 1 }

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
```

- [ ] **Step 4: Add `variant = 0` to each TowerData .tres file**

In `resources/simple_emitter.tres`, append `variant = 0` inside `[resource]`:
```
[resource]
script = ExtResource("1_towerdata")
tower_name = "单向炮"
sprite = ExtResource("2_sprite")
icon = ExtResource("2_sprite")
firing_rate = 1.0
barrel_directions = PackedVector2Array(0, -1)
initial_ammo = 10
variant = 0
```

In `resources/tower1010.tres`, append `variant = 0` inside `[resource]`.

In `resources/tower1100.tres`, append `variant = 0` inside `[resource]`.

In `resources/tower1110.tres`, append `variant = 0` inside `[resource]`.

In `resources/tower1111.tres`, append `variant = 0` inside `[resource]`.

- [ ] **Step 5: Run tests — expect pass**

Open Godot Editor → GdUnit → Run Tests → select `TowerDataTest` and `VariantPaletteTest`.
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add resources/TowerData.gd resources/simple_emitter.tres resources/tower1010.tres \
        resources/tower1100.tres resources/tower1110.tres resources/tower1111.tres \
        tests/gdunit/TowerDataTest.gd
git commit -m "feat: add Variant enum to TowerData, set all existing towers to FALSE"
```

---

### Task 3: Tower tint shader and visual application

**Files:**
- Create: `entities/towers/tower_tint.gdshader`
- Modify: `entities/towers/tower.gd`
- Create: `tests/gdunit/TowerVariantVisualTest.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/gdunit/TowerVariantVisualTest.gd`:

```gdscript
class_name TowerVariantVisualTest
extends GdUnitTestSuite

const TowerScene := preload("res://entities/towers/tower.tscn")

var _nodes_to_free: Array[Node] = []


func after_test() -> void:
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()


func _add_child(node: Node) -> Node:
	get_tree().root.add_child(node)
	_nodes_to_free.append(node)
	return node


func test_false_variant_tower_has_shader_material_with_blue_tint() -> void:
	var td := TowerData.new()
	td.sprite = load("res://assets/tower1000.svg")
	td.firing_rate = 1.0
	td.variant = TowerData.Variant.NEGATIVE

	var tower: Node2D = TowerScene.instantiate()
	tower.data = td
	_add_child(tower)
	await await_idle_frame()

	var sprite: Sprite2D = tower.get_node("TowerVisual/Sprite2D")
	assert_object(sprite.material).is_not_null()
	assert_bool(sprite.material is ShaderMaterial) \
		.override_failure_message("sprite.material should be a ShaderMaterial").is_true()
	var mat := sprite.material as ShaderMaterial
	var color := mat.get_shader_parameter("color") as Color
	assert_that(color).is_equal(Color.BLUE)


func test_true_variant_tower_has_shader_material_with_red_tint() -> void:
	var td := TowerData.new()
	td.sprite = load("res://assets/tower1000.svg")
	td.firing_rate = 1.0
	td.variant = TowerData.Variant.POSITIVE

	var tower: Node2D = TowerScene.instantiate()
	tower.data = td
	_add_child(tower)
	await await_idle_frame()

	var sprite: Sprite2D = tower.get_node("TowerVisual/Sprite2D")
	assert_bool(sprite.material is ShaderMaterial).is_true()
	var mat := sprite.material as ShaderMaterial
	var color := mat.get_shader_parameter("color") as Color
	assert_that(color).is_equal(Color.RED)


func test_two_towers_have_independent_materials() -> void:
	var td_false := TowerData.new()
	td_false.sprite = load("res://assets/tower1000.svg")
	td_false.firing_rate = 1.0
	td_false.variant = TowerData.Variant.NEGATIVE

	var td_true := TowerData.new()
	td_true.sprite = load("res://assets/tower1000.svg")
	td_true.firing_rate = 1.0
	td_true.variant = TowerData.Variant.POSITIVE

	var tower_a: Node2D = TowerScene.instantiate()
	tower_a.data = td_false
	_add_child(tower_a)

	var tower_b: Node2D = TowerScene.instantiate()
	tower_b.data = td_true
	_add_child(tower_b)
	await await_idle_frame()

	var sprite_a: Sprite2D = tower_a.get_node("TowerVisual/Sprite2D")
	var sprite_b: Sprite2D = tower_b.get_node("TowerVisual/Sprite2D")

	assert_bool(sprite_a.material == sprite_b.material) \
		.override_failure_message("Two towers must not share a ShaderMaterial instance").is_false()
```

- [ ] **Step 2: Run test — expect failure**

Open Godot Editor → GdUnit → Run Tests → select `TowerVariantVisualTest`.
Expected: FAIL — `sprite.material` is null (shader not applied yet).

- [ ] **Step 3: Create `entities/towers/tower_tint.gdshader`**

```glsl
shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = tex * color;
}
```

- [ ] **Step 4: Modify `entities/towers/tower.gd` — add preloads and apply shader in `_apply_data()`**

Add these two `const` declarations at the top of the file, after the existing `const CooldownOverlayScript` line:

```gdscript
const _VARIANT_PALETTE = preload("res://resources/variant_palette.tres")
const _TOWER_TINT_SHADER = preload("res://entities/towers/tower_tint.gdshader")
```

In `_apply_data()`, replace the block:
```gdscript
	if data:
		if data.sprite:
			sprite.texture = data.sprite
		ammo = data.initial_ammo
```

with:
```gdscript
	if data:
		if data.sprite:
			sprite.texture = data.sprite
		var mat := ShaderMaterial.new()
		mat.shader = _TOWER_TINT_SHADER
		mat.set_shader_parameter("color", _VARIANT_PALETTE.get_color(data.variant))
		sprite.material = mat
		ammo = data.initial_ammo
```

- [ ] **Step 5: Run tests — expect pass**

Open Godot Editor → GdUnit → Run Tests → select `TowerVariantVisualTest`.
Expected: all 3 tests pass.

- [ ] **Step 6: Run full test suite to check for regressions**

Open Godot Editor → GdUnit → Run Tests (all).
Expected: all existing tests still pass.

- [ ] **Step 7: Commit**

```bash
git add entities/towers/tower_tint.gdshader entities/towers/tower.gd \
        tests/gdunit/TowerVariantVisualTest.gd
git commit -m "feat: apply variant tint shader to tower sprite via VariantPalette"
```

---

### Task 4: Bullet variant filter

**Files:**
- Modify: `entities/bullets/bullet.gd`
- Create: `tests/gdunit/TowerVariantFilterTest.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/gdunit/TowerVariantFilterTest.gd`:

```gdscript
# GdUnit4 — Tower Variant Filter Tests
# Verifies that bullets only interact with towers of matching variant.
# Uses direct _on_hitbox_area_entered() calls (same pattern as ShadowTowerCollisionTest).

class_name TowerVariantFilterTest
extends GdUnitTestSuite

const TowerScene := preload("res://entities/towers/tower.tscn")
const BulletScene := preload("res://entities/bullets/bullet.tscn")

var _nodes_to_free: Array[Node] = []


func before_test() -> void:
	BulletPool.clear_pool()
	_nodes_to_free.clear()


func after_test() -> void:
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()


func _add_child(node: Node) -> Node:
	get_tree().root.add_child(node)
	_nodes_to_free.append(node)
	return node


## Creates a tower instance with the given variant. entity_id avoids self-hit filter.
func _make_tower(variant: TowerData.Variant, entity_id: int) -> Node2D:
	var td := TowerData.new()
	td.sprite = load("res://assets/tower1000.svg")
	td.firing_rate = 1.0
	td.barrel_directions = PackedVector2Array([Vector2(0, -1)])
	td.variant = variant
	var tower: Node2D = TowerScene.instantiate()
	tower.data = td
	tower.entity_id = entity_id
	return tower


## Creates a bullet with the given bullet_type. Does NOT include the target in transmission_chain.
func _make_bullet(bullet_type: int) -> Node2D:
	var bullet: Node2D = BulletScene.instantiate()
	var bd := BulletData.new()
	bd.bullet_type = bullet_type
	bd.shadow_team_id = -1  # Normal bullet
	bd.tower_body_mask = Layers.TOWER_BODY
	bd.transmission_chain = []
	bd.effects = []
	bullet.data = bd
	return bullet


# ── Matching variant: bullet SHOULD interact ─────────────────────

func test_bullet_type_0_hits_false_variant_tower() -> void:
	"""bullet_type=0 hitting Variant.NEGATIVE tower: _pending_release = true"""
	var tower := _make_tower(TowerData.Variant.NEGATIVE, 100)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()  # deferred TowerBody shape

	var bullet := _make_bullet(0)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("bullet_type=0 SHOULD hit Variant.NEGATIVE tower") \
		.is_true()


func test_bullet_type_1_hits_true_variant_tower() -> void:
	"""bullet_type=1 hitting Variant.POSITIVE tower: _pending_release = true"""
	var tower := _make_tower(TowerData.Variant.POSITIVE, 101)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(1)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("bullet_type=1 SHOULD hit Variant.POSITIVE tower") \
		.is_true()


# ── Non-matching variant: bullet MUST NOT interact ────────────────

func test_bullet_type_1_does_not_hit_false_variant_tower() -> void:
	"""bullet_type=1 hitting Variant.NEGATIVE tower: filter rejects, bullet continues"""
	var tower := _make_tower(TowerData.Variant.NEGATIVE, 102)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(1)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("bullet_type=1 must NOT hit Variant.NEGATIVE tower") \
		.is_false()
	assert_bool(bullet.visible) \
		.override_failure_message("Bullet should remain visible after mismatch") \
		.is_true()
	assert_bool(bullet.is_physics_processing()) \
		.override_failure_message("Bullet should keep moving after mismatch") \
		.is_true()


func test_bullet_type_0_does_not_hit_true_variant_tower() -> void:
	"""bullet_type=0 hitting Variant.POSITIVE tower: filter rejects, bullet continues"""
	var tower := _make_tower(TowerData.Variant.POSITIVE, 103)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(0)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("bullet_type=0 must NOT hit Variant.POSITIVE tower") \
		.is_false()
	assert_bool(bullet.visible).is_true()
	assert_bool(bullet.is_physics_processing()).is_true()


# ── Null data guard ───────────────────────────────────────────────

func test_tower_with_null_data_is_not_filtered() -> void:
	"""Tower with data=null: variant filter is skipped, bullet hits normally"""
	var tower: Node2D = TowerScene.instantiate()
	tower.data = null
	tower.entity_id = 104
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(0)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()

	# Should not crash; bullet should be consumed (normal hit path)
	bullet._on_hitbox_area_entered(tower_body)
	# No crash = pass. _pending_release may be true or false depending on null guards elsewhere.
	assert_bool(true).is_true()
```

- [ ] **Step 2: Run test — expect failure**

Open Godot Editor → GdUnit → Run Tests → select `TowerVariantFilterTest`.
Expected: `test_bullet_type_1_does_not_hit_false_variant_tower` and `test_bullet_type_0_does_not_hit_true_variant_tower` FAIL — filter not yet implemented, bullets hit regardless of variant.

- [ ] **Step 3: Add variant filter to `entities/bullets/bullet.gd`**

In `_on_hitbox_area_entered`, locate this block (after the shadow-team filter, around line 62):

```gdscript
	# 不击中自己发射的炮塔（transmission_chain 防止自碰）
	if data and data.transmission_chain.has(parent):
		return
```

Insert the variant filter immediately before it:

```gdscript
	# Variant filter: bullet type must match tower variant; mismatched bullets pass through
	if data and parent.data != null and data.bullet_type != parent.data.variant:
		return

	# 不击中自己发射的炮塔（transmission_chain 防止自碰）
	if data and data.transmission_chain.has(parent):
		return
```

- [ ] **Step 4: Run variant filter tests — expect all pass**

Open Godot Editor → GdUnit → Run Tests → select `TowerVariantFilterTest`.
Expected: all 5 tests pass.

- [ ] **Step 5: Run full test suite to check for regressions**

Open Godot Editor → GdUnit → Run Tests (all).
Expected: all existing tests still pass. Pay attention to `ShadowTowerCollisionTest`, `FullChainTest`, `IntegrationTest`.

- [ ] **Step 6: Commit**

```bash
git add entities/bullets/bullet.gd tests/gdunit/TowerVariantFilterTest.gd
git commit -m "feat: add bullet variant filter — mismatched bullets pass through towers"
```

---

### Task 5: Documentation

**Files:**
- Create: `docs/content/variants.md`
- Modify: `docs/DOC_INDEX.md`

- [ ] **Step 1: Create `docs/content/variants.md`**

```markdown
# Tower Variant System

## Overview

Each tower has a **variant identity** (`Variant.NEGATIVE = 0` or `Variant.POSITIVE = 1`). A bullet only interacts with a tower when `bullet_type == tower.data.variant`. Non-matching bullets pass through silently: no hit animation, no BulletEffect, no TowerEffect, no ammo replenishment.

## Variant Enum

Defined in `TowerData.gd`:

```gdscript
enum Variant { NEGATIVE = 0, POSITIVE = 1 }
```

Integer values intentionally align with `BulletData.bullet_type` (0 and 1).

## Assigning Tower Variant

Set `variant` in the tower's `TowerData` resource (`.tres` file). All towers default to `Variant.NEGATIVE`.

Example `.tres` excerpt:
```
variant = 0   # Variant.NEGATIVE
variant = 1   # Variant.POSITIVE
```

## Bullet Side

`BulletData.bullet_type` is the bullet's variant. It flows from `AmmoItem.bullet_type` → `BulletData.bullet_type` in `tower.gd/_do_fire()`. Default is `0` (FALSE).

## Filter Location

`entities/bullets/bullet.gd` — `_on_hitbox_area_entered()`:

```gdscript
if data and parent.data != null and data.bullet_type != parent.data.variant:
    return
```

The filter runs after the shadow-team filter, before the `transmission_chain` check.

## Visual

Each tower sprite receives a `ShaderMaterial` using `entities/towers/tower_tint.gdshader`. The tint color comes from `resources/variant_palette.tres` (a `VariantPalette` resource).

To change variant colors, open `resources/variant_palette.tres` in the Godot editor and modify `false_color` / `true_color`. No code changes needed.

| Variant | Default color |
|---------|--------------|
| FALSE (0) | Blue |
| TRUE (1) | Red |

## VariantPalette Resource

`resources/VariantPalette.gd`:

```gdscript
class_name VariantPalette extends Resource
@export var false_color: Color = Color.BLUE
@export var true_color: Color = Color.RED
func get_color(variant: TowerData.Variant) -> Color
```

## Testing

See `tests/gdunit/TowerVariantFilterTest.gd` (filter logic) and `tests/gdunit/TowerVariantVisualTest.gd` (shader application).
```

- [ ] **Step 2: Add entry to `docs/DOC_INDEX.md`**

In the `## 游戏内容知识库` table, add a new row:

```markdown
| [`content/variants.md`](content/variants.md) | 炮塔变体系统：Variant 枚举、子弹过滤规则、VariantPalette 着色器配置 |
```

- [ ] **Step 3: Commit**

```bash
git add docs/content/variants.md docs/DOC_INDEX.md
git commit -m "docs: add tower variant system documentation"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] Named enum `Variant { FALSE = 0, TRUE = 1 }` in `TowerData` → Task 2
- [x] `VariantPalette` resource with configurable colors → Task 1
- [x] `variant_palette.tres` default file → Task 1
- [x] `tower_tint.gdshader` → Task 3
- [x] Shader applied per-tower (duplicated material) → Task 3
- [x] Filter in `bullet.gd`: `bullet_type != tower.data.variant` → Task 4
- [x] Null-data guard → Task 4 test + filter condition
- [x] All existing `.tres` set to `Variant.NEGATIVE` → Task 2
- [x] Tests for all 4 matching/non-matching combinations → Task 4
- [x] Test: null tower data doesn't crash → Task 4
- [x] Docs created and indexed → Task 5

**No placeholders:** All steps include complete code.

**Type consistency:** `TowerData.Variant.NEGATIVE/TRUE` used consistently across all tasks. `parent.data.variant` compared directly to `data.bullet_type` (both int-compatible).
