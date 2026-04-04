# GdUnit4 测试套件

本项目使用 [GdUnit4](https://github.com/MikeSchulze/gdUnit4) 作为测试框架。

GdUnit4 已安装在 `addons/gdUnit4/` 目录下。

## 运行测试

### 方式1：Godot 编辑器（推荐）

1. 打开 Godot 编辑器
2. 点击顶部菜单 `GdUnit` → `Run Tests`
3. 或在 GdUnit 面板（右侧）选择特定测试文件运行

### 方式2：命令行

> ⚠️ GdUnit4 v5.0.3 在 Godot 4.4 命令行模式下有兼容性问题，建议使用编辑器。

## 文件结构

```
tests/
├── gdunit/
│   ├── StatAttributeTest.gd    # StatAttribute 计算逻辑测试
│   ├── BulletDataTest.gd       # BulletData 复制和修改测试
│   ├── ModuleTest.gd           # 模块资源完整性 + 生命周期测试
│   ├── EffectTriggerTest.gd    # Effect 触发行为测试
│   ├── FullChainTest.gd        # 完整效果链条测试 ★
│   └── IntegrationTest.gd      # 场景集成测试（需要真实 Godot 运行时）
├── mock_tower.gd               # MockTower 辅助类
└── validate.gd                 # 独立验证脚本

docs/tests/
├── HOW_TO_RUN_TESTS.md         # 如何运行测试
└── gdunit_testing.md           # 本文档
```

## 测试覆盖详情

### StatAttributeTest.gd
- ✅ 基础值
- ✅ 加性修饰符（`+10` → `110`）
- ✅ 乘性修饰符（`×1.5` → `150`）
- ✅ 加性 + 乘性组合（`(base + add) × mult`）
- ✅ 多个加性修饰符叠加
- ✅ 多个乘性修饰符叠加
- ✅ 复杂组合场景（`(100 + 50 + 10) × 2.0 × 1.5 = 480`）
- ✅ `remove_modifiers_from(source)` 清理

### BulletDataTest.gd
- ✅ `duplicate_with_mods({})` 复制所有字段（attack, speed, chain_count, knockback）
- ✅ 副本独立于原对象
- ✅ `duplicate_with_mods(mods)` 应用字段覆盖
- ✅ `transmission_chain` 保留
- ✅ `effects` 数组保留
- ✅ 默认值验证

### ModuleTest.gd
- ✅ 自动扫描 `resources/module_data/` 目录下所有 `.tres` 文件
- ✅ 所有模块可加载
- ✅ 所有模块有 `module_name`、`description`、`slot_color`、有效 `category`
- ✅ 特定模块详细属性（accelerator, multiplier, flying, anti_air, cd_on_hit_*, replenish*）
- ✅ 安装模块 → stat 增加（accelerator: 200→350 speed）
- ✅ 卸载模块 → stat 恢复
- ✅ 多模块叠加（multiplier ×1.2 × ×1.2 = ×1.44）
- ✅ 槽位上限：最多 4 个，第 5 个返回 `false`
- ✅ **覆盖率自动验证**：`after()` 断言测试的模块数 == 目录中的模块数

### EffectTriggerTest.gd
通过 MockTower 测试各 effect 的触发行为：

- ✅ `CdReduceOnEnemyEffect`（`cd_on_hit_enemy.tres`）：安装后 effect 进入 `bullet_effects`，`on_hit_enemy` 调用塔的 `reduce_cooldown(0.5)`
- ✅ `CdReduceOnReceiveTowerEffect`（`cd_on_receive_hit.tres`）：安装后 effect 进入 `tower_effects`，`on_receive_bullet_hit` 可触发
- ✅ `ReplenishEffect`（`replenish1.tres`）：`on_hit_tower` 调用目标塔 `add_ammo(1)`，ammo 从 3→4
- ✅ effect 安装/卸载后 `bullet_effects` 数组大小正确

### FullChainTest.gd ★（完整链条测试）

测试"安装模块 → 发射子弹 → 击中目标 → 触发效果"完整链条：

- ✅ cd_on_hit_enemy：`install_module` → `bd.effects` 携带 effect → `on_hit_enemy(bd, enemy)` → `reduce_cooldown(0.5)` 被调用，CD 从 2.0→1.5
- ✅ replenish1：`install_module` → `on_hit_tower(bd, target)` → `add_ammo(1)` 被调用，ammo 从 3→4
- ✅ accelerator `stat_modifiers` 安装后速度 +150
- ✅ 子弹 `effects` 从塔继承，`transmission_chain` 正确绑定
- ✅ 两个 effect 同时在链条中触发（cd_on_hit_enemy + replenish）
- ✅ 卸载模块后 `bullet_effects` 清空，速度恢复

### IntegrationTest.gd（场景集成测试）

实例化真实场景节点，在 Godot 运行时中测试实际行为：

- ✅ `start_firing()` 后等待 CD 到期，场景中出现 bullets（`get_nodes_in_group("bullets")`）
- ✅ 子弹飞向目标位置时触发 `enemy_hit` 信号
- ✅ 处理 `enemy_hit` 信号后敌人 `current_health` 下降
- ✅ 3 次命中后敌人触发 `enemy_destroyed` 信号
- ✅ 有限弹药（`ammo=5`）在开火后递减
- ✅ 无限弹药（`ammo=-1`）在 5 秒内发射多发子弹

> **注意**：IntegrationTest 依赖 `resources/simple_emitter.tres`，且测试有时间等待（最长 5 秒/测试），总耗时较长。

## MockTower 类

`tests/mock_tower.gd` 是用于单元测试的轻量 Tower 模拟对象：

- 不依赖任何 autoload（GameState、BulletPool、EventManager 等）
- 实现完整的 `StatAttribute` 系统（CD、speed、attack、ammo_extra）
- 实现 `install_module` / `uninstall_module` / `get_module_count`
- 实现 `add_ammo` / `consume_ammo` / `reduce_cooldown` / `has_ammo`
- 记录所有方法调用（`install_calls`、`reduce_cooldown_calls`、`ammo_added` 等）供断言

## 编写新测试

### 基础模板

```gdscript
class_name MyTest
extends GdUnitTestSuite

func test_something() -> void:
	var value := 123
	var result := some_function(value)
	assert_that(result).is_equal(expected_value)
```

### 效果链条测试模板

```gdscript
func test_new_effect_chain() -> void:
	# 1. 加载模块
	var module := load("res://resources/module_data/new_module.tres") as Module

	# 2. 创建 MockTower 并安装模块
	var MockTowerScript = load("res://tests/mock_tower.gd")
	var tower = auto_free(MockTowerScript.new())
	tower.install_module(module)

	# 3. 子弹携带塔的 effects
	var bd := BulletData.new()
	bd.effects = tower.bullet_effects.duplicate()
	bd.transmission_chain = [tower]

	# 4. 触发效果
	var effect = bd.effects[0]
	var target := auto_free(Node.new())
	if effect.has_method("on_hit_enemy"):
		effect.on_hit_enemy(bd, target)
	elif effect.has_method("on_hit_tower"):
		effect.on_hit_tower(bd, target)

	# 5. 断言
	assert_array(tower.reduce_cooldown_calls).has_size(1)
```

### 常用断言速查

```gdscript
assert_that(actual).is_equal(expected)
assert_bool(cond).is_true()
assert_bool(cond).is_false()
assert_object(obj).is_not_null()
assert_object(obj).is_instanceof(SomeClass)
assert_array(arr).has_size(3)
assert_array(arr).is_not_empty()
assert_int(n).is_equal(42)
assert_int(n).is_greater(0)
assert_float(f).is_equal(3.14)
assert_float(f).is_equal_approx(3.14, 0.01)
assert_str(s).is_equal("text")
```

### 生命周期钩子

```gdscript
func before() -> void:       # 整个套件开始前（一次）
func after() -> void:        # 整个套件结束后（一次）
func before_test() -> void:  # 每个 test_ 函数前
func after_test() -> void:   # 每个 test_ 函数后
```

## 参考

- [GdUnit4 文档](https://godot-gdunit-labs.github.io/gdUnit4/)
- [GdUnit4 GitHub](https://github.com/MikeSchulze/gdUnit4)
- [项目架构](../../CLAUDE.md)
