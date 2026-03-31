# 如何运行测试

## 使用 Godot 编辑器（推荐）

1. 打开 Godot 4.4+ 编辑器
2. 加载 `shooting-playground-godot` 项目
3. 在顶部菜单栏点击 `GdUnit` → `Run Tests`
4. 或者在右侧面板中找到 GdUnit 面板，点击运行按钮

## 测试结构

### GdUnit4 测试套件
所有测试都在 `tests/gdunit/` 目录下：

- **ModuleTest.gd** - 模块资源完整性测试
- **StatAttributeTest.gd** - StatAttribute 计算逻辑测试  
- **BulletDataTest.gd** - BulletData 复制和修改测试
- **EffectTriggerTest.gd** - Effect 基础触发测试
- **FullChainTest.gd** - 完整效果链条测试 ★

### 完整效果链条测试

`FullChainTest.gd` 测试完整的"安装模块→发射子弹→击中目标→触发效果"链条：

1. **安装 cd_on_hit_enemy 模块** → 发射子弹 → 击中敌人 → 减少塔的 CD
2. **安装 replenish 模块** → 发射子弹 → 击中塔 → 补充弹药
3. 模块安装时 stat_modifiers 正确应用
4. 子弹从塔继承 effects
5. 多个 effects 在链条中正确触发
6. 模块卸载时 effects 正确清理

## 模拟对象

测试使用 `tests/mock_tower.gd` 中的 `MockTower` 类，它：

- 不依赖任何 autoload (GameState, BulletPool, EventManager 等)
- 实现 Module/Relic 交互所需的最小接口
- 提供 `add_ammo()`, `reduce_cooldown()` 等效果所需的方法
- 记录方法调用用于测试验证

## 验证脚本

`tests/validate.gd` 是一个独立的验证脚本，可以单独运行：

```bash
godot --headless --script tests/validate.gd
```

## 已知问题

- **GdUnit4 v5.0.3 在 Godot 4.4 命令行模式下可能有兼容性问题**
- 建议使用 Godot 编辑器中的 GdUnit 面板运行测试
- 如果遇到问题，尝试更新 GdUnit4 到最新版本

## 添加新测试

1. 在 `tests/gdunit/` 目录下创建新的测试文件
2. 继承 `GdUnitTestSuite` 类
3. 使用 `auto_free()` 自动清理创建的对象
4. 使用 `assert_*` 方法进行断言

## 测试覆盖率

测试覆盖了：
- 所有 14 个模块资源的加载和基本属性
- StatAttribute 的各种修饰符计算
- BulletData 的复制和修改
- Effect 的触发和验证
- 完整的模块→子弹→目标→效果链条

## 故障排除

### 测试无法运行
- 确保 GdUnit4 插件已启用
- 检查 Godot 版本是否兼容（4.4+）
- 尝试重新导入项目

### 测试失败
- 检查测试输出中的错误信息
- 确保所有依赖的资源路径正确
- 验证 MockTower 实现了所需的方法

### 性能问题
- 大量测试可能需要一些时间运行
- 使用 `skip()` 跳过不需要的测试
- 分批运行测试套件