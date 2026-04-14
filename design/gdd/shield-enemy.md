# Shield Enemy System — Agent Reference

> 本文档是护盾敌人系统的权威参考。修改护盾逻辑前请先阅读"战斗机制"一节，
> 避免破坏护盾/血量的隔离性。测试覆盖见 `tests/gdunit/ShieldEnemyTest.gd`。

---

## 1. 系统概述

**护盾敌人（ShieldEnemy）** 是一种带多层护盾的敌人变体。护盾耗尽前本体不受任何伤害，
形成"先破盾、再打血"的两阶段战斗体验。

核心规则：
- 每层护盾抵挡 **一次完整伤害**，无视伤害量
- 护盾层数可配置（默认 2 层）
- 护盾存在时，HP 条不变化
- 最后一层破盾触发短暂 **僵直（0.25s）**
- 僵直结束后，等价于普通敌人

---

## 2. 组件一览

| 文件 | 类 / 职责 |
|------|----------|
| `entities/enemies/shield_enemy.gd` | 主脚本，继承 `enemy.gd`；覆盖 `take_damage()` 实现护盾逻辑 |
| `entities/enemies/shield_enemy.tscn` | 场景文件，蓝色调 Sprite（modulate `0.5,0.7,1.0`），同 `strong_enemy.tscn` 结构 |
| `entities/enemies/shield_bubble.gd` | 视觉气泡叠层，脉动动画 + 受击涟漪 + 破碎淡出 |
| `entities/enemies/shield_bubble.gdshader` | canvas_item 着色器：呼吸动画、边缘光晕、涟漪扩散 |
| `ui/hud/shield_bar.gd` | 分段式护盾条，绘制在 HP 条上方（`OFFSET_Y = -44`） |
| `entities/enemies/shield_break_effect.gd` | 破碎特效：8 块碎片向外飞溅，0.5s 后自毁 |

---

## 3. 战斗机制

### 护盾吸收流程

```
take_damage(amount) 被调用
    ↓
if shield_layers > 0:
    shield_layers -= 1
    更新护盾条
    SignalBus.enemy_damaged(self, damage=0.0, ...)   ← HP 信号发出 0 伤害
    显示 "0" 伤害数字
    if layers == 0: _break_shield()
    else:           bubble.play_ripple()
    return  ← 不调用 super.take_damage()
else:
    super.take_damage(amount)   ← 正常扣血
```

### 破盾事件（`_break_shield()`）

1. `_shield_bubble.play_break()` — 气泡 0.2s 淡出并隐藏
2. `ShieldBreakEffect.play(position)` — 碎片飞溅特效
3. `speed = 0`, `_is_stunned = true`
4. 0.25s 后：`_is_stunned = false`, `speed = 25.0`

> **注意：** 僵直期间的 `take_damage()` 调用会直接 return，不触发任何效果。

---

## 4. 视觉组件

### ShieldBubble（`shield_bubble.gd` + `shield_bubble.gdshader`）

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `pulse_speed` | 2.0 | 呼吸动画速度 |
| `pulse_min` / `pulse_max` | 0.3 / 0.7 | Alpha 脉动范围 |
| `layer_intensity` | 1.0 | 层数比例控制亮度，由 `update_layers()` 设置（clamp 0.2..1.0） |
| `shield_color` | `(0.3, 0.5, 1.0, 0.5)` | 蓝色半透明 |
| `ripple_time` | -1.0 | 受击时设置为 TIME，驱动扩散环效果 |

**方法：**
- `setup(max_layers)` — 创建白色 64×64 ImageTexture，挂载着色器，缩放至 56×56
- `update_layers(current)` — 更新 `layer_intensity`（层数越少越暗）
- `play_ripple()` — 闪亮 + 0.4s 后恢复强度
- `play_break()` — 0.2s 淡出，然后 `visible = false`

### ShieldBar（`ui/hud/shield_bar.gd`）

绘制在 HP 条上方，`OFFSET_Y = -44`（HP 条在 `-36`）。

- 宽 48px，高 5px，分段间距 2px
- 颜色：蓝色 `(0.3, 0.55, 1.0, 0.9)`
- `update(current, max_layers)` — `current == 0` 时自动隐藏（`visible = false`）

### ShieldBreakEffect（`shield_break_effect.gd`）

- 8 块 `ColorRect` 碎片，大小 5×5，蓝白配色
- 均匀分布角度（± 0.3 rad 随机抖动）
- 飞行距离：40px × randf(0.6..1.2)
- 动画：EASE_OUT/TRANS_CUBIC，0.5s，淡出 + 旋转
- 自毁：0.55s 后 `queue_free()`

---

## 5. 生成权重

在 `enemy_spawn_picker.gd` 中：

| 波次 | 普通敌人权重 | 强敌权重 | 护盾敌人权重 |
|------|------------|---------|------------|
| 1–2  | 5 | 0 | 0 |
| 3–4  | 5 | 5+(wave-3) | 0 |
| 5    | 5 | 7 | 3 |
| 6    | 5 | 8 | 4 |
| N≥5  | 5 | 5+(N-3) | 3+(N-5) |

---

## 6. 属性一览

| 属性 | 值 |
|------|----|
| `speed` | 25.0（比普通敌人慢，比强敌快） |
| `max_health` | 4.0 |
| `shield_layers` | 2（可配置） |
| `max_shield_layers` | 2 |

---

## 7. 新增护盾敌人变体

1. 继承 `"res://entities/enemies/shield_enemy.gd"`
2. 在 `_ready()` 中设置 `shield_layers` / `max_shield_layers`，再调 `super._ready()`
3. 在 `enemy_spawn_picker.gd` 注册新场景及权重
4. 在 `ShieldEnemyTest.gd` 补充测试

---

## 8. 测试覆盖

测试文件：`tests/gdunit/ShieldEnemyTest.gd` — 9 个测试用例

| 测试 | 验证内容 |
|------|---------|
| `test_shield_enemy_initial_properties` | 初始属性：shield=2, hp=4, speed=25 |
| `test_shield_absorbs_damage_without_hp_loss` | 受击不扣血，护盾层数 -1 |
| `test_shield_absorbs_high_damage_as_one_layer` | 999 伤害也只消耗 1 层 |
| `test_two_hits_break_all_shields` | 2 次攻击耗尽全部护盾 |
| `test_stun_on_shield_break` | 破盾后立即进入僵直 |
| `test_stun_recovery` | 0.25s 后僵直结束，恢复移动 |
| `test_damage_after_shields_gone` | 护盾消耗后正常扣血 |
| `test_enemy_dies_after_shields_and_hp_depleted` | 完整击杀流程（2+4 次攻击） |
| `test_damage_ignored_during_stun` | 僵直期间受击无效 |
