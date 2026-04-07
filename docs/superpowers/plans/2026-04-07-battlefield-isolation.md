# Battlefield Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Isolate the battlefield (Grid + enemies + bullets + dead zones) into a dedicated container that supports pan and zoom, with UI hiding during combat.

**Architecture:** A new `BattlefieldContainer` (Node2D) is inserted between CenterContainer and GridRoot. All runtime combat elements (enemies, bullets, dead zones) spawn as children of this container. Pan/zoom is achieved by modifying the container's `position` and `scale`. Existing code that adds children to `get_tree().root` is redirected to the container via the `bullet_layer` group.

**Tech Stack:** GDScript, Godot 4.4+, Tween API

---

### Task 1: Create BattlefieldContainer script

**Files:**
- Create: `core/battlefield_container.gd`

- [ ] **Step 1: Create the battlefield_container.gd script**

```gdscript
extends Node2D

## battlefield_container.gd — 战场容器
## 管理战场的拖拽平移和缩放动画

# 战场范围（以 Cell 为单位），Grid 居中其内
@export var battlefield_cells: int = 12
const CELL_SIZE := 80.0

# 缩放参数
const COMBAT_SCALE := 0.85
const ZOOM_DURATION := 0.3

# 拖拽状态
var _pan_enabled := false
var _is_dragging := false
var _drag_start_pos := Vector2.ZERO
var _container_start_pos := Vector2.ZERO
var _initial_position := Vector2.ZERO

# 缩放 tween
var _zoom_tween: Tween = null

func _ready():
	add_to_group("bullet_layer")
	_initial_position = position

## 战场范围的半边长（像素）
func _get_battlefield_half_extent() -> float:
	return battlefield_cells * CELL_SIZE / 2.0

## 获取平移的最大偏移量（像素）
## 基于战场范围与可视区域的差值
func _get_max_pan_offset() -> Vector2:
	var half_extent := _get_battlefield_half_extent()
	# Grid 占 5*80=400px，战场占 battlefield_cells*80
	# 缩放后可视 Grid 区域变大（scale < 1 时能看到更多），但平移上限不变
	var grid_half := 5 * CELL_SIZE / 2.0
	var max_offset := half_extent - grid_half
	return Vector2(max_offset, max_offset)

func _input(event: InputEvent) -> void:
	if not _pan_enabled:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_is_dragging = true
			_drag_start_pos = event.position
			_container_start_pos = position
		else:
			_is_dragging = false

	elif event is InputEventScreenDrag and _is_dragging:
		var delta := event.position - _drag_start_pos
		var new_pos := _container_start_pos + delta / scale
		var max_offset := _get_max_pan_offset()
		new_pos.x = clampf(new_pos.x, _initial_position.x - max_offset.x, _initial_position.x + max_offset.x)
		new_pos.y = clampf(new_pos.y, _initial_position.y - max_offset.y, _initial_position.y + max_offset.y)
		position = new_pos

	# 也支持鼠标拖拽（桌面端调试）
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_start_pos = event.position
				_container_start_pos = position
			else:
				_is_dragging = false

	elif event is InputEventMouseMotion and _is_dragging:
		var delta := event.position - _drag_start_pos
		var new_pos := _container_start_pos + delta / scale
		var max_offset := _get_max_pan_offset()
		new_pos.x = clampf(new_pos.x, _initial_position.x - max_offset.x, _initial_position.x + max_offset.x)
		new_pos.y = clampf(new_pos.y, _initial_position.y - max_offset.y, _initial_position.y + max_offset.y)
		position = new_pos

## 进入战斗：缩放到 COMBAT_SCALE，启用拖拽
func enter_combat() -> void:
	_pan_enabled = true
	_is_dragging = false
	_kill_zoom_tween()
	_zoom_tween = create_tween()
	_zoom_tween.set_trans(Tween.TRANS_QUAD)
	_zoom_tween.set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(self, "scale", Vector2.ONE * COMBAT_SCALE, ZOOM_DURATION)

## 退出战斗：缩放回 1.0，平移归位，禁用拖拽
func exit_combat() -> void:
	_pan_enabled = false
	_is_dragging = false
	_kill_zoom_tween()
	_zoom_tween = create_tween()
	_zoom_tween.set_trans(Tween.TRANS_QUAD)
	_zoom_tween.set_ease(Tween.EASE_OUT)
	_zoom_tween.set_parallel(true)
	_zoom_tween.tween_property(self, "scale", Vector2.ONE, ZOOM_DURATION)
	_zoom_tween.tween_property(self, "position", _initial_position, ZOOM_DURATION)

func _kill_zoom_tween() -> void:
	if is_instance_valid(_zoom_tween) and _zoom_tween.is_running():
		_zoom_tween.kill()
	_zoom_tween = null
```

- [ ] **Step 2: Commit**

```bash
git add core/battlefield_container.gd
git commit -m "feat: add BattlefieldContainer script with pan and zoom"
```

---

### Task 2: Insert BattlefieldContainer into main.tscn and update main.gd

**Files:**
- Modify: `main.tscn` — restructure scene tree
- Modify: `main.gd:53-56` — update @onready paths, add battlefield_container reference
- Modify: `main.gd:91-103` — setup BattlefieldContainer in _setup_managers
- Modify: `main.gd:523-530` — trigger enter/exit combat and hide/show deploy UI

- [ ] **Step 1: Modify main.tscn — insert BattlefieldContainer between CenterContainer and GridRoot**

The CenterContainer currently contains GridRoot directly. We need to:
1. Add a Node2D `BattlefieldContainer` as a child of CenterContainer
2. Move GridRoot to be a child of BattlefieldContainer

In `main.tscn`, change the GridRoot parent from `GameContent/CenterContainer` to `GameContent/CenterContainer/BattlefieldContainer`:

Add after the CenterContainer node (line 199):
```
[node name="BattlefieldContainer" type="Node2D" parent="GameContent/CenterContainer"]
script = ExtResource("<battlefield_container_script_id>")
```

Change GridRoot parent path from `GameContent/CenterContainer` to `GameContent/CenterContainer/BattlefieldContainer`.

Change Grid parent path from `GameContent/CenterContainer/GridRoot` to `GameContent/CenterContainer/BattlefieldContainer/GridRoot`.

**Note:** Since manually editing .tscn files is fragile, prefer using Godot MCP tools:
1. Use `mcp__godot__add_node` to add the BattlefieldContainer Node2D
2. Reparent GridRoot under it

Alternatively, modify the scene tree in main.gd code by reparenting at runtime (simpler approach that avoids .tscn editing):

- [ ] **Step 2: Update main.gd — add runtime BattlefieldContainer insertion**

Update the `@onready` vars and add BattlefieldContainer reference. In `main.gd`, change:

```gdscript
# Old (line 53-56):
@onready var game_content = $GameContent
@onready var start_stop_button = $GameContent/PanelContainer/StartStopButton
@onready var grid_root = $GameContent/CenterContainer/GridRoot
@onready var grid_container = $GameContent/CenterContainer/GridRoot/Grid

# New:
@onready var game_content = $GameContent
@onready var start_stop_button = $GameContent/PanelContainer/StartStopButton
@onready var _center_container = $GameContent/CenterContainer
@onready var grid_root = $GameContent/CenterContainer/GridRoot
@onready var grid_container = $GameContent/CenterContainer/GridRoot/Grid
```

Add new constants and variables:

```gdscript
const BattlefieldContainerScript := preload("res://core/battlefield_container.gd")

var _battlefield_container: Node2D
```

Add `@onready` for the deployment panel:

```gdscript
@onready var _removal_zone_panel = $GameContent/RemovalZonePanel
```

- [ ] **Step 3: Update _setup_managers() to create BattlefieldContainer and reparent GridRoot**

In `main.gd`, after `_setup_managers()` line 91, add BattlefieldContainer setup:

```gdscript
func _setup_managers():
	# ── BattlefieldContainer：将 GridRoot 移入战场容器 ──
	_battlefield_container = Node2D.new()
	_battlefield_container.name = "BattlefieldContainer"
	_battlefield_container.set_script(BattlefieldContainerScript)
	_center_container.add_child(_battlefield_container)
	# 将 GridRoot 从 CenterContainer 移到 BattlefieldContainer 下
	grid_root.reparent(_battlefield_container)

	_layout_manager = LayoutManager.new()
	_layout_manager.setup(game_content)
	add_child(_layout_manager)

	_game_loop = GameLoopManager.new()
	_game_loop.setup(grid_container)
	_game_loop.all_enemies_defeated.connect(_on_all_enemies_defeated)
	add_child(_game_loop)

	_effect_manager = EffectManager.new()
	_effect_manager.setup(game_content)
	add_child(_effect_manager)
```

- [ ] **Step 4: Add enter/exit combat calls and UI hiding in game state handlers**

Update `_on_game_started()` and `_on_game_stopped()` in `main.gd`:

```gdscript
func _on_game_started():
	# 隐藏部署 UI（Dev 模式除外）
	if not GameState.is_dev_mode():
		_removal_zone_panel.visible = false
	# 触发战场缩放和启用拖拽
	_battlefield_container.enter_combat()
	_update_button_style()

func _on_game_stopped():
	# GAME_OVER 路径：shake 即将由 _on_enemy_breached 启动，不提前 reset
	if not GameState.is_game_over() and not _effect_manager.is_shaking():
		_effect_manager.reset_position()
	# 退出战斗模式：缩放归位、禁用拖拽
	_battlefield_container.exit_combat()
	# 显示部署 UI
	_removal_zone_panel.visible = true
	_update_button_style()
```

- [ ] **Step 5: Commit**

```bash
git add main.gd
git commit -m "feat: insert BattlefieldContainer, wire combat zoom and UI hiding"
```

---

### Task 3: Redirect enemies and warnings to BattlefieldContainer

**Files:**
- Modify: `core/GameLoopManager.gd:84-95` — pass BattlefieldContainer to dead zone and enemy managers
- Modify: `core/GameLoopManager.gd:152-165` — add enemies as children of BattlefieldContainer
- Modify: `entities/enemies/enemy_manager.gd:55,184,215,243,262,329-334` — use parent container instead of `get_tree().root`

Currently enemies and warnings are added to `get_tree().root`. They need to be added to BattlefieldContainer instead.

- [ ] **Step 1: Add battlefield_container reference to GameLoopManager**

In `GameLoopManager.gd`, add a variable and update `setup()`:

```gdscript
# Add after line 16 (var _enemy_manager):
var _battlefield_container: Node2D = null

# Change setup() signature:
func setup(grid_container: Control, battlefield_container: Node2D = null):
	_grid_container = grid_container
	_battlefield_container = battlefield_container
	SignalBus.game_started.connect(_on_game_started)
	SignalBus.game_stopped.connect(_on_game_stopped)
```

- [ ] **Step 2: Update main.gd to pass BattlefieldContainer to GameLoopManager**

In `main.gd` `_setup_managers()`, change:

```gdscript
# Old:
_game_loop.setup(grid_container)

# New:
_game_loop.setup(grid_container, _battlefield_container)
```

- [ ] **Step 3: Pass container to dead zone and enemy managers in GameLoopManager**

Update `_create_dead_zones()` in `GameLoopManager.gd`:

```gdscript
func _create_dead_zones():
	if is_instance_valid(_dead_zone_manager):
		_dead_zone_manager.queue_free()
	_dead_zone_manager = DeadZoneManager.new()
	_dead_zone_manager.name = "DeadZoneManager"
	if is_instance_valid(_battlefield_container):
		_battlefield_container.add_child(_dead_zone_manager)
	else:
		add_child(_dead_zone_manager)
```

Update `prepare_enemy_warnings()` (line 112-114) — add enemy manager to battlefield container:

```gdscript
# Old:
_enemy_manager = EnemyManager.new()
_enemy_manager.name = "EnemyManager"
add_child(_enemy_manager)

# New:
_enemy_manager = EnemyManager.new()
_enemy_manager.name = "EnemyManager"
if is_instance_valid(_battlefield_container):
	_battlefield_container.add_child(_enemy_manager)
else:
	add_child(_enemy_manager)
```

Apply the same change to `_create_enemy_manager()` (line 156-158).

- [ ] **Step 4: Add spawn_parent to EnemyManager**

In `enemy_manager.gd`, add a variable for the parent container and a setter:

```gdscript
# Add after line 12 (var active_warnings):
var spawn_parent: Node = null  # 敌人和警告的父节点（BattlefieldContainer or root）

func _get_spawn_parent() -> Node:
	if is_instance_valid(spawn_parent):
		return spawn_parent
	return get_tree().root
```

- [ ] **Step 5: Replace all `get_tree().root.add_child` in enemy_manager.gd**

Replace every `get_tree().root.add_child(...)` with `_get_spawn_parent().add_child(...)`:

Line 55 (`_spawn_delayed`):
```gdscript
# Old:
get_tree().root.add_child(enemy)

# New:
_get_spawn_parent().add_child(enemy)
```

Line 184 (`prepare_enemies` — warning creation):
```gdscript
# Old:
get_tree().root.add_child(warning)

# New:
_get_spawn_parent().add_child(warning)
```

Line 217-218 (`spawn_enemies` — direct spawn):
```gdscript
# Old:
get_tree().root.add_child(enemy)

# New:
_get_spawn_parent().add_child(enemy)
```

Line 243 (`spawn_enemies_from_data` — direct spawn):
```gdscript
# Old:
get_tree().root.add_child(enemy)

# New:
_get_spawn_parent().add_child(enemy)
```

Line 262 (`show_warnings_for_existing`):
```gdscript
# Old:
get_tree().root.add_child(warning)

# New:
_get_spawn_parent().add_child(warning)
```

Lines 329-334 (`_on_enemy_destroyed` — dev mode respawn):
```gdscript
# Old:
get_tree().root.add_child(new_enemy)

# New:
_get_spawn_parent().add_child(new_enemy)
```

- [ ] **Step 6: Set spawn_parent when creating enemy manager in GameLoopManager**

In `prepare_enemy_warnings()` and `_create_enemy_manager()`, after creating the enemy manager:

```gdscript
_enemy_manager.spawn_parent = _battlefield_container
```

Add this line after `add_child(_enemy_manager)` in both `prepare_enemy_warnings()` and `_create_enemy_manager()`.

- [ ] **Step 7: Commit**

```bash
git add core/GameLoopManager.gd entities/enemies/enemy_manager.gd main.gd
git commit -m "feat: redirect enemies, warnings, dead zones into BattlefieldContainer"
```

---

### Task 4: Update dead zone positioning to use battlefield bounds

**Files:**
- Modify: `core/dead_zone_manager.gd` — position dead zones based on battlefield range, accept grid_rect parameter

Currently dead zones are positioned based on viewport edges. They need to be positioned based on the battlefield range (12×12 cells centered on the grid).

- [ ] **Step 1: Refactor dead_zone_manager.gd to accept grid_rect and battlefield_cells**

Replace the full `_create_zones()` method and add a setup method:

```gdscript
extends Node2D

# 四个死亡区域（上下左右）
var zones: Array[Area2D] = []

var _grid_rect: Rect2 = Rect2()
var _battlefield_cells: int = 12
var _cell_size: float = 80.0

## 设置战场参数（由 GameLoopManager 调用）
func setup(grid_rect: Rect2, cell_size: float, battlefield_cells: int) -> void:
	_grid_rect = grid_rect
	_cell_size = cell_size
	_battlefield_cells = battlefield_cells

func _ready():
	# 如果已有参数则创建，否则等 setup 后手动调用
	if _grid_rect.size != Vector2.ZERO:
		_create_zones()

func create_zones_from_setup() -> void:
	_create_zones()

func _create_zones():
	for zone in zones:
		if is_instance_valid(zone):
			zone.queue_free()
	zones.clear()

	# 计算战场范围（以 Grid 中心为基准）
	var grid_center := _grid_rect.get_center()
	var bf_half := _battlefield_cells * _cell_size / 2.0
	var margin := 50.0

	# 战场边界坐标
	var bf_top := grid_center.y - bf_half
	var bf_bottom := grid_center.y + bf_half
	var bf_left := grid_center.x - bf_half
	var bf_right := grid_center.x + bf_half
	var bf_width := bf_right - bf_left
	var bf_height := bf_bottom - bf_top

	# 上（在战场顶部外侧）
	_create_zone("Top",
		Vector2(grid_center.x, bf_top - margin / 2),
		Vector2(bf_width + margin * 2, margin))

	# 下（在战场底部外侧）
	_create_zone("Bottom",
		Vector2(grid_center.x, bf_bottom + margin / 2),
		Vector2(bf_width + margin * 2, margin))

	# 左（在战场左侧外侧）
	_create_zone("Left",
		Vector2(bf_left - margin / 2, grid_center.y),
		Vector2(margin, bf_height + margin * 2))

	# 右（在战场右侧外侧）
	_create_zone("Right",
		Vector2(bf_right + margin / 2, grid_center.y),
		Vector2(margin, bf_height + margin * 2))
```

- [ ] **Step 2: Remove viewport resize handler**

Delete the `_on_viewport_size_changed` connection and method since dead zones are now based on battlefield bounds, not viewport:

```gdscript
# Remove from _ready():
get_tree().root.size_changed.connect(_on_viewport_size_changed)

# Remove the method:
# func _on_viewport_size_changed():
#     _create_zones()
```

Keep `_create_zone()`, `_create_debug_visual()`, `_on_area_entered()`, and `clear_all()` unchanged.

- [ ] **Step 3: Update GameLoopManager._create_dead_zones() to pass parameters**

```gdscript
func _create_dead_zones():
	if is_instance_valid(_dead_zone_manager):
		_dead_zone_manager.queue_free()
	_dead_zone_manager = DeadZoneManager.new()
	_dead_zone_manager.name = "DeadZoneManager"

	var grid_rect := _grid_container.get_global_rect()
	_dead_zone_manager.setup(grid_rect, CELL_SIZE, _get_battlefield_cells())

	if is_instance_valid(_battlefield_container):
		_battlefield_container.add_child(_dead_zone_manager)
	else:
		add_child(_dead_zone_manager)
	_dead_zone_manager.create_zones_from_setup()
```

Add a helper to get battlefield cells from the container:

```gdscript
func _get_battlefield_cells() -> int:
	if is_instance_valid(_battlefield_container) and _battlefield_container.has_method("_get_battlefield_half_extent"):
		return _battlefield_container.battlefield_cells
	return 12  # fallback default
```

- [ ] **Step 4: Commit**

```bash
git add core/dead_zone_manager.gd core/GameLoopManager.gd
git commit -m "feat: position dead zones based on battlefield range instead of viewport"
```

---

### Task 5: Update enemy spawn distance to 3 cells from Grid edge

**Files:**
- Modify: `entities/enemies/enemy_manager.gd:6-7` — change SPAWN_MARGIN and WARNING_DISTANCE

- [ ] **Step 1: Update spawn constants**

In `enemy_manager.gd`, change:

```gdscript
# Old (line 6-7):
const SPAWN_MARGIN = 60.0  # 生成位置距离屏幕边缘的距离
const WARNING_DISTANCE = 60.0  # 警告图标距离grid的距离（大半个cell）

# New:
const SPAWN_MARGIN = 240.0  # 生成位置距离 Grid 边缘的距离（3 个 Cell）
const WARNING_DISTANCE = 240.0  # 警告图标距离 Grid 边缘的距离（3 个 Cell）
```

- [ ] **Step 2: Update spawn position calculations to use grid-relative positions**

Currently spawn positions use viewport edges (e.g., `y = -SPAWN_MARGIN` or `y = viewport_size.y + SPAWN_MARGIN`). With the new 240px margin, positions should be relative to grid edges:

In `prepare_enemies()`, replace the spawn position calculations (lines 118-144):

```gdscript
		if direction == Vector2(0, 1):  # 从上往下
			col = randi() % cols
			var x = grid_rect.position.x + col * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(x, grid_rect.position.y - SPAWN_MARGIN)
			warning_pos = Vector2(x, grid_rect.position.y - WARNING_DISTANCE)
			pos_key = "top_" + str(col)

		elif direction == Vector2(0, -1):  # 从下往上
			col = randi() % cols
			var x = grid_rect.position.x + col * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(x, grid_rect.position.y + grid_rect.size.y + SPAWN_MARGIN)
			warning_pos = Vector2(x, grid_rect.position.y + grid_rect.size.y + WARNING_DISTANCE)
			pos_key = "bottom_" + str(col)

		elif direction == Vector2(1, 0):  # 从左往右
			row = randi() % rows
			var y = grid_rect.position.y + row * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(grid_rect.position.x - SPAWN_MARGIN, y)
			warning_pos = Vector2(grid_rect.position.x - WARNING_DISTANCE, y)
			pos_key = "left_" + str(row)

		elif direction == Vector2(-1, 0):  # 从右往左
			row = randi() % rows
			var y = grid_rect.position.y + row * grid_cell_size + grid_cell_size / 2
			spawn_pos = Vector2(grid_rect.position.x + grid_rect.size.x + SPAWN_MARGIN, y)
			warning_pos = Vector2(grid_rect.position.x + grid_rect.size.x + WARNING_DISTANCE, y)
			pos_key = "right_" + str(row)
```

Note: The key change is that spawn positions are now relative to `grid_rect` edges (e.g., `grid_rect.position.y - SPAWN_MARGIN`) instead of viewport edges (e.g., `-SPAWN_MARGIN` or `viewport_size.y + SPAWN_MARGIN`). This ensures spawning works correctly regardless of where the grid is positioned on screen.

- [ ] **Step 3: Commit**

```bash
git add entities/enemies/enemy_manager.gd
git commit -m "feat: move enemy spawn to 3 cells from grid edge"
```

---

### Task 6: Run game and verify all features

**Files:** None (verification only)

- [ ] **Step 1: Run the game and verify basic functionality**

Run: `mcp__godot__run_project`

Verify:
1. Game starts normally, Grid is visible and centered
2. Towers can be placed on the grid during deployment phase
3. Click "开始第1关" — deployment UI hides (or stays visible in Dev mode), Grid scales down smoothly
4. Enemies spawn at ~3 cells distance from Grid edge (visually further than before)
5. Dead zones are visible (debug visuals) around the battlefield boundary, not viewport edges
6. Bullets are cleaned up by dead zones before leaving the battlefield area
7. Can drag/pan the battlefield during combat phase
8. Pan is bounded (cannot drag infinitely)
9. After all enemies defeated (or game over), Grid zooms back to 1.0, position resets, deployment UI reappears
10. Cannot pan during deployment phase

- [ ] **Step 2: Verify Dev mode**

Switch to Dev mode and verify:
1. Deployment UI stays visible during combat
2. Zoom and pan still work
3. Debug stop button works correctly
4. Enemies respawn correctly in Dev mode

- [ ] **Step 3: Stop the project**

Run: `mcp__godot__stop_project`

---

### Task 7: Write tests

**Files:**
- Create: `tests/gdunit/test_battlefield_container.gd`

- [ ] **Step 1: Write BattlefieldContainer unit tests**

```gdscript
extends GdUnitTestSuite

const BattlefieldContainerScript = preload("res://core/battlefield_container.gd")

var _container: Node2D

func before_test():
	_container = Node2D.new()
	_container.set_script(BattlefieldContainerScript)
	add_child(_container)
	_container.position = Vector2(200, 300)
	_container._initial_position = _container.position

func after_test():
	if is_instance_valid(_container):
		_container.queue_free()

func test_initial_state():
	assert_bool(_container._pan_enabled).is_false()
	assert_bool(_container._is_dragging).is_false()

func test_enter_combat_enables_pan():
	_container.enter_combat()
	assert_bool(_container._pan_enabled).is_true()

func test_exit_combat_disables_pan():
	_container.enter_combat()
	_container.exit_combat()
	assert_bool(_container._pan_enabled).is_false()
	assert_bool(_container._is_dragging).is_false()

func test_enter_combat_scales_down():
	_container.enter_combat()
	# Wait for tween to complete
	await get_tree().create_timer(0.5).timeout
	assert_float(_container.scale.x).is_equal_approx(0.85, 0.01)
	assert_float(_container.scale.y).is_equal_approx(0.85, 0.01)

func test_exit_combat_restores_scale():
	_container.enter_combat()
	await get_tree().create_timer(0.5).timeout
	_container.exit_combat()
	await get_tree().create_timer(0.5).timeout
	assert_float(_container.scale.x).is_equal_approx(1.0, 0.01)
	assert_float(_container.scale.y).is_equal_approx(1.0, 0.01)

func test_exit_combat_restores_position():
	_container.enter_combat()
	await get_tree().create_timer(0.1).timeout
	_container.position = Vector2(100, 100)  # simulate pan
	_container.exit_combat()
	await get_tree().create_timer(0.5).timeout
	assert_vector(_container.position).is_equal_approx(Vector2(200, 300), Vector2(1, 1))

func test_pan_clamped_to_battlefield_bounds():
	_container.enter_combat()
	# Max offset for 12-cell battlefield with 5-cell grid:
	# (12*80/2) - (5*80/2) = 480 - 200 = 280px
	_container.position = Vector2(9999, 9999)
	# Manually call the clamp logic
	var max_offset = _container._get_max_pan_offset()
	assert_float(max_offset.x).is_equal_approx(280.0, 0.01)
	assert_float(max_offset.y).is_equal_approx(280.0, 0.01)

func test_bullet_layer_group():
	assert_bool(_container.is_in_group("bullet_layer")).is_true()

func test_battlefield_cells_configurable():
	_container.battlefield_cells = 16
	var max_offset = _container._get_max_pan_offset()
	# (16*80/2) - (5*80/2) = 640 - 200 = 440px
	assert_float(max_offset.x).is_equal_approx(440.0, 0.01)
```

- [ ] **Step 2: Run tests**

Run the GdUnit4 test suite from the Godot Editor (GdUnit → Run Tests) or via CLI.
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add tests/gdunit/test_battlefield_container.gd
git commit -m "test: add BattlefieldContainer tests for pan, zoom, and bounds"
```

---

### Task 8: Write documentation

**Files:**
- Create: `docs/content/battlefield-container.md`
- Modify: `docs/DOC_INDEX.md` — add index entry

- [ ] **Step 1: Create battlefield container documentation**

```markdown
# 战场容器（BattlefieldContainer）

## 概述

BattlefieldContainer 是一个 Node2D 容器，将战场元素（Grid、敌人、子弹、Dead Zone）与 UI 隔离。支持战斗阶段的拖拽平移和缩放动画。

## 参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `battlefield_cells` | 12 | 战场范围（Cell 为单位），Grid 居中其内 |
| `COMBAT_SCALE` | 0.85 | 战斗阶段缩放比例 |
| `ZOOM_DURATION` | 0.3s | 缩放 Tween 时长 |

## 行为

### 部署阶段（DEPLOYMENT）

- Grid 居中，scale = 1.0
- 拖拽平移禁用
- 底部部署 UI 可见

### 战斗阶段（RUNNING）

- `enter_combat()` 触发：
  - 缩放到 COMBAT_SCALE（Tween）
  - 启用拖拽平移（触摸和鼠标）
- 拖拽范围：不超出 battlefield_cells 定义的战场范围
- 底部部署 UI 隐藏（Dev 模式除外）

### 战斗结束

- `exit_combat()` 触发：
  - 缩放回 1.0（Tween）
  - 位置回到初始位置（Tween）
  - 禁用拖拽
- 显示部署 UI

## 场景树

```text
CenterContainer
└── BattlefieldContainer (Node2D)  ← 运行时插入
    ├── GridRoot → Grid (5×5)
    ├── EnemyManager (运行时)
    ├── DeadZones ×4 (运行时)
    └── Bullets (通过 bullet_layer group)
```

## 敌人生成

- 距 Grid 边缘 3 个 Cell（240px）处生成
- Dead Zone 位于战场范围边缘

## 相关文件

- `core/battlefield_container.gd` — 容器脚本
- `core/dead_zone_manager.gd` — Dead Zone 定位（基于战场范围）
- `entities/enemies/enemy_manager.gd` — 敌人生成距离
```

- [ ] **Step 2: Update DOC_INDEX.md**

Add an entry under the appropriate section:

```markdown
- [战场容器](content/battlefield-container.md) — BattlefieldContainer：拖拽平移、缩放动画、战场隔离
```

- [ ] **Step 3: Commit**

```bash
git add docs/content/battlefield-container.md docs/DOC_INDEX.md
git commit -m "docs: add battlefield container documentation"
```
