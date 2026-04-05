# 弹药链式限制系统设计

**日期：** 2026-04-05  
**问题：** A/B 炮塔互射时，补充弹药 + 减 CD 特效无限叠加，导致弹药指数级爆炸、游戏卡死  
**目标：** 同一条链上，每个 tower 的 bullet_effects 和 tower_effects 最多各触发 max_chain 次  

---

## 背景

### 当前 Bug

A、B 各有"补充+2"和"减 CD 1s"特效时：
1. A 射击 B → B 补充弹药、CD 缩短 → B 立刻射击 A → A 补充弹药、CD 缩短 → 循环
2. 每轮弹药 ×3，指数增长，数秒内游戏卡死

### 根本原因

- `add_ammo()` 只是简单计数加法，不携带任何链追踪信息
- 子弹击中炮塔后触发的所有效果无限制地重复激活

---

## 设计概述

将 tower 的弹药从简单计数改为**带游标的队列**。每个 AmmoItem 记录当前链的贡献历史。炮塔开火时检查自己是否还有贡献次数，耗尽则不再追加 extra effects。TowerEffect 同理。

---

## Section 1：核心数据结构

### AmmoItem（新文件：`entities/bullets/ammo_item.gd`）

```gdscript
class_name AmmoItem

## {tower_id → int}：各 tower 的 bullet_effects 已贡献次数
var effect_contribution_counts: Dictionary = {}

## {tower_id → int}：各 tower 的 tower_effects 已触发次数
var tower_effect_trigger_counts: Dictionary = {}
```

### BulletData 新增字段

```gdscript
# 新增到 BulletData.gd
var effect_contribution_counts: Dictionary = {}
var tower_effect_trigger_counts: Dictionary = {}
```

`duplicate_with_mods()` 需同步复制这两个字段。

### Tower 新增字段

```gdscript
var ammo_queue: Array = []   # Array[AmmoItem]，替代 var ammo: int
var ammo_cursor: int = 0
var bullet_effect_max_chain: int = 1   # 本 tower bullet_effects 最多贡献次数
var tower_effect_max_chain: int = 1    # 本 tower tower_effects 最多触发次数
```

**兼容性：** `var ammo: int` 保留为计算属性（或完全移除，改用 `ammo_count()`）。  
`has_ammo()` → `ammo == -1 or ammo_cursor < ammo_queue.size()`  
`consume_ammo()` → `ammo_cursor += 1`  
`ammo_count()` → `ammo_queue.size() - ammo_cursor`（用于 Label 显示）

初始弹药（`_apply_data()`）：不再 `ammo = data.initial_ammo`，改为 push `data.initial_ammo` 个空 AmmoItem 进队列。

---

## Section 2：Tower 开火逻辑

`_do_fire()` 核心变更：

```gdscript
func _do_fire() -> void:
    # 取当前弹药项
    var ammo_item: AmmoItem
    if ammo == -1:
        ammo_item = AmmoItem.new()   # 无限弹药：每次全新链
    else:
        ammo_item = ammo_queue[ammo_cursor]
    consume_ammo()

    var bd := BulletData.new()
    bd.attack = _bullet_attack_stat.get_value()
    bd.speed  = _bullet_speed_stat.get_value()
    bd.transmission_chain = [self]  # 不变，仅用于防自碰

    # 继承链追踪状态
    bd.effect_contribution_counts = ammo_item.effect_contribution_counts.duplicate()
    bd.tower_effect_trigger_counts = ammo_item.tower_effect_trigger_counts.duplicate()

    # 检查本 tower 是否还能贡献 bullet_effects
    var contrib_count = bd.effect_contribution_counts.get(entity_id, 0)
    if contrib_count < bullet_effect_max_chain:
        bd.effects.append_array(bullet_effects)
        bd.effect_contribution_counts[entity_id] = contrib_count + 1

    # default_replenish 无条件追加，不计入 contribution
    var default_replenish := HitTowerTargetReplenishEffect.new()
    bd.effects.append(default_replenish)

    # ... 其余 fire_effects、飞行标志、CD 重置、子弹生成逻辑不变 ...
```

**规则：**
- `effect_contribution_counts` 在**开火时**自增，不是 hit 时
- `default_replenish` 永远追加，不参与计数（基础传递机制，不增殖）
- `transmission_chain = [self]` 保持不变，与链计数完全独立

---

## Section 3：Bullet 击中逻辑

`bullet.gd` 的 `_on_hitbox_area_entered` 变更：

```gdscript
# BulletEffect 照常触发（顺序不变）
for effect in data.effects:
    effect.on_hit_tower(data, parent)

# 受击动画：无条件播放（视觉反馈不受限）
parent.play_hit_effect()

# TowerEffect：检查目标 tower 是否还有触发次数
var te_count = data.tower_effect_trigger_counts.get(parent.entity_id, 0)
if te_count < parent.tower_effect_max_chain:
    data.tower_effect_trigger_counts[parent.entity_id] = te_count + 1
    for te in parent.tower_effects:
        te.on_receive_bullet_hit(data, parent)   # 直接调用，绕过 on_bullet_hit
```

---

## Section 4：Replenish Effects（链式弹药注入）

### Tower 新增 add_ammo_from_chain

```gdscript
## 全新弹药（初始弹药 / 击杀敌人奖励，空链）
func add_ammo(amount: int) -> void:
    for _i in range(amount):
        ammo_queue.append(AmmoItem.new())
    _update_ammo_label()
    if _is_firing and _cooldown_remaining <= 0.0:
        set_process(true)

## 链式弹药（炮塔间传递，继承当前子弹的链追踪状态）
func add_ammo_from_chain(amount: int, bullet_data: BulletData) -> void:
    for _i in range(amount):
        var item := AmmoItem.new()
        item.effect_contribution_counts = bullet_data.effect_contribution_counts.duplicate()
        item.tower_effect_trigger_counts = bullet_data.tower_effect_trigger_counts.duplicate()
        ammo_queue.append(item)
    _update_ammo_label()
    if _is_firing and _cooldown_remaining <= 0.0:
        set_process(true)
```

### Effect 调用方变更

| Effect 文件 | 原调用 | 新调用 | 说明 |
|---|---|---|---|
| `hit_tower_target_replenish_effect.gd` | `tower.add_ammo(n)` | `tower.add_ammo_from_chain(n, bullet_data)` | 炮塔间传递 |
| `receive_hit_self_replenish_effect.gd` | `tower.add_ammo(n)` | `tower.add_ammo_from_chain(n, bullet_data)` | 炮塔间传递 |
| `hit_enemy_self_replenish_effect.gd` | `tower.add_ammo(n)` | 保持 `add_ammo(n)` | 击杀奖励，全新链 |
| `deal_damage_self_replenish_effect.gd` | `tower.add_ammo(n)` | 保持 `add_ammo(n)` | 击伤奖励，全新链 |

`default_replenish`（built-in，在 `_do_fire()` 里创建）同样改为调用 `add_ammo_from_chain(1, bullet_data)`，透传链上下文但不增加 contribution_counts。

---

## Section 5：连锁模组（Chain Module）

**新文件：** `entities/modules/chain_module.gd`

```gdscript
class_name ChainModule extends Module

## 安装后：本 tower 的 bullet_effects 和 tower_effects 各可额外多触发一次
func on_install(tower: Node) -> void:
    tower.bullet_effect_max_chain += 1
    tower.tower_effect_max_chain += 1

func on_uninstall(tower: Node) -> void:
    tower.bullet_effect_max_chain -= 1
    tower.tower_effect_max_chain -= 1
```

需对应：
- `resources/module_data/` 下新增 ChainModule resource 文件
- 加入 RewardPool 供波次奖励选择

---

## Section 6：边界情况与稳定性

### 无限弹药（ammo == -1）
`_do_fire()` 的 `ammo == -1` 分支直接 `AmmoItem.new()`（空 contribution），始终全新链，不受 chain 限制，现有行为完全不变。

### 稳定性（直觉证明）
设 A/B 各有 extra_replenish(+2)，max_chain=1：
- 初始 1 颗子弹
- 经过一个完整链传播后，系统内弹药稳定在 (1 + extra_amount)² = 9 颗
- 此后所有弹药的 contribution_counts 均已满，只有 default_replenish 传递，不再增殖

使用 Chain Module（max_chain=2）时，稳定弹药数相应增加，但仍有限。

### transmission_chain 不变
依然 `= [self]`，只负责防止子弹打到自己，与 `effect_contribution_counts` 完全独立，无需修改 bullet.gd 自碰检测逻辑。

### ammo_queue 内存管理
队列只增不减（cursor 前移），历史 AmmoItem 不再被引用，GC 正常回收。若游戏运行时间很长（cursor 前的项目堆积），可在 `_do_fire()` 里定期 trim：
```gdscript
if ammo_cursor > 100:
    ammo_queue = ammo_queue.slice(ammo_cursor)
    ammo_cursor = 0
```

---

## 受影响文件清单

**新建：**
- `entities/bullets/ammo_item.gd`
- `entities/modules/chain_module.gd`
- `resources/module_data/chain_module.tres`

**修改：**
- `resources/BulletData.gd` — 新增两个 Dictionary 字段
- `entities/towers/tower.gd` — ammo_queue/cursor、max_chain 字段、`_do_fire()`、`add_ammo()`、`add_ammo_from_chain()`
- `entities/bullets/bullet.gd` — TowerEffect chain 检查；不再调用 `on_bullet_hit`，改为直接调用 `play_hit_effect()` + 迭代 `tower_effects`
- `entities/effects/bullet_effects/hit_tower_target_replenish_effect.gd` — 改用 `add_ammo_from_chain`
- `entities/effects/tower_effects/receive_hit_self_replenish_effect.gd` — 改用 `add_ammo_from_chain`
