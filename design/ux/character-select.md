# UX Spec: Character Select

> **Status**: In Design
> **Author**: user + ux-designer
> **Last Updated**: 2026-04-17
> **Journey Phase(s)**: Pre-run setup (between Start Menu and game)
> **Template**: UX Spec
> **Language**: Chinese (all UI text)
> **Visual Style**: Minimalist modern — whitespace, flat, monochrome

---

## Purpose & Player Need

角色选择屏位于 Start Menu 之后、正式游戏之前。玩家在此选择一个角色，该角色携带的被动属性将影响整局的伤害、射速等核心数值。当前仅 Vera 可用，Mox 和 Wren 作为锁定占位展示，让玩家感知角色系统的存在感。如果这个屏幕体验差或难以使用，玩家会在游戏开始前就感到困惑，影响对游戏深度的第一印象。

---

## Player Context on Arrival

玩家在 Start Menu 选择了游戏模式后按 Start 进入此屏。此时玩家处于准备状态，期待快速进入游戏。角色选择是一个一次性决策——选定后整局不可更改。Vera 默认预选中，玩家可以不假思索直接 Confirm 开始游戏，也可以花几秒看一下角色描述。对于首次游玩的玩家，这里建立了对"角色系统"的第一印象：原来角色有不同玩法倾向。

---

## Navigation Position

位于导航层级的中间位置：`Start Menu → Character Select → 正式游戏(main.tscn)`。仅能从 Start Menu 的 Start 按钮进入。DEV 模式下完全跳过此屏。

---

## Entry & Exit Points

**入口：** 唯一入口是 Start Menu 按 Start。玩家到达时已选定游戏模式（混乱/普通），GameState.character 在 StartMenu._ready() 被重置为 null。

**出口：** Back 返回 Start Menu（不保存选择）。Confirm 将选中的角色写入 GameState.character 并跳转 main.tscn。DEV 模式下直接跳过此屏，不经过。

---

## Layout Specification

### Information Hierarchy

按重要性排序：

1. **角色卡片** — 视觉主体，玩家第一眼看到的内容
2. **角色详情面板** — 补充信息，辅助最终决策
3. **确认按钮** — 操作入口，页面底部居中
4. **返回按钮** — 辅助操作，左上角
5. **标题** — 已移除，不占用视觉空间

### Layout Zones

**配色方案（浅色极简）：**
- 背景：`#F5F5F7`（浅灰白，Apple 风格）
- 卡片可用：`#FFFFFF`（纯白），带微妙阴影
- 卡片锁定：`#E8E8ED`（淡灰，desaturated）
- 选中强调色：`#007AFF`（系统蓝）
- 文字主色：`#1D1D1F`（近黑）
- 文字辅色：`#86868B`（中灰）
- 分隔线：`#E5E5E7`

**卡片设计（圆角极简）：**
- 圆角：`12px`
- 可用卡片：白色底，`box-shadow: 0 1px 3px rgba(0,0,0,0.08)`
- 选中状态：`2px #007AFF` 边框 + 右上角 ✓ 图标
- 锁定卡片：`#E8E8ED` 底，无阴影，肖像 desaturated（grayscale 100%）
- 最小尺寸：`140×200px`

### Component Inventory

| 组件 | 类型 | 内容 | 交互 | 状态 |
|------|------|------|------|------|
| 返回按钮 | Button | "← 返回" | 点击 | 始终可用 |
| 角色卡片×3 | PanelContainer | 头像/占位符 + 中文名 + 中文 tagline | 点击选择 | 可选/锁定 |
| 分隔线 | HSeparator | — | 无 | 静态 |
| 详情名称 | Label | 中文名 | 无 | 随选中变化 |
| 详情 tagline | Label | 中文 tagline | 无 | 随选中变化 |
| 详情描述 | Label | 中文描述 | 无 | 随选中变化 |
| 确认按钮 | Button | "确认选择" | 点击 | 始终可用 |

### ASCII Wireframe

```
+--------------------------------------------+
| ← 返回                                     |
|                                            |
|  +----------+  +----------+  +----------+  |
|  |          |  |          |  |          |  |
|  |  Vera    |  |  Mox     |  |  Wren    |  |
|  |  精准一击  |  |  每杀赚金  |  |  见过风浪  |  |
|  |          |  |  即将推出  |  |  即将推出  |  |
|  |          |  |          |  |          |  |
|  +----------+  +----------+  +----------+  |
|                                            |
|  ──────────────────────────────────        |
|                                            |
|  Vera                                      |
|  一发入魂，足以致命。                       |
|  Vera 的塔攻击力极高但需要耐心等待。        |
|  一轮齐射可清空一波敌人，但火力空档代价高昂。|
|                                            |
|         +------------------+                |
|         |    确认选择       |                |
|         +------------------+                |
+--------------------------------------------+
```

---

## States & Variants

| 状态 | 触发 | 变化 |
|------|------|------|
| 默认/已选中 | 页面 `_ready()` | Vera 预选中，蓝色边框 + ✓，详情面板填充 Vera 信息 |
| 切换选中 | 点击其他可用卡片 | 原卡片取消高亮，新卡片获得蓝色边框 + ✓，详情面板更新 |
| 锁定反馈 | 点击锁定卡片 | 卡片水平抖动 200ms，"即将推出" tooltip 显示 1.5s，不改变选中状态 |
| DEV 模式 | `GameState.is_dev_mode()` 为 true | 此屏不出现，Start Menu 直接跳 main.tscn |

无空数据状态（角色硬编码预加载 3 个，不可能为空）。

---

## Interaction Map

| 组件 | 操作 | 输入方式 | 反馈 | 结果 |
|------|------|----------|------|------|
| 返回按钮 | 点击 | 鼠标左键 / 触摸 | 按钮按下态 | 返回 Start Menu，不保存选择 |
| 角色卡片（可用） | 点击 | 鼠标左键 / 触摸 | 蓝色边框 + ✓ 立即出现 | 更新选中状态，详情面板刷新 |
| 角色卡片（锁定） | 点击 | 鼠标左键 / 触摸 | 抖动 200ms + "即将推出" tooltip 1.5s | 无状态变化 |
| 确认按钮 | 点击 | 鼠标左键 / 触摸 | 按钮按下态 | 保存角色到 GameState，跳转 main.tscn |

所有交互均为单次点击/触摸触发，无长按、拖拽、滑动操作。

---

## Events Fired

| 玩家操作 | 触发事件 | 数据 |
|----------|----------|------|
| 点击返回 | 无 | —（纯场景跳转） |
| 选择角色卡片 | 无 | —（仅 UI 状态变化） |
| 点击确认 | 无 | —（仅写入 GameState.character） |
| 点击锁定卡片 | 无 | —（仅 UI 反馈） |

本屏不产生任何分析事件或游戏状态变更。角色选择仅在 Confirm 时写入 `GameState.character`，由后续系统读取。

---

## Transitions & Animations

| 过渡 | 方式 | 时长 |
|------|------|------|
| 屏幕进入 | 淡入 (fade in) | 150ms |
| 屏幕退出 | 淡出 (fade out) | 150ms |
| 选中态切换 | 边框颜色过渡 | 100ms |
| 锁定卡片抖动 | 水平位移振荡 | 200ms |
| "即将推出" tooltip | 淡入/淡出 | 100ms / 200ms |
| 卡片选中背景 | 颜色过渡 | 100ms |

无可能导致晕动症的大幅度动画。

---

## Data Requirements

| 数据 | 来源系统 | 读/写 | 备注 |
|------|----------|-------|------|
| 角色列表 | 硬编码预加载 | Read | `VERA`, `MOX`, `WREN` 三个 `CharacterData` |
| 角色名称/tagline/描述 | `CharacterData` 资源 | Read | 直接读取 `.display_name` / `.tagline` / `.description` |
| 角色可用性 | `CharacterData.is_available` | Read | 控制卡片交互和视觉 |
| 角色头像 | `CharacterData.portrait` | Read | 可用时显示，锁定时灰度 |
| 选中角色 | 本地 UI 状态 → `GameState.character` | Write | 仅 Confirm 时写入 |

UI 不拥有游戏状态。所有数据通过 `CharacterData` 资源提供，选中结果通过 `GameState.character` 持久化。

---

## Accessibility

| 要求 | 实现方式 |
|------|----------|
| 最小触摸目标 | 所有可点击元素 ≥ 48×48px |
| 文字可读性 | 主标题 ≥ 20px，正文 ≥ 14px，对比度 ≥ 4.5:1 |
| 色盲安全 | 选中态不用颜色单独标识，同时使用边框 + ✓ 图标 |
| 锁定反馈 | 不用颜色传达锁定状态，使用 "即将推出" 文字 + 抖动动画 |
| 浅色底适配 | 锁定卡片底色 `#E8E8ED` 与背景 `#F5F5F7` 有足够对比 |
| 键盘导航 | 本游戏目标为 Touch/Mouse，暂不实现键盘导航 |

---

## Localization Considerations

当前所有文本直接写入 `.tres` 资源文件，不使用 Godot TranslationServer。

| 文本元素 | 当前语言 | 最大宽度限制 | 扩展风险 |
|----------|----------|--------------|----------|
| 角色名（中文） | 2-4 汉字 | 卡片宽度内无风险 | 英文翻译时可能变长 |
| Tagline（中文） | 4-8 汉字 | 卡片宽度内无风险 | 英文翻译可能多 30% 字符 |
| 描述（中文） | 1-3 行 | 详情面板自动换行 | 英文翻译可能多行 |
| 按钮文字 | "← 返回" / "确认选择" | 按钮宽度充足 | 英文翻译可能变长 |
| "即将推出" | 4 汉字 | 卡片内居中 | 英文 "Coming Soon" 略长但无风险 |

当前中文文案长度在浅色底布局下无溢出风险。

---

## Acceptance Criteria

- [ ] 屏幕在 150ms 内从 Start Menu 淡入完成
- [ ] 页面打开时 Vera 卡片已处于选中态（蓝色边框 + ✓），详情面板显示 Vera 的中文名、tagline、描述
- [ ] 点击 Mox 或 Wren 卡片不改变选中状态，卡片抖动 200ms 并显示 "即将推出" tooltip
- [ ] 点击 Confirm 后 `GameState.character.id == &"vera"`，场景切换到 main.tscn
- [ ] 点击返回按钮返回 Start Menu，`GameState.character` 保持 null
- [ ] 锁定卡片与可用卡片通过背景色（#E8E8ED vs #FFFFFF）和 "即将推出" 文字区分，不依赖颜色单独传达
- [ ] 所有文字对比度在浅色底上 ≥ 4.5:1，正文字号 ≥ 14px
- [ ] 锁定卡片点击后 2 秒内重复点击不重复触发 tooltip（防抖）

---

## Open Questions

- 角色中文名文案是否最终确认？当前 GDD 使用英文 tagline，需要确定中文翻译
- Vera 头像资源是否存在？如无，需要占位符设计（纯色圆形/字母 V）
- Mox/Wren 锁定状态的占位视觉是否需要更具体的设计（如锁图标）？
