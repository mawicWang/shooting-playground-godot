# 如何运行测试

## 使用 Godot 编辑器（推荐）

1. 打开 Godot 4.4+ 编辑器并加载本项目
2. 顶部菜单 `GdUnit` → `Run Tests`，或在右侧 GdUnit 面板中选择特定测试

## 测试套件一览

所有 GdUnit4 测试位于 `tests/gdunit/`：

| 文件 | 说明 | 是否需要运行时 |
|------|------|--------------|
| `StatAttributeTest.gd` | StatAttribute 修饰符计算逻辑 | 否（纯数据） |
| `BulletDataTest.gd` | BulletData 复制和修改 | 否（纯数据） |
| `ModuleTest.gd` | 模块资源完整性 + 安装/卸载生命周期 | 否 |
| `EffectTriggerTest.gd` | Effect 触发行为（via MockTower） | 否 |
| `FullChainTest.gd` | 完整效果链条端到端测试 ★ | 否 |
| `IntegrationTest.gd` | 真实 Tower/Enemy 场景集成测试 | **是**（有时间等待） |

## 完整效果链条测试（FullChainTest）

测试"安装模块 → 子弹携带 effects → 击中目标 → 效果触发"全流程，无需运行时：

1. 安装 `cd_on_hit_enemy` → 击中敌人 → 塔的 CD 减少 0.5s
2. 安装 `replenish1` → 击中塔 → 目标塔弹药 +1
3. `accelerator` 的 stat_modifiers 正确修改子弹速度
4. 子弹 `transmission_chain` 绑定到发射塔
5. 多个 effect 在同一子弹上同时触发
6. 卸载模块后 effects 和 stat 完全回滚

## 场景集成测试（IntegrationTest）

实例化真实 Tower + Enemy 场景节点，验证：

1. `start_firing()` → 等待 CD 到期 → bullets 组中出现子弹
2. 子弹沿正确方向飞行并触发 `enemy_hit`
3. `take_damage` 后 `current_health` 下降
4. 3 次命中后 `enemy_destroyed` 触发
5. 有限弹药（`ammo=5`）在开火后递减
6. 5 秒内发射多发子弹

> **注意**：IntegrationTest 单个测试最长等待 5 秒，整套约需 15–20 秒。

## 模拟对象

`tests/mock_tower.gd` 的 `MockTower` 类：

- 无任何 autoload 依赖（GameState、BulletPool、EventManager 等）
- 实现完整的 StatAttribute 系统（CD / speed / attack / ammo_extra）
- 实现 `install_module` / `uninstall_module` / `add_ammo` / `reduce_cooldown`
- 记录所有方法调用（`reduce_cooldown_calls`、`ammo_added` 等）供断言

## 独立验证脚本

`tests/validate.gd` 可单独运行，快速检查场景和脚本完整性：

```bash
godot --headless --script tests/validate.gd
```

## 添加新测试

1. 在 `tests/gdunit/` 下创建新文件，继承 `GdUnitTestSuite`
2. 函数名以 `test_` 开头
3. 节点用 `auto_free(obj)` 自动清理
4. 使用 `assert_*` 系列方法断言

详细文档见 [`docs/tests/gdunit_testing.md`](../tests/gdunit_testing.md)。

## 已知问题

- GdUnit4 v5.0.3 在 Godot 4.4 命令行模式下可能有兼容性问题，建议使用编辑器
- 遇到问题时尝试重新导入项目，或确认 GdUnit4 插件已在 `项目设置 → 插件` 中启用
