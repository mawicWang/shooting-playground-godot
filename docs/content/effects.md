# Effects — Game Content Knowledge Base

> Agent guidance: This file documents the effect system interfaces.
> Use this when writing new effects or new tests.
> Effect classes live in `entities/effects/`.

## Effect Base Classes

All effects are `Resource` subclasses. Modules store them in typed arrays;
`Module.on_install` appends them to the tower's matching array.

| Base class | Tower array | Triggered by |
|-----------|-------------|--------------|
| `BulletEffect` | `tower.bullet_effects` | Bullet collision callbacks |
| `FireEffect` | `tower.fire_effects` | Each time the tower fires |
| `TowerEffect` | `tower.tower_effects` | Events on the tower itself |

---

## BulletEffect Interface

File: `entities/effects/bullet_effects/bullet_effect.gd`

Override one or more callbacks; default implementations are no-ops:

```gdscript
func on_hit_tower(bullet_data: BulletData, tower: Node) -> void
func on_hit_enemy(bullet_data: BulletData, enemy: Node) -> void
func on_deal_damage(bullet_data: BulletData, target: Node, damage: float) -> void
func on_killed_enemy(bullet_data: BulletData, enemy: Node) -> void
```

**Accessing the source tower:** `bullet_data.transmission_chain[0]`
Always guard: `if bullet_data.transmission_chain.is_empty(): return`

---

## TowerEffect Interface

File: `entities/effects/tower_effects/tower_effect.gd`

```gdscript
func on_receive_bullet_hit(bullet_data: BulletData, tower: Node) -> void
```

---

## FireEffect Interface

File: `entities/effects/fire_effects/fire_effect.gd`

```gdscript
func apply(tower: Node, bd: BulletData) -> void
```

---

## Concrete Effect Implementations

Naming convention: `{Trigger}{Target}{Effect}Effect`
- **Trigger**: `HitTower`, `HitEnemy`, `KillEnemy`, `ReceiveHit`, `DealDamage`
- **Target**: `Self` = source tower (`transmission_chain[0]`) or self (TowerEffect); `Target` = the hit tower
- **Effect**: `CdReduce`, `Replenish`, `SpeedBoost`

| Class | File | Trigger method | What it calls |
|-------|------|---------------|---------------|
| `HitTowerSelfCdReduceEffect` | `bullet_effects/hit_tower_self_cd_reduce_effect.gd` | `on_hit_tower` | `source.reduce_cooldown(reduction)` |
| `HitTowerTargetCdReduceEffect` | `bullet_effects/hit_tower_target_cd_reduce_effect.gd` | `on_hit_tower` | `hit_tower.reduce_cooldown(reduction)` |
| `HitTowerTargetReplenishEffect` | `bullet_effects/hit_tower_target_replenish_effect.gd` | `on_hit_tower` | `tower.add_ammo(ammo_amount)` |
| `HitTowerTargetSpeedBoostEffect` | `bullet_effects/hit_tower_target_speed_boost_effect.gd` | `on_hit_tower` | `hit_tower.apply_speed_boost(duration)` |
| `HitEnemySelfCdReduceEffect` | `bullet_effects/hit_enemy_self_cd_reduce_effect.gd` | `on_hit_enemy` | `source.reduce_cooldown(reduction)` |
| `HitEnemySelfReplenishEffect` | `bullet_effects/hit_enemy_self_replenish_effect.gd` | `on_hit_enemy` | `source.add_ammo(ammo_amount)` |
| `HitEnemySelfSpeedBoostEffect` | `bullet_effects/hit_enemy_self_speed_boost_effect.gd` | `on_hit_enemy` | `source.apply_speed_boost(duration)` |
| `KillEnemySelfSpeedBoostEffect` | `bullet_effects/kill_enemy_self_speed_boost_effect.gd` | `on_killed_enemy` | `source.apply_speed_boost(boost_duration)` |
| `ReceiveHitSelfCdReduceEffect` | `tower_effects/receive_hit_self_cd_reduce_effect.gd` | `on_receive_bullet_hit` | `tower.reduce_cooldown(reduction)` |
| `ReceiveHitSelfReplenishEffect` | `tower_effects/receive_hit_self_replenish_effect.gd` | `on_receive_bullet_hit` | `tower.add_ammo(ammo_amount)` |
| `ReceiveHitSelfSpeedBoostEffect` | `tower_effects/receive_hit_self_speed_boost_effect.gd` | `on_receive_bullet_hit` | `tower.apply_speed_boost(duration)` |
| `DealDamageSelfCdReduceEffect` | `bullet_effects/deal_damage_self_cd_reduce_effect.gd` | `on_deal_damage` | `source.reduce_cooldown(reduction)` |
| `DealDamageSelfReplenishEffect` | `bullet_effects/deal_damage_self_replenish_effect.gd` | `on_deal_damage` | `source.add_ammo(ammo_amount)` |
| `DealDamageSelfSpeedBoostEffect` | `bullet_effects/deal_damage_self_speed_boost_effect.gd` | `on_deal_damage` | `source.apply_speed_boost(duration)` |

---

## MockTower Interface (for tests)

File: `tests/mock_tower.gd`

MockTower exposes all methods effects call, without autoload dependencies:

| Method | Behavior in mock |
|--------|-----------------|
| `reduce_cooldown(amount)` | Appends to `reduce_cooldown_calls: Array` |
| `add_ammo(amount)` | Increments `ammo` and `ammo_added`; no-op if `ammo == -1` |
| `apply_speed_boost(duration)` | Appends to `speed_boost_calls: Array` |
| `get_stat(stat)` | Returns real `StatAttribute` (modifiers actually apply) |

---

## Adding New Effects

1. Create `entities/effects/<category>/<ClassName>.gd` extending the appropriate base
2. Create a sub_resource referencing it in the relevant module's `.tres`
3. Document in `docs/content/modules.md` under the module entry
4. Add test in the appropriate `tests/gdunit/Module*Test.gd`

**Which test file?**

| Module category | Test file |
|----------------|-----------|
| COMPUTATIONAL (stat mod only) | `ModuleStatTest.gd` |
| LOGICAL (BulletEffect or TowerEffect) | `ModuleBehaviorTest.gd` |
| SPECIAL (custom `on_install`/`on_uninstall`) | `ModuleSpecialTest.gd` |
