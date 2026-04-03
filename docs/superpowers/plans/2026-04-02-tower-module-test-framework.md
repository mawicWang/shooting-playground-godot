# Tower/Module Test Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete regression test framework covering all towers and modules, plus a Claude-readable knowledge base that stays in sync.

**Architecture:** Three layers — (1) docs/content/ knowledge base as the authoritative spec, (2) TowerDataTest auto-scans all tower .tres for invariants, (3) Module behavior tests verify actual final-state outcomes using MockTower (stat values, ammo counts, cooldown call values, speed boost records).

**Tech Stack:** GdUnit4, GDScript, Godot 4.4+, MockTower (tests/mock_tower.gd)

---

## Pre-read: existing coverage (do NOT re-test these)

| What | Where |
|------|-------|
| `cd_on_hit_enemy` + CD actually decreases | `FullChainTest.test_cd_reduce_on_enemy_full_chain` |
| `replenish1` + ammo actually increases | `FullChainTest.test_replenish_effect_full_chain` |
| `accelerator` stat + rollback on uninstall | `FullChainTest.test_module_install_adds_stat_modifiers` + `test_effect_cleanup_on_module_uninstall` |
| Effect install/uninstall array housekeeping | `EffectTriggerTest.test_effect_install_uninstall` |

---

## Known data issue: heavy_ammo.tres stat=4

`heavy_ammo.tres` has `stat = 4` for the AMMO_EXTRA modifier, but `TowerStatModifierRes.Stat` only defines values 0–3 (CD=0, BULLET_SPEED=1, BULLET_ATTACK=2, AMMO_EXTRA=3). `Module.on_install` silently skips unknown stats. Result: heavy_ammo's "发射额外消耗 1 弹药" effect never applies in-game. Task 6 includes a fix.

---

## File Map

| Action | Path |
|--------|------|
| Create | `docs/content/towers.md` |
| Create | `docs/content/modules.md` |
| Create | `docs/content/effects.md` |
| Modify | `tests/mock_tower.gd` |
| Create | `tests/gdunit/TowerDataTest.gd` |
| Create | `tests/gdunit/ModuleStatTest.gd` |
| Create | `tests/gdunit/ModuleBehaviorTest.gd` |
| Create | `tests/gdunit/ModuleSpecialTest.gd` |
| Fix    | `resources/module_data/heavy_ammo.tres` |

---

## Task 1: Create towers.md knowledge base

**Files:**
- Create: `docs/content/towers.md`

- [ ] **Step 1: Write towers.md**

```markdown
# Towers — Game Content Knowledge Base

> Agent guidance: This file is the authoritative spec for all tower resources.
> Tests in `tests/gdunit/TowerDataTest.gd` verify every tower against this spec.
> When adding a new tower: (1) create the .tres, (2) add a row to the table below,
> (3) add a `test_tower_<name>` function in TowerDataTest.gd.

## Quick Reference

| File | 名称 | firing_rate | 炮管数 | barrel_directions | initial_ammo |
|------|------|------------|--------|-------------------|-------------|
| `tower1010.tres` | 双向炮 | 1.0 | 2 | (0,-1), (0,1) | 10 |
| `tower1100.tres` | 直角炮 | 1.0 | 2 | (0,-1), (1,0) | 3 |
| `tower1110.tres` | 三向炮 | 1.0 | 3 | (0,-1), (1,0), (0,1) | 3 |
| `tower1111.tres` | 四向炮 | 1.0 | 4 | (0,-1), (1,0), (0,1), (-1,0) | 0 |

## Invariants (enforced by TowerDataTest)

Every tower .tres in `res://resources/` matching `tower*.tres` must satisfy:
- `tower_name` is non-empty string
- `sprite` is not null
- `icon` is not null
- `firing_rate > 0`
- `barrel_directions.size() >= 1`
- `initial_ammo >= -1` (-1 = infinite, 0 = starts empty, positive = count)

## Notes

- `tower1111` 四向炮 starts with `initial_ammo = 0` — intentional, needs ammo modules to function
- Barrel directions are local-space unit vectors; naming scheme = binary flags for Up/Right/Down/Left (1=active)
- All current towers share `firing_rate = 1.0`
```

- [ ] **Step 2: Commit**

```bash
git add docs/content/towers.md
git commit -m "docs: add towers knowledge base"
```

---

## Task 2: Create modules.md knowledge base

**Files:**
- Create: `docs/content/modules.md`

- [ ] **Step 1: Write modules.md**

```markdown
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

---

## COMPUTATIONAL Modules (stat modifiers only)

### accelerator — 加速器
- **File:** `resources/module_data/accelerator.tres`
- **Slot color:** Cyan `Color(0.1, 0.9, 1, 1)`
- **Stat change:** `BULLET_SPEED` +150 (ADDITIVE)
- **Expected:** `get_stat(BULLET_SPEED).get_value()` increases by 150.0 after install
- **Rollback:** stat returns to baseline after uninstall
- **No effects:** fire_effects=[], bullet_effects=[], tower_effects=[]

### multiplier — 乘法器
- **File:** `resources/module_data/multiplier.tres`
- **Slot color:** Orange `Color(1, 0.6, 0.1, 1)`
- **Stat change:** `BULLET_ATTACK` ×1.2 (MULTIPLICATIVE)
- **Expected:** `get_stat(BULLET_ATTACK).get_value()` = 1.0 × 1.2 = **1.2** after install
- **Rollback:** stat returns to 1.0 after uninstall
- **No effects**

### rate_boost — 加速射击
- **File:** `resources/module_data/rate_boost.tres`
- **Slot color:** Orange-red `Color(1, 0.35, 0.1, 1)`
- **Stat change:** `CD` -0.3 (ADDITIVE)
- **Expected:** with default MockTower (firing_rate=1.0, base CD=1.0): `get_stat(CD).get_value()` = **0.7** after install
- **Rollback:** stat returns to 1.0 after uninstall
- **No effects**

### heavy_ammo — 重弹头
- **File:** `resources/module_data/heavy_ammo.tres`
- **Slot color:** Dark red `Color(0.8, 0.2, 0.2, 1)`
- **Stat changes (2 modifiers):**
  - `BULLET_ATTACK` ×1.8 (MULTIPLICATIVE) — `get_stat(BULLET_ATTACK).get_value()` = **1.8** after install ✅
  - `AMMO_EXTRA` +1.0 (ADDITIVE) — **known bug:** .tres stores `stat = 4` but enum only defines 0–3; this modifier is silently ignored (see `heavy_ammo.tres` fix in plan)
- **No effects**

---

## LOGICAL Modules (trigger-based effects)

### cd_on_hit_enemy — 击敌减CD
- **File:** `resources/module_data/cd_on_hit_enemy.tres`
- **Slot color:** Yellow `Color(1, 0.8, 0.1, 1)`
- **Trigger:** `BulletEffect.on_hit_enemy(bullet_data, enemy)`
- **Effect:** calls `source_tower.reduce_cooldown(0.5)` where source = `bullet_data.transmission_chain[0]`
- **Expected:** `source.reduce_cooldown_calls[-1] == 0.5`
- **Covered by:** `FullChainTest.test_cd_reduce_on_enemy_full_chain` ✅

### cd_on_hit_tower_self — 连接自减CD
- **File:** `resources/module_data/cd_on_hit_tower_self.tres`
- **Slot color:** Light blue `Color(0.3, 0.8, 1, 1)`
- **Trigger:** `BulletEffect.on_hit_tower(bullet_data, hit_tower)`
- **Effect:** calls `source_tower.reduce_cooldown(0.5)` (source = `transmission_chain[0]`, NOT the hit tower)
- **Expected:** `source.reduce_cooldown_calls[-1] == 0.5`; `target.reduce_cooldown_calls` is empty

### cd_on_hit_tower_target — 连接减CD
- **File:** `resources/module_data/cd_on_hit_tower_target.tres`
- **Slot color:** Purple `Color(0.5, 0.3, 1, 1)`
- **Trigger:** `BulletEffect.on_hit_tower(bullet_data, hit_tower)`
- **Effect:** calls `hit_tower.reduce_cooldown(0.5)` (target receives CD reduction, NOT source)
- **Expected:** `target.reduce_cooldown_calls[-1] == 0.5`; `source.reduce_cooldown_calls` is empty

### cd_on_receive_hit — 受击减CD
- **File:** `resources/module_data/cd_on_receive_hit.tres`
- **Slot color:** Pink `Color(1, 0.4, 0.8, 1)`
- **Trigger:** `TowerEffect.on_receive_bullet_hit(bullet_data, tower)` — triggered on the RECEIVING tower
- **Effect:** calls `tower.reduce_cooldown(0.5)`
- **Expected:** `tower.reduce_cooldown_calls[-1] == 0.5`

### replenish1 — 补充+1
- **File:** `resources/module_data/replenish1.tres`
- **Slot color:** Green `Color(0.2, 0.85, 0.45, 1)`
- **Trigger:** `BulletEffect.on_hit_tower(bullet_data, hit_tower)`
- **Effect:** calls `hit_tower.add_ammo(1)` → `hit_tower.ammo += 1`
- **Expected:** `target.ammo == initial + 1`
- **Covered by:** `FullChainTest.test_replenish_effect_full_chain` ✅

### replenish2 — 补充+2
- **File:** `resources/module_data/replenish2.tres`
- **Slot color:** Teal-blue `Color(0.1, 0.65, 0.95, 1)`
- **Trigger:** `BulletEffect.on_hit_tower(bullet_data, hit_tower)`
- **Effect:** calls `hit_tower.add_ammo(2)` → `hit_tower.ammo += 2`
- **Expected:** `target.ammo == initial + 2`

### speed_boost — 击杀加速
- **File:** `resources/module_data/speed_boost.tres`
- **Slot color:** Orange-red `Color(1, 0.4, 0.1, 1)`
- **Trigger:** `BulletEffect.on_killed_enemy(bullet_data, enemy)`
- **Effect:** calls `source_tower.apply_speed_boost(1.0)` where source = `transmission_chain[0]`
- **Expected:** `source.speed_boost_calls[-1] == 1.0`

### hit_speed_boost — 击中加速
- **File:** `resources/module_data/hit_speed_boost.tres`
- **Slot color:** Yellow `Color(1, 0.85, 0.1, 1)`
- **Trigger:** `BulletEffect.on_hit_tower(bullet_data, hit_tower)`
- **Effect:** calls `hit_tower.apply_speed_boost(1.0)` (TARGET tower gets boosted, not source)
- **Expected:** `target.speed_boost_calls[-1] == 1.0`; source is unaffected

---

## SPECIAL Modules (structural tower state changes)

### flying — 飞行器
- **File:** `resources/module_data/flying.tres`
- **Slot color:** Sky blue `Color(0.4, 0.8, 1, 1)`
- **Script:** `FlyingModule` (extends Module)
- **On install:** sets `tower.is_flying = true`; starts visual bob/rot animations (uses `tower.sprite` and scene-tree tweens; both gracefully no-op if not in scene)
- **On uninstall:** sets `tower.is_flying = false`; stops animations; restores `tower.sprite.scale`
- **Test note:** MockTower must have a `sprite: Node2D` property for scale access; animations are skipped (no scene tree)

### anti_air — 防空炮
- **File:** `resources/module_data/anti_air.tres`
- **Slot color:** Yellow `Color(1, 0.9, 0.2, 1)`
- **Script:** `AntiAirModule` (extends Module)
- **On install:** sets `tower.has_anti_air = true`
- **On uninstall:** sets `tower.has_anti_air = false`
```

- [ ] **Step 2: Commit**

```bash
git add docs/content/modules.md
git commit -m "docs: add modules knowledge base"
```

---

## Task 3: Create effects.md knowledge base

**Files:**
- Create: `docs/content/effects.md`

- [ ] **Step 1: Write effects.md**

```markdown
# Effects — Game Content Knowledge Base

> Agent guidance: This file documents the effect system interfaces.
> Use this when writing new effects or new tests.

## Effect Base Classes

All effects are `Resource` subclasses. Modules store them in typed arrays;
`Module.on_install` appends them to the tower's matching array.

| Base class | Tower array | Triggered by |
|-----------|-------------|--------------|
| `BulletEffect` | `tower.bullet_effects` | Bullet collision callbacks |
| `FireEffect` | `tower.fire_effects` | Each time the tower fires |
| `TowerEffect` | `tower.tower_effects` | Events on the tower itself |

## BulletEffect Callbacks

Override one or more; default implementations are no-ops:

```gdscript
func on_hit_tower(bullet_data: BulletData, tower: Node) -> void
func on_hit_enemy(bullet_data: BulletData, enemy: Node) -> void
func on_deal_damage(bullet_data: BulletData, target: Node, damage: float) -> void
func on_killed_enemy(bullet_data: BulletData, enemy: Node) -> void
```

**Access source tower:** `bullet_data.transmission_chain[0]` (always guard with `is_empty()` check first)

## TowerEffect Callbacks

```gdscript
func on_receive_bullet_hit(bullet_data: BulletData, tower: Node) -> void
```

## FireEffect Callbacks

```gdscript
func apply(tower: Node, bd: BulletData) -> void
```

## Concrete Effect Classes (current)

| Class | Trigger | What it calls |
|-------|---------|---------------|
| `CdReduceOnEnemyEffect` | `on_hit_enemy` | `source.reduce_cooldown(reduction)` |
| `CdReduceOnHitTowerEffect` | `on_hit_tower` | `source.reduce_cooldown(reduction)` |
| `CdReduceTargetTowerEffect` | `on_hit_tower` | `hit_tower.reduce_cooldown(reduction)` |
| `CdReduceOnReceiveTowerEffect` | `on_receive_bullet_hit` | `tower.reduce_cooldown(reduction)` |
| `ReplenishEffect` | `on_hit_tower` | `tower.add_ammo(ammo_amount)` |
| `HitSpeedBoostEffect` | `on_hit_tower` | `hit_tower.apply_speed_boost(duration)` |
| `KillBoostEffect` | `on_killed_enemy` | `source.apply_speed_boost(boost_duration)` |

## Adding New Effects

1. Create `entities/effects/<category>/<class_name>.gd` extending the appropriate base
2. Add a `.tres` resource instance under `resources/module_data/` referencing the effect
3. Document in `docs/content/modules.md`
4. Add test in the appropriate `tests/gdunit/Module*Test.gd`
```

- [ ] **Step 2: Commit**

```bash
git add docs/content/effects.md
git commit -m "docs: add effects knowledge base"
```

---

## Task 4: Update MockTower

**Files:**
- Modify: `tests/mock_tower.gd`

MockTower needs two additions for uncovered modules:
- `var sprite: Node2D` — `FlyingModule.on_install` accesses `tower.sprite.scale`
- `apply_speed_boost(duration)` + `speed_boost_calls` — for `KillBoostEffect` and `HitSpeedBoostEffect`

- [ ] **Step 1: Add sprite property**

In `tests/mock_tower.gd`, after `var has_anti_air: bool = false` (line 27), add:

```gdscript
## Dummy sprite node so FlyingModule can access .scale without crashing
var sprite: Node2D = Node2D.new()
```

- [ ] **Step 2: Add speed_boost tracking**

After `var reduce_cooldown_calls: Array = []` (line 33), add:

```gdscript
var speed_boost_calls: Array = []    # 记录 apply_speed_boost 调用
```

- [ ] **Step 3: Add apply_speed_boost method**

After the `reduce_cooldown` method (after line 127), add:

```gdscript
func apply_speed_boost(duration: float) -> void:
	speed_boost_calls.append(duration)
```

- [ ] **Step 4: Verify MockTower loads correctly**

Open Godot editor, let it reimport, check the Script tab for `tests/mock_tower.gd` shows no errors.

- [ ] **Step 5: Commit**

```bash
git add tests/mock_tower.gd
git commit -m "test: add sprite and apply_speed_boost to MockTower"
```

---

## Task 5: Create TowerDataTest.gd

**Files:**
- Create: `tests/gdunit/TowerDataTest.gd`

- [ ] **Step 1: Write TowerDataTest.gd**

```gdscript
# GdUnit4 — Tower Data Contract Tests
# 验证所有 tower .tres 满足基本字段契约，并验证每个塔的具体期望值
# 知识库参考：docs/content/towers.md

class_name TowerDataTest
extends GdUnitTestSuite

const TOWER_DIR := "res://resources/"


## 自动扫描 res://resources/ 中所有 tower*.tres 文件
func _get_tower_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(TOWER_DIR)
	if not dir:
		return paths
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("tower") and fname.ends_with(".tres"):
			paths.append(TOWER_DIR + fname)
		fname = dir.get_next()
	dir.list_dir_end()
	return paths


## 所有塔必须通过基本字段合约
func test_all_towers_satisfy_invariants() -> void:
	var paths := _get_tower_paths()
	assert_array(paths).is_not_empty()

	for path in paths:
		var td := load(path) as TowerData
		assert_object(td).override_failure_message("Failed to load: %s" % path).is_not_null()
		assert_str(td.tower_name).override_failure_message("%s: tower_name empty" % path).is_not_empty()
		assert_object(td.sprite).override_failure_message("%s: sprite null" % path).is_not_null()
		assert_object(td.icon).override_failure_message("%s: icon null" % path).is_not_null()
		assert_float(td.firing_rate).override_failure_message("%s: firing_rate <= 0" % path).is_greater(0.0)
		assert_bool(td.barrel_directions.size() >= 1).override_failure_message("%s: no barrel_directions" % path).is_true()
		assert_bool(td.initial_ammo >= -1).override_failure_message("%s: invalid initial_ammo" % path).is_true()


## 双向炮 (tower1010) 具体值验证
func test_tower1010_shuangxiang_pao() -> void:
	var td := load("res://resources/tower1010.tres") as TowerData
	assert_object(td).is_not_null()
	assert_str(td.tower_name).is_equal("双向炮")
	assert_float(td.firing_rate).is_equal(1.0)
	assert_int(td.barrel_directions.size()).is_equal(2)
	assert_int(td.initial_ammo).is_equal(10)


## 直角炮 (tower1100) 具体值验证
func test_tower1100_zhijiao_pao() -> void:
	var td := load("res://resources/tower1100.tres") as TowerData
	assert_object(td).is_not_null()
	assert_str(td.tower_name).is_equal("直角炮")
	assert_float(td.firing_rate).is_equal(1.0)
	assert_int(td.barrel_directions.size()).is_equal(2)
	assert_int(td.initial_ammo).is_equal(3)


## 三向炮 (tower1110) 具体值验证
func test_tower1110_sanxiang_pao() -> void:
	var td := load("res://resources/tower1110.tres") as TowerData
	assert_object(td).is_not_null()
	assert_str(td.tower_name).is_equal("三向炮")
	assert_float(td.firing_rate).is_equal(1.0)
	assert_int(td.barrel_directions.size()).is_equal(3)
	assert_int(td.initial_ammo).is_equal(3)


## 四向炮 (tower1111) 具体值验证
func test_tower1111_sixiang_pao() -> void:
	var td := load("res://resources/tower1111.tres") as TowerData
	assert_object(td).is_not_null()
	assert_str(td.tower_name).is_equal("四向炮")
	assert_float(td.firing_rate).is_equal(1.0)
	assert_int(td.barrel_directions.size()).is_equal(4)
	assert_int(td.initial_ammo).is_equal(0)
```

- [ ] **Step 2: Run test in Godot editor**

GdUnit menu → Run Tests → select `TowerDataTest`. All 5 tests should pass.

- [ ] **Step 3: Commit**

```bash
git add tests/gdunit/TowerDataTest.gd
git commit -m "test: add TowerDataTest - contract + specific value tests for all 4 towers"
```

---

## Task 6: Create ModuleStatTest.gd

**Files:**
- Create: `tests/gdunit/ModuleStatTest.gd`

Covers stat-modifier modules. Verifies `get_stat().get_value()` before install, after install, and after uninstall. Default MockTower: firing_rate=1.0, base CD=1.0, base BULLET_SPEED=200.0, base BULLET_ATTACK=1.0, base AMMO_EXTRA=0.0.

- [ ] **Step 1: Write ModuleStatTest.gd**

```gdscript
# GdUnit4 — Module Stat Modifier Tests
# 验证 COMPUTATIONAL 模块安装后 StatAttribute 数值变化，以及卸载后回滚
# 知识库参考：docs/content/modules.md

class_name ModuleStatTest
extends GdUnitTestSuite

const MODULE_DIR := "res://resources/module_data/"


## 加速器：BULLET_SPEED +150 (ADDITIVE)
## 200.0 + 150.0 = 350.0
func test_accelerator_increases_bullet_speed() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "accelerator.tres") as Module
	assert_object(module).is_not_null()

	var before := tower.get_stat(TowerStatModifierRes.Stat.BULLET_SPEED).get_value()
	assert_float(before).is_equal(200.0)

	tower.install_module(module)
	var after := tower.get_stat(TowerStatModifierRes.Stat.BULLET_SPEED).get_value()
	assert_float(after).is_equal(350.0)


## 加速器：卸载后 BULLET_SPEED 回滚
func test_accelerator_reverts_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "accelerator.tres") as Module

	var before := tower.get_stat(TowerStatModifierRes.Stat.BULLET_SPEED).get_value()
	tower.install_module(module)
	tower.uninstall_module(0)
	var after := tower.get_stat(TowerStatModifierRes.Stat.BULLET_SPEED).get_value()
	assert_float(after).is_equal(before)


## 乘法器：BULLET_ATTACK ×1.2 (MULTIPLICATIVE)
## 1.0 × 1.2 = 1.2
func test_multiplier_scales_bullet_attack() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "multiplier.tres") as Module
	assert_object(module).is_not_null()

	var before := tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()
	assert_float(before).is_equal(1.0)

	tower.install_module(module)
	var after := tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()
	assert_float(after).is_equal_approx(1.2, 0.001)


## 乘法器：卸载后 BULLET_ATTACK 回滚
func test_multiplier_reverts_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "multiplier.tres") as Module

	tower.install_module(module)
	tower.uninstall_module(0)
	assert_float(tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()).is_equal(1.0)


## 加速射击：CD -0.3 (ADDITIVE)
## 默认 MockTower firing_rate=1.0 → base_cd=1.0；安装后 1.0 + (-0.3) = 0.7
func test_rate_boost_reduces_cd() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "rate_boost.tres") as Module
	assert_object(module).is_not_null()

	var before := tower.get_stat(TowerStatModifierRes.Stat.CD).get_value()
	assert_float(before).is_equal(1.0)

	tower.install_module(module)
	var after := tower.get_stat(TowerStatModifierRes.Stat.CD).get_value()
	assert_float(after).is_equal_approx(0.7, 0.001)


## 加速射击：卸载后 CD 回滚
func test_rate_boost_reverts_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "rate_boost.tres") as Module

	tower.install_module(module)
	tower.uninstall_module(0)
	assert_float(tower.get_stat(TowerStatModifierRes.Stat.CD).get_value()).is_equal(1.0)


## 重弹头：BULLET_ATTACK ×1.8 (MULTIPLICATIVE)
## 1.0 × 1.8 = 1.8
## 注意：AMMO_EXTRA modifier 在 .tres 中 stat=4（超出枚举范围），被 Module.on_install 静默跳过
## 该 bug 在 Task 8 中修复
func test_heavy_ammo_scales_bullet_attack() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "heavy_ammo.tres") as Module
	assert_object(module).is_not_null()

	tower.install_module(module)
	var attack := tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()
	assert_float(attack).is_equal_approx(1.8, 0.001)


## 重弹头：卸载后 BULLET_ATTACK 回滚
func test_heavy_ammo_reverts_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "heavy_ammo.tres") as Module

	tower.install_module(module)
	tower.uninstall_module(0)
	assert_float(tower.get_stat(TowerStatModifierRes.Stat.BULLET_ATTACK).get_value()).is_equal(1.0)


## 重弹头修复后：AMMO_EXTRA +1.0 生效
## 此测试在 Task 8 修复 heavy_ammo.tres stat=4→3 之前会失败，修复后应通过
func test_heavy_ammo_ammo_extra_after_fix() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "heavy_ammo.tres") as Module

	tower.install_module(module)
	var ammo_extra := tower.get_stat(TowerStatModifierRes.Stat.AMMO_EXTRA).get_value()
	assert_float(ammo_extra).is_equal_approx(1.0, 0.001)
```

- [ ] **Step 2: Run tests (expect test_heavy_ammo_ammo_extra_after_fix to FAIL until Task 8)**

GdUnit menu → Run Tests → `ModuleStatTest`. 8 tests: 7 pass, 1 fails (ammo_extra).

- [ ] **Step 3: Commit**

```bash
git add tests/gdunit/ModuleStatTest.gd
git commit -m "test: add ModuleStatTest - stat value verification for all COMPUTATIONAL modules"
```

---

## Task 7: Create ModuleBehaviorTest.gd

**Files:**
- Create: `tests/gdunit/ModuleBehaviorTest.gd`

Covers LOGICAL modules. Verifies trigger → actual outcome (ammo count, reduce_cooldown value, speed_boost value). Requires MockTower with `apply_speed_boost` from Task 4.

- [ ] **Step 1: Write ModuleBehaviorTest.gd**

```gdscript
# GdUnit4 — Module Trigger Behavior Tests
# 验证 LOGICAL 模块触发后的实际结果（弹药量、CD调用值、加速调用值）
# 知识库参考：docs/content/modules.md

class_name ModuleBehaviorTest
extends GdUnitTestSuite

const MODULE_DIR := "res://resources/module_data/"


## 辅助：从塔的 bullet_effects 中触发 on_hit_tower
func _trigger_bullet_hit_tower(source: MockTower, target: MockTower) -> void:
	var bd := BulletData.new()
	bd.transmission_chain = [source]
	for effect in source.bullet_effects:
		if effect.has_method("on_hit_tower"):
			effect.on_hit_tower(bd, target)


## 辅助：从塔的 bullet_effects 中触发 on_hit_enemy
func _trigger_bullet_hit_enemy(source: MockTower, enemy: Node) -> void:
	var bd := BulletData.new()
	bd.transmission_chain = [source]
	for effect in source.bullet_effects:
		if effect.has_method("on_hit_enemy"):
			effect.on_hit_enemy(bd, enemy)


## 辅助：从塔的 bullet_effects 中触发 on_killed_enemy
func _trigger_bullet_killed_enemy(source: MockTower, enemy: Node) -> void:
	var bd := BulletData.new()
	bd.transmission_chain = [source]
	for effect in source.bullet_effects:
		if effect.has_method("on_killed_enemy"):
			effect.on_killed_enemy(bd, enemy)


## 辅助：从塔的 tower_effects 中触发 on_receive_bullet_hit
func _trigger_receive_hit(tower: MockTower) -> void:
	var bd := BulletData.new()
	for effect in tower.tower_effects:
		if effect.has_method("on_receive_bullet_hit"):
			effect.on_receive_bullet_hit(bd, tower)


# ──────────────────────────────────────────────
# cd_on_hit_tower_self：子弹击中炮塔，来源塔自身 CD 减少
# ──────────────────────────────────────────────

func test_cd_on_hit_tower_self_reduces_source_cd() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_hit_tower_self.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	assert_array(source.bullet_effects).is_not_empty()

	_trigger_bullet_hit_tower(source, target)

	assert_array(source.reduce_cooldown_calls).has_size(1)
	assert_float(source.reduce_cooldown_calls[0]).is_equal(0.5)


func test_cd_on_hit_tower_self_does_not_affect_target() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_hit_tower_self.tres") as Module

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(target.reduce_cooldown_calls).is_empty()


# ──────────────────────────────────────────────
# cd_on_hit_tower_target：子弹击中炮塔，目标塔 CD 减少
# ──────────────────────────────────────────────

func test_cd_on_hit_tower_target_reduces_target_cd() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_hit_tower_target.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(target.reduce_cooldown_calls).has_size(1)
	assert_float(target.reduce_cooldown_calls[0]).is_equal(0.5)


func test_cd_on_hit_tower_target_does_not_affect_source() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_hit_tower_target.tres") as Module

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(source.reduce_cooldown_calls).is_empty()


# ──────────────────────────────────────────────
# cd_on_receive_hit：被子弹击中，自身 CD 减少
# ──────────────────────────────────────────────

func test_cd_on_receive_hit_reduces_self_cd_by_half() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "cd_on_receive_hit.tres") as Module
	assert_object(module).is_not_null()

	tower.install_module(module)
	assert_array(tower.tower_effects).is_not_empty()

	_trigger_receive_hit(tower)

	assert_array(tower.reduce_cooldown_calls).has_size(1)
	assert_float(tower.reduce_cooldown_calls[0]).is_equal(0.5)


# ──────────────────────────────────────────────
# replenish2：补充目标塔弹药 +2
# ──────────────────────────────────────────────

func test_replenish2_adds_two_ammo_to_target() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	target.ammo = 5
	var module := load(MODULE_DIR + "replenish2.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_int(target.ammo).is_equal(7)
	assert_int(target.ammo_added).is_equal(2)


func test_replenish2_does_not_add_to_infinite_ammo_tower() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	target.ammo = -1  # infinite
	var module := load(MODULE_DIR + "replenish2.tres") as Module

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_int(target.ammo).is_equal(-1)
	assert_int(target.ammo_added).is_equal(0)


# ──────────────────────────────────────────────
# speed_boost (击杀加速)：击杀敌人时，来源塔触发加速 1s
# ──────────────────────────────────────────────

func test_speed_boost_calls_apply_speed_boost_on_kill() -> void:
	var source := auto_free(MockTower.new())
	var enemy := auto_free(Node.new())
	var module := load(MODULE_DIR + "speed_boost.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	assert_array(source.bullet_effects).is_not_empty()

	_trigger_bullet_killed_enemy(source, enemy)

	assert_array(source.speed_boost_calls).has_size(1)
	assert_float(source.speed_boost_calls[0]).is_equal(1.0)


# ──────────────────────────────────────────────
# hit_speed_boost (击中加速)：击中炮塔时，目标塔触发加速 1s
# ──────────────────────────────────────────────

func test_hit_speed_boost_calls_apply_speed_boost_on_target() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "hit_speed_boost.tres") as Module
	assert_object(module).is_not_null()

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(target.speed_boost_calls).has_size(1)
	assert_float(target.speed_boost_calls[0]).is_equal(1.0)


func test_hit_speed_boost_does_not_affect_source() -> void:
	var source := auto_free(MockTower.new())
	var target := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "hit_speed_boost.tres") as Module

	source.install_module(module)
	_trigger_bullet_hit_tower(source, target)

	assert_array(source.speed_boost_calls).is_empty()
```

- [ ] **Step 2: Run tests**

GdUnit → Run Tests → `ModuleBehaviorTest`. All 11 tests should pass.

- [ ] **Step 3: Commit**

```bash
git add tests/gdunit/ModuleBehaviorTest.gd
git commit -m "test: add ModuleBehaviorTest - trigger outcome tests for all LOGICAL modules"
```

---

## Task 8: Fix heavy_ammo.tres and add SPECIAL module tests

**Files:**
- Fix: `resources/module_data/heavy_ammo.tres`
- Create: `tests/gdunit/ModuleSpecialTest.gd`

### Part A: Fix heavy_ammo.tres

- [ ] **Step 1: Fix stat value in heavy_ammo.tres**

In `resources/module_data/heavy_ammo.tres`, find:

```
[sub_resource type="Resource" id="Resource_w3gsl"]
script = ExtResource("2_tsmr")
stat = 4
value = 1.0
modifier_type = 0
```

Change `stat = 4` to `stat = 3` (AMMO_EXTRA is index 3 in `TowerStatModifierRes.Stat`):

```
[sub_resource type="Resource" id="Resource_w3gsl"]
script = ExtResource("2_tsmr")
stat = 3
value = 1.0
modifier_type = 0
```

- [ ] **Step 2: Re-run ModuleStatTest**

GdUnit → Run Tests → `ModuleStatTest`. Now all 8 tests including `test_heavy_ammo_ammo_extra_after_fix` should pass.

### Part B: ModuleSpecialTest.gd

- [ ] **Step 3: Write ModuleSpecialTest.gd**

```gdscript
# GdUnit4 — Special Module Tests
# 验证 SPECIAL 模块（FlyingModule、AntiAirModule）的安装/卸载状态变化
# 知识库参考：docs/content/modules.md
#
# 注意：FlyingModule.on_install 会访问 tower.sprite.scale（MockTower 已添加 sprite 属性）
# 并尝试通过 tower.get_node_or_null("TowerBody") 切换碰撞层（返回 null，安全跳过）
# 以及通过 tower.create_tween() 启动动画（MockTower 不在场景树，create_tween 失败，
# _start_animation 内先用 get_node_or_null("TowerVisual/Sprite2D") 检查，返回 null 则提前退出）

class_name ModuleSpecialTest
extends GdUnitTestSuite

const MODULE_DIR := "res://resources/module_data/"


# ──────────────────────────────────────────────
# flying — 飞行器
# ──────────────────────────────────────────────

func test_flying_sets_is_flying_true_on_install() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "flying.tres") as Module
	assert_object(module).is_not_null()

	assert_bool(tower.is_flying).is_false()
	tower.install_module(module)
	assert_bool(tower.is_flying).is_true()


func test_flying_clears_is_flying_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "flying.tres") as Module

	tower.install_module(module)
	assert_bool(tower.is_flying).is_true()

	tower.uninstall_module(0)
	assert_bool(tower.is_flying).is_false()


func test_flying_restores_sprite_scale_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var original_scale := tower.sprite.scale
	var module := load(MODULE_DIR + "flying.tres") as Module

	tower.install_module(module)
	# FlyingModule 放大 sprite scale ×1.5
	assert_bool(tower.sprite.scale.length() > original_scale.length()).is_true()

	tower.uninstall_module(0)
	assert_float(tower.sprite.scale.x).is_equal_approx(original_scale.x, 0.001)
	assert_float(tower.sprite.scale.y).is_equal_approx(original_scale.y, 0.001)


# ──────────────────────────────────────────────
# anti_air — 防空炮
# ──────────────────────────────────────────────

func test_anti_air_sets_has_anti_air_true_on_install() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "anti_air.tres") as Module
	assert_object(module).is_not_null()

	assert_bool(tower.has_anti_air).is_false()
	tower.install_module(module)
	assert_bool(tower.has_anti_air).is_true()


func test_anti_air_clears_has_anti_air_on_uninstall() -> void:
	var tower := auto_free(MockTower.new())
	var module := load(MODULE_DIR + "anti_air.tres") as Module

	tower.install_module(module)
	assert_bool(tower.has_anti_air).is_true()

	tower.uninstall_module(0)
	assert_bool(tower.has_anti_air).is_false()
```

- [ ] **Step 4: Run tests**

GdUnit → Run Tests → `ModuleSpecialTest`. All 5 tests should pass.

- [ ] **Step 5: Commit**

```bash
git add resources/module_data/heavy_ammo.tres tests/gdunit/ModuleSpecialTest.gd
git commit -m "fix: correct heavy_ammo.tres AMMO_EXTRA stat index (4→3); add ModuleSpecialTest"
```

---

## Summary: Coverage After This Plan

### Towers
| Tower | Data contract | Specific values |
|-------|--------------|----------------|
| tower1010 双向炮 | ✅ auto-scan | ✅ TowerDataTest |
| tower1100 直角炮 | ✅ auto-scan | ✅ TowerDataTest |
| tower1110 三向炮 | ✅ auto-scan | ✅ TowerDataTest |
| tower1111 四向炮 | ✅ auto-scan | ✅ TowerDataTest |
| *New tower* | ✅ auto-scan | ➕ add one test func |

### Modules
| Module | Stat | Behavior | Pre-existing |
|--------|------|---------|-------------|
| accelerator | ✅ ModuleStatTest | — | ✅ FullChainTest |
| multiplier | ✅ ModuleStatTest | — | — |
| rate_boost | ✅ ModuleStatTest | — | — |
| heavy_ammo | ✅ ModuleStatTest | — | — |
| cd_on_hit_enemy | — | ✅ pre-existing | ✅ FullChainTest |
| cd_on_hit_tower_self | — | ✅ ModuleBehaviorTest | — |
| cd_on_hit_tower_target | — | ✅ ModuleBehaviorTest | — |
| cd_on_receive_hit | — | ✅ ModuleBehaviorTest | partial |
| replenish1 | — | ✅ pre-existing | ✅ FullChainTest |
| replenish2 | — | ✅ ModuleBehaviorTest | — |
| speed_boost | — | ✅ ModuleBehaviorTest | — |
| hit_speed_boost | — | ✅ ModuleBehaviorTest | — |
| flying | — | ✅ ModuleSpecialTest | — |
| anti_air | — | ✅ ModuleSpecialTest | — |

### Adding new content checklist
- New tower: create .tres → add row to `docs/content/towers.md` → auto-scan catches invariants → add `test_tower_<name>` in `TowerDataTest.gd`
- New COMPUTATIONAL module: create .tres → add entry to modules.md → add `test_<name>_*` in `ModuleStatTest.gd`
- New LOGICAL module: create .tres → add entry to modules.md → add `test_<name>_*` in `ModuleBehaviorTest.gd`
- New SPECIAL module: create .tres → add entry to modules.md → add `test_<name>_*` in `ModuleSpecialTest.gd`
