# Warning Danger Shader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 若某方向有敌人生成但无炮管指向，该方向的感叹号警告变为红色并加粗（Shader 实现）。

**Architecture:** 在 `GameLoopManager.prepare_enemy_warnings()` 收集所有已部署炮塔的世界空间炮管方向，与每个 warning 节点的 `direction` 属性比对；若无炮管覆盖该来袭方向，调用 `warning.set_danger(true)` 挂载红色 outline shader。

**Tech Stack:** GDScript 4.4, Godot CanvasItem Shader (GLSL-like)

---

## Files

| Action | Path | Purpose |
|--------|------|---------|
| Create | `entities/enemies/enemy_warning_danger.gdshader` | 红色 + outline 加粗效果 shader |
| Modify | `entities/enemies/enemy_warning.gd` | 新增 `set_danger(bool)` 方法 |
| Modify | `core/GameLoopManager.gd` | 新增 `_get_covered_directions()` 和后处理逻辑 |

---

### Task 1: 创建 Danger Shader 文件

**Files:**
- Create: `entities/enemies/enemy_warning_danger.gdshader`

- [ ] **Step 1: 创建 shader 文件**

```
# File: entities/enemies/enemy_warning_danger.gdshader
shader_type canvas_item;

uniform float outline_size : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (color.a > 0.1) {
		// 原始像素变红
		COLOR = vec4(1.0, 0.0, 0.0, color.a);
	} else {
		// Outline 采样：让相邻像素形成红色轮廓，实现"加粗"感
		vec2 texel = TEXTURE_PIXEL_SIZE;
		float alpha = 0.0;
		for (float x = -outline_size; x <= outline_size; x += 1.0) {
			for (float y = -outline_size; y <= outline_size; y += 1.0) {
				if (length(vec2(x, y)) <= outline_size) {
					alpha = max(alpha, texture(TEXTURE, UV + vec2(x, y) * texel).a);
				}
			}
		}
		COLOR = vec4(1.0, 0.0, 0.0, alpha);
	}
}
```

- [ ] **Step 2: 在 Godot 编辑器中确认文件被识别**

打开 Godot 编辑器，FileSystem 面板中应能看到 `entities/enemies/enemy_warning_danger.gdshader`，且无导入错误。

- [ ] **Step 3: Commit**

```bash
cd /Users/wangyiwen/Projects/shooting-playground-godot
git add entities/enemies/enemy_warning_danger.gdshader
git commit -m "feat: add danger shader for enemy warning (red + outline bold)"
```

---

### Task 2: 给 EnemyWarning 加 set_danger 方法

**Files:**
- Modify: `entities/enemies/enemy_warning.gd`

- [ ] **Step 1: 阅读当前文件内容（确认理解现有结构）**

当前 `enemy_warning.gd`：
```gdscript
extends Node2D

const ANIMATION_SPEED = 6.0
const ANIMATION_AMPLITUDE = 8.0

var direction: Vector2 = Vector2.ZERO
var base_position: Vector2 = Vector2.ZERO
var time_accumulator: float = 0.0

func _ready():
    rotation = 0
    base_position = position

func _process(delta):
    time_accumulator += delta
    var offset_y = sin(time_accumulator * ANIMATION_SPEED) * ANIMATION_AMPLITUDE
    position.y = base_position.y + offset_y

func set_direction(dir: Vector2):
    direction = dir

func set_grid_aligned_position(pos: Vector2):
    base_position = pos
    position = pos
```

- [ ] **Step 2: 添加 `set_danger` 方法和 shader 缓存变量**

在 `var time_accumulator` 声明之后、`_ready()` 之前插入：

```gdscript
var _danger_material: ShaderMaterial = null
```

在文件末尾 `set_grid_aligned_position` 之后追加：

```gdscript
func set_danger(is_danger: bool) -> void:
	var sprite := $Sprite2D
	if is_danger:
		if _danger_material == null:
			_danger_material = ShaderMaterial.new()
			_danger_material.shader = load("res://entities/enemies/enemy_warning_danger.gdshader")
		sprite.material = _danger_material
	else:
		sprite.material = null
```

- [ ] **Step 3: 验证文件无语法错误**

在 Godot 编辑器中打开 `entities/enemies/enemy_warning.gd`，底部状态栏无错误提示（或运行游戏时无脚本报错）。

- [ ] **Step 4: Commit**

```bash
git add entities/enemies/enemy_warning.gd
git commit -m "feat: add set_danger() to EnemyWarning for red shader activation"
```

---

### Task 3: 在 GameLoopManager 中计算覆盖方向并设置 danger

**Files:**
- Modify: `core/GameLoopManager.gd`

- [ ] **Step 1: 在 GameLoopManager 末尾添加 `_get_covered_directions()` 辅助函数**

在 `get_pending_enemy_data()` 函数之后追加：

```gdscript
## 收集所有已部署炮塔当前世界空间炮管方向（归一化到4个基本方向）
func _get_covered_directions() -> Array:
	var covered: Array = []
	for cell in _grid_container.get_children():
		if not cell.has_method("get_deployed_tower"):
			continue
		var tower = cell.get_deployed_tower()
		if not is_instance_valid(tower):
			continue
		var rotation_rad := deg_to_rad(float(tower.current_rotation_index) * 90.0)
		var barrel_dirs: PackedVector2Array
		if tower.data and tower.data.barrel_directions.size() > 0:
			barrel_dirs = tower.data.barrel_directions
		else:
			barrel_dirs = PackedVector2Array([Vector2(0, -1)])
		for local_dir in barrel_dirs:
			var world_dir: Vector2 = local_dir.rotated(rotation_rad)
			covered.append(_snap_cardinal(world_dir))
	return covered

## 将任意向量吸附到最近的4个基本方向之一
func _snap_cardinal(dir: Vector2) -> Vector2:
	if abs(dir.x) >= abs(dir.y):
		return Vector2(sign(dir.x), 0)
	else:
		return Vector2(0, sign(dir.y))
```

- [ ] **Step 2: 添加 `_apply_danger_to_warnings()` 辅助函数**

紧接在 `_snap_cardinal` 之后追加：

```gdscript
## 根据覆盖方向集合，为每个 active warning 设置 danger 状态
func _apply_danger_to_warnings() -> void:
	if not is_instance_valid(_enemy_manager):
		return
	var covered := _get_covered_directions()
	for warning in _enemy_manager.active_warnings:
		if not is_instance_valid(warning):
			continue
		# 敌人从 warning.direction 方向移动过来
		# 炮塔需指向 -warning.direction 才能覆盖该方向
		var needed_dir := -warning.direction
		var is_covered := needed_dir in covered
		warning.set_danger(not is_covered)
```

- [ ] **Step 3: 在 `prepare_enemy_warnings()` 末尾调用 `_apply_danger_to_warnings()`**

`prepare_enemy_warnings()` 函数末尾目前是：
```gdscript
    _accumulated_enemy_data = _pending_enemy_data.duplicate()
```

在这行之后追加：
```gdscript
    _apply_danger_to_warnings()
```

完整 `prepare_enemy_warnings()` 函数末尾应如下：
```gdscript
    _accumulated_enemy_data = _pending_enemy_data.duplicate()
    _apply_danger_to_warnings()
```

- [ ] **Step 4: 验证逻辑正确性（手动推理）**

情景验证：
- 敌人从顶部（`direction = Vector2(0, 1)`）来袭，needed_dir = `Vector2(0, -1)` (UP)
  - 若场上有炮台朝上（`current_rotation_index = 0`，barrel `(0,-1)` rotated 0° = `(0,-1)`） → covered → 不变红 ✓
  - 若无炮台朝上 → 不在 covered → 变红 ✓
- 敌人从右侧（`direction = Vector2(-1, 0)`）来袭，needed_dir = `Vector2(1, 0)` (RIGHT)
  - 炮台朝右（`current_rotation_index = 1`，barrel `(0,-1)` rotated 90° = `(1,0)`）→ covered ✓

- [ ] **Step 5: 运行游戏验证效果**

1. 打开 Godot 编辑器运行游戏（F5 from start_menu.tscn）
2. 进入战斗准备阶段
3. 确认：
   - 有炮管指向的方向：感叹号维持原色（白色/默认）
   - 无炮管指向的方向：感叹号变红且有加粗轮廓
4. 旋转炮塔，重新开一局，确认颜色随之变化

- [ ] **Step 6: Commit**

```bash
git add core/GameLoopManager.gd
git commit -m "feat: highlight uncovered spawn directions with red danger shader"
```

---

## Self-Review

**Spec coverage:**
- [x] 有敌人生成方向 → 检测是否有炮管覆盖（Task 3）
- [x] 无覆盖 → 感叹号变红（shader, Task 1 + Task 2）
- [x] 加粗效果（outline shader, Task 1）
- [x] 正常方向不受影响（`set_danger(false)` → `material = null`）

**Placeholder scan:** 无 TBD/TODO，所有步骤含完整代码。

**Type consistency:**
- `set_danger(bool)` 在 Task 2 定义，Task 3 调用 ✓
- `_get_covered_directions() -> Array` 在 Task 3 定义并在 `_apply_danger_to_warnings()` 内调用 ✓
- `_apply_danger_to_warnings()` 在 Task 3 定义，`prepare_enemy_warnings()` 末尾调用 ✓
- `warning.direction` 是 `enemy_warning.gd` 中已有的 `var direction: Vector2` ✓
- `_enemy_manager.active_warnings` 是 `enemy_manager.gd` 中已有的 `var active_warnings: Array` ✓
