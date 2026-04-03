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

| Class | File | Trigger method | What it calls |
|-------|------|---------------|---------------|
| `CdReduceOnEnemyEffect` | `bullet_effects/cd_reduce_on_enemy_effect.gd` | `on_hit_enemy` | `source.reduce_cooldown(reduction)` |
| `CdReduceOnHitTowerEffect` | `bullet_effects/cd_reduce_on_hit_tower_effect.gd` | `on_hit_tower` | `source.reduce_cooldown(reduction)` |
| `CdReduceTargetTowerEffect` | `bullet_effects/cd_reduce_target_tower_effect.gd` | `on_hit_tower` | `hit_tower.reduce_cooldown(reduction)` |
| `CdReduceOnReceiveTowerEffect` | `tower_effects/cd_reduce_on_receive_tower_effect.gd` | `on_receive_bullet_hit` | `tower.reduce_cooldown(reduction)` |
| `ReplenishEffect` | `bullet_effects/replenish_effect.gd` | `on_hit_tower` | `tower.add_ammo(ammo_amount)` |
| `HitSpeedBoostEffect` | `bullet_effects/hit_speed_boost_effect.gd` | `on_hit_tower` | `hit_tower.apply_speed_boost(duration)` |
| `KillBoostEffect` | `bullet_effects/kill_boost_effect.gd` | `on_killed_enemy` | `source.apply_speed_boost(boost_duration)` |

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
