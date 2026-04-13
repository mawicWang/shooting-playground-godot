# Tower Variant NEUTRAL + Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a NEUTRAL (no-filter) variant tier, rename _true→_positive and create _negative variants, unify bullet_type naming with TowerData.Variant enum, and apply shader tinting to dev-sidebar icons.

**Architecture:** Shift `TowerData.Variant` enum values (NEUTRAL=0, NEGATIVE=1, POSITIVE=2) so base .tres files (`variant=0`) automatically become NEUTRAL. Rename _true .tres files to _positive, update their `variant` value from 1→2, and create new _negative .tres files with `variant=1`. Change `bullet_type` in BulletData/AmmoItem from `int` to `TowerData.Variant`. Update filter in bullet.gd to skip NEUTRAL towers. Apply variant shader tint to tower_icon.gd.

**Tech Stack:** GDScript 4.4, GdUnit4 tests, .tres resource files

---

## File Map

| File | Action | Reason |
|------|--------|--------|
| `resources/TowerData.gd` | Modify | Add NEUTRAL=0 to enum, shift NEGATIVE→1, POSITIVE→2; default variant=NEUTRAL |
| `resources/VariantPalette.gd` | Modify | Add neutral_color field; return white for NEUTRAL |
| `resources/variant_palette.tres` | Modify | Add neutral_color = white |
| `resources/BulletData.gd` | Modify | bullet_type: int → TowerData.Variant (default NEGATIVE) |
| `entities/bullets/ammo_item.gd` | Modify | bullet_type: int → TowerData.Variant (default NEGATIVE) |
| `entities/bullets/bullet.gd` | Modify | Filter: skip NEUTRAL, compare bullet_type to tower variant |
| `entities/towers/tower.gd` | Modify | Color logic: compare to TowerData.Variant enum; override sentinel -1 |
| `entities/towers/not_tower.gd` | Modify | Flip: 1-type → 3-type (since NEGATIVE=1, POSITIVE=2) |
| `resources/*_true.tres` (6 files) | Rename+edit | → *_positive.tres; name "(TRUE)"→"(POSITIVE)"; variant 1→2 |
| `resources/*_negative.tres` (6 new) | Create | New negative variant .tres for each tower type |
| `resources/item_pool.gd` | Modify | Update preload paths; add 6 new _negative entries |
| `ui/deployment/tower_icon.gd` | Modify | Apply variant shader tint in _ready() |
| `tests/gdunit/TowerVariantFilterTest.gd` | Modify | Use Variant enum values; add NEUTRAL tests |
| `tests/gdunit/TowerVariantVisualTest.gd` | Modify | Add NEUTRAL visual test; update existing tests |
| `tests/gdunit/VariantPaletteTest.gd` | Modify | Add NEUTRAL→white test |

---

### Task 1: Shift TowerData.Variant enum

**Files:**
- Modify: `resources/TowerData.gd`

- [ ] **Step 1: Update the enum and default**

Replace the entire `TowerData.gd`:

```gdscript
class_name TowerData extends Resource

enum Variant {
	NEUTRAL  = 0,  ## 基础，不过滤，无染色
	NEGATIVE = 1,  ## 蓝色，忽略 POSITIVE 子弹
	POSITIVE = 2,  ## 红色，忽略 NEGATIVE 子弹
}

@export var tower_name: String = ""
@export var sprite: Texture2D
@export var icon: Texture2D
@export var firing_rate: float = 1.0
@export var barrel_directions: PackedVector2Array = PackedVector2Array([Vector2(0, -1)])
## 初始弹药数量。-1 表示无限；0 或正整数为有限弹药。
@export var initial_ammo: int = 3
## 炮塔变体标识。子弹 bullet_type 必须与此匹配才能触发交互。NEUTRAL 不过滤。
@export var variant: Variant = Variant.NEUTRAL
## 自定义炮塔场景。null 时使用默认 tower.tscn。
@export var scene: PackedScene
## 是否出现在普通模式奖励池（三选一弹窗）
@export var in_normal_pool: bool = true
## 是否出现在开发者模式侧边栏
@export var in_dev_pool: bool = true
```

- [ ] **Step 2: Run existing variant tests to see what breaks**

```bash
# In Godot Editor: GdUnit → Run Tests → select TowerVariantFilterTest + TowerVariantVisualTest + VariantPaletteTest
```

Expected: multiple failures — bullet_type values and palette tests will fail due to the enum shift. This confirms we know what to fix next.

- [ ] **Step 3: Commit**

```bash
git add resources/TowerData.gd
git commit -m "refactor: add Variant.NEUTRAL=0, shift NEGATIVE=1 POSITIVE=2"
```

---

### Task 2: Update VariantPalette for NEUTRAL

**Files:**
- Modify: `resources/VariantPalette.gd`
- Modify: `resources/variant_palette.tres`

- [ ] **Step 1: Write failing test for NEUTRAL color**

In `tests/gdunit/VariantPaletteTest.gd`, add after the last test:

```gdscript
func test_get_color_returns_white_for_neutral_variant() -> void:
	var palette := VariantPalette.new()
	palette.neutral_color = Color.WHITE

	var result := palette.get_color(TowerData.Variant.NEUTRAL)

	assert_that(result).is_equal(Color.WHITE)


func test_default_neutral_color_is_white() -> void:
	var palette := VariantPalette.new()

	assert_that(palette.neutral_color).is_equal(Color.WHITE)
```

- [ ] **Step 2: Run to verify failure**

Run `VariantPaletteTest`. Expected: FAIL — `neutral_color` property doesn't exist yet.

- [ ] **Step 3: Update VariantPalette.gd**

Replace entire file:

```gdscript
## 变体颜色配置资源。将 TowerData.Variant 映射到用于炮塔 Sprite 着色的颜色。
class_name VariantPalette extends Resource

## NEUTRAL 变体炮塔的着色颜色（白色=无染色）
@export var neutral_color: Color = Color.WHITE
## NEGATIVE 变体炮塔的着色颜色（默认蓝色）
@export var negative_color: Color = Color.BLUE
## POSITIVE 变体炮塔的着色颜色（默认红色）
@export var positive_color: Color = Color.RED

## 根据变体返回对应颜色。
func get_color(variant: TowerData.Variant) -> Color:
	match variant:
		TowerData.Variant.NEGATIVE: return negative_color
		TowerData.Variant.POSITIVE: return positive_color
		_: return neutral_color
```

- [ ] **Step 4: Update variant_palette.tres**

Open `resources/variant_palette.tres` and add `neutral_color` line. The file should look like:

```
[gd_resource type="Resource" script_class="VariantPalette" load_steps=2 format=3 uid="uid://..."]

[ext_resource type="Script" uid="uid://..." path="res://resources/VariantPalette.gd" id="1_..."]

[resource]
script = ExtResource("1_...")
neutral_color = Color(1, 1, 1, 1)
negative_color = Color(0, 0, 1, 1)
positive_color = Color(1, 0, 0, 1)
```

(Read the actual uid values from the existing file and preserve them; only add the `neutral_color` line.)

- [ ] **Step 5: Run VariantPaletteTest**

Expected: all tests PASS including the two new NEUTRAL tests.

- [ ] **Step 6: Commit**

```bash
git add resources/VariantPalette.gd resources/variant_palette.tres tests/gdunit/VariantPaletteTest.gd
git commit -m "feat: add VariantPalette.neutral_color for NEUTRAL variant (white)"
```

---

### Task 3: Update BulletData and AmmoItem bullet_type to use TowerData.Variant

**Files:**
- Modify: `resources/BulletData.gd`
- Modify: `entities/bullets/ammo_item.gd`

- [ ] **Step 1: Update BulletData.gd**

Change line 11 from:
```gdscript
var bullet_type: int = 0        ## 子弹内在属性类型（0=蓝，1=红，未来可扩展）
```
to:
```gdscript
var bullet_type: TowerData.Variant = TowerData.Variant.NEGATIVE  ## 子弹极性（NEGATIVE 蓝 / POSITIVE 红）
```

Change line 12 from:
```gdscript
var color: Color = Color.BLUE   ## 子弹颜色，通过 Sprite2D.modulate 应用（根据 bullet_type 设置）
```
to:
```gdscript
var color: Color = Color.BLUE   ## 子弹颜色，通过 Sprite2D.modulate 应用
```

- [ ] **Step 2: Update AmmoItem.gd**

Change line 12 from:
```gdscript
var bullet_type: int = 0
```
to:
```gdscript
var bullet_type: TowerData.Variant = TowerData.Variant.NEGATIVE
```

Also update the comment on that line from `## 子弹内在属性类型（0=蓝，1=红，未来可扩展）` to `## 子弹极性（NEGATIVE 蓝 / POSITIVE 红）`.

- [ ] **Step 3: Commit**

```bash
git add resources/BulletData.gd entities/bullets/ammo_item.gd
git commit -m "refactor: bullet_type type int → TowerData.Variant"
```

---

### Task 4: Fix tower.gd color logic and override_bullet_type

**Files:**
- Modify: `entities/towers/tower.gd` (lines 312-320 and 477-478)

- [ ] **Step 1: Fix color assignment (line ~478)**

Find:
```gdscript
	bd.color = Color.BLUE if bd.bullet_type == 0 else Color.RED
```

Replace with:
```gdscript
	bd.color = Color.BLUE if bd.bullet_type == TowerData.Variant.NEGATIVE else Color.RED
```

- [ ] **Step 2: Fix override_bullet_type sentinel check (lines ~312-320)**

Find:
```gdscript
## override_bullet_type >= 0 时覆盖弹药类型（用于 NOT Tower 等翻转场景）
func add_ammo_from_chain(amount: int, bullet_data: BulletData, override_bullet_type: int = -1) -> void:
```
and the line:
```gdscript
		item.bullet_type = override_bullet_type if override_bullet_type >= 0 else bullet_data.bullet_type
```

Replace with:
```gdscript
## override_bullet_type != -1 时覆盖弹药类型（用于 NOT Tower 等翻转场景）
func add_ammo_from_chain(amount: int, bullet_data: BulletData, override_bullet_type: int = -1) -> void:
```
and:
```gdscript
		item.bullet_type = override_bullet_type if override_bullet_type != -1 else bullet_data.bullet_type
```

- [ ] **Step 3: Commit**

```bash
git add entities/towers/tower.gd
git commit -m "fix: tower.gd bullet_type comparisons use TowerData.Variant enum"
```

---

### Task 5: Fix NOT Tower flip logic

**Files:**
- Modify: `entities/towers/not_tower.gd`

The NOT Tower flips bullet polarity. Old code: `1 - bullet_type` (0↔1). New enum values are NEGATIVE=1, POSITIVE=2, so the flip is `3 - bullet_type` (1↔2).

- [ ] **Step 1: Update not_tower.gd**

Replace:
```gdscript
## NOT Tower：所有链式弹药补充均翻转子弹类型（0↔1）

func _ready() -> void:
	super._ready()
	sprite.modulate = Color(0.6, 0.2, 0.8, 1.0)

## 拦截所有 add_ammo_from_chain，强制翻转 bullet_type
## HitTowerTargetReplenishEffect 调用此方法时会自动获得翻转后的类型，无需额外加弹
func add_ammo_from_chain(amount: int, bullet_data: BulletData, _override_bullet_type: int = -1) -> void:
	super.add_ammo_from_chain(amount, bullet_data, 1 - bullet_data.bullet_type)
```

With:
```gdscript
## NOT Tower：所有链式弹药补充均翻转子弹极性（NEGATIVE↔POSITIVE）

func _ready() -> void:
	super._ready()
	sprite.modulate = Color(0.6, 0.2, 0.8, 1.0)

## 拦截所有 add_ammo_from_chain，强制翻转 bullet_type（NEGATIVE=1↔POSITIVE=2）
## HitTowerTargetReplenishEffect 调用此方法时会自动获得翻转后的类型，无需额外加弹
func add_ammo_from_chain(amount: int, bullet_data: BulletData, _override_bullet_type: int = -1) -> void:
	super.add_ammo_from_chain(amount, bullet_data, 3 - bullet_data.bullet_type)
```

- [ ] **Step 2: Commit**

```bash
git add entities/towers/not_tower.gd
git commit -m "fix: not_tower flip NEGATIVE↔POSITIVE with 3-bullet_type (enum values 1,2)"
```

---

### Task 6: Update bullet.gd variant filter for NEUTRAL

**Files:**
- Modify: `entities/bullets/bullet.gd` (line ~67)

- [ ] **Step 1: Write failing test for NEUTRAL tower accepting all bullets**

In `tests/gdunit/TowerVariantFilterTest.gd`, add these tests (NEUTRAL tower should be hit by any bullet_type):

```gdscript
# ── NEUTRAL variant: accepts all bullet types ─────────────────────

func test_negative_bullet_hits_neutral_tower() -> void:
	var tower := _make_tower(TowerData.Variant.NEUTRAL, 200)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.NEGATIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("NEGATIVE bullet SHOULD hit NEUTRAL tower") \
		.is_true()


func test_positive_bullet_hits_neutral_tower() -> void:
	var tower := _make_tower(TowerData.Variant.NEUTRAL, 201)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.POSITIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("POSITIVE bullet SHOULD hit NEUTRAL tower") \
		.is_true()
```

Also update `_make_bullet` to use the Variant type, and update the existing test names/values. Replace the full `_make_bullet` helper and existing match/non-match tests:

```gdscript
## Creates a bullet with the given bullet_type.
func _make_bullet(bullet_type: TowerData.Variant) -> Node2D:
	var bullet: Node2D = BulletScene.instantiate()
	var bd := BulletData.new()
	bd.bullet_type = bullet_type
	bd.shadow_team_id = -1
	bd.tower_body_mask = Layers.TOWER_BODY
	bd.transmission_chain = []
	bd.effects = []
	bullet.data = bd
	return bullet


# ── Matching variant: bullet SHOULD interact ─────────────────────

func test_negative_bullet_hits_negative_tower() -> void:
	var tower := _make_tower(TowerData.Variant.NEGATIVE, 100)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.NEGATIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("NEGATIVE bullet SHOULD hit NEGATIVE tower") \
		.is_true()


func test_positive_bullet_hits_positive_tower() -> void:
	var tower := _make_tower(TowerData.Variant.POSITIVE, 101)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.POSITIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("POSITIVE bullet SHOULD hit POSITIVE tower") \
		.is_true()


# ── Non-matching variant: bullet MUST NOT interact ────────────────

func test_positive_bullet_does_not_hit_negative_tower() -> void:
	var tower := _make_tower(TowerData.Variant.NEGATIVE, 102)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.POSITIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("POSITIVE bullet must NOT hit NEGATIVE tower") \
		.is_false()
	assert_bool(bullet.visible).is_true()
	assert_bool(bullet.is_physics_processing()).is_true()


func test_negative_bullet_does_not_hit_positive_tower() -> void:
	var tower := _make_tower(TowerData.Variant.POSITIVE, 103)
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.NEGATIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)

	assert_bool(bullet._pending_release) \
		.override_failure_message("NEGATIVE bullet must NOT hit POSITIVE tower") \
		.is_false()
	assert_bool(bullet.visible).is_true()
	assert_bool(bullet.is_physics_processing()).is_true()


# ── Null data guard ───────────────────────────────────────────────

func test_tower_with_null_data_is_not_filtered() -> void:
	var tower: Node2D = TowerScene.instantiate()
	tower.data = null
	tower.entity_id = 104
	_add_child(tower)
	await await_idle_frame()
	await await_idle_frame()

	var bullet := _make_bullet(TowerData.Variant.NEGATIVE)
	_add_child(bullet)
	bullet.reset()
	await await_idle_frame()

	var tower_body := tower.get_node_or_null("TowerBody") as Area2D
	assert_object(tower_body).is_not_null()
	bullet._on_hitbox_area_entered(tower_body)
	assert_bool(bullet._pending_release) \
		.override_failure_message("null-data tower should not be filtered — bullet should be consumed") \
		.is_true()
```

- [ ] **Step 2: Run TowerVariantFilterTest — expect NEUTRAL tests to fail**

The NEUTRAL tests will fail because the filter currently applies regardless of variant. The match/mismatch tests may also fail due to bullet_type value changes.

- [ ] **Step 3: Update bullet.gd filter**

Find (line ~67):
```gdscript
	# Variant filter: bullet type must match tower variant; mismatched bullets pass through
	if data and parent.data != null and data.bullet_type != parent.data.variant:
		return
```

Replace with:
```gdscript
	# Variant filter: NEUTRAL towers accept all bullets; NEGATIVE/POSITIVE only accept matching polarity
	if data and parent.data != null \
			and parent.data.variant != TowerData.Variant.NEUTRAL \
			and data.bullet_type != parent.data.variant:
		return
```

- [ ] **Step 4: Run TowerVariantFilterTest**

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add entities/bullets/bullet.gd tests/gdunit/TowerVariantFilterTest.gd
git commit -m "feat: NEUTRAL variant bypasses bullet filter; update filter tests to use Variant enum"
```

---

### Task 7: Update TowerVariantVisualTest for NEUTRAL

**Files:**
- Modify: `tests/gdunit/TowerVariantVisualTest.gd`

- [ ] **Step 1: Add NEUTRAL visual test**

Add after the last existing test:

```gdscript
func test_neutral_variant_tower_has_shader_material_with_white_tint() -> void:
	var td := TowerData.new()
	td.sprite = load("res://assets/tower1000.svg")
	td.firing_rate = 1.0
	td.variant = TowerData.Variant.NEUTRAL

	var tower: Node2D = TowerScene.instantiate()
	tower.data = td
	_add_child(tower)
	await await_idle_frame()

	var sprite: Sprite2D = tower.get_node("TowerVisual/Sprite2D")
	assert_object(sprite.material).is_not_null()
	assert_bool(sprite.material is ShaderMaterial).is_true()
	var mat := sprite.material as ShaderMaterial
	var color := mat.get_shader_parameter("color") as Color
	assert_that(color).is_equal(Color.WHITE)
```

- [ ] **Step 2: Run TowerVariantVisualTest**

Expected: all tests PASS (the shader is applied with `get_color(NEUTRAL)` = white from VariantPalette).

- [ ] **Step 3: Commit**

```bash
git add tests/gdunit/TowerVariantVisualTest.gd
git commit -m "test: add NEUTRAL variant shader visual test (white tint)"
```

---

### Task 8: Rename _true .tres files to _positive and update variant value

There are 6 `_true` .tres files. Each needs: (a) renamed, (b) `tower_name` "(TRUE)"→"(POSITIVE)", (c) `variant = 1` → `variant = 2`.

**Files:**
- Rename + edit: all 6 `resources/*_true.tres`

- [ ] **Step 1: Git-rename and update simple_emitter_true.tres**

```bash
git mv resources/simple_emitter_true.tres resources/simple_emitter_positive.tres
```

Then edit `resources/simple_emitter_positive.tres`: change `tower_name = "单向炮 (TRUE)"` to `tower_name = "单向炮 (POSITIVE)"` and `variant = 1` to `variant = 2`.

- [ ] **Step 2: Rename and update tower1010_true.tres**

```bash
git mv resources/tower1010_true.tres resources/tower1010_positive.tres
```

Edit `resources/tower1010_positive.tres`: `tower_name = "双向炮 (POSITIVE)"`, `variant = 2`.

- [ ] **Step 3: Rename and update tower1100_true.tres**

```bash
git mv resources/tower1100_true.tres resources/tower1100_positive.tres
```

Edit: check current `tower_name` in that file and append/replace "(TRUE)"→"(POSITIVE)", `variant = 2`.

- [ ] **Step 4: Rename and update tower1110_true.tres**

```bash
git mv resources/tower1110_true.tres resources/tower1110_positive.tres
```

Edit: update tower_name "(TRUE)"→"(POSITIVE)", `variant = 2`.

- [ ] **Step 5: Rename and update tower1111_true.tres**

```bash
git mv resources/tower1111_true.tres resources/tower1111_positive.tres
```

Edit: update tower_name "(TRUE)"→"(POSITIVE)", `variant = 2`.

- [ ] **Step 6: Rename and update not_tower_true.tres**

```bash
git mv resources/not_tower_true.tres resources/not_tower_positive.tres
```

Edit `resources/not_tower_positive.tres`: `tower_name = "NOT 塔 (POSITIVE)"`, `variant = 2`.

- [ ] **Step 7: Commit**

```bash
git add -A resources/
git commit -m "refactor: rename *_true.tres → *_positive.tres; variant 1→2 (enum shift)"
```

---

### Task 9: Create _negative .tres files for each tower type

**Files:**
- Create: 6 new `resources/*_negative.tres`

Each negative file copies the base tower's .tres structure but sets `tower_name` to include "(NEGATIVE)" and `variant = 1`.

- [ ] **Step 1: Create simple_emitter_negative.tres**

Read `resources/simple_emitter.tres` for the uid/ext_resource structure, then write:

```
[gd_resource type="Resource" script_class="TowerData" load_steps=3 format=3 uid="uid://simple_emitter_neg"]

[ext_resource type="Script" uid="uid://ch3f0r75qtmfc" path="res://resources/TowerData.gd" id="1_towerdata"]
[ext_resource type="Texture2D" uid="uid://c1wbms40reft2" path="res://assets/tower1000.svg" id="2_sprite"]

[resource]
script = ExtResource("1_towerdata")
tower_name = "单向炮 (NEGATIVE)"
sprite = ExtResource("2_sprite")
icon = ExtResource("2_sprite")
firing_rate = 1.0
barrel_directions = PackedVector2Array(0, -1)
initial_ammo = 10
variant = 1
```

**Note:** The `uid` value must be unique. Use `mcp__godot__get_uid` to generate a valid UID or let Godot assign one by omitting it and letting the editor create it. The ext_resource UIDs must match the exact values from `simple_emitter.tres`.

- [ ] **Step 2: Create tower1010_negative.tres**

Read `resources/tower1010.tres` for structure. Write `resources/tower1010_negative.tres`:

```
[gd_resource type="Resource" script_class="TowerData" load_steps=3 format=3 uid="uid://tower1010_neg"]

[ext_resource type="Script" uid="uid://ch3f0r75qtmfc" path="res://resources/TowerData.gd" id="1_towerdata"]
[ext_resource type="Texture2D" uid="uid://dtmrgentliip0" path="res://assets/tower1010.svg" id="2_sprite"]

[resource]
script = ExtResource("1_towerdata")
tower_name = "双向炮 (NEGATIVE)"
sprite = ExtResource("2_sprite")
icon = ExtResource("2_sprite")
firing_rate = 1.0
barrel_directions = PackedVector2Array(0, -1, 0, 1)
initial_ammo = 10
variant = 1
```

- [ ] **Step 3: Create tower1100_negative.tres, tower1110_negative.tres, tower1111_negative.tres**

Read each base .tres (`tower1100.tres`, `tower1110.tres`, `tower1111.tres`) for their `tower_name`, `barrel_directions`, `initial_ammo`, and sprite ext_resource uid. Then create the _negative version with same values but `tower_name = "<name> (NEGATIVE)"` and `variant = 1`.

- [ ] **Step 4: Create not_tower_negative.tres**

Read `resources/not_tower.tres`. Write `resources/not_tower_negative.tres`:

```
[gd_resource type="Resource" script_class="TowerData" load_steps=4 format=3 uid="uid://not_tower_neg"]

[ext_resource type="Script" uid="uid://ch3f0r75qtmfc" path="res://resources/TowerData.gd" id="1_towerdata"]
[ext_resource type="Texture2D" uid="uid://dtmrgentliip0" path="res://assets/tower1010.svg" id="2_sprite"]
[ext_resource type="PackedScene" uid="uid://not_tower_scene" path="res://entities/towers/not_tower.tscn" id="3_scene"]

[resource]
script = ExtResource("1_towerdata")
tower_name = "NOT 塔 (NEGATIVE)"
sprite = ExtResource("2_sprite")
icon = ExtResource("2_sprite")
firing_rate = 1.0
barrel_directions = PackedVector2Array(0, -1)
initial_ammo = 3
scene = ExtResource("3_scene")
variant = 1
```

- [ ] **Step 5: Commit**

```bash
git add resources/*_negative.tres
git commit -m "feat: add _negative variant .tres for all 6 tower types"
```

---

### Task 10: Update item_pool.gd

**Files:**
- Modify: `resources/item_pool.gd`

- [ ] **Step 1: Update ALL_ITEMS to use new paths and add _negative entries**

Replace the tower section of `ALL_ITEMS`:

```gdscript
const ALL_ITEMS: Array = [
	preload("res://resources/simple_emitter.tres"),
	preload("res://resources/simple_emitter_negative.tres"),
	preload("res://resources/simple_emitter_positive.tres"),
	preload("res://resources/tower1010.tres"),
	preload("res://resources/tower1010_negative.tres"),
	preload("res://resources/tower1010_positive.tres"),
	preload("res://resources/tower1100.tres"),
	preload("res://resources/tower1100_negative.tres"),
	preload("res://resources/tower1100_positive.tres"),
	preload("res://resources/tower1110.tres"),
	preload("res://resources/tower1110_negative.tres"),
	preload("res://resources/tower1110_positive.tres"),
	preload("res://resources/tower1111.tres"),
	preload("res://resources/tower1111_negative.tres"),
	preload("res://resources/tower1111_positive.tres"),
	preload("res://resources/not_tower.tres"),
	preload("res://resources/not_tower_negative.tres"),
	preload("res://resources/not_tower_positive.tres"),
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
```

- [ ] **Step 2: Run ItemPoolTest**

Expected: all tests PASS. The pool counts will be larger but the type/flag invariants still hold.

- [ ] **Step 3: Commit**

```bash
git add resources/item_pool.gd
git commit -m "feat: item_pool includes _negative and _positive variants for all tower types"
```

---

### Task 11: Apply variant shader tint to tower_icon.gd

**Files:**
- Modify: `ui/deployment/tower_icon.gd`

The dev sidebar and reward popup both use `tower_icon.gd`. The icon is a `TextureRect`. Apply shader material in `_ready()` so NEGATIVE icons show blue tint and POSITIVE icons show red tint.

- [ ] **Step 1: Update tower_icon.gd**

At the top of the file, add two preload constants after the existing script header:

```gdscript
const _TOWER_TINT_SHADER := preload("res://entities/towers/tower_tint.gdshader")
const _VARIANT_PALETTE := preload("res://resources/variant_palette.tres")
```

In `_ready()`, after the line `texture = tower_data.icon`, add:

```gdscript
		_apply_variant_tint()
```

Add the new method after `_ready()`:

```gdscript
func _apply_variant_tint() -> void:
	if not tower_data:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _TOWER_TINT_SHADER
	mat.set_shader_parameter("color", _VARIANT_PALETTE.get_color(tower_data.variant))
	self.material = mat
```

- [ ] **Step 2: Run the game in dev mode and verify**

```bash
godot --path . scenes/start_menu.tscn
```

Open dev mode. Verify:
- NEUTRAL tower icons: no tint (white = original color)
- NEGATIVE tower icons: blue tint
- POSITIVE tower icons: red tint

- [ ] **Step 3: Commit**

```bash
git add ui/deployment/tower_icon.gd
git commit -m "feat: apply variant shader tint to tower_icon in dev sidebar and reward popup"
```

---

### Task 12: Run full test suite and fix regressions

- [ ] **Step 1: Run all tests in GdUnit4**

In Godot Editor: GdUnit → Run Tests (all suites).

- [ ] **Step 2: Fix any remaining failures**

Common regressions to check:
- `FullChainTest.gd`: may reference bullet_type as `0` or `1` — update to `TowerData.Variant.NEGATIVE` / `TowerData.Variant.POSITIVE`
- `TowerDataTest.gd`: may reference old variant values
- `IntegrationTest.gd`: check any bullet_type assertions
- `ModuleTest.gd` / `ModuleSpecialTest.gd`: check for bullet_type=0/1 literals

For each broken test: find the `bullet_type = 0` / `bullet_type = 1` literal and replace with `TowerData.Variant.NEGATIVE` / `TowerData.Variant.POSITIVE`. Find any `variant == 0` / `variant == 1` and update accordingly.

- [ ] **Step 3: Commit fixes**

```bash
git add tests/gdunit/
git commit -m "fix: update remaining tests to use TowerData.Variant enum values"
```

---

### Task 13: Update uid registry

**Files:**
- Run: `mcp__godot__update_project_uids`

New .tres files need UIDs registered in Godot's project.

- [ ] **Step 1: Update UIDs via MCP**

Use `mcp__godot__update_project_uids` to register all new resource UIDs.

- [ ] **Step 2: Verify no uid warnings in debug output**

Use `mcp__godot__get_debug_output` after running the project and confirm no "UID not found" warnings for the new resources.

- [ ] **Step 3: Commit any generated .uid files**

```bash
git add resources/*.uid resources/*.gd.uid
git commit -m "chore: register UIDs for new _negative and _positive .tres files"
```

---

### Task 14: Final verification

- [ ] **Step 1: Run full test suite**

Expected: all tests PASS.

- [ ] **Step 2: Run game and do manual smoke test**

```bash
godot --path . scenes/start_menu.tscn
```

- Open dev mode
- Confirm base towers: no tint, accept all bullets
- Confirm NEGATIVE towers: blue tint, reject POSITIVE bullets (only interact with NEGATIVE)
- Confirm POSITIVE towers: red tint, reject NEGATIVE bullets
- Confirm NOT Tower: still flips bullet polarity correctly (NEGATIVE→POSITIVE, POSITIVE→NEGATIVE)
- Confirm normal mode reward popup shows correct tints

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: tower variant NEUTRAL tier + rename _true→_positive + add _negative variants"
```
