# Tower Variant System — Design Spec

**Date:** 2026-04-11
**Status:** Approved

---

## Overview

Introduce two distinct variant identities for towers (`FALSE` and `TRUE`). A bullet whose `bullet_type` does not match the target tower's `variant` is silently ignored — no `TowerEffect`, no `BulletEffect`, no hit animation. Variant is displayed via a shader tint on the tower sprite, with colors driven by a configurable `VariantPalette` resource.

---

## Section 1: Data Model

### `TowerData.gd`

Add a named enum and a new export field:

```gdscript
enum Variant { FALSE = 0, TRUE = 1 }
@export var variant: Variant = Variant.FALSE
```

- Accessed as `TowerData.Variant.FALSE` / `TowerData.Variant.TRUE`.
- All existing `.tres` TowerData files have `variant` set explicitly to `Variant.FALSE` (no surprise defaults).
- Enum integers intentionally align with the existing `bullet_type` values in `BulletData` (0 and 1).

### `VariantPalette.gd` (new)

```gdscript
class_name VariantPalette extends Resource

@export var false_color: Color = Color.BLUE
@export var true_color: Color = Color.RED

func get_color(variant: TowerData.Variant) -> Color:
    return false_color if variant == TowerData.Variant.FALSE else true_color
```

- Saved as `resources/variant_palette.tres` with BLUE/RED defaults.
- Preloaded in `tower.gd`; changing the `.tres` file changes all tower tints without touching code.
- Colors are purely cosmetic — they have no effect on game logic.

---

## Section 2: Shader & Visual

### `entities/towers/tower_tint.gdshader` (new)

```glsl
shader_type canvas_item;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = tex * color;
}
```

Identical logic to the existing `bullet_color.gdshader`, scoped to towers to avoid cross-entity coupling.

### `tower.gd` — `_apply_data()` addition

```gdscript
const _VARIANT_PALETTE = preload("res://resources/variant_palette.tres")
const _TOWER_TINT_SHADER = preload("res://entities/towers/tower_tint.gdshader")

# after sprite.texture = data.sprite:
if data:
    var mat := ShaderMaterial.new()
    mat.shader = _TOWER_TINT_SHADER
    mat.set_shader_parameter("color", _VARIANT_PALETTE.get_color(data.variant))
    sprite.material = mat
```

- Each tower instance gets its own `ShaderMaterial` — no shared-state contamination.
- Follows the same pattern as `bullet.gd`'s per-bullet material duplication.

---

## Section 3: Bullet-Tower Interaction Filter

### `bullet.gd` — `_on_hitbox_area_entered()`

Insert after the shadow-team filter, before the `transmission_chain` check:

```gdscript
# Variant filter: ignore interaction if bullet type doesn't match tower variant
if data and parent.data != null and data.bullet_type != parent.data.variant:
    return
```

**Behaviour:**
- Strict equality: `FALSE` towers (`variant == 0`) only react to bullets with `bullet_type == 0`; `TRUE` towers only to `bullet_type == 1`.
- A non-matching bullet **continues flying** — it is not consumed, not released from the pool.
- All downstream effects are skipped: `play_hit_effect()`, `BulletEffect.on_hit_tower()`, `on_bullet_hit()` (TowerEffects), and ammo replenishment.
- If `parent.data` is `null`, the filter is skipped — existing behaviour is preserved, no crash.

**No changes to `AmmoItem` or `_do_fire()`:** `bullet_type` already flows from `AmmoItem.bullet_type` → `BulletData.bullet_type`. Default is `0` (`FALSE`), consistent with all existing towers being set to `Variant.FALSE`.

---

## Section 4: Files & Scope

### Files to create

| File | Purpose |
|---|---|
| `resources/VariantPalette.gd` | Resource class: two colors + `get_color()` |
| `resources/variant_palette.tres` | Default palette (BLUE=FALSE, RED=TRUE) |
| `entities/towers/tower_tint.gdshader` | Simple tint shader for tower sprites |

### Files to modify

| File | Change |
|---|---|
| `resources/TowerData.gd` | Add `enum Variant` + `@export var variant` |
| `entities/towers/tower.gd` | Preload palette + shader; apply in `_apply_data()` |
| `entities/bullets/bullet.gd` | Add variant filter in `_on_hitbox_area_entered()` |
| All `resources/*.tres` TowerData files | Set `variant` explicitly (all `FALSE` initially) |

### Out of scope

- Setting any existing tower to `TRUE` variant (done manually by the developer after implementation).
- Applying variant color to bullet sprites (bullets already have `bullet_color.gdshader`; palette reuse is a future nice-to-have).
- Multi-barrel tower testing (initial experiment targets single-direction towers only).

---

## Section 5: Tests (GdUnit4)

All tests in `tests/gdunit/`, extending `GdUnitTestSuite`.

| Test | Expected result |
|---|---|
| `bullet_type==0` hits `Variant.FALSE` tower | Effects fire, ammo replenished normally |
| `bullet_type==1` hits `Variant.FALSE` tower | All effects skipped; bullet continues flying |
| `bullet_type==0` hits `Variant.TRUE` tower | All effects skipped; bullet continues flying |
| `bullet_type==1` hits `Variant.TRUE` tower | Effects fire normally |
| Tower with `data == null` hit by any bullet | Filter skipped, no crash |
