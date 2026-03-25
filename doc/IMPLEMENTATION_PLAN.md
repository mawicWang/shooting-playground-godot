# Shooting Playground v1.0 实施计划

> 基于 DESIGN_V1.0.md 的分步重构与功能实现方案

---

## 整体策略

### 核心原则
1. **渐进式重构** - 每一步都保持现有功能完整
2. **先重构，后功能** - 架构先行，功能后置
3. **可回滚** - 每个阶段都能随时回退到稳定版本
4. **测试驱动** - 关键重构节点需验证所有现有功能

### 阶段划分

```
Phase 1: 项目结构重构 (基础架构)
Phase 2: Tower 架构重构 (可扩展底座系统)
Phase 3: Bullet 架构重构 (信号数据包系统)
Phase 4: 组件与模块系统 (Modules)
Phase 5: 遗物系统 (Relics)
Phase 6: Roguelike 循环与 UI
```

---

## Phase 1: 项目结构重构

### 目标
建立清晰的分层架构，为后续组件化开发奠定基础。

### 目录结构调整

```
res://
├── main.tscn                    # 主场景（入口）
├── main.gd                      # 主控制器（精简）
│
├── autoload/                    # 自动加载单例
│   ├── GameState.gd            # 游戏状态管理（替代 DragManager 全局功能）
│   ├── SignalBus.gd            # 全局信号总线
│   └── EventManager.gd         # 事件系统（遗物触发等）
│
├── core/                        # 核心抽象层
│   ├── TowerBase.gd            # 炮塔抽象基类
│   ├── BulletBase.gd           # 子弹抽象基类
│   ├── Component.gd            # 组件基类
│   └── Module.gd               # 模块基类（Resource）
│
├── entities/                    # 实体实现
│   ├── towers/                 # 炮塔实例
│   │   ├── TowerBaseScene.tscn # 基础炮塔场景
│   │   ├── chassis/            # 底座类型
│   │   │   ├── EmitterChassis.gd
│   │   │   ├── RelayChassis.gd
│   │   │   └── TerminalChassis.gd
│   │   └── TowerFactory.gd     # 炮塔工厂
│   │
│   ├── bullets/
│   │   ├── BulletBaseScene.tscn
│   │   └── BulletFactory.gd
│   │
│   ├── enemies/
│   │   ├── enemy.tscn
│   │   └── enemy.gd
│   │
│   └── modules/                # 逻辑模块
│       ├── computational/      # 计算类
│       └── logical/            # 逻辑类
│
├── components/                  # 可复用组件
│   ├── Damageable.gd           # 受伤组件
│   ├── Rotatable.gd            # 旋转组件（提取自 tower）
│   ├── Shootable.gd            # 射击组件
│   ├── SignalReceiver.gd       # 信号接收
│   └── SignalTransmitter.gd    # 信号发射
│
├── grid/                        # 网格系统
│   ├── cell.tscn
│   ├── cell.gd
│   ├── GridManager.gd          # 重命名自 grid_manager.gd
│   └── GridUtils.gd
│
├── ui/                          # UI 系统
│   ├── hud/
│   ├── shop/
│   ├── deployment/
│   └── popups/
│
├── relics/                      # 遗物系统
│   ├── RelicBase.gd
│   └── implementations/
│
└── resources/                   # 数据资源
    ├── tower_data/
    ├── module_data/
    └── relic_data/
```

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 1.1 创建目录结构 | 按上述结构创建空目录和 .gitkeep | 目录完整 |
| 1.2 迁移现有文件 | 将现有脚本移动到对应目录，更新引用 | 无报错运行 |
| 1.3 创建 SignalBus | 全局信号总线，替代直接节点引用 | 信号正常传递 |
| 1.4 创建 GameState | 管理游戏状态（开始/停止/拖拽状态） | 状态同步正确 |
| 1.5 重构 main.gd | 精简为协调者角色 | 功能不变，代码 < 200 行 |

### 风险点
- **DragManager 迁移** - 需要小心处理全局拖拽状态
- **节点路径引用** - 需要批量更新 `get_node()` 路径

---

## Phase 2: Tower 架构重构

### 目标
实现底座+组件的组装式架构，支持 Emitter/Relay/Terminal 三种类型。

### 类图设计

```
                    ┌──────────────────┐
                    │   TowerBase      │  ← 抽象基类
                    │   (Node2D)       │
                    ├──────────────────┤
                    │ - chassis_type   │
                    │ - muzzle_count   │
                    │ - slot_count     │
                    │ - modules[]      │
                    ├──────────────────┤
                    │ + setup_chassis()│
                    │ + install_module()│
                    │ + receive_signal()│
                    │ + fire()         │
                    └────────┬─────────┘
                             │ 继承
            ┌────────────────┼────────────────┐
            ▼                ▼                ▼
   ┌────────────────┐ ┌──────────────┐ ┌──────────────┐
   │ EmitterTower   │ │ RelayTower   │ │ TerminalTower│
   │                │ │              │ │              │
   │ - auto_fire    │ │ - trigger_on │ │ - absorb     │
   │   timer        │ │   hit        │ │ - charge     │
   └────────────────┘ └──────────────┘ └──────────────┘
```

### Component 组装模式

```gdscript
# TowerBase.gd - 组合模式
class_name TowerBase extends Node2D

@export var chassis_data: ChassisData  # Resource 配置

var components: Dictionary = {}

func _ready():
    # 动态添加组件
    add_component("rotatable", RotatableComponent.new(self))
    add_component("shootable", ShootableComponent.new(self, chassis_data.muzzles))
    
    # 根据底座类型添加特定组件
    match chassis_data.type:
        ChassisType.EMITTER:
            add_component("emitter", EmitterComponent.new(self))
        ChassisType.RELAY:
            add_component("relay", RelayComponent.new(self))
        ChassisType.TERMINAL:
            add_component("terminal", TerminalComponent.new(self))

func add_component(name: String, component: Component):
    components[name] = component
    add_child(component)

func get_component(name: String) -> Component:
    return components.get(name)

# 转发方法到组件
func rotate_clockwise():
    get_component("rotatable")?.rotate_90_clockwise()
```

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 2.1 创建 Component 基类 | 所有组件继承 Node，持有 tower 引用 | 组件可访问父塔 |
| 2.2 创建 RotatableComponent | 提取 tower.gd 旋转逻辑 | 旋转功能正常 |
| 2.3 创建 ShootableComponent | 提取射击逻辑 | 射击功能正常 |
| 2.4 创建 TowerBase | 抽象基类，组装组件 | 可实例化测试 |
| 2.5 创建 EmitterTower | 发射源类型 | 定时发射子弹 |
| 2.6 创建 RelayTower | 中继器类型 | 被击中后转发 |
| 2.7 创建 TowerFactory | 工厂模式创建炮塔 | 支持旧塔数据迁移 |
| 2.8 迁移现有 tower | 用新架构替换旧 tower | 所有功能等价 |

### 兼容性策略

```gdscript
# TowerFactory.gd - 兼容旧数据
static func create_from_legacy(legacy_tower: Node) -> TowerBase:
    """从旧 tower 节点创建新架构炮塔"""
    var new_tower = preload("res://entities/towers/TowerBaseScene.tscn").instantiate()
    
    # 复制基础属性
    new_tower.rotation = legacy_tower.rotation
    new_tower.position = legacy_tower.position
    
    # 默认创建 Emitter 类型（保持现有行为）
    new_tower.setup_chassis(ChassisType.EMITTER, muzzle_count=1, slot_count=0)
    
    return new_tower
```

---

## Phase 3: Bullet 架构重构

### 目标
实现信号数据包系统，支持携带能量、属性等数据。

### 数据结构

```gdscript
# BulletData.gd - Resource
class_name BulletData extends Resource

enum ElementType { NEUTRAL, FIRE, ICE, ELECTRIC }

var energy: float = 1.0           # 能量/伤害值
var speed: float = 300.0          # 飞行速度
var element: ElementType = ElementType.NEUTRAL
var source_tower: TowerBase       # 发射源
var bounce_count: int = 0         # 弹跳次数
var piercing: bool = false        # 是否穿透

# 信号传递链
var transmission_chain: Array[TowerBase] = []

func duplicate_with_mods(mods: Dictionary) -> BulletData:
    """创建带有修改的数据副本"""
    var copy = self.duplicate()
    for key in mods:
        copy.set(key, mods[key])
    return copy
```

### 碰撞检测重构

```gdscript
# SignalReceiver.gd - 组件
class_name SignalReceiver extends Component

func _ready():
    # 设置 Area2D 碰撞层
    var area = Area2D.new()
    area.collision_layer = 2  # 信号层
    area.collision_mask = 2   # 只检测信号
    
    area.area_entered.connect(_on_signal_entered)

func _on_signal_entered(bullet: BulletBase):
    # 检查是否来自有效源
    if bullet.data.source_tower == owner:
        return  # 忽略自己发射的
    
    # 触发中继逻辑
    if owner is RelayTower:
        owner.retransmit(bullet.data)
    
    # 触发终端逻辑
    if owner is TerminalTower:
        owner.absorb(bullet.data)
```

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 3.1 创建 BulletData Resource | 信号数据结构 | 可序列化存储 |
| 3.2 创建 BulletBase | 子弹抽象基类 | 支持 data 驱动 |
| 3.3 创建 BulletFactory | 工厂创建子弹 | 支持属性修改 |
| 3.4 重构 Bullet 碰撞 | 改为 Area2D 检测 | 可检测塔间传递 |
| 3.5 实现信号链追踪 | 记录传递路径 | 用于遗物递归逻辑 |
| 3.6 迁移现有 bullet | 替换旧 bullet | 功能等价 |

---

## Phase 4: 组件与模块系统

### 目标
实现可插拔的模块系统，支持运行时安装/卸载。

### Module Resource 设计

```gdscript
# Module.gd - Resource
class_name Module extends Resource

enum Category { COMPUTATIONAL, LOGICAL, SPECIAL }

@export var module_name: String
@export var category: Category
@export var description: String
@export var icon: Texture2D

# 虚拟方法，子类重写
func apply_effect(tower: TowerBase, bullet_data: BulletData) -> BulletData:
    """修改子弹数据并返回"""
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
```

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
 4.1 创建 Module 基类 | Resource 基类 | 可定义模块数据 |
| 4.2 实现插槽系统 | TowerBase 支持 slots[] | 可安装/卸载模块 |
| 4.3 创建乘法器模块 | MultiplierModule | 能量倍增效果 |
| 4.4 创建加速器模块 | AcceleratorModule | 速度提升 |
| 4.5 创建分频器模块 | DividerModule | 计数触发 |
| 4.6 创建过滤器模块 | FilterModule | 属性筛选 |
| 4.7 模块安装 UI | 拖拽安装模块 | 与现有拖拽兼容 |

---

## Phase 5: 遗物系统

### 目标
实现全局机制修改器，增强策略深度。

### 遗物基类

```gdscript
# Relic.gd - Resource
class_name Relic extends Resource

@export var relic_name: String
@export var description: String
@export var rarity: int  # 1-4

# 钩子方法，遗物系统调用
func on_bullet_transmit(bullet: BulletData, from: TowerBase, to: TowerBase):
    pass

func on_terminal_absorb(terminal: TerminalTower, bullet: BulletData):
    pass

func on_wave_start():
    pass
```

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 5.1 创建 Relic 基类 | 钩子系统 | 可监听全局事件 |
| 5.2 创建 EventManager | 全局事件分发 | 遗物可注册监听 |
| 5.3 实现"量子纠缠" | 终端共享能量 | 多终端同步效果 |
| 5.4 实现"超导回路" | 速度不衰减+电击 | 子弹传递增强 |
| 5.5 实现"递归逻辑" | 闭环增强 | 检测循环并增强 |
| 5.6 实现"多线程" | 发射源双炮口 | 修改底座属性 |

---

## Phase 6: Roguelike 循环与 UI

### 目标
完成游戏循环，实现局外成长和局内构建。

### 具体任务

| 任务 | 描述 | 验收标准 |
|------|------|----------|
| 6.1 情报预警 UI | 显示敌人波次信息 | 方向/类型提示 |
| 6.2 炮塔商店系统 | 购买底座和模块 | 货币系统 |
| 6.3 战后奖励选择 | 三选一奖励 | 可领取遗物/模块 |
| 6.4 局外成长系统 | Meta-progression | 解锁新模块 |
| 6.5 视觉流向预览 | 部署时显示弹道 | 半透明预览线 |
| 6.6 移动端优化 | 触摸交互优化 | 点击/手势区分 |

---

## 实施建议

### 版本管理

```bash
# 每个 Phase 完成后打 tag
git tag -a v0.9-phase1 -m "Phase 1 完成: 项目结构重构"
git tag -a v0.9-phase2 -m "Phase 2 完成: Tower 架构重构"
# ...
git tag -a v1.0.0 -m "v1.0 发布"
```

### 测试策略

1. **每个任务完成后** - 运行现有游戏，验证功能未损坏
2. **每个 Phase 完成后** - 完整测试所有现有功能
3. **添加新功能后** - 单元测试 + 集成测试

### 文档维护

- `docs/API.md` - 核心类 API 文档
- `docs/MIGRATION.md` - 迁移指南
- `docs/CHANGELOG.md` - 变更日志

---

## 下一步行动

1. **Review** - 确认 Phase 1 目录结构和迁移方案
2. **Setup** - 创建 Phase 1 分支 `git checkout -b phase1-restructure`
3. **Start** - 执行 Phase 1 任务 1.1

**准备好了吗？我们可以从 Phase 1 开始！**
