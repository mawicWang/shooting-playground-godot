# Shadow Tower System — Agent Reference

> 本文档是影子炮塔系统的权威参考。修改前请先读完整体设计，
> 尤其是"共享实例陷阱"和"生成深度控制"两节，避免引入递归或 team 混乱。

---

## 1. 系统概述

**幻影炮塔（ShadowTowerModule）** 是一个 SPECIAL 类模块，装备后炮塔每发射 5 颗子弹
就在周围 3×3 空格中随机生成一座影子炮塔。

影子炮塔特点：
- 半透明深色外观（区分于普通炮塔）
- 无限弹药（`ammo = -1`），不依赖弹药链存活
- 继承父塔的外观（`data.sprite`）和射击方向
- 继承父塔的其他所有模块（含 ShadowTowerModule，有深度限制）
- 使用独立碰撞层（`SHADOW_TOWER_BODY = Layer 8`），与普通炮塔互不干扰
- 每波结束后自动清除

---

## 2. 组件一览

| 文件 | 类 / 资源 | 职责 |
|------|-----------|------|
| `resources/module_data/shadow_tower_module.tres` | `Module` | 模块数据容器，持有 `SpawnShadowTowerEffect` |
| `entities/effects/fire_effects/spawn_shadow_tower_effect.gd` | `SpawnShadowTowerEffect` | 每 5 发触发，负责查找空格、实例化、模块安装 |
| `entities/towers/shadow_tower.gd` | `ShadowTower` (extends `tower.gd`) | 影子炮塔运行时逻辑，覆盖碰撞层、开火、生命周期 |
| `entities/towers/shadow_tower.tscn` | — | 场景文件，与 `tower.tscn` 同结构但挂 `shadow_tower.gd` |

---

## 3. 碰撞层设计

```
Layers.TOWER_BODY       = 32   (Layer 6)  普通炮塔 TowerBody
Layers.AIR_TOWER_BODY   = 64   (Layer 7)  飞行炮塔 TowerBody
Layers.SHADOW_TOWER_BODY = 128  (Layer 8)  影子炮塔 TowerBody  ← 新增
```

### 子弹 collision_mask 规则

| 发射炮塔类型 | `tower_body_mask` | 可命中目标 |
|-------------|-------------------|-----------|
| 普通炮塔（默认） | `TOWER_BODY = 32` | 普通炮塔 |
| 普通炮塔（飞行） | `AIR_TOWER_BODY = 64` | 飞行炮塔 |
| 普通炮塔（防空） | `TOWER_BODY \| AIR_TOWER_BODY = 96` | 普通 + 飞行 |
| **影子炮塔（默认）** | `SHADOW_TOWER_BODY = 128` | 影子炮塔（同 team） |
| 影子炮塔（飞行） | `AIR_TOWER_BODY \| SHADOW_TOWER_BODY = 192` | 飞行 + 影子 |
| 影子炮塔（防空） | `TOWER_BODY \| AIR_TOWER_BODY \| SHADOW_TOWER_BODY = 224` | 三者全部 |

`reset()` 在 `BulletPool.spawn()` 中调用，会将 `$Hitbox.collision_mask` 设为 `data.tower_body_mask`。

### 普通子弹 ↔ 影子炮塔

- **物理层**：普通子弹 mask=32，影子 TowerBody layer=128，`32 & 128 = 0` → 不触发回调，无需额外过滤。
- **代码层**（安全兜底）：`bullet.gd._on_hitbox_area_entered` 中：
  ```gdscript
  elif parent.has_method("get_shadow_team_id"):
      return  # 普通子弹跳过影子炮塔
  ```

---

## 4. Team 隔离机制

每个影子团队用 **起源父塔的 `entity_id`** 作为 `shadow_team_id`。

```
父塔 P (entity_id = 5)
  ├── 影子炮塔 A  (shadow_team_id = 5)
  ├── 影子炮塔 B  (shadow_team_id = 5)
  └── 影子炮塔 C  (shadow_team_id = 5)
      └── 子弹 (shadow_team_id = 5) → 可命中 A / B
```

### bullet.gd 过滤逻辑（`_on_hitbox_area_entered`）

```gdscript
if data and data.shadow_team_id >= 0:
    # 影子子弹：只命中同 team 的影子炮塔
    if not parent.has_method("get_shadow_team_id"):
        return  # 不是影子炮塔，跳过
    if parent.get_shadow_team_id() != data.shadow_team_id:
        return  # 不同 team，跳过
elif parent.has_method("get_shadow_team_id"):
    return  # 普通子弹不命中影子炮塔
```

> **关键**：过滤在物理层（`collision_mask`）和代码层双重保障。

---

## 5. SpawnShadowTowerEffect 详解

### 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `origin_entity_id` | `int` | 起源父塔的 entity_id；同时用作 team ID 和计数器 key |
| `_bullet_counters` | `Dictionary` | `{origin_entity_id → 发射计数}` |
| `MAX_SHADOW_GENERATION` | `const int = 1` | 允许安装 ShadowTowerModule 的最大影子深度 |

### 共享实例陷阱（必读）

`SpawnShadowTowerEffect` 在 `.tres` 中定义为 sub_resource。`Module.duplicate()`
做**浅拷贝**，`fire_effects` 数组中的 Effect 对象是**共享引用**。

这意味着：所有持有 ShadowTowerModule 的炮塔（父塔 + 各代影子炮塔）共用**同一个**
`SpawnShadowTowerEffect` 实例，共享 `_bullet_counters` 字典和 `origin_entity_id`。

**`on_module_install` 的写保护**（防止后安装的炮塔覆盖 `origin_entity_id`）：

```gdscript
func on_module_install(tower: Node) -> void:
    if origin_entity_id == -1:          # 只在未初始化时赋值
        origin_entity_id = tower.entity_id
```

第一次（安装到父塔时）写入父塔 ID；影子炮塔继承安装时，值已非 -1，不覆盖。

### 触发流程

```
tower._do_fire()
  → for effect in fire_effects:
      effect.apply(tower, bd)      ← 每次开火都调用
        → _bullet_counters[origin_entity_id]++
        → if count % 5 == 0:
            _try_spawn_shadow(tower)
              → _find_parent_cell(tower)    ← 遍历 "grid_cells" 组
              → _get_adjacent_empty_cells() ← 3×3 范围，排除中心
              → pick_random()
              → _spawn_shadow_at_cell(tower, target_cell)
```

---

## 6. 生成深度控制

防止链式生成导致无限递归的机制：

### ShadowTower.shadow_generation

```gdscript
var shadow_generation: int = 0
# 0 = 普通炮塔（默认值，不在 tower.gd 中定义，用 get() 读取）
# 1 = 第一代影子炮塔
# 2 = 第二代影子炮塔（不再安装 ShadowTowerModule）
```

### _spawn_shadow_at_cell 中的安装规则

```gdscript
shadow_tower.shadow_generation = parent_tower.get("shadow_generation", 0) + 1

for module in parent_tower.modules:
    var has_shadow_effect := false
    for e in module.fire_effects:
        if e is SpawnShadowTowerEffect:
            has_shadow_effect = true; break

    if has_shadow_effect:
        # 仅在深度未超限时安装（允许继续链式生成）
        if shadow_tower.shadow_generation <= MAX_SHADOW_GENERATION:
            shadow_tower.install_module(module)
        # else: 跳过，截断递归
    else:
        shadow_tower.install_module(module)  # 其他模块无限制
```

### 生成链示意（MAX_SHADOW_GENERATION = 1）

```
父塔 P (generation=0)
│  每 5 发 → 生成第一代
└── 影子 A (generation=1)  ← 有 ShadowTowerModule（1 <= 1）
    │  每 5 发 → 生成第二代
    └── 影子 B (generation=2)  ← 无 ShadowTowerModule（2 > 1），不再生成
```

影子 A 的子弹飞向前方 → 若影子 B 在路径上可命中 B → 实现"互相击中"。

---

## 7. ShadowTower 覆盖行为

`shadow_tower.gd` 继承 `tower.gd`，覆盖以下三处：

### 7.1 `_apply_data()` — 强制无限弹药

```gdscript
func _apply_data() -> void:
    super._apply_data()   # 初始化 stat、sprite
    ammo = -1             # 覆盖：无限弹药，不依赖弹药链
    ammo_queue.clear()
    ammo_cursor = 0
    _update_ammo_label()
```

### 7.2 `_setup_tower_body()` — 独立碰撞层

```gdscript
func _setup_tower_body() -> void:
    _tower_body = Area2D.new()
    _tower_body.collision_layer = Layers.SHADOW_TOWER_BODY  # 128，不是 32
    _tower_body.collision_mask = 0
    _tower_body.monitoring = false
    _tower_body.monitorable = true
    add_child(_tower_body)
    call_deferred("_init_tower_body_shape")  # 继承父类方法，基于 sprite 尺寸
```

### 7.3 `_do_fire()` — 影子子弹标记

关键差异（与 `tower.gd._do_fire()` 对比）：

```gdscript
# 新增：子弹携带 shadow_team_id 和影子专属碰撞 mask
bd.shadow_team_id = shadow_team_id
bd.tower_body_mask = Layers.SHADOW_TOWER_BODY

# 飞行/防空状态下扩展 mask（含 SHADOW_TOWER_BODY）
if is_flying:
    bd.tower_body_mask = Layers.AIR_TOWER_BODY | Layers.SHADOW_TOWER_BODY
elif has_anti_air:
    bd.tower_body_mask = Layers.TOWER_BODY | Layers.AIR_TOWER_BODY | Layers.SHADOW_TOWER_BODY
```

> `_do_fire()` 完全重实现，未调用 `super._do_fire()`。

---

## 8. 生命周期

### 生成时序

```
spawn_shadow_tower_effect._spawn_shadow_at_cell(parent, cell)
  1. shadow_tower.data = parent.data          # 共享 TowerData（只读）
  2. shadow_tower.shadow_team_id = origin_entity_id
  3. shadow_tower.entity_id = GameState.generate_entity_id()
  4. shadow_tower.shadow_generation = parent.get("shadow_generation", 0) + 1
  5. cell.add_child(shadow_tower)             # 触发 _ready() / _apply_data()
  6. cell._setup_tower_visuals(shadow_tower)  # 位置 + 缩放
  7. cell.is_occupied = true
  8. cell.tower_node = shadow_tower
  9. install_module() × N                     # 各模块安装（见第 6 节）
 10. cell._refresh_slot_dots()                # 刷新槽位视觉
 11. shadow_tower.set_initial_direction(parent.current_rotation_index)
 12. if GameState.is_running(): shadow_tower.start_firing()
```

### 清除时序

```
SignalBus.game_stopped  OR  SignalBus.wave_completed
  → shadow_tower._cleanup()
      → parent_cell.remove_tower_reference()  # is_occupied=false, tower_node=null
      → queue_free()
```

> `wave_completed` 信号在每波所有敌人消灭后由 `EnemyManager` 发出，
> 影子炮塔在波间部署阶段不存在。

---

## 9. 模块安装规则总结

| 场景 | 行为 |
|------|------|
| 其他模块（无 SpawnShadowTowerEffect） | 直接 `install_module()`，无限制 |
| ShadowTowerModule（generation <= MAX） | `install_module()`，允许链式生成 |
| ShadowTowerModule（generation > MAX） | 跳过，截断递归 |
| 安装后视觉刷新 | 调用 `target_cell._refresh_slot_dots()` |

AntiAirModule / FlyingModule 安装后，影子炮塔的 `has_anti_air` / `is_flying` 为 true，
`_do_fire()` 中的 mask 分支会相应扩展，使影子子弹同时能命中普通炮塔或飞行炮塔。

---

## 10. 已知约束

| 约束 | 原因 |
|------|------|
| 影子炮塔间无法通过弹药链互相补弹 | `add_ammo_from_chain` 遇 `ammo=-1` 直接返回 |
| 普通炮塔子弹无法命中影子炮塔 | 物理层双重隔离（layer + 代码过滤） |
| 不同 team 的影子炮塔互不可见 | `shadow_team_id` 不匹配则过滤 |
| 第一代影子与父塔处于不同格，子弹需几何对齐才能互相命中 | 影子炮塔与父塔同向，需链式生成使第二代处于第一代射击路径 |
| 影子炮塔不可被玩家拖拽移动 | 未注册为可拖拽节点，`source_icon = null` |
| 影子炮塔槽位在部署阶段不可操作 | `GameState.is_deployment()` 期间影子炮塔不存在 |

---

## 11. 关键文件速查

```
entities/effects/fire_effects/spawn_shadow_tower_effect.gd  ← 触发逻辑、生成、模块安装
entities/towers/shadow_tower.gd                              ← 覆盖行为（弹药/碰撞/开火）
entities/towers/shadow_tower.tscn                            ← 场景（与 tower.tscn 同结构）
resources/module_data/shadow_tower_module.tres               ← 模块资源（含共享 effect）
autoload/Layers.gd                                           ← SHADOW_TOWER_BODY = 128
resources/BulletData.gd                                      ← shadow_team_id 字段
entities/bullets/bullet.gd                                   ← team 过滤逻辑
grid/cell.gd                                                 ← _refresh_slot_dots()
```
