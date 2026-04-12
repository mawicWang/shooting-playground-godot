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

`BulletData.bullet_type` is the bullet's variant. It flows from `AmmoItem.bullet_type` → `BulletData.bullet_type` in `tower.gd/_do_fire()`. Default is `0` (NEGATIVE).

## Filter Location

`entities/bullets/bullet.gd` — `_on_hitbox_area_entered()`:

```gdscript
# Variant filter: bullet type must match tower variant; mismatched bullets pass through
if data and parent.data != null and data.bullet_type != parent.data.variant:
    return
```

The filter runs after the shadow-team filter, before the `transmission_chain` check. When `parent.data` is null (tower has no TowerData), the filter is skipped and the bullet hits normally.

## Visual

Each tower sprite receives a `ShaderMaterial` using `entities/towers/tower_tint.gdshader`. The tint color comes from `resources/variant_palette.tres` (a `VariantPalette` resource). Each tower gets its own `ShaderMaterial` instance — never shared — so changing one tower's tint does not affect others.

To change variant colors, open `resources/variant_palette.tres` in the Godot editor and modify `negative_color` / `positive_color`. No code changes needed.

| Variant | Default color |
|---------|--------------|
| NEGATIVE (0) | Blue |
| POSITIVE (1) | Red |

## VariantPalette Resource

`resources/VariantPalette.gd`:

```gdscript
class_name VariantPalette extends Resource
@export var negative_color: Color = Color.BLUE
@export var positive_color: Color = Color.RED
func get_color(variant: TowerData.Variant) -> Color
```

## Testing

See `tests/gdunit/TowerVariantFilterTest.gd` (filter logic) and `tests/gdunit/TowerVariantVisualTest.gd` (shader application).
