# Dev Mode Infinite Respawn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make dev mode a sandbox where enemies respawn indefinitely from a fixed position and the player can stop the game at any time.

**Architecture:** Three isolated changes — (1) `EnemyManager` gains a `dev_spawn_info` dict and respawn logic in `_on_enemy_destroyed`, (2) `GameLoopManager.prepare_enemy_warnings` clamps `enemy_count` to 1 in dev mode, (3) `main.gd._update_button_style` shows the existing `_debug_stop_button` while running in dev mode.

**Tech Stack:** GDScript 4, GdUnit4 (test runner: `addons/gdUnit4/bin/GdUnitCmdTool.gd`)

---

## File Map

| File | Change |
|------|--------|
| `entities/enemies/enemy_manager.gd` | Add `dev_spawn_info`, modify `spawn_enemies_from_data`, modify `_on_enemy_destroyed` |
| `core/GameLoopManager.gd` | Clamp `enemy_count = 1` in dev mode inside `prepare_enemy_warnings` |
| `main.gd` | Show/hide `_debug_stop_button` based on dev mode + running state |
| `tests/gdunit/DevModeRespawnTest.gd` | New test file |

---

### Task 1: Write failing tests for EnemyManager dev respawn

**Files:**
- Create: `tests/gdunit/DevModeRespawnTest.gd`

- [ ] **Step 1: Create the test file**

```gdscript
# tests/gdunit/DevModeRespawnTest.gd
class_name DevModeRespawnTest
extends GdUnitTestSuite

var _nodes_to_free: Array[Node] = []

func before_test() -> void:
	_nodes_to_free.clear()
	GameState.game_mode = GameState.GameMode.DEV

func after_test() -> void:
	GameState.game_mode = GameState.GameMode.CHAOS
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()

func _add(node: Node) -> Node:
	get_tree().root.add_child(node)
	_nodes_to_free.append(node)
	return node

# Test: in dev mode, destroying the single enemy does NOT emit all_enemies_defeated
func test_dev_mode_no_all_enemies_defeated_signal() -> void:
	GameState.start_game()
	var em: Node2D = load("res://entities/enemies/enemy_manager.gd").new()
	em.name = "EnemyManagerTest"
	_add(em)
	await await_idle_frame()

	# Set a fake grid rect so spawn math doesn't crash
	em.set_grid_info(Rect2(100, 100, 400, 400), 80.0)

	var spawn_info := {
		"spawn_pos": Vector2(300, 50),
		"warning_pos": Vector2(300, 40),
		"direction": Vector2(0, 1),
		"pos_key": "top_2"
	}
	em.spawn_enemies_from_data([spawn_info])
	await await_idle_frame()

	# Listen for the signal — it must NOT be emitted
	var signal_emitted := false
	em.all_enemies_defeated.connect(func(): signal_emitted = true)

	# Kill the enemy
	assert_int(em.active_enemies.size()).is_equal(1)
	var enemy = em.active_enemies[0]
	em._on_enemy_destroyed(enemy)
	await await_idle_frame()

	assert_bool(signal_emitted).is_false()
	GameState.stop_game()

# Test: in dev mode, a new enemy is spawned after the old one is destroyed
func test_dev_mode_enemy_respawns_after_death() -> void:
	GameState.start_game()
	var em: Node2D = load("res://entities/enemies/enemy_manager.gd").new()
	em.name = "EnemyManagerTest2"
	_add(em)
	await await_idle_frame()

	em.set_grid_info(Rect2(100, 100, 400, 400), 80.0)

	var spawn_info := {
		"spawn_pos": Vector2(300, 50),
		"warning_pos": Vector2(300, 40),
		"direction": Vector2(0, 1),
		"pos_key": "top_2"
	}
	em.spawn_enemies_from_data([spawn_info])
	await await_idle_frame()

	var first_enemy = em.active_enemies[0]
	em._on_enemy_destroyed(first_enemy)
	await await_idle_frame()

	# A new enemy should have been added
	assert_int(em.active_enemies.size()).is_equal(1)
	assert_bool(em.active_enemies[0] != first_enemy).is_true()
	GameState.stop_game()

# Test: in normal mode, all_enemies_defeated IS emitted when last enemy dies
func test_normal_mode_all_enemies_defeated_signal() -> void:
	GameState.game_mode = GameState.GameMode.CHAOS
	GameState.start_game()
	var em: Node2D = load("res://entities/enemies/enemy_manager.gd").new()
	em.name = "EnemyManagerTest3"
	_add(em)
	await await_idle_frame()

	em.set_grid_info(Rect2(100, 100, 400, 400), 80.0)

	var spawn_info := {
		"spawn_pos": Vector2(300, 50),
		"warning_pos": Vector2(300, 40),
		"direction": Vector2(0, 1),
		"pos_key": "top_2"
	}
	em.spawn_enemies_from_data([spawn_info])
	await await_idle_frame()

	var signal_emitted := false
	em.all_enemies_defeated.connect(func(): signal_emitted = true)

	var enemy = em.active_enemies[0]
	em._on_enemy_destroyed(enemy)
	await await_idle_frame()

	assert_bool(signal_emitted).is_true()
	GameState.stop_game()
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/wangyiwen/Projects/shooting-playground-godot
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests/gdunit/DevModeRespawnTest.gd 2>&1 | tail -30
```

Expected: Tests fail (methods/fields don't exist yet).

---

### Task 2: Implement dev respawn in EnemyManager

**Files:**
- Modify: `entities/enemies/enemy_manager.gd`

- [ ] **Step 1: Add `dev_spawn_info` field and populate it in `spawn_enemies_from_data`**

In `enemy_manager.gd`, add the field after `var pending_enemies`:

```gdscript
var dev_spawn_info: Dictionary = {}
```

In `spawn_enemies_from_data`, after the existing loop that instantiates enemies, add at the end:

```gdscript
	# Dev mode: store the first spawn position for infinite respawn
	if GameState.is_dev_mode() and enemy_data.size() > 0:
		dev_spawn_info = enemy_data[0].duplicate()
```

The full modified `spawn_enemies_from_data` looks like:

```gdscript
func spawn_enemies_from_data(enemy_data: Array):
	# 清除警告
	clear_warnings()
	
	# 清除现有敌人
	clear_enemies()
	
	# 根据传入的数据生成敌人
	for enemy_info in enemy_data:
		var enemy = ENEMY_SCENE.instantiate()
		enemy.set_grid_aligned_position(enemy_info["spawn_pos"])
		enemy.set_direction(enemy_info["direction"])
		
		# 连接碰撞信号
		enemy.enemy_hit.connect(_on_enemy_hit)
		enemy.enemy_destroyed.connect(_on_enemy_destroyed)
		
		# 添加到场景
		get_tree().root.add_child(enemy)
		active_enemies.append(enemy)
	
	# Dev mode: store the first spawn position for infinite respawn
	if GameState.is_dev_mode() and enemy_data.size() > 0:
		dev_spawn_info = enemy_data[0].duplicate()
```

- [ ] **Step 2: Modify `_on_enemy_destroyed` to respawn in dev mode**

Replace the existing `_on_enemy_destroyed` with:

```gdscript
func _on_enemy_destroyed(enemy: CharacterBody2D):
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		GameState.add_coins(1)
		
		if GameState.is_dev_mode() and GameState.is_running() and not dev_spawn_info.is_empty():
			# Dev mode: immediately respawn a new enemy at the same position
			var new_enemy = ENEMY_SCENE.instantiate()
			new_enemy.set_grid_aligned_position(dev_spawn_info["spawn_pos"])
			new_enemy.set_direction(dev_spawn_info["direction"])
			new_enemy.enemy_hit.connect(_on_enemy_hit)
			new_enemy.enemy_destroyed.connect(_on_enemy_destroyed)
			get_tree().root.add_child(new_enemy)
			active_enemies.append(new_enemy)
		elif active_enemies.size() == 0:
			all_enemies_defeated.emit()
```

- [ ] **Step 3: Run the tests**

```bash
cd /Users/wangyiwen/Projects/shooting-playground-godot
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests/gdunit/DevModeRespawnTest.gd 2>&1 | tail -30
```

Expected: All 3 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add entities/enemies/enemy_manager.gd tests/gdunit/DevModeRespawnTest.gd
git commit -m "feat: dev mode infinite enemy respawn at fixed spawn position"
```

---

### Task 3: Clamp enemy count to 1 in dev mode (GameLoopManager)

**Files:**
- Modify: `core/GameLoopManager.gd`

- [ ] **Step 1: Add dev mode branch in `prepare_enemy_warnings`**

In `GameLoopManager.gd`, the end of `prepare_enemy_warnings` currently has:

```gdscript
	if GameState.game_mode == GameState.GameMode.NORMAL and _accumulated_enemy_data.size() > 0:
		# ... normal mode logic ...
	else:
		# 混乱模式（或普通模式首波）：完全随机生成
		_enemy_manager.excluded_pos_keys = []
		_enemy_manager.enemy_count = new_enemy_count
		_pending_enemy_data = _enemy_manager.prepare_enemies()
```

Replace with:

```gdscript
	if GameState.is_dev_mode():
		# Dev mode: always 1 enemy, fully random position, no accumulation
		_enemy_manager.excluded_pos_keys = []
		_enemy_manager.enemy_count = 1
		_pending_enemy_data = _enemy_manager.prepare_enemies()
	elif GameState.game_mode == GameState.GameMode.NORMAL and _accumulated_enemy_data.size() > 0:
		# 普通模式：保留上一波敌人位置，只新增差额
		_pending_enemy_data = _accumulated_enemy_data.duplicate()
		var additional_count = new_enemy_count - _accumulated_enemy_data.size()
		if additional_count > 0:
			# 排除已有位置，只随机生成新增部分
			_enemy_manager.excluded_pos_keys = []
			for info in _accumulated_enemy_data:
				_enemy_manager.excluded_pos_keys.append(info["pos_key"])
			_enemy_manager.enemy_count = additional_count
			var new_data = _enemy_manager.prepare_enemies()
			_pending_enemy_data.append_array(new_data)
			# 为已有敌人补充显示警告
			_enemy_manager.show_warnings_for_existing(_accumulated_enemy_data)
		else:
			# 敌人数未增加，为所有已有敌人显示警告
			_enemy_manager.show_warnings_for_existing(_accumulated_enemy_data)
	else:
		# 混乱模式（或普通模式首波）：完全随机生成
		_enemy_manager.excluded_pos_keys = []
		_enemy_manager.enemy_count = new_enemy_count
		_pending_enemy_data = _enemy_manager.prepare_enemies()

	_accumulated_enemy_data = _pending_enemy_data.duplicate()
```

- [ ] **Step 2: Verify existing tests still pass**

```bash
cd /Users/wangyiwen/Projects/shooting-playground-godot
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests/gdunit/DevModeRespawnTest.gd 2>&1 | tail -20
```

Expected: All 3 DevModeRespawnTest tests PASS.

- [ ] **Step 3: Commit**

```bash
git add core/GameLoopManager.gd
git commit -m "feat: dev mode uses single fixed spawn position per wave"
```

---

### Task 4: Show stop button in dev mode during gameplay

**Files:**
- Modify: `main.gd` — `_update_button_style()`

- [ ] **Step 1: Update `_update_button_style` to show `_debug_stop_button` in dev mode**

Replace the existing `_update_button_style` method:

```gdscript
func _update_button_style():
	var is_running = GameState.is_running()
	var is_dev = GameState.is_dev_mode()

	# Dev mode running: show stop button, hide start button
	if is_dev and is_running:
		start_stop_button.visible = false
		_debug_stop_button.visible = true
		return

	# All other states: hide stop button
	_debug_stop_button.visible = false
	start_stop_button.visible = not is_running
	if not is_running:
		var has_staging: bool = is_instance_valid(_staging_icon) and _staging_icon.visible
		start_stop_button.disabled = has_staging
		var next_wave = _game_loop.get_current_wave() + 1
		start_stop_button.text = "开始第" + str(next_wave) + "关"
		var style = _create_button_style(has_staging)
		start_stop_button.add_theme_stylebox_override("normal", style.normal)
		start_stop_button.add_theme_stylebox_override("hover", style.hover)
		start_stop_button.add_theme_stylebox_override("pressed", style.pressed)
```

- [ ] **Step 2: Run validate script to catch any scene/script issues**

```bash
cd /Users/wangyiwen/Projects/shooting-playground-godot
godot --headless -s tests/validate.gd 2>&1 | tail -20
```

Expected: No errors reported.

- [ ] **Step 3: Commit**

```bash
git add main.gd
git commit -m "feat: show stop button during dev mode gameplay"
```

---

## Self-Review Notes

- **Spec coverage:** All 4 spec requirements covered (stop button §1, single spawn §2, respawn §3, no wave progression §3/§4).
- **No placeholders:** All steps contain complete code.
- **Type consistency:** `dev_spawn_info` is `Dictionary`, used consistently across Task 1 tests and Task 2 implementation. `_on_enemy_destroyed` signature unchanged (`CharacterBody2D`).
- **Normal mode unaffected:** Task 2 only branches on `GameState.is_dev_mode()`, Task 3 adds dev branch before existing conditions.
