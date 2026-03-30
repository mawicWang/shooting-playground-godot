# Effect Test Harness - 快速开始

## 运行测试

```bash
# 方式1: 使用脚本
./tests/run_tests.sh

# 方式2: 直接运行
godot --headless --script res://tests/effect_test_harness.gd
```

## 检查覆盖率

```bash
godot --headless --script res://tests/check_coverage.gd
```

## 添加新测试

1. 在 `effect_test_harness.gd` 的 `_run_all_tests()` 中添加测试套件和测试函数
2. 使用 `MockTower` 测试 Module 的完整生命周期
3. 使用提供的断言工具验证结果

### 示例

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
    
    # 使用 MockTower 测试安装/卸载
    var MockTowerScript = load("res://tests/mock_tower.gd")
    var tower = MockTowerScript.new(fixture("basic_tower_data"))
    
    var initial = tower.get_bullet_speed()
    tower.install_module(module)
    _assert_true("speed_increased", tower.get_bullet_speed() > initial)
    
    tower.uninstall_module(0)
    _assert_eq("speed_restored", tower.get_bullet_speed(), initial)
```

## 当前测试覆盖

### 自动扫描验证
- ✅ 自动扫描 `resources/module_data/` 目录
- ✅ 为每个发现的模块运行基础测试
- ✅ 验证测试数量等于资源数量
- ✅ 验证模块名字一一对应

### 功能测试
- ✅ StatAttribute 计算（加性/乘性/混合/清理）
- ✅ BulletData 复制行为
- ✅ 14个 Module 资源加载和配置验证
- ✅ Module install/uninstall 生命周期
- ✅ Module 叠加效果验证
- ✅ MockTower 属性追踪

## 添加新模块

当你在 `resources/module_data/` 添加新模块时：

1. 测试会自动发现新模块
2. 基础测试（名称、描述、颜色）会自动运行
3. 如果需要特定测试逻辑，在 `_match_module_specific_test()` 中添加：

```gdscript
func _match_module_specific_test(module_name: String, module: Module) -> void:
    match module_name:
        "your_new_module":
            _test_your_new_module_details(module)
        # ...

func _test_your_new_module_details(module: Module) -> void:
    _assert_eq("your_module_property", module.some_property, expected_value)
```

## 已知限制

- ❌ 依赖 autoload (GameState/BulletPool) 的类无法直接测试
- ❌ 需要场景实例化的效果（动画、粒子）无法自动验证
- ❌ Relic 的 on_bullet_fired 效果需要完整游戏环境

## 文件说明

| 文件 | 用途 |
|------|------|
| `effect_test_harness.gd` | 主测试脚本 |
| `mock_tower.gd` | Tower 模拟对象，用于测试 Module |
| `check_coverage.gd` | 覆盖率检查工具 |
| `run_tests.sh` | 便捷运行脚本 |
| `README.md` | 详细文档 |
| `validate.gd` | 基础验证脚本（脚本解析、场景加载）|
