# Modules — Game Content Knowledge Base

> Agent guidance: This file is the authoritative spec for all module resources.
> Tests verify behavior against this spec. When adding a new module:
> (1) create the .tres, (2) add an entry below, (3) add tests to the appropriate
> test file (ModuleStatTest, ModuleBehaviorTest, or ModuleSpecialTest).

## Categories

| Enum value | Name | Description |
|-----------|------|-------------|
| 0 | COMPUTATIONAL | Passive stat modifiers (no trigger logic) |
| 1 | LOGICAL | Trigger-based effects (react to game events) |
| 2 | SPECIAL | Structural changes to tower behavior |

## Stat System Reference

`TowerStatModifierRes.Stat` enum:

| Value | Name | MockTower base |
|-------|------|---------------|
| 0 | CD | `1.0 / firing_rate` (default: 1.0) |
| 1 | BULLET_SPEED | 200.0 |
| 2 | BULLET_ATTACK | 1.0 |
| 3 | AMMO_EXTRA | 0.0 |

`get_value()` formula: `(base + Σ ADDITIVE) × Π MULTIPLICATIVE`

---

## COMPUTATIONAL Modules (stat modifiers only, no trigger effects)

### accelerator — 加速器
- **File:** `resources/module_data/accelerator.tres`
- **Slot color:** Cyan `Color(0.1, 0.9, 1, 1)`
- **Stat modifier:** `BULLET_SPEED` +150 (ADDITIVE)
- **Expected after install:** `get_stat(BULLET_SPEED).get_value()` = **350.0** (base 200 + 150)
- **Rollback:** returns to 200.0 after uninstall
- **Test:** `ModuleStatTest.test_accelerator_*`

### multiplier — 乘法器
- **File:** `resources/module_data/multiplier.tres`
- **Slot color:** Orange `Color(1, 0.6, 0.1, 1)`
- **Stat modifier:** `BULLET_ATTACK` ×1.2 (MULTIPLICATIVE)
- **Expected after install:** `get_stat(BULLET_ATTACK).get_value()` = **1.2**
- **Rollback:** returns to 1.0 after uninstall
- **Test:** `ModuleStatTest.test_multiplier_*`

### rate_boost — 加速射击
- **File:** `resources/module_data/rate_boost.tres`
- **Slot color:** Orange-red `Color(1, 0.35, 0.1, 1)`
- **Stat modifier:** `CD` -0.3 (ADDITIVE)
- **Expected after install:** with default MockTower (firing_rate=1.0, base CD=1.0): **0.7**
- **Rollback:** returns to 1.0 after uninstall
- **Test:** `ModuleStatTest.test_rate_boost_*`

### heavy_ammo — 重弹头
- **File:** `resources/module_data/heavy_ammo.tres`
- **Slot color:** Dark red `Color(0.8, 0.2, 0.2, 1)`
- **Stat modifiers (2):**
  - `BULLET_ATTACK` ×1.8 (MULTIPLICATIVE) → `get_stat(BULLET_ATTACK).get_value()` = **1.8** ✅
  - `AMMO_EXTRA` +1.0 (ADDITIVE) → `get_stat(AMMO_EXTRA).get_value()` = **1.0**
- **Known bug (fixed):** .tres originally stored `stat = 4` for AMMO_EXTRA; correct value is `stat = 3`
- **Rollback:** both stats return to baseline after uninstall
- **Test:** `ModuleStatTest.test_heavy_ammo_*`

---

## LOGICAL Modules (trigger-based effects)

### cd_on_hit_enemy — 击敌减CD
- **File:** `resources/module_data/cd_on_hit_enemy.tres`
- **Slot color:** Yellow `Color(1, 0.8, 0.1, 1)`
- **Effect type:** `BulletEffect` → `CdReduceOnEnemyEffect`
- **Trigger:** `on_hit_enemy(bullet_data, enemy)`
- **Target:** `bullet_data.transmission_chain[0]` (source tower)
- **Action:** `source.reduce_cooldown(0.5)`
- **Expected:** `source.reduce_cooldown_calls[-1] == 0.5`; target unaffected
- **Test:** `FullChainTest.test_cd_reduce_on_enemy_full_chain` ✅ (pre-existing)

### cd_on_hit_tower_self — 连接自减CD
- **File:** `resources/module_data/cd_on_hit_tower_self.tres`
- **Slot color:** Light blue `Color(0.3, 0.8, 1, 1)`
- **Effect type:** `BulletEffect` → `CdReduceOnHitTowerEffect`
- **Trigger:** `on_hit_tower(bullet_data, hit_tower)`
- **Target:** `bullet_data.transmission_chain[0]` (SOURCE tower gets CD reduction, not the hit tower)
- **Action:** `source.reduce_cooldown(0.5)`
- **Expected:** `source.reduce_cooldown_calls[-1] == 0.5`; hit_tower.reduce_cooldown_calls is empty
- **Test:** `ModuleBehaviorTest.test_cd_on_hit_tower_self_*`

### cd_on_hit_tower_target — 连接减CD
- **File:** `resources/module_data/cd_on_hit_tower_target.tres`
- **Slot color:** Purple `Color(0.5, 0.3, 1, 1)`
- **Effect type:** `BulletEffect` → `CdReduceTargetTowerEffect`
- **Trigger:** `on_hit_tower(bullet_data, hit_tower)`
- **Target:** `hit_tower` (TARGET tower gets CD reduction, not the source)
- **Action:** `hit_tower.reduce_cooldown(0.5)`
- **Expected:** `target.reduce_cooldown_calls[-1] == 0.5`; source.reduce_cooldown_calls is empty
- **Test:** `ModuleBehaviorTest.test_cd_on_hit_tower_target_*`

### cd_on_receive_hit — 受击减CD
- **File:** `resources/module_data/cd_on_receive_hit.tres`
- **Slot color:** Pink `Color(1, 0.4, 0.8, 1)`
- **Effect type:** `TowerEffect` → `CdReduceOnReceiveTowerEffect`
- **Trigger:** `on_receive_bullet_hit(bullet_data, tower)` — called on the RECEIVING tower
- **Action:** `tower.reduce_cooldown(0.5)`
- **Expected:** `tower.reduce_cooldown_calls[-1] == 0.5`
- **Test:** `ModuleBehaviorTest.test_cd_on_receive_hit_*`

### replenish1 — 补充+1
- **File:** `resources/module_data/replenish1.tres`
- **Slot color:** Green `Color(0.2, 0.85, 0.45, 1)`
- **Effect type:** `BulletEffect` → `ReplenishEffect`
- **Trigger:** `on_hit_tower(bullet_data, hit_tower)`
- **Action:** `hit_tower.add_ammo(1)`
- **Expected:** `target.ammo == initial + 1`; no effect on source
- **Test:** `FullChainTest.test_replenish_effect_full_chain` ✅ (pre-existing)

### replenish2 — 补充+2
- **File:** `resources/module_data/replenish2.tres`
- **Slot color:** Teal-blue `Color(0.1, 0.65, 0.95, 1)`
- **Effect type:** `BulletEffect` → `ReplenishEffect`
- **Trigger:** `on_hit_tower(bullet_data, hit_tower)`
- **Action:** `hit_tower.add_ammo(2)`
- **Expected:** `target.ammo == initial + 2`; infinite-ammo tower (`ammo == -1`) unaffected
- **Test:** `ModuleBehaviorTest.test_replenish2_*`

### speed_boost — 击杀加速
- **File:** `resources/module_data/speed_boost.tres`
- **Slot color:** Orange-red `Color(1, 0.4, 0.1, 1)`
- **Effect type:** `BulletEffect` → `KillBoostEffect`
- **Trigger:** `on_killed_enemy(bullet_data, enemy)`
- **Target:** `bullet_data.transmission_chain[0]` (source tower)
- **Action:** `source.apply_speed_boost(1.0)`
- **Expected:** `source.speed_boost_calls[-1] == 1.0`
- **Test:** `ModuleBehaviorTest.test_speed_boost_*`

### hit_speed_boost — 击中加速
- **File:** `resources/module_data/hit_speed_boost.tres`
- **Slot color:** Yellow `Color(1, 0.85, 0.1, 1)`
- **Effect type:** `BulletEffect` → `HitSpeedBoostEffect`
- **Trigger:** `on_hit_tower(bullet_data, hit_tower)`
- **Target:** `hit_tower` (TARGET tower gets boosted, not source)
- **Action:** `hit_tower.apply_speed_boost(1.0)`
- **Expected:** `target.speed_boost_calls[-1] == 1.0`; source.speed_boost_calls is empty
- **Test:** `ModuleBehaviorTest.test_hit_speed_boost_*`

---

## SPECIAL Modules (structural tower state changes)

### flying — 飞行器
- **File:** `resources/module_data/flying.tres`
- **Script:** `FlyingModule extends Module`
- **Slot color:** Sky blue `Color(0.4, 0.8, 1, 1)`
- **On install:** `tower.is_flying = true`; scales `tower.sprite` by ×1.5; starts bob/rot animations (skipped if no scene tree)
- **On uninstall:** `tower.is_flying = false`; restores `tower.sprite.scale`; stops animations
- **MockTower note:** Requires `var sprite: Node2D` property; animations gracefully skip (no "TowerVisual/Sprite2D" child)
- **Test:** `ModuleSpecialTest.test_flying_*`

### anti_air — 防空炮
- **File:** `resources/module_data/anti_air.tres`
- **Script:** `AntiAirModule extends Module`
- **Slot color:** Yellow `Color(1, 0.9, 0.2, 1)`
- **On install:** `tower.has_anti_air = true`
- **On uninstall:** `tower.has_anti_air = false`
- **Test:** `ModuleSpecialTest.test_anti_air_*`
