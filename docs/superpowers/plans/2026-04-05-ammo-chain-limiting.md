# Ammo Chain Limiting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把炮塔弹药从简单计数改为带游标的 AmmoItem 队列，防止 bullet_effects 和 tower_effects 在同一条传递链上指数级爆炸触发。

**Architecture:** 每个 AmmoItem 携带两个 Dictionary（effect_contribution_counts / tower_effect_trigger_counts），记录本链中各 tower 已贡献/触发次数。Tower 开火时查自身 entity_id 是否耗尽 max_chain；bullet.gd 对 tower_effects 做同样检查。无限弹药（ammo == -1）分支不变。

**Tech Stack:** GDScript / Godot 4.4，无第三方库。每任务用 `godot --headless --script res://tests/validate.gd` 验证。

---

## 文件结构

| 操作 | 路径 | 变更说明 |
|------|------|----------|
| 新建 | `entities/bullets/ammo_item.gd` | AmmoItem 数据类 |
| 修改 | `resources/BulletData.gd` | 新增两个 Dictionary 字段 |
| 修改 | `entities/towers/tower.gd` | 弹药队列、max_chain、`_do_fire()`、`add_ammo_from_chain()` |
| 修改 | `entities/bullets/bullet.gd` | TowerEffect chain 检查，替换 on_bullet_hit 调用 |
| 修改 | `entities/effects/bullet_effects/hit_tower_target_replenish_effect.gd` | 改用 `add_ammo_from_chain` |
| 修改 | `entities/effects/tower_effects/receive_hit_self_replenish_effect.gd` | 改用 `add_ammo_from_chain` |
| 新建 | `entities/modules/chain_module.gd` | 连锁+1 模块逻辑 |
| 新建 | `resources/module_data/chain_module.tres` | 连锁+1 模块资源 |
| 修改 | `ui/popups/reward_popup.gd` | REWARD_POOL 加入 chain_module |

---

## Task 1：创建 AmmoItem 数据类

**Files:**
- Create: `entities/bullets/ammo_item.gd`

- [ ] **Step 1: 创建文件**

```gdscript
# entities/bullets/ammo_item.gd
class_name AmmoItem

## {tower_entity_id (int) → 已贡献次数 (int)}
## Tower 开火时追加自身 bullet_effects 前检查此计数。
var effect_contribution_counts: Dictionary = {}

## {tower_entity_id (int) → tower_effects 已触发次数 (int)}
## bullet.gd 击中炮塔时检查此计数，决定是否触发 tower_effects。
var tower_effect_trigger_counts: Dictionary = {}
```

- [ ] **Step 2: 运行 validate**

```bash
godot --headless --script res://tests/validate.gd
```

期望：`PASS  [SCRIPT] res://entities/bullets/ammo_item.gd`，全部通过。

- [ ] **Step 3: Commit**

```bash
git add entities/bullets/ammo_item.gd
git commit -m "feat: add AmmoItem class for ammo chain tracking"
```

---

## Task 2：BulletData 新增链追踪字段

**Files:**
- Modify: `resources/BulletData.gd`

- [ ] **Step 1: 在 BulletData.gd 末尾追加两个字段**

打开 `resources/BulletData.gd`，在 `var tower_body_mask` 行之后、`duplicate_with_mods()` 之前添加：

```gdscript
## 本子弹所在链上各 tower 的 bullet_effects 已贡献次数（{int → int}）
var effect_contribution_counts: Dictionary = {}
## 本子弹所在链上各 tower 的 tower_effects 已触发次数（{int → int}）
var tower_effect_trigger_counts: Dictionary = {}
```

- [ ] **Step 2: 更新 `duplicate_with_mods()`，同步复制新字段**

找到 `duplicate_with_mods` 函数，在 `copy.tower_body_mask = tower_body_mask` 之后添加：

```gdscript
copy.effect_contribution_counts = effect_contribution_counts.duplicate()
copy.tower_effect_trigger_counts = tower_effect_trigger_counts.duplicate()
```

完整函数应为：

```gdscript
func duplicate_with_mods(mods: Dictionary) -> BulletData:
	var copy := BulletData.new()
	copy.attack = attack
	copy.speed = speed
	copy.chain_count = chain_count
	copy.knockback = knockback
	copy.knockback_decay = knockback_decay
	copy.transmission_chain = transmission_chain.duplicate()
	copy.effects = effects.duplicate()
	copy.tower_body_mask = tower_body_mask
	copy.effect_contribution_counts = effect_contribution_counts.duplicate()
	copy.tower_effect_trigger_counts = tower_effect_trigger_counts.duplicate()
	for key in mods:
		copy.set(key, mods[key])
	return copy
```

- [ ] **Step 3: 运行 validate**

```bash
godot --headless --script res://tests/validate.gd
```

期望：全部 PASS。

- [ ] **Step 4: Commit**

```bash
git add resources/BulletData.gd
git commit -m "feat: add chain tracking dictionaries to BulletData"
```

---

## Task 3：Tower 弹药队列系统

**Files:**
- Modify: `entities/towers/tower.gd`

本任务只改弹药字段和 ammo 相关方法（`has_ammo`、`consume_ammo`、`add_ammo`、新增 `add_ammo_from_chain` 和 `ammo_count`），**不动 `_do_fire()`**（Task 4 再改）。

- [ ] **Step 1: 替换弹药字段声明**

找到当前这一行（约第 25 行）：

```gdscript
## 弹药系统：-1 = 无限，≥0 = 有限弹药
var ammo: int = 0
```

替换为：

```gdscript
## 弹药系统：-1 = 无限弹药；0 = 有限弹药（由 ammo_queue 管理）
var ammo: int = 0
var ammo_queue: Array = []   # Array[AmmoItem]
var ammo_cursor: int = 0
var bullet_effect_max_chain: int = 1   # 本 tower 的 bullet_effects 在链上最多触发次数
var tower_effect_max_chain: int = 1    # 本 tower 的 tower_effects 在链上最多触发次数
```

- [ ] **Step 2: 更新 `_apply_data()` 初始化弹药队列**

找到 `_apply_data()` 函数中：

```gdscript
	if data:
		if data.sprite:
			sprite.texture = data.sprite
		ammo = data.initial_ammo
	else:
		ammo = 3
	_update_ammo_label()
```

替换为：

```gdscript
	ammo_queue.clear()
	ammo_cursor = 0
	if data:
		if data.sprite:
			sprite.texture = data.sprite
		ammo = data.initial_ammo
	else:
		ammo = 3
	# 有限弹药：初始化队列（无限弹药跳过，_do_fire 会即时创建空 AmmoItem）
	if ammo >= 0:
		for _i in range(ammo):
			ammo_queue.append(AmmoItem.new())
		ammo = 0  # 有限弹药由队列管理，ammo 只保留 -1（无限）标志位
	_update_ammo_label()
```

- [ ] **Step 3: 替换 `has_ammo()`**

找到：

```gdscript
func has_ammo() -> bool:
	return ammo == -1 or ammo > 0
```

替换为：

```gdscript
func has_ammo() -> bool:
	return ammo == -1 or ammo_cursor < ammo_queue.size()

func ammo_count() -> int:
	if ammo == -1:
		return -1
	return ammo_queue.size() - ammo_cursor
```

- [ ] **Step 4: 替换 `consume_ammo()`**

找到：

```gdscript
func consume_ammo() -> void:
	if ammo == -1:
		return
	ammo = max(0, ammo - 1)
	_update_ammo_label()
```

替换为：

```gdscript
func consume_ammo() -> void:
	if ammo == -1:
		return
	ammo_cursor += 1
	# 定期清理已消费项，防止长时间运行后内存堆积
	if ammo_cursor > 200:
		ammo_queue = ammo_queue.slice(ammo_cursor)
		ammo_cursor = 0
	_update_ammo_label()
```

- [ ] **Step 5: 替换 `add_ammo()` 并新增 `add_ammo_from_chain()`**

找到：

```gdscript
func add_ammo(amount: int) -> void:
	if ammo == -1:
		return
	ammo += amount
	_update_ammo_label()
	# CD 已归零且正在开火阶段：重启 process，下一帧统一检查并发射
	# 注意：不在此直接调用 _do_fire()，避免多 effect 顺序执行时
	# 第一次补充触发开炮消耗弹药，导致后续补充效果被抵消
	if _is_firing and _cooldown_remaining <= 0.0:
		set_process(true)
```

替换为：

```gdscript
## 全新弹药（空链）：初始弹药、击杀敌人奖励等来源
func add_ammo(amount: int) -> void:
	if ammo == -1:
		return
	for _i in range(amount):
		ammo_queue.append(AmmoItem.new())
	_update_ammo_label()
	# CD 已归零且正在开火阶段：重启 process，下一帧统一检查并发射
	if _is_firing and _cooldown_remaining <= 0.0:
		set_process(true)

## 链式弹药：继承当前子弹的链追踪状态，用于炮塔间弹药传递
func add_ammo_from_chain(amount: int, bullet_data: BulletData) -> void:
	if ammo == -1:
		return
	for _i in range(amount):
		var item := AmmoItem.new()
		item.effect_contribution_counts = bullet_data.effect_contribution_counts.duplicate()
		item.tower_effect_trigger_counts = bullet_data.tower_effect_trigger_counts.duplicate()
		ammo_queue.append(item)
	_update_ammo_label()
	if _is_firing and _cooldown_remaining <= 0.0:
		set_process(true)
```

- [ ] **Step 6: 更新 `_update_ammo_label()` 使用 `ammo_count()`**

找到：

```gdscript
func _update_ammo_label() -> void:
	if not is_instance_valid(_ammo_label):
		return
	_ammo_label.text = "∞" if ammo == -1 else str(ammo)
```

替换为：

```gdscript
func _update_ammo_label() -> void:
	if not is_instance_valid(_ammo_label):
		return
	_ammo_label.text = "∞" if ammo == -1 else str(ammo_count())
```

- [ ] **Step 7: 运行 validate**

```bash
godot --headless --script res://tests/validate.gd
```

期望：全部 PASS。

- [ ] **Step 8: Commit**

```bash
git add entities/towers/tower.gd
git commit -m "feat: replace tower ammo int with AmmoItem queue + add_ammo_from_chain"
```

---

## Task 4：更新 `_do_fire()` 使用队列和链贡献

**Files:**
- Modify: `entities/towers/tower.gd`

- [ ] **Step 1: 替换 `_do_fire()` 全函数**

找到 `func _do_fire() -> void:` 整个函数，替换为：

```gdscript
func _do_fire() -> void:
	# 取当前弹药项（无限弹药每次创建空 AmmoItem，保持全新链）
	var ammo_item: AmmoItem
	if ammo == -1:
		ammo_item = AmmoItem.new()
	else:
		ammo_item = ammo_queue[ammo_cursor]
	consume_ammo()

	# 额外弹药消耗（由 ammo_extra_stat 驱动，如重弹头模块）
	var extra := int(_ammo_extra_stat.get_value())
	for _i in range(extra):
		consume_ammo()

	var bd := BulletData.new()
	bd.attack = _bullet_attack_stat.get_value()
	bd.speed  = _bullet_speed_stat.get_value()
	bd.transmission_chain = [self]  # 仅防自碰，与链计数无关

	# 从弹药项继承链追踪状态
	bd.effect_contribution_counts = ammo_item.effect_contribution_counts.duplicate()
	bd.tower_effect_trigger_counts = ammo_item.tower_effect_trigger_counts.duplicate()

	# 检查本 tower 是否还能贡献 bullet_effects
	var contrib_count = bd.effect_contribution_counts.get(entity_id, 0)
	if contrib_count < bullet_effect_max_chain:
		bd.effects.append_array(bullet_effects)
		bd.effect_contribution_counts[entity_id] = contrib_count + 1

	# default_replenish：无条件追加，不计入 contribution（基础传递机制）
	var default_replenish := HitTowerTargetReplenishEffect.new()
	bd.effects.append(default_replenish)

	# 设置子弹碰撞层以反映飞行/反空状态
	if is_flying:
		bd.tower_body_mask = Layers.AIR_TOWER_BODY
	elif has_anti_air:
		bd.tower_body_mask = Layers.TOWER_BODY | Layers.AIR_TOWER_BODY

	var cd := _get_effective_cd()
	_cooldown_remaining = cd
	_current_full_cooldown = cd
	_update_cd_overlay()

	var parent := get_tree().get_first_node_in_group("bullet_layer")
	if not is_instance_valid(parent):
		parent = get_tree().root

	var directions: PackedVector2Array
	if data and data.barrel_directions.size() > 0:
		directions = data.barrel_directions
	else:
		directions = PackedVector2Array([Vector2(0, -1)])

	for local_dir in directions:
		BulletPool.spawn(parent, global_position, local_dir.rotated(_tower_visual.rotation), bd)

	EventManager.notify_bullet_fired(bd, self)
```

- [ ] **Step 2: 运行 validate**

```bash
godot --headless --script res://tests/validate.gd
```

期望：全部 PASS。

- [ ] **Step 3: Commit**

```bash
git add entities/towers/tower.gd
git commit -m "feat: _do_fire uses AmmoItem queue and chain contribution tracking"
```

---

## Task 5：bullet.gd — TowerEffect 链式限制

**Files:**
- Modify: `entities/bullets/bullet.gd`

- [ ] **Step 1: 替换 `_on_hitbox_area_entered` 中的命中处理段**

找到从 `# 记录弹药基线` 到 `BulletPool.release.call_deferred(self)` 这一段（约 59–74 行），替换为：

```gdscript
	# 受击动画：每次击中都播，不受 chain 限制
	parent.play_hit_effect()

	# 记录弹药基线（用于命中后弹药回复浮动数字）
	var ammo_before: int = parent.ammo_count() if parent.has_method("ammo_count") else -1

	# 1. 触发 BulletEffect.on_hit_tower（子弹侧，顺序不变）
	if data:
		for effect in data.effects:
			effect.on_hit_tower(data, parent)

	# 2. TowerEffect：检查目标 tower 是否还有触发次数
	if data and parent.get("entity_id") != null and parent.get("tower_effect_max_chain") != null:
		var te_count = data.tower_effect_trigger_counts.get(parent.entity_id, 0)
		if te_count < parent.tower_effect_max_chain:
			data.tower_effect_trigger_counts[parent.entity_id] = te_count + 1
			for te in parent.tower_effects:
				te.on_receive_bullet_hit(data, parent)

	# 3. 弹药回复浮动数字（在所有效果跑完后统一显示）
	var ammo_after: int = parent.ammo_count() if parent.has_method("ammo_count") else -1
	if ammo_before != -1 and ammo_after != -1 and ammo_after > ammo_before:
		var an := AmmoNumber.new()
		get_tree().root.add_child(an)
		an.show_ammo(parent.global_position, ammo_after - ammo_before)

	# 4. 延迟回收，避免在物理回调中直接修改场景树
	BulletPool.release.call_deferred(self)
```

完整替换后的 `_on_hitbox_area_entered` 函数：

```gdscript
func _on_hitbox_area_entered(other_area: Area2D) -> void:
	if _pending_release:
		return
	var parent = other_area.get_parent()
	if not is_instance_valid(parent) or not parent.is_in_group("towers"):
		return
	# 不击中自己发射的炮塔（transmission_chain 防止自碰）
	if data and data.transmission_chain.has(parent):
		return
	_pending_release = true
	visible = false
	set_physics_process(false)
	# 碰撞特效
	var impact := BulletImpact.new()
	get_tree().root.add_child(impact)
	impact.spawn(global_position, BulletImpact.COLORS_TOWER)

	# 受击动画：每次击中都播，不受 chain 限制
	parent.play_hit_effect()

	# 记录弹药基线（用于命中后弹药回复浮动数字）
	var ammo_before: int = parent.ammo_count() if parent.has_method("ammo_count") else -1

	# 1. 触发 BulletEffect.on_hit_tower（子弹侧，顺序不变）
	if data:
		for effect in data.effects:
			effect.on_hit_tower(data, parent)

	# 2. TowerEffect：检查目标 tower 是否还有触发次数
	if data and parent.get("entity_id") != null and parent.get("tower_effect_max_chain") != null:
		var te_count = data.tower_effect_trigger_counts.get(parent.entity_id, 0)
		if te_count < parent.tower_effect_max_chain:
			data.tower_effect_trigger_counts[parent.entity_id] = te_count + 1
			for te in parent.tower_effects:
				te.on_receive_bullet_hit(data, parent)

	# 3. 弹药回复浮动数字（在所有效果跑完后统一显示）
	var ammo_after: int = parent.ammo_count() if parent.has_method("ammo_count") else -1
	if ammo_before != -1 and ammo_after != -1 and ammo_after > ammo_before:
		var an := AmmoNumber.new()
		get_tree().root.add_child(an)
		an.show_ammo(parent.global_position, ammo_after - ammo_before)

	# 4. 延迟回收，避免在物理回调中直接修改场景树
	BulletPool.release.call_deferred(self)
```

- [ ] **Step 2: 运行 validate**

```bash
godot --headless --script res://tests/validate.gd
```

期望：全部 PASS。

- [ ] **Step 3: Commit**

```bash
git add entities/bullets/bullet.gd
git commit -m "feat: chain-limit TowerEffects in bullet hit handler"
```

---

## Task 6：更新 Replenish Effects 使用 `add_ammo_from_chain`

**Files:**
- Modify: `entities/effects/bullet_effects/hit_tower_target_replenish_effect.gd`
- Modify: `entities/effects/tower_effects/receive_hit_self_replenish_effect.gd`

- [ ] **Step 1: 更新 `hit_tower_target_replenish_effect.gd`**

整个文件替换为：

```gdscript
class_name HitTowerTargetReplenishEffect extends BulletEffect

## 子弹击中炮塔时补充弹药（链式传递：继承当前子弹的链追踪状态）

@export var ammo_amount: int = 1

func on_hit_tower(bullet_data: BulletData, tower: Node) -> void:
	if not tower.has_method("add_ammo_from_chain"):
		return
	tower.add_ammo_from_chain(ammo_amount, bullet_data)
```

- [ ] **Step 2: 更新 `receive_hit_self_replenish_effect.gd`**

整个文件替换为：

```gdscript
class_name ReceiveHitSelfReplenishEffect extends TowerEffect

## 炮塔被子弹击中时，补充自身弹药（链式传递：继承当前子弹的链追踪状态）

@export var ammo_amount: int = 1

func on_receive_bullet_hit(bullet_data: BulletData, tower: Node) -> void:
	if not tower.has_method("add_ammo_from_chain"):
		return
	tower.add_ammo_from_chain(ammo_amount, bullet_data)
```

- [ ] **Step 3: 运行 validate**

```bash
godot --headless --script res://tests/validate.gd
```

期望：全部 PASS。

- [ ] **Step 4: Commit**

```bash
git add entities/effects/bullet_effects/hit_tower_target_replenish_effect.gd
git add entities/effects/tower_effects/receive_hit_self_replenish_effect.gd
git commit -m "feat: replenish effects use add_ammo_from_chain to preserve chain context"
```

---

## Task 7：连锁+1 模组

**Files:**
- Create: `entities/modules/chain_module.gd`
- Create: `resources/module_data/chain_module.tres`
- Modify: `ui/popups/reward_popup.gd`

- [ ] **Step 1: 创建 `chain_module.gd`**

```gdscript
# entities/modules/chain_module.gd
class_name ChainModule extends Module

## 连锁+1 模组：本炮塔的 bullet_effects 和 tower_effects
## 在同一传递链上各可额外多触发一次。

func on_install(tower: Node) -> void:
	super.on_install(tower)
	tower.bullet_effect_max_chain += 1
	tower.tower_effect_max_chain += 1

func on_uninstall(tower: Node) -> void:
	super.on_uninstall(tower)
	tower.bullet_effect_max_chain -= 1
	tower.tower_effect_max_chain -= 1
```

- [ ] **Step 2: 运行 validate，确认脚本解析通过**

```bash
godot --headless --script res://tests/validate.gd
```

期望：`PASS  [SCRIPT] res://entities/modules/chain_module.gd`，全部通过。

- [ ] **Step 3: 获取 chain_module.gd 的 UID**

```bash
godot --headless --script res://tests/validate.gd
```

或使用 mcp__godot__get_uid 工具（如可用）：

```
mcp__godot__get_uid  path="res://entities/modules/chain_module.gd"
```

记录输出的 UID，格式如 `uid://xxxxxxxxxxxxxx`，后续步骤中用 `CHAIN_MODULE_UID` 代指。

- [ ] **Step 4: 创建 `resources/module_data/chain_module.tres`**

将以下内容中的 `CHAIN_MODULE_UID` 替换为上一步获取的实际 UID，写入文件：

```
[gd_resource type="Resource" script_class="ChainModule" load_steps=7 format=3 uid="uid://chain_module_res"]

[ext_resource type="Script" uid="CHAIN_MODULE_UID" path="res://entities/modules/chain_module.gd" id="1_chain"]
[ext_resource type="Script" uid="uid://do2jgxl5quy1u" path="res://entities/effects/bullet_effects/bullet_effect.gd" id="1_lnxmg"]
[ext_resource type="Script" uid="uid://c1dpu43lt5kgn" path="res://entities/effects/fire_effects/fire_effect.gd" id="2_agm0r"]
[ext_resource type="Texture2D" uid="uid://cehynituxp320" path="res://assets/modules/flying.png" id="2_icon"]
[ext_resource type="Script" uid="uid://colbecdbctu8q" path="res://resources/TowerStatModifierRes.gd" id="5_ltwva"]
[ext_resource type="Script" uid="uid://dp3m8vtf2fdtx" path="res://entities/effects/tower_effects/tower_effect.gd" id="6_baiug"]

[resource]
script = ExtResource("1_chain")
module_name = "连锁+1"
category = 2
description = "本炮塔的 bullet_effects 和 tower_effects
在同一传递链上各可额外多触发一次"
icon = ExtResource("2_icon")
slot_color = Color(0.9, 0.5, 0.1, 1)
fire_effects = Array[ExtResource("2_agm0r")]([])
tower_effects = Array[ExtResource("6_baiug")]([])
bullet_effects = Array[ExtResource("1_lnxmg")]([])
stat_modifiers = Array[ExtResource("5_ltwva")]([])
```

注：`uid://chain_module_res` 是资源文件本身的 UID，Godot 首次加载时会在 `.godot/uid_cache.bin` 中注册；若 Godot editor 提示 UID 冲突可删除该字段让 Godot 自动分配。

- [ ] **Step 5: 把 chain_module 加入 REWARD_POOL**

打开 `ui/popups/reward_popup.gd`，在 `REWARD_POOL` 数组最后一项 `deal_damage_speed_boost.tres` 后追加一行：

```gdscript
	preload("res://resources/module_data/chain_module.tres"),
```

- [ ] **Step 6: 运行 validate**

```bash
godot --headless --script res://tests/validate.gd
```

期望：全部 PASS，包含 `chain_module.gd` 和场景加载检查。

- [ ] **Step 7: Commit**

```bash
git add entities/modules/chain_module.gd
git add resources/module_data/chain_module.tres
git add ui/popups/reward_popup.gd
git commit -m "feat: add ChainModule (+1 chain count) and register in reward pool"
```

---

## 验证 Checklist

完成所有 task 后，在 Godot 编辑器中手动验证（或交给人工测试）：

- [ ] AB 双塔对射，各有 `补充+2` + `减CD` 模块：弹药不再无限增长，系统稳定在约 9 颗
- [ ] AB 双塔对射，只有默认 `default_replenish`（无额外模块）：弹药正常 1:1 传递，无停止
- [ ] 安装 ChainModule 到一个炮塔后，该塔的特效在链上触发两次（max_chain=2）
- [ ] 无限弹药炮塔（initial_ammo=-1）行为不变
- [ ] 击杀敌人补充弹药（`HitEnemySelfReplenishEffect`）正常工作，不受 chain 影响
