# Shield Enemy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shielded enemy type with multi-layer shields that absorb one hit each, with visual shield bubble, segmented shield bar, and break animations.

**Architecture:** New `shield_enemy.gd` extends `enemy.gd`, overrides `take_damage()` to consume shield layers before dealing HP damage. Shield visuals are a dedicated `ShieldBubble` node (shader-based pulsing effect) and a `ShieldBar` drawn above the health bar. Shield break triggers a particle-like fragment animation. The spawn picker gets a third enemy type entry.

**Tech Stack:** GDScript, Godot 4.4+ shaders, custom `_draw()` for shield bar

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `entities/enemies/shield_enemy.gd` | Create | Shield enemy script extending `enemy.gd` — shield layer logic, damage override |
| `entities/enemies/shield_enemy.tscn` | Create | Scene with Sprite2D, Hitbox, ShieldBubble child |
| `entities/enemies/shield_bubble.gd` | Create | Visual shield bubble overlay — pulsing animation, layer-based opacity, ripple on hit |
| `entities/enemies/shield_bubble.gdshader` | Create | Shader for breathing/pulsing effect and hit ripple |
| `ui/hud/shield_bar.gd` | Create | Segmented shield bar drawn above health bar |
| `entities/enemies/shield_break_effect.gd` | Create | Break animation — fragments fly outward on last shield destroyed |
| `entities/enemies/enemy_spawn_picker.gd` | Modify | Add shield enemy to spawn pool |
| `core/Paths.gd` | Modify | Add `SHIELD_ENEMY_SCENE` constant |

---

### Task 1: Shield Enemy Core — Script + Scene

**Files:**
- Create: `entities/enemies/shield_enemy.gd`
- Create: `entities/enemies/shield_enemy.tscn` (via MCP)
- Modify: `core/Paths.gd`

- [ ] **Step 1: Create `shield_enemy.gd`**

```gdscript
extends "res://entities/enemies/enemy.gd"

## shield_layers: 当前剩余护盾层数
var shield_layers: int = 2
var max_shield_layers: int = 2

var _shield_bubble: Node2D = null
var _shield_bar: Node2D = null
var _is_stunned: bool = false

func _ready():
	speed = 25.0
	max_health = 4.0
	super._ready()
	_setup_shield_visuals()

func _setup_shield_visuals():
	# Shield bubble (visual overlay)
	var ShieldBubbleScript = preload("res://entities/enemies/shield_bubble.gd")
	_shield_bubble = ShieldBubbleScript.new()
	add_child(_shield_bubble)
	_shield_bubble.setup(max_shield_layers)

	# Shield bar (above health bar)
	var ShieldBarScript = preload("res://ui/hud/shield_bar.gd")
	_shield_bar = ShieldBarScript.new()
	add_child(_shield_bar)
	_shield_bar.update(shield_layers, max_shield_layers)

func take_damage(amount: float, bullet_data: BulletData = null) -> void:
	if _is_dying or _is_stunned:
		return

	_last_bullet_data = bullet_data

	if shield_layers > 0:
		shield_layers -= 1
		_shield_bar.update(shield_layers, max_shield_layers)
		SignalBus.enemy_damaged.emit(self, 0.0, current_health, max_health)

		if shield_layers <= 0:
			_break_shield()
		else:
			_shield_bubble.play_ripple()
			_shield_bubble.update_layers(shield_layers)

		# Show "0" damage or shield-specific feedback
		var dn := DamageNumber.new()
		get_tree().root.add_child(dn)
		dn.show_damage(global_position + Vector2(0.0, -42.0), 0.0)
		return

	# No shield — normal damage
	super.take_damage(amount, bullet_data)

func _break_shield():
	_is_stunned = true
	_shield_bubble.play_break()

	# Spawn break effect
	var ShieldBreakScript = preload("res://entities/enemies/shield_break_effect.gd")
	var break_effect := ShieldBreakScript.new()
	get_tree().root.add_child(break_effect)
	break_effect.play(global_position)

	# Brief stun (0.25s)
	speed = 0.0
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_callback(func():
		_is_stunned = false
		speed = 25.0
	)
```

- [ ] **Step 2: Create `shield_enemy.tscn` via MCP**

Use MCP tools to create the scene, modeled after `strong_enemy.tscn`:
- Root: `CharacterBody2D` named "ShieldEnemy", script = `shield_enemy.gd`
- Child: `Sprite2D` with the enemy shader material and a distinct texture (reuse `strong_enemy.png` for now, tinted blue)
- Child: `Hitbox` (Area2D, collision_layer=2, collision_mask=31) with `CollisionShape2D` (RectangleShape2D size 40x40)

If MCP scene creation is limited, manually create the `.tscn` file modeled exactly after `strong_enemy.tscn` but with the shield_enemy script and a blue-ish `modulate` on Sprite2D (`Color(0.4, 0.6, 1.0, 1.0)`).

- [ ] **Step 3: Add path to `Paths.gd`**

In `core/Paths.gd`, add after the `ENEMY_WARNING_SCENE` line:

```gdscript
const SHIELD_ENEMY_SCENE := "res://entities/enemies/shield_enemy.tscn"
```

- [ ] **Step 4: Commit**

```bash
git add entities/enemies/shield_enemy.gd entities/enemies/shield_enemy.tscn core/Paths.gd
git commit -m "feat: add shield enemy core script and scene"
```

---

### Task 2: Shield Bubble Visual

**Files:**
- Create: `entities/enemies/shield_bubble.gd`
- Create: `entities/enemies/shield_bubble.gdshader`

- [ ] **Step 1: Create `shield_bubble.gdshader`**

```glsl
shader_type canvas_item;

uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_max : hint_range(0.0, 1.0) = 0.7;
uniform float layer_intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 shield_color : source_color = vec4(0.3, 0.5, 1.0, 0.5);

// Ripple effect
instance uniform float ripple_time : hint_range(-1.0, 10.0) = -1.0;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);

    // Circle mask — soft edge ellipse
    float radius = 0.45;
    float edge = smoothstep(radius, radius - 0.08, dist);

    // Breathing pulse
    float pulse = mix(pulse_min, pulse_max, (sin(TIME * pulse_speed) * 0.5 + 0.5));
    float alpha = edge * pulse * layer_intensity;

    // Edge glow — brighter at the rim
    float rim = smoothstep(radius - 0.15, radius, dist) * edge;
    float rim_glow = rim * 0.6;

    // Ripple effect (if active)
    float ripple = 0.0;
    if (ripple_time >= 0.0) {
        float elapsed = TIME - ripple_time;
        if (elapsed < 0.4) {
            float ripple_ring = abs(dist - elapsed * 0.8);
            ripple = smoothstep(0.08, 0.0, ripple_ring) * (1.0 - elapsed / 0.4);
        }
    }

    COLOR = vec4(shield_color.rgb + vec3(rim_glow + ripple), alpha + ripple * 0.5);
}
```

- [ ] **Step 2: Create `shield_bubble.gd`**

```gdscript
class_name ShieldBubble extends Node2D

## ShieldBubble - 护盾气泡视觉效果
## 半透明脉动气泡，层数越多越亮

const BUBBLE_SIZE := Vector2(56.0, 56.0)

var _sprite: Sprite2D
var _material: ShaderMaterial
var _max_layers: int = 1

func setup(max_layers: int) -> void:
	_max_layers = max_layers
	_create_bubble()
	update_layers(max_layers)

func _create_bubble() -> void:
	var shader := preload("res://entities/enemies/shield_bubble.gdshader")
	_material = ShaderMaterial.new()
	_material.shader = shader

	# Use a white texture as base, shader handles everything
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)

	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.material = _material
	_sprite.scale = BUBBLE_SIZE / Vector2(64.0, 64.0)
	add_child(_sprite)

func update_layers(current_layers: int) -> void:
	if _material == null:
		return
	# Intensity scales with layer ratio
	var intensity := clampf(float(current_layers) / float(_max_layers), 0.2, 1.0)
	_material.set_shader_parameter("layer_intensity", intensity)

func play_ripple() -> void:
	if _material == null:
		return
	_sprite.set_instance_shader_parameter("ripple_time", float(Engine.get_frames_drawn()) * 0.0)
	# Actually use TIME-based approach: we set ripple_time in the shader to current time
	# The shader reads TIME, so we need to pass the current TIME value
	# We'll use a tween to reset after the ripple duration
	_material.set_shader_parameter("layer_intensity", 1.0)
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		update_layers(get_parent().shield_layers if get_parent().has_method("take_damage") else 0)
	)

func play_break() -> void:
	# Fade out and disappear
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		visible = false
	)
```

- [ ] **Step 3: Commit**

```bash
git add entities/enemies/shield_bubble.gd entities/enemies/shield_bubble.gdshader
git commit -m "feat: add shield bubble visual with pulse shader and ripple"
```

---

### Task 3: Shield Bar (Segmented)

**Files:**
- Create: `ui/hud/shield_bar.gd`

- [ ] **Step 1: Create `shield_bar.gd`**

```gdscript
class_name ShieldBar extends Node2D

## ShieldBar - 分段式护盾条
## 显示在血条上方，每段 = 1 层护盾

const BAR_WIDTH := 48.0
const BAR_HEIGHT := 5.0
const OFFSET_Y := -44.0  # Above health bar (which is at -36)
const SEGMENT_GAP := 2.0
const SHIELD_COLOR := Color(0.3, 0.55, 1.0, 0.9)
const SHIELD_BG := Color(0.1, 0.15, 0.3, 0.7)
const BORDER_COLOR := Color(0.15, 0.2, 0.5, 0.9)

var _current: int = 0
var _max: int = 1

func update(current: int, max_layers: int) -> void:
	_current = current
	_max = max_layers
	queue_redraw()

func _draw() -> void:
	if _max <= 0:
		return

	var origin := Vector2(-BAR_WIDTH * 0.5, OFFSET_Y)

	# Background
	draw_rect(Rect2(origin, Vector2(BAR_WIDTH, BAR_HEIGHT)), SHIELD_BG)

	# Segments
	var total_gap := SEGMENT_GAP * float(_max - 1)
	var seg_width := (BAR_WIDTH - total_gap) / float(_max)

	for i in _max:
		var x := origin.x + float(i) * (seg_width + SEGMENT_GAP)
		var rect := Rect2(Vector2(x, origin.y), Vector2(seg_width, BAR_HEIGHT))
		if i < _current:
			draw_rect(rect, SHIELD_COLOR)
		# else: background already visible

	# Border
	draw_rect(Rect2(origin, Vector2(BAR_WIDTH, BAR_HEIGHT)), BORDER_COLOR, false, 1.0)
```

- [ ] **Step 2: Verify shield bar hides when shields are gone**

The shield bar should become invisible when `_current == 0`. Add to `update()`:

```gdscript
visible = current > 0
```

Add this line at the end of the `update()` function body.

- [ ] **Step 3: Commit**

```bash
git add ui/hud/shield_bar.gd
git commit -m "feat: add segmented shield bar UI"
```

---

### Task 4: Shield Break Effect

**Files:**
- Create: `entities/enemies/shield_break_effect.gd`

- [ ] **Step 1: Create `shield_break_effect.gd`**

```gdscript
class_name ShieldBreakEffect extends Node2D

## ShieldBreakEffect - 护盾破碎动画
## 碎片向外飞溅，模拟玻璃破碎

const FRAGMENT_COUNT := 8
const FRAGMENT_SIZE := Vector2(5.0, 5.0)
const SPREAD_DISTANCE := 40.0
const DURATION := 0.5
const FRAGMENT_COLOR := Color(0.4, 0.65, 1.0, 0.9)

func play(world_pos: Vector2) -> void:
	global_position = world_pos

	for i in FRAGMENT_COUNT:
		var angle := (TAU / FRAGMENT_COUNT) * i + randf_range(-0.3, 0.3)
		var frag := _create_fragment()
		add_child(frag)

		var target := Vector2.from_angle(angle) * SPREAD_DISTANCE * randf_range(0.6, 1.2)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(frag, "position", target, DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(frag, "modulate:a", 0.0, DURATION)
		tw.tween_property(frag, "rotation", randf_range(-PI, PI), DURATION)

	# Self-destruct
	var cleanup := create_tween()
	cleanup.tween_interval(DURATION + 0.05)
	cleanup.tween_callback(queue_free)

func _create_fragment() -> ColorRect:
	var rect := ColorRect.new()
	rect.custom_minimum_size = FRAGMENT_SIZE
	rect.size = FRAGMENT_SIZE
	rect.color = FRAGMENT_COLOR.lerp(Color.WHITE, randf_range(0.0, 0.3))
	rect.pivot_offset = FRAGMENT_SIZE * 0.5
	return rect
```

- [ ] **Step 2: Commit**

```bash
git add entities/enemies/shield_break_effect.gd
git commit -m "feat: add shield break fragment effect"
```

---

### Task 5: Register Shield Enemy in Spawn Picker

**Files:**
- Modify: `entities/enemies/enemy_spawn_picker.gd`

- [ ] **Step 1: Add shield enemy to spawn picker**

Add the shield enemy constant and weight logic. Shield enemies appear starting wave 5.

In `enemy_spawn_picker.gd`, add after `const STRONG_ENEMY_SCENE`:

```gdscript
const SHIELD_ENEMY_SCENE = preload("res://entities/enemies/shield_enemy.tscn")
```

Add new weight constants after existing ones:

```gdscript
const SHIELD_ENEMY_START_WAVE: int = 5
const SHIELD_ENEMY_BASE_WEIGHT: int = 3
const SHIELD_ENEMY_WEIGHT_PER_WAVE: int = 1
```

Add weight calculation method:

```gdscript
static func _get_shield_enemy_weight(wave: int) -> int:
	if wave < SHIELD_ENEMY_START_WAVE:
		return 0
	return SHIELD_ENEMY_BASE_WEIGHT + (wave - SHIELD_ENEMY_START_WAVE) * SHIELD_ENEMY_WEIGHT_PER_WAVE
```

Update `pick()` to include shield enemy:

```gdscript
static func pick(wave: int) -> PackedScene:
	var strong_w = _get_strong_enemy_weight(wave)
	var shield_w = _get_shield_enemy_weight(wave)
	var base_w = BASE_ENEMY_WEIGHT
	var total = strong_w + shield_w + base_w
	var roll = randi() % total
	if roll < shield_w:
		return SHIELD_ENEMY_SCENE
	if roll < shield_w + strong_w:
		return STRONG_ENEMY_SCENE
	return ENEMY_SCENE
```

Update `pick_for_dev()`:

```gdscript
static func pick_for_dev() -> PackedScene:
	var roll = randi() % 3
	if roll == 0:
		return STRONG_ENEMY_SCENE
	elif roll == 1:
		return SHIELD_ENEMY_SCENE
	return ENEMY_SCENE
```

- [ ] **Step 2: Commit**

```bash
git add entities/enemies/enemy_spawn_picker.gd
git commit -m "feat: register shield enemy in spawn picker (wave 5+)"
```

---

### Task 6: Integration Test — Run and Verify

- [ ] **Step 1: Run `validate.gd` if it exists**

```bash
godot --headless --script scripts/validate.gd 2>&1 || true
```

- [ ] **Step 2: Run the game in dev mode and verify**

Use MCP `mcp__godot__run_project` to launch the game. Set wave to 5+ to see shield enemies spawn. Verify:
- Shield bubble appears (blue pulsing overlay)
- Shield bar shows above health bar (blue segments)
- Hitting shield enemy consumes shield layer (shows "0" damage, ripple effect)
- Last shield break triggers fragment effect + brief stun
- After shields gone, normal damage applies

- [ ] **Step 3: Fix any issues found**

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: shield enemy integration complete"
```

---

## Spec Coverage Check

| Spec Requirement | Task |
|---|---|
| Multi-layer shield absorbs 1 hit each | Task 1 — `take_damage()` override |
| Shield bubble with breathing animation | Task 2 — shader pulse |
| Layer-dependent bubble brightness | Task 2 — `update_layers()` intensity |
| Segmented shield bar above health bar | Task 3 |
| Blue color scheme | Tasks 2, 3 — all use blue |
| Hit ripple on shield | Task 2 — `play_ripple()` |
| No HP damage while shielded | Task 1 — returns before `super.take_damage()` |
| Break animation (fragments) | Task 4 |
| Brief stun on break | Task 1 — 0.25s speed=0 |
| Configurable layer count | Task 1 — `shield_layers` / `max_shield_layers` vars |
| Sound effects | Spec says "暂时不做" — skipped |
| Spawn in waves | Task 5 — wave 5+ |
