# Towers — Game Content Knowledge Base

> Agent guidance: This file is the authoritative spec for all tower resources.
> Tests in `tests/gdunit/TowerDataTest.gd` verify every tower against this spec.
> When adding a new tower: (1) create the .tres, (2) add a row to the table below,
> (3) add a `test_tower_<name>` function in TowerDataTest.gd.

## Quick Reference

| File | 名称 | firing_rate | 炮管数 | barrel_directions | initial_ammo |
|------|------|------------|--------|-------------------|--------------|
| `tower1010.tres` | 双向炮 | 1.0 | 2 | (0,-1), (0,1) | 10 |
| `tower1100.tres` | 直角炮 | 1.0 | 2 | (0,-1), (1,0) | 3 |
| `tower1110.tres` | 三向炮 | 1.0 | 3 | (0,-1), (1,0), (0,1) | 3 |
| `tower1111.tres` | 四向炮 | 1.0 | 4 | (0,-1), (1,0), (0,1), (-1,0) | 0 |
| `not_tower.tres` | NOT 塔 | 1.0 | 1 | (0,-1) | 3 |

## Special Towers

### NOT Tower (`not_tower.tres`)

逻辑非门塔，击中时翻转子弹属性类型（0↔1）。

- **行为**: 任意子弹击中后，`bullet_type` 翻转（0=蓝 → 1=红，1=红 → 0=蓝）
- **弹药**: 翻转后的子弹作为弹药进入队列，发射时颜色跟随类型
- **视觉**: 紫色外观（modulate = 0.6, 0.2, 0.8）
- **脚本**: `entities/towers/not_tower.gd` 继承 `tower.gd`，重写 `on_bullet_hit()`

## Invariants (enforced by TowerDataTest)

Every tower .tres in `res://resources/` matching `tower*.tres` must satisfy:

- `tower_name` is non-empty string
- `sprite` is not null
- `icon` is not null
- `firing_rate > 0`
- `barrel_directions.size() >= 1`
- `initial_ammo >= -1` (-1 = infinite, 0 = starts empty, positive = count)

## Notes

- **tower1111 四向炮** starts with `initial_ammo = 0` — intentional, needs ammo-replenish modules to function
- **Naming scheme** — binary flags for Up/Right/Down/Left (1=active): `tower1010` = Up+Down barrels
- **All current towers** share `firing_rate = 1.0`
- Barrel directions are local-space unit vectors: `(0,-1)` = up, `(1,0)` = right, `(0,1)` = down, `(-1,0)` = left
