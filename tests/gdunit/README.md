# GdUnit4 测试套件

本项目使用 [GdUnit4](https://github.com/MikeSchulze/gdUnit4) 作为测试框架，测试完整的"安装模块→发射子弹→击中目标→触发效果"链条。

## 安装

GdUnit4 已安装在 `addons/gdUnit4/` 目录下。

## 运行测试

### 方式1: Godot 编辑器（推荐）

1. 打开 Godot 编辑器
2. 点击顶部菜单 `GdUnit` → `Run Tests`
3. 或点击 GdUnit 面板（右侧）运行特定测试

### 方式2: 命令行（已知在 Godot 4.4 上有问题）

```bash
# 注意：GdUnit4 v5.0.3 在 Godot 4.4 命令行模式下可能有兼容性问题
# 建议使用 Godot 编辑器中的 GdUnit 面板运行测试
```

## 测试文件结构

```
tests/
├── gdunit/
│   ├── ModuleTest.gd          # Module 资源完整性测试
│   ├── StatAttributeTest.gd   # StatAttribute 计算逻辑测试
│   ├── BulletDataTest.gd      # BulletData 复制和修改测试
│   ├── EffectTriggerTest.gd   # Effect 基础触发测试
│   ├── FullChainTest.gd       # 完整效果链条测试 ★
│   └── README.md              # 本文档
├── mock_tower.gd              # MockTower 类，用于测试
└── validate.gd                # 验证脚本
```

## 测试覆盖

### ModuleTest.gd
- ✅ 自动扫描 `resources/module_data/` 目录（14个模块）
- ✅ 验证所有模块资源可以加载
- ✅ 验证模块名称、描述、颜色、category
- ✅ 特定模块详细测试（accelerator, multiplier, flying 等）
- ✅ **自动验证**: 测试的模块数量等于资源数量

### StatAttributeTest.gd
- ✅ 基础值测试
- ✅ 加性修饰符
- ✅ 乘性修饰符
- ✅ 组合修饰符
- ✅ 修饰符清理
- ✅ 复杂组合场景

### BulletDataTest.gd
- ✅ 复制所有值
- ✅ 独立副本验证
- ✅ 带修改的复制
- ✅ transmission_chain 保留
- ✅ effects 数组保留
- ✅ 默认值验证

### EffectTriggerTest.gd
- ✅ Effect 安装验证
- ✅ Effect 触发测试
- ✅ 使用 MockTower 模拟塔行为

### FullChainTest.gd ★（完整链条测试）
- ✅ **安装 cd_on_hit_enemy 模块 → 发射子弹 → 击中敌人 → 减少 CD**
- ✅ **安装 replenish 模块 → 发射子弹 → 击中塔 → 补充弹药**
- ✅ 模块安装时 stat_modifiers 正确应用
- ✅ 子弹从塔继承 effects
- ✅ 多个 effects 在链条中正确触发
- ✅ 模块卸载时 effects 正确清理

## 完整效果链条测试示例

```gdscript
# FullChainTest.gd 中的测试示例
func test_cd_reduce_on_enemy_full_chain() -> void:
    # 1. 加载模块
    var module = load("res://resources/module_data/cd_on_hit_enemy.tres")
    
    # 2. 创建测试塔并安装模块
    var tower = TestTower.new()
    tower.install_module(module)
    
    # 3. 创建子弹数据（携带塔的 effects）
    var bd = BulletData.new()
    bd.effects = tower.bullet_effects.duplicate()
    bd.transmission_chain = [tower]
    
    # 4. 模拟子弹击中敌人
    var enemy = Node.new()
    var effect = bd.effects[0]
    effect.on_hit_enemy(bd, enemy)
    
    # 5. 验证效果触发：塔的 CD 被减少
    assert_array(tower.reduce_cooldown_calls).has_size(1)
    assert_float(tower.reduce_cooldown_calls[0]).is_equal(0.5)
```

## MockTower 类

`MockTower` 是一个轻量级的 Tower 模拟类，用于测试：

- 不依赖任何 autoload (GameState, BulletPool 等)
- 实现 Module/Relic 交互所需的最小接口
- 提供 `add_ammo()`, `reduce_cooldown()` 等效果所需的方法
- 记录方法调用用于测试验证

## 添加新测试

### 基础测试模板

```gdscript
class_name MyTest
extends GdUnitTestSuite

func test_something() -> void:
    # 准备数据
    var value = 123
    
    # 执行操作
    var result = some_function(value)
    
    # 验证结果
    assert_that(result).is_equal(expected_value)
```

### 测试完整效果链条

```gdscript
func test_new_effect_chain() -> void:
    # 1. 加载模块
    var module = load("res://resources/module_data/new_module.tres")
    
    # 2. 创建测试塔
    var tower = auto_free(TestTower.new())
    tower.install_module(module)
    
    # 3. 创建子弹数据
    var bd = BulletData.new()
    bd.effects = tower.bullet_effects.duplicate()
    bd.transmission_chain = [tower]
    
    # 4. 触发效果
    var effect = bd.effects[0]
    var target = auto_free(Node.new())
    
    if effect.has_method("on_hit_enemy"):
        effect.on_hit_enemy(bd, target)
    elif effect.has_method("on_hit_tower"):
        effect.on_hit_tower(bd, target)
    
    # 5. 验证效果
    assert_something_happened()
```

## 最佳实践

1. **测试名称清晰**: `test_xxx` 格式，描述测试内容
2. **完整链条覆盖**: 测试从模块安装到效果触发的完整流程
3. **使用 Mock 对象**: 使用 `MockTower` 避免依赖 autoload
4. **验证方法调用**: 检查 `reduce_cooldown()`, `add_ammo()` 等方法是否被调用
5. **使用 auto_free**: 创建的对象使用 `auto_free(obj)` 自动清理

## 参考

- [GdUnit4 文档](https://godot-gdunit-labs.github.io/gdUnit4/)
- [GdUnit4 GitHub](https://github.com/MikeSchulze/gdUnit4)
- [项目架构文档](../CLAUDE.md)
- [validate.gd](../validate.gd) - 验证脚本

## 测试覆盖

### ModuleTest.gd
- ✅ 自动扫描 `resources/module_data/` 目录
- ✅ 验证所有模块资源可以加载
- ✅ 验证模块名称、描述、颜色、category
- ✅ 特定模块详细测试（accelerator, multiplier, flying 等）
- ✅ Module 安装/卸载生命周期
- ✅ 多个模块叠加效果
- ✅ 模块槽位上限（4个）
- ✅ **自动验证**: 测试的模块数量等于资源数量

### StatAttributeTest.gd
- ✅ 基础值测试
- ✅ 加性修饰符
- ✅ 乘性修饰符
- ✅ 组合修饰符
- ✅ 修饰符清理
- ✅ 复杂组合场景

### BulletDataTest.gd
- ✅ 复制所有值
- ✅ 独立副本验证
- ✅ 带修改的复制
- ✅ transmission_chain 保留
- ✅ effects 数组保留
- ✅ 默认值验证

### EffectTriggerTest.gd
- ✅ Effect 安装验证
- ✅ Effect 触发（手动调用）

## 添加新测试

### 基础测试模板

```gdscript
class_name MyTest
extends GdUnitTestSuite

func test_something() -> void:
    # 准备数据
    var value = 123
    
    # 执行操作
    var result = some_function(value)
    
    # 验证结果
    assert_that(result).is_equal(expected_value)
```

### 常用断言

```gdscript
# 基本相等
assert_that(actual).is_equal(expected)

# 布尔值
assert_bool(condition).is_true()
assert_bool(condition).is_false()

# 空值检查
assert_object(obj).is_null()
assert_object(obj).is_not_null()

# 数组
assert_array(arr).has_size(3)
assert_array(arr).contains(element)
assert_array(arr).contains_exactly([1, 2, 3])

# 字符串
assert_str(text).is_equal("expected")
assert_str(text).contains("substring")

# 数字
assert_int(value).is_equal(42)
assert_float(value).is_equal_approx(3.14, 0.01)
```

### 使用 Mock 和 Spy

```gdscript
# 创建 mock
var mock = mock(SomeClass)
do_return(123).on(mock).some_method()

# 创建 spy
var spy = spy(real_instance)
spy.some_method()
verify(spy).some_method()

# 验证无交互
verify_no_interactions(mock)

# 验证调用次数
verify(spy, 2).some_method()  # 验证调用了2次
```

### 场景运行器（集成测试）

```gdscript
func test_scene_interaction() -> void:
    var runner = scene_runner("res://scenes/my_scene.tscn")
    
    # 模拟输入
    runner.simulate_key_press(KEY_SPACE)
    runner.simulate_key_release(KEY_SPACE)
    
    # 等待信号
    await assert_signal(runner.scene()).is_emitted("some_signal")
    
    # 等待帧
    await runner.await_idle_frame()
    
    # 验证状态
    assert_that(runner.scene().some_property).is_equal(expected)
```

## 生命周期钩子

```gdscript
func before() -> void:
    # 整个测试套件开始前执行
    pass

func after() -> void:
    # 整个测试套件结束后执行
    pass

func before_test() -> void:
    # 每个测试用例开始前执行
    pass

func after_test() -> void:
    # 每个测试用例结束后执行
    pass
```

## 跳过测试

```gdscript
func test_feature() -> void:
    if some_condition_not_met:
        skip("跳过原因")
        return
    
    # 测试代码
```

## 最佳实践

1. **测试名称清晰**: `test_xxx` 格式，描述测试内容
2. **独立测试**: 每个测试用例应该独立，不依赖其他测试
3. **使用 auto_free**: 创建的对象使用 `auto_free(obj)` 自动清理
4. **覆盖边界情况**: 测试正常情况和异常情况
5. **避免复杂逻辑**: 测试代码应该简单直接

## 参考

- [GdUnit4 文档](https://godot-gdunit-labs.github.io/gdUnit4/)
- [GdUnit4 GitHub](https://github.com/MikeSchulze/gdUnit4)
