# 战场区域独立化与交互优化

## 概述

将游戏核心区域（Grid + 敌人 + 子弹 + Dead Zone）封装为独立的 BattlefieldContainer，支持战斗阶段的拖拽平移和缩放动画，并联动隐藏部署 UI。

## 1. 场景树重构

在 GameContent 下新增 `BattlefieldContainer`（Node2D），将 GridRoot 及所有运行时战场元素移入其下。

```
main (Control)
├── Background
├── GameContent (Control, 720px max)
│   ├── PanelContainer         (顶部按钮栏 — 固定)
│   ├── RemovalZonePanel       (底部部署UI — 战斗时隐藏)
│   ├── RelicPanel             (固定)
│   └── BattlefieldContainer   (Node2D — 新增)
│       ├── GridRoot → Grid (5×5)
│       ├── EnemyManager       (运行时创建)
│       ├── Dead Zones ×4      (运行时创建)
│       └── Bullets            (BulletPool 在此容器下生成)
├── LivesLabel, CoinLabel, FpsLabel  (HUD — 固定)
```

**关键点：** BattlefieldContainer 的 position 设为 Grid 中心在屏幕上的位置。GridRoot 作为子节点需要相应偏移，使 Grid 视觉位置不变。

## 2. 战场范围

- 逻辑战场范围：**12×12 Cell**（960×960px），Grid 居中其内
- 此值可配置（导出变量或常量），未来可调节
- 战场范围定义了拖拽边界、Dead Zone 位置、敌人生成范围

## 3. 拖拽平移（Pan）

- **仅战斗阶段（RUNNING）可用**，部署阶段禁用
- 交互：在战场空白区域按住拖动
- 移动 BattlefieldContainer 的 position
- 边界限制：position 偏移不超出战场范围（clamp）
- 战斗结束时，position 通过 Tween 回到初始位置

## 4. 缩放动画

- **战斗开始：** BattlefieldContainer.scale 从 1.0 Tween 到 0.85（具体值可调，范围 0.8~0.9）
- **战斗结束：** scale Tween 回 1.0
- **缩放锚点：** Grid 中心（即 BattlefieldContainer 的 position）
- **Tween 时长：** 约 0.3s，ease-out

## 5. 部署 UI 隐藏

- 战斗开始：隐藏 RemovalZonePanel（`visible = false`）
- 战斗结束：显示 RemovalZonePanel（`visible = true`）
- **Dev 模式例外：** Dev 模式下不隐藏，保持可见
- 缩放和拖拽在 Dev 模式下正常启用

## 6. 敌人生成位置

- 生成距离：距 Grid 边缘 **3 个 Cell**（240px），替代当前的 60px
- SPAWN_MARGIN 改为 `3 * CELL_SIZE`（240px）
- WARNING_DISTANCE 同步调整

## 7. Dead Zone 外扩

- Dead Zone 定位改为基于战场范围边缘，而非 Viewport 边缘
- 4 个 Dead Zone 围绕 12×12 Cell 的战场范围放置
- 确保子弹在敌人生成线之外才被回收

## 8. 状态转换时序

### 开始战斗

1. 隐藏部署 UI（非 Dev 模式）
2. Tween: BattlefieldContainer.scale → 0.85, ~0.3s
3. 启用拖拽平移输入
4. 创建 Dead Zone（战场边缘）
5. 生成敌人（距 Grid 3 Cell）
6. 塔开始射击

### 战斗结束

1. 停止射击、清除子弹、移除敌人
2. 移除 Dead Zone
3. 禁用拖拽平移
4. Tween: BattlefieldContainer.scale → 1.0, ~0.3s
5. Tween: BattlefieldContainer.position → 初始位置, ~0.3s
6. 显示部署 UI

## 9. 需要修改的文件

| 文件 | 改动 |
|------|------|
| `main.tscn` | 新增 BattlefieldContainer Node2D，GridRoot 移入其下 |
| 新增 `core/battlefield_container.gd` | 拖拽平移 + 缩放逻辑 |
| `main.gd` | 初始化 BattlefieldContainer，战斗时隐藏/显示部署 UI |
| `core/GameLoopManager.gd` | 触发缩放/平移启停 |
| `core/dead_zone_manager.gd` | Dead Zone 定位改为基于战场范围 |
| `entities/enemies/enemy_manager.gd` | SPAWN_MARGIN 改为 240px |
| `autoload/SignalBus.gd` | 按需新增信号 |
