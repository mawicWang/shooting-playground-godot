# Shooting Playground v1.0 实施计划

> 基于 DESIGN_V1.0.md 的分步重构与功能实现方案

---

## 整体策略

### 核心原则
1. **渐进式重构** - 每一步都保持现有功能完整
2. **先重构，后功能** - 架构先行，功能后置
3. **可回滚** - 每个阶段完成后打 git tag
4. **先跑通，再优化** - 新功能先验证逻辑正确性，再追求性能

### 阶段划分

```
Phase 1: 项目结构重构 (基础架构)          ✅ 已完成
Phase 2: Tower 架构重构 (可扩展底座系统)  ✅ 已完成
Phase 3: Bullet 架构重构 (信号数据包系统)  🔜 下一步
Phase 4: 组件与模块系统 (Modules)
Phase 5: 遗物系统 (Relics)
Phase 6: Roguelike 循环与 UI
```

---

## Phase 1: 项目结构重构 ✅

### 目标
建立清晰的分层架构，为后续组件化开发奠定基础。

### 目录结构

```
res://
├── main.tscn / main.gd              # 主场景入口（协调者，< 200 行）
├── autoload/                        # 自动加载单例
│   ├── SignalBus.gd                # 全局信号总线
│   ├── GameState.gd               # 游戏阶段状态（DEPLOYMENT/RUNNING...）
│   ├── DragManager.gd             # 拖拽预览与旋转计算
│   └── Paths.gd                   # 资源路径常量
├── core/                            # 管理器层
│   ├── GameLoopManager.gd
│   ├── LayoutManager.gd
│   ├── EffectManager.gd
│   └── dead_zone_manager.gd
├── entities/                        # 实体实现
│   ├── towers/
│   ├── bullets/
│   ├── enemies/
│   └── modules/                    # 预留
├── grid/                            # 网格系统
├── ui/                              # UI 系统
├── relics/                          # 预留
└── resources/                       # 预留
```

### 任务完成情况

| 任务 | 状态 | 备注 |
|------|------|------|
| 1.1 目录结构 | ✅ | 按计划建立，modules/relics/resources 为空目录 |
| 1.2 迁移现有文件 | ✅ | 所有文件已在正确位置 |
| 1.3 创建 SignalBus | ✅ | 全局信号总线，signal 签名已修正 |
| 1.4 创建 GameState | ✅ | 仅管理游戏阶段，冗余拖拽状态已移除 |
| 1.5 重构 main.gd | ✅ | 149 行，职责清晰 |
| 代码质量预备 | ✅ | group 检测、tween 修复、节点创建方式、忙等待等 critical/high 问题已解决 |

> EventManager 推迟到 Phase 5 创建，届时遗物系统需要它。

---

## Phase 2: Tower 架构重构 ✅

### 目标
引入 TowerData 数据驱动架构和 Stat Modifier 系统。代码层面保持单一 Tower 类，不做类型继承。

### 设计原则
- **一个 Tower 类，任意多种塔**：不同塔的行为差异由 TowerData Resource 配置，新增塔 = 新建 `.tres` 文件
- **属性按需添加**：TowerData 字段只在实际用到时才加，不预留空接口
- **Stat Modifier 先行**：数值修改基础设施必须在模块系统之前建立

### TowerData Resource（当前最小集）

```gdscript
class_name TowerData extends Resource

@export var tower_name: String = ""
@export var sprite: Texture2D       # 格子上的外观
@export var icon: Texture2D         # 商店图标
@export var firing_rate: float = 1.0
```

后续随着需求增加字段（如 bullet_speed、damage 等），不预留。

### Stat Modifier 系统

所有可被模块/遗物修改的数值统一用此机制管理，安装模块时加 modifier，卸载时按 source 移除，数值自动回退。

```gdscript
# StatModifier.gd - RefCounted 值对象
class_name StatModifier extends RefCounted
enum Type { ADDITIVE, MULTIPLICATIVE }
var value: float;  var type: Type;  var source: Object

# StatAttribute.gd - 单个数值的完整生命周期
class_name StatAttribute extends RefCounted
var base_value: float
var _modifiers: Array[StatModifier] = []

func get_value() -> float:
    var total = base_value
    var mult = 1.0
    for m in _modifiers:
        if m.type == StatModifier.Type.ADDITIVE: total += m.value
        else: mult *= m.value
    return total * mult

func add_modifier(mod: StatModifier): _modifiers.append(mod)
func remove_modifiers_from(source: Object):
    _modifiers = _modifiers.filter(func(m): return m.source != source)
```

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 2.1 创建 TowerData | 4 字段极简 Resource | ✅ `resources/TowerData.gd` |
| 2.2 创建 StatModifier | value + type + source 值对象 | ✅ `resources/StatModifier.gd` |
| 2.3 创建 StatAttribute | base + modifiers，get_value() | ✅ `resources/StatAttribute.gd` |
| 2.4 重构 tower.gd | 加 `@export var data: TowerData`；firing_rate 改为 StatAttribute；FireTimer 由 stat 驱动 | ✅ 功能等价 |
| 2.5 创建 simple_emitter.tres | 初始塔数据文件（firing_rate=1.0）| ✅ `resources/simple_emitter.tres` |
| 2.6 更新 tower_icon.gd | `PackedScene` → `TowerData`；texture 从 data.icon 读取 | ✅ |
| 2.7 更新 cell._drop_data | 收到 tower_data 后 instantiate 通用 tower.tscn，赋值 data | ✅ |

---

## Phase 3: Bullet 架构重构

### 目标
实现信号数据包系统，子弹携带能量、属性、传递链等数据。

### 前置决策：子弹物理类型

> ⚠️ 需要在 Phase 3 开始前确认：BulletBase 用 **CharacterBody2D**（保持现状）还是改为 **Area2D**？
> - `CharacterBody2D`：可以用 move_and_slide，但 SignalReceiver 需用 `body_entered`
> - `Area2D`：需手动更新 position，但碰撞检测更灵活
>
> **建议保持 CharacterBody2D**，SignalReceiver 改用 `body_entered` 而不是 `area_entered`。

### 数据结构

```gdscript
# BulletData.gd - Resource
class_name BulletData extends Resource

enum ElementType { NEUTRAL, FIRE, ICE, ELECTRIC }

var energy: float = 1.0
var speed: float = 300.0
var element: ElementType = ElementType.NEUTRAL
var source_tower: TowerBase       # 原始发射者（用于 Module 逻辑）
var last_sender: TowerBase        # 上一个转发者（用于避免立即反弹）
var transmission_chain: Array[TowerBase] = []  # 完整路径（用于遗物闭环检测）
var bounce_count: int = 0
var piercing: bool = false

func duplicate_with_mods(mods: Dictionary) -> BulletData:
    var copy = self.duplicate()
    for key in mods:
        copy.set(key, mods[key])
    return copy
```

> 注意 `last_sender` 与 `source_tower` 的区别：
> - `source_tower`：原始 Emitter，模块可用来避免自我增益
> - `last_sender`：上一个塔，用于 Relay 避免立即反弹给来源，但不阻断闭环

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 3.1 创建 BulletData Resource | 含 source/last_sender/chain 字段 | 可序列化，字段清晰 |
| 3.2 创建 BulletBase | CharacterBody2D，持有 BulletData | data 驱动移动速度 |
| 3.3 迁移现有 bullet | SimpleBullet 继承 BulletBase | 功能等价，group "bullets" 保留 |
| 3.4 创建 BulletFactory | 通过工厂创建/复用子弹 | 支持属性初始化 |
| 3.5 实现信号链追踪 | 每次塔转发时 append 到 chain | 遗物可读取 chain 检测闭环 |
| 3.6 引入对象池 | 复用 queue_free 的子弹实例 | 百颗以上子弹无明显卡顿 |

---

## Phase 4: 组件与模块系统

### 目标
实现可插拔的模块系统，支持运行时安装/卸载，不产生数值残留。

### 关键设计：Module 状态隔离

```gdscript
# Module.gd - Resource 基类
class_name Module extends Resource

enum Category { COMPUTATIONAL, LOGICAL, SPECIAL }

@export var module_name: String
@export var category: Category
@export var description: String
@export var icon: Texture2D

# 虚拟方法，子类重写
# 注意：Module 实例通过 TowerBase.install_module() 中的 duplicate() 隔离
# 每个 Tower 持有独立副本，此处可安全存储每塔状态（如计数器）
func apply_effect(tower: TowerBase, bullet_data: BulletData) -> BulletData:
    return bullet_data

func on_install(tower: TowerBase):
    pass

func on_uninstall(tower: TowerBase):
    pass
```

### 模块示例

```gdscript
# MultiplierModule.gd
class_name MultiplierModule extends Module
@export var multiplier: float = 1.2

func apply_effect(_tower: TowerBase, bullet_data: BulletData) -> BulletData:
    bullet_data.energy *= multiplier
    return bullet_data

# DividerModule.gd - 需要实例状态，duplicate() 保证安全
class_name DividerModule extends Module
@export var trigger_every: int = 3
var _hit_count: int = 0  # 每个 Tower 的副本独立维护此状态

func apply_effect(tower: TowerBase, bullet_data: BulletData) -> BulletData:
    _hit_count += 1
    if _hit_count >= trigger_every:
        _hit_count = 0
        bullet_data.energy *= 5.0  # 积蓄后爆发
    return bullet_data
```

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 4.1 创建 Module 基类 | Resource，含 apply/install/uninstall 钩子 | 可定义模块数据 |
| 4.2 创建乘法器模块 | MultiplierModule | 能量倍增，数值正确 |
| 4.3 创建加速器模块 | AcceleratorModule | bullet_data.speed 提升 |
| 4.4 创建分频器模块 | DividerModule（需实例状态）| 计数正确，卸载后重置 |
| 4.5 创建过滤器模块 | FilterModule | 按 element 类型筛选子弹 |
| 4.6 模块安装 UI | 拖拽模块到炮塔插槽 | 与现有拖拽系统兼容 |

---

## Phase 5: 遗物系统

### 目标
实现全局机制修改器，侧重修改规则而非纯数值加成。

### 遗物基类

```gdscript
# Relic.gd - Resource
class_name Relic extends Resource

@export var relic_name: String
@export var description: String
@export var rarity: int  # 1-4

# 钩子方法，由 EventManager 在对应事件时调用
func on_bullet_transmit(bullet: BulletData, from: TowerBase, to: TowerBase):
    pass

func on_terminal_absorb(terminal: TowerBase, bullet: BulletData):
    pass

func on_wave_start():
    pass
```

### 递归遗物的闭环检测

```gdscript
# RecursiveRelic.gd - "递归逻辑"遗物
func on_bullet_transmit(bullet: BulletData, _from: TowerBase, to: TowerBase):
    # 检测 to 是否已在传递链中（闭环）
    if to in bullet.transmission_chain:
        bullet.energy *= 1.1  # 每完成一圈增幅 10%
```

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 5.1 创建 Relic 基类 | Resource + 钩子接口 | 可被 EventManager 调用 |
| 5.2 创建 EventManager | Autoload，分发 on_bullet_transmit 等事件 | 遗物可注册/注销 |
| 5.3 实现"量子纠缠" | Terminal 共享能量进度 | 多个 Terminal 同步效果 |
| 5.4 实现"超导回路" | 转发不衰减 + 电击周围敌人 | 电击范围可见，不影响帧率 |
| 5.5 实现"递归逻辑" | 读取 transmission_chain 检测闭环 | 闭环检测准确，增幅堆叠正确 |
| 5.6 实现"多线程" | 所有 Emitter 额外增加后方炮口 | 动态修改 muzzle_count 生效 |

---

## Phase 6: Roguelike 循环与 UI

### 目标
完成完整游戏循环，实现局内构建与局外成长。

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 6.1 情报预警 UI | 显示敌人波次方向/类型 | 动画预警清晰 |
| 6.2 炮塔商店系统 | 购买底座和模块，货币系统 | 资源增减正确 |
| 6.3 战后奖励三选一 | 从遗物/模块/底座中随机组合 | 选择后正确加入库存 |
| 6.4 局外成长系统 | 跨局解锁新模块/遗物池 | 存档读写正确 |
| 6.5 逻辑流向预览 | 部署时显示子弹预期弹道 | 半透明虚线，不遮挡操作 |
| 6.6 移动端优化 | 触摸拖拽、模块安装手势 | iOS/Android 无误触 |

---

## 实施建议

### 版本管理

```bash
git tag -a v0.2-phase1 -m "Phase 1 完成: 项目结构重构 + 代码质量修复"
git tag -a v0.3-phase2 -m "Phase 2 完成: Tower 架构重构"
git tag -a v0.4-phase3 -m "Phase 3 完成: Bullet 数据包系统"
git tag -a v0.5-phase4 -m "Phase 4 完成: 模块系统"
git tag -a v0.8-phase5 -m "Phase 5 完成: 遗物系统"
git tag -a v1.0.0     -m "v1.0 发布: 完整 Roguelike 循环"
```

### 测试策略

1. **每个任务完成后** - 运行游戏，验证现有功能未损坏
2. **每个 Phase 完成后** - 完整回归测试 + 打 tag
3. **Phase 2 特别验证** - 重构后 tower 行为与改动前 100% 等价；StatAttribute 数值增删可安全回退
4. **Phase 3 特别验证** - 对象池内存占用与裸 instantiate 对比

### 文档维护

- `doc/DESIGN_V1.0.md` - 核心设计方案
- `doc/IMPLEMENTATION_PLAN.md` - 本文件，阶段进度
- `doc/DEVELOPER.md` - 架构与实现细节
- `CLAUDE.md` - Claude Code 上下文指引
