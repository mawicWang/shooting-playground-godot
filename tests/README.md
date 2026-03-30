# Effect Test Harness — 效果验证脚手架

## 快速开始

```bash
# 运行所有测试
godot --headless --script res://tests/effect_test_harness.gd

# 在 CI 中使用（返回非零退出码表示失败）
godot --headless --script res://tests/effect_test_harness.gd || echo "Tests failed!"
```

## 设计哲学

### 为什么不用 GUT 或其他测试框架？

1. **零依赖** — 不需要安装额外的插件或库
2. **headless 友好** — 纯脚本运行，不依赖场景系统
3. **快速反馈** — 5 秒内完成全部测试
4. **渐进式** — 从纯数据测试开始，逐步添加集成测试

### 测试分层

```
┌─────────────────────────────────────────────────────────┐
│  Layer 3: 集成测试 (Integration)                         │
│  - 需要完整场景实例化                                     │
│  - 标记为 SLOW，CI 中可选运行                            │
│  - 验证端到端效果链                                       │
├─────────────────────────────────────────────────────────┤
│  Layer 2: 逻辑测试 (Logic)                               │
│  - 使用 Mock 对象测试交互                                 │
│  - 验证 install/uninstall 生命周期                        │
│  - 效果触发顺序验证                                       │
├─────────────────────────────────────────────────────────┤
│  Layer 1: 数据测试 (Data)  ← 当前主要覆盖层               │
│  - 纯资源验证                                            │
│  - StatAttribute 计算正确性                               │
│  - BulletData 复制行为                                    │
│  - Module/Relic 配置完整性                                │
└─────────────────────────────────────────────────────────┘
```

## 添加新测试

### 1. 纯数据测试（推荐）

在 `_run_all_tests()` 中添加：

```gdscript
func _run_all_tests() -> void:
    # ... 现有测试 ...
    
    _suite("MyNewFeature")
    _test_my_new_feature()

func _test_my_new_feature() -> void:
    var module := fixture("module_my_module") as Module
    if not module:
        _skip("my_module not found")
        return
    
    # 验证配置
    _assert_eq("expected_property", module.some_property, expected_value)
    
    # 验证计算
    var result := some_calculation(module)
    _assert_true("calculation_result_valid", result > 0)
```

### 2. 使用 MockTower 测试 Module 生命周期

```gdscript
func _test_my_module_behavior() -> void:
    var MockTowerScript = load("res://tests/mock_tower.gd")
    if not MockTowerScript:
        _skip("mock_tower.gd not found")
        return
    
    var tower_data: TowerData = fixture("basic_tower_data")
    var tower = MockTowerScript.new(tower_data)
    
    # 记录初始状态
    var initial_speed: float = tower.get_bullet_speed()
    
    # 安装模块
    var my_module := fixture("module_my_module") as Module
    tower.install_module(my_module)
    
    # 验证效果
    _assert_true("speed_increased", tower.get_bullet_speed() > initial_speed)
    
    // 验证追踪数据
    _assert_eq("install_recorded", tower.install_calls.size(), 1)
    
    // 卸载并验证恢复
    tower.uninstall_module(0)
    _assert_eq("speed_restored", tower.get_bullet_speed(), initial_speed)
```

### 3. 添加新的 Fixture

在 `_setup_fixtures()` 中添加：

```gdscript
func _setup_fixtures() -> void:
    # ... 现有夹具 ...
    
    # 预加载自定义资源
    _fixtures["my_custom_data"] = load("res://resources/my_data.tres")
    
    # 创建程序化测试数据
    var complex_data = {
        "key1": StatAttribute.new(100.0),
        "key2": BulletData.new(),
    }
    _fixtures["complex_data"] = complex_data
```

### 3. 断言工具

| 断言 | 用途 |
|------|------|
| `_assert_eq(name, actual, expected)` | 精确相等 |
| `_assert_true(name, condition)` | 布尔真 |
| `_assert_false(name, condition)` | 布尔假 |
| `_assert_not_null(name, value)` | 非空检查 |
| `_assert_null(name, value)` | 空检查 |
| `_skip(reason)` | 跳过测试 |

## 测试策略建议

### 新增 Module 时

1. **必须测试**: 资源加载、stat_modifiers 配置
2. **推荐测试**: install/uninstall 生命周期（使用 Mock Tower）
3. **可选测试**: 视觉效果、动画（人工验证即可）

### 新增 Relic 时

1. **必须测试**: 资源加载、接口可调用性
2. **推荐测试**: on_bullet_fired 效果验证
3. **可选测试**: 与 Module 的交互组合

### 重构时

1. 运行测试确保无回归
2. 如果修改了 StatAttribute 计算逻辑，添加边界测试
3. 如果修改了效果触发顺序，添加顺序验证测试

## 已知限制

1. **无法测试 Tower 实例** — Tower.gd 依赖 GameState/BulletPool 等 autoload，headless 环境下难以实例化
2. **无法测试场景交互** — 需要完整 Godot 场景系统的测试需要单独的场景测试
3. **视觉效果无法自动验证** — 动画、粒子等需要人工验证

## 未来扩展

### 集成测试场景

创建 `tests/integration/` 目录，包含：

```
tests/integration/
├── test_module_interactions.tscn  # 测试模块组合效果
├── test_relic_synergies.tscn      # 测试遗物协同
└── test_wave_scaling.tscn         # 测试波次难度曲线
```

运行方式：

```bash
# 运行集成测试（较慢，需要显示服务器）
godot --script res://tests/run_integration_tests.gd
```

### 性能基准测试

```gdscript
func _benchmark_stat_attribute_with_100_mods() -> void:
    var attr := StatAttribute.new(100.0)
    for i in 100:
        attr.add_modifier(StatModifier.new(1.0, StatModifier.Type.ADDITIVE, self))
    
    var start := Time.get_ticks_usec()
    for i in 10000:
        var _v := attr.get_value()
    var elapsed := Time.get_ticks_usec() - start
    
    _assert_true("performance_acceptable", elapsed < 1000)  # < 1ms
```

## 调试技巧

### 查看详细输出

```bash
# 显示 Godot 内部日志
godot --headless --verbose --script res://tests/effect_test_harness.gd
```

### 只运行特定测试套件

临时修改 `_run_all_tests()`：

```gdscript
func _run_all_tests() -> void:
    # 注释掉其他套件，只运行目标测试
    # _suite("DataLayer")
    # _test_tower_data_resource()
    
    _suite("StatAttribute")
    _test_stat_attribute_base_value()
    _test_stat_attribute_additive()
    # ...
```

### 检查 Fixture 内容

在测试中添加调试输出：

```gdscript
func _test_debug() -> void:
    var module := fixture("module_accelerator")
    print("Module: ", module)
    print("Stat modifiers: ", module.stat_modifiers)
    for mod in module.stat_modifiers:
        print("  - stat: ", mod.stat, ", value: ", mod.value)
```
