# Effect Matrix Completion — Design Spec

**Date:** 2026-04-04
**Status:** Approved

## Overview

Four sequential parts:
1. Rename 7 existing Effect classes to a unified `{Trigger}{Target}{Effect}Effect` convention
2. Create 7 new Effect classes to fill missing matrix cells
3. Create 9 new module `.tres` files for those cells
4. Generate pixel art icons for all 14 existing modules via PixelLab MCP

---

## Part 1: Effect Class Rename

### Naming Convention

Format: `{Trigger}{Target}{Effect}Effect`

- **Trigger** — when it fires: `HitTower`, `HitEnemy`, `KillEnemy`, `ReceiveHit`, `DealDamage`
- **Target** — who receives the benefit: `Self` (source tower or tower itself), `Target` (the tower that was hit)
- **Effect** — what happens: `CdReduce`, `Replenish`, `SpeedBoost`

`Self` on a `BulletEffect` means `transmission_chain[0]` (the firing tower).
`Self` on a `TowerEffect` means the tower receiving the callback.

### Rename Table

| Old class name | New class name | File rename |
|----------------|----------------|-------------|
| `CdReduceOnHitTowerEffect` | `HitTowerSelfCdReduceEffect` | `cd_reduce_on_hit_tower_effect.gd` → `hit_tower_self_cd_reduce_effect.gd` |
| `CdReduceTargetTowerEffect` | `HitTowerTargetCdReduceEffect` | `cd_reduce_target_tower_effect.gd` → `hit_tower_target_cd_reduce_effect.gd` |
| `CdReduceOnEnemyEffect` | `HitEnemySelfCdReduceEffect` | `cd_reduce_on_enemy_effect.gd` → `hit_enemy_self_cd_reduce_effect.gd` |
| `CdReduceOnReceiveTowerEffect` | `ReceiveHitSelfCdReduceEffect` | `cd_reduce_on_receive_tower_effect.gd` → `receive_hit_self_cd_reduce_effect.gd` |
| `ReplenishEffect` | `HitTowerTargetReplenishEffect` | `replenish_effect.gd` → `hit_tower_target_replenish_effect.gd` |
| `HitSpeedBoostEffect` | `HitTowerTargetSpeedBoostEffect` | `hit_speed_boost_effect.gd` → `hit_tower_target_speed_boost_effect.gd` |
| `KillBoostEffect` | `KillEnemySelfSpeedBoostEffect` | `kill_boost_effect.gd` → `kill_enemy_self_speed_boost_effect.gd` |

### Required Updates

- Each `.gd` file: update `class_name` declaration
- All `.tres` files referencing these scripts: update `path=` for each `ext_resource`
- `docs/content/effects.md`: update Concrete Effect Implementations table
- `docs/content/modules.md`: update Effect type references in each module entry
- `docs/content/effect-matrix.md`: update class name column

---

## Part 2: New Effect Classes

### Files to Create

All BulletEffects go in `entities/effects/bullet_effects/`.
All TowerEffects go in `entities/effects/tower_effects/`.

| New class name | Base class | File | Trigger method | Target | Action |
|----------------|-----------|------|----------------|--------|--------|
| `HitEnemySelfReplenishEffect` | `BulletEffect` | `hit_enemy_self_replenish_effect.gd` | `on_hit_enemy` | `transmission_chain[0]` | `source.add_ammo(ammo_amount)` |
| `HitEnemySelfSpeedBoostEffect` | `BulletEffect` | `hit_enemy_self_speed_boost_effect.gd` | `on_hit_enemy` | `transmission_chain[0]` | `source.apply_speed_boost(duration)` |
| `ReceiveHitSelfReplenishEffect` | `TowerEffect` | `receive_hit_self_replenish_effect.gd` | `on_receive_bullet_hit` | `tower` (self) | `tower.add_ammo(ammo_amount)` |
| `ReceiveHitSelfSpeedBoostEffect` | `TowerEffect` | `receive_hit_self_speed_boost_effect.gd` | `on_receive_bullet_hit` | `tower` (self) | `tower.apply_speed_boost(duration)` |
| `DealDamageSelfCdReduceEffect` | `BulletEffect` | `deal_damage_self_cd_reduce_effect.gd` | `on_deal_damage` | `transmission_chain[0]` | `source.reduce_cooldown(reduction)` |
| `DealDamageSelfReplenishEffect` | `BulletEffect` | `deal_damage_self_replenish_effect.gd` | `on_deal_damage` | `transmission_chain[0]` | `source.add_ammo(ammo_amount)` |
| `DealDamageSelfSpeedBoostEffect` | `BulletEffect` | `deal_damage_self_speed_boost_effect.gd` | `on_deal_damage` | `transmission_chain[0]` | `source.apply_speed_boost(duration)` |

### Parameters (all `@export`)

- `CdReduce` effects: `reduction: float = 0.5`
- `Replenish` effects: `ammo_amount: int = 1` (set to 2 in the ×2 module .tres)
- `SpeedBoost` effects: `duration: float = 1.0`

---

## Part 3: New Module .tres Files

Directory: `resources/module_data/`

9 new files to fill matrix gaps. Replenish ×1 and ×2 share the same effect class — only `ammo_amount` differs.

| File | Module name | Effect class | ammo_amount | Slot color |
|------|------------|--------------|-------------|------------|
| `hit_enemy_replenish1.tres` | 击敌补1弹 | `HitEnemySelfReplenishEffect` | 1 | Green `Color(0.2, 0.85, 0.45, 1)` |
| `hit_enemy_replenish2.tres` | 击敌补2弹 | `HitEnemySelfReplenishEffect` | 2 | Teal `Color(0.1, 0.65, 0.95, 1)` |
| `hit_enemy_speed_boost.tres` | 击敌加速 | `HitEnemySelfSpeedBoostEffect` | — | Yellow `Color(1, 0.85, 0.1, 1)` |
| `receive_hit_replenish1.tres` | 受击补1弹 | `ReceiveHitSelfReplenishEffect` | 1 | Green `Color(0.2, 0.85, 0.45, 1)` |
| `receive_hit_replenish2.tres` | 受击补2弹 | `ReceiveHitSelfReplenishEffect` | 2 | Teal `Color(0.1, 0.65, 0.95, 1)` |
| `receive_hit_speed_boost.tres` | 受击加速 | `ReceiveHitSelfSpeedBoostEffect` | — | Yellow `Color(1, 0.85, 0.1, 1)` |
| `deal_damage_cd_reduce.tres` | 伤害减CD | `DealDamageSelfCdReduceEffect` | — | Pink `Color(1, 0.4, 0.8, 1)` |
| `deal_damage_replenish1.tres` | 伤害补1弹 | `DealDamageSelfReplenishEffect` | 1 | Green `Color(0.2, 0.85, 0.45, 1)` |
| `deal_damage_speed_boost.tres` | 伤害加速 | `DealDamageSelfSpeedBoostEffect` | — | Yellow `Color(1, 0.85, 0.1, 1)` |

> Note: `deal_damage_replenish2` is intentionally omitted — "deal damage + replenish 2 ammo" is powerful enough that it should only be added if gameplay requires it.

All new modules are **LOGICAL** category (`category = 1`).

---

## Part 4: PixelLab Icon Generation

### Tool

`mcp__pixellab__create_map_object` — 32×32 px, `side` view, transparent background, `flat shading`, `single color outline`.

### Output Directory

`assets/modules/` (new directory, separate from existing SVG assets)

### Generation Plan

14 icons total, generated in batches. Each icon gets a dedicated prompt:

| Module | File name | Prompt |
|--------|-----------|--------|
| 加速器 | `accelerator.png` | pixel art bullet with speed lines, small, icon |
| 乘法器 | `multiplier.png` | pixel art multiply symbol glowing, small icon |
| 加速射击 | `rate_boost.png` | pixel art clock with lightning bolt, small icon |
| 重弹头 | `heavy_ammo.png` | pixel art heavy cannonball with skull, small icon |
| 击敌减CD | `cd_hit_enemy.png` | pixel art bullet hitting target with clock, small icon |
| 连接自减CD | `cd_hit_tower_self.png` | pixel art two towers with arrow looping back, clock, small icon |
| 连接减CD | `cd_hit_tower_target.png` | pixel art bullet hitting tower with clock boost, small icon |
| 受击减CD | `cd_receive_hit.png` | pixel art shield absorbing hit with clock, small icon |
| 补充+1 | `replenish1.png` | pixel art ammo crate with +1 label, small icon |
| 补充+2 | `replenish2.png` | pixel art ammo crate with +2 label, small icon |
| 击杀加速 | `kill_speed_boost.png` | pixel art skull with lightning, small icon |
| 击中加速 | `hit_speed_boost.png` | pixel art bullet collision with speed flash, small icon |
| 飞行器 | `flying.png` | pixel art wings or jet pack, small icon |
| 防空炮 | `anti_air.png` | pixel art radar dish or anti-air cannon barrel, small icon |

### .tres Update

After generation, update each module `.tres` to replace old SVG `ext_resource` with the new PNG path under `assets/modules/`.

---

## Updated Effect Matrix (target state)

| 触发时机 | 减0.5s CD | 补充1弹药 | 补充2弹药 | 恢复速度提升1s |
|---------|:---------:|:--------:|:--------:|:------------:|
| **击中炮塔时** | ✅ HitTowerSelfCdReduceEffect<br>✅ HitTowerTargetCdReduceEffect | ✅ HitTowerTargetReplenishEffect(×1) | ✅ HitTowerTargetReplenishEffect(×2) | ✅ HitTowerTargetSpeedBoostEffect |
| **击中敌人时** | ✅ HitEnemySelfCdReduceEffect | ✅ HitEnemySelfReplenishEffect(×1) | ✅ HitEnemySelfReplenishEffect(×2) | ✅ HitEnemySelfSpeedBoostEffect |
| **被击中时** | ✅ ReceiveHitSelfCdReduceEffect | ✅ ReceiveHitSelfReplenishEffect(×1) | ✅ ReceiveHitSelfReplenishEffect(×2) | ✅ ReceiveHitSelfSpeedBoostEffect |
| **造成伤害时** | ✅ DealDamageSelfCdReduceEffect | ✅ DealDamageSelfReplenishEffect(×1) | ❌ (deferred) | ✅ DealDamageSelfSpeedBoostEffect |

---

## Docs Updates

- `docs/content/effects.md` — update Concrete Effect Implementations table with new names + new classes
- `docs/content/modules.md` — add 9 new module entries; update class names in existing entries
- `docs/content/effect-matrix.md` — replace entirely with updated matrix above
- `docs/DOC_INDEX.md` — no change needed

---

## Out of Scope

- Tests for new effect classes (can follow the existing pattern in `ModuleBehaviorTest.gd` in a separate task)
- `deal_damage_replenish2.tres` (deferred, see note above)
- Replacing tower/enemy/bullet SVG assets with pixel art
