# AGENTS.md

Instructions for agentic coding agents working in this repository.

## Project Overview

Godot 4.4+ tower defense game prototype ("shooting playground") using GDScript. Features drag-and-drop tower placement, wave-based combat, coin economy, module/relic system, and responsive Web/mobile layout.

## Build & Run Commands

```bash
# Run the game (main scene is start_menu.tscn)
godot --path . scenes/start_menu.tscn

# Web export
./build_web.sh

# Serve web build locally
python3 -m http.server 8000 --directory web

# Headless validation (parse all scripts + instantiate key scenes)
godot --headless --script tests/validate.gd
```

## Testing

Framework: **GdUnit4 v5.0.3** (Godot plugin).

```bash
# Run all tests (in Godot Editor: GdUnit → Run Tests)
# Note: GdUnit4 v5.0.3 may have CLI compatibility issues with Godot 4.4
# Prefer running via Godot Editor GdUnit panel

# Run single test file (if CLI works in your environment)
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/gdunit/StatAttributeTest.gd
```

**Test location:** `tests/gdunit/` — files named `*Test.gd`.

**Test conventions:**
- Extend `GdUnitTestSuite`
- Use `class_name` matching filename (e.g., `class_name StatAttributeTest`)
- Use `auto_free()` for objects created in tests
- Use `assert_that()` / `assert_*` methods
- Use `tests/mock_tower.gd` (`MockTower`) for tower mocking (no autoloads)

## Code Style

### General
- **GDScript** with static typing encouraged (use `:=` for type inference)
- **No trailing whitespace**, UTF-8 charset
- **4-space indentation** (Godot default)
- Comments may be in Chinese (项目使用中文注释) or English

### Naming Conventions
- **Files:** `snake_case.gd` (e.g., `game_loop_manager.gd`)
- **Classes:** `PascalCase` (e.g., `GameLoopManager`)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `TOWER_RESERVE_MAX`)
- **Signals:** `snake_case` (e.g., `coins_changed`)
- **Private methods/vars:** prefix with `_` (e.g., `_setup_managers()`)
- **Node references:** `@onready var node_name = $Path/Node`

### Imports & Resource Loading
- Use `preload()` at file top for compile-time resource loading:
  ```gdscript
  const TowerScene := preload("res://entities/towers/tower.tscn")
  ```
- **Never hardcode scene paths** — use constants from `core/Paths.gd`:
  ```gdscript
  # Good
  var scene = load(Paths.TOWER_SCENE)
  # Bad
  var scene = load("res://entities/towers/tower.tscn")
  ```

### Architecture Patterns
- **Autoloads** (global singletons): `SignalBus`, `GameState`, `DragManager`, `BulletPool`, `EventManager`, `Paths`, `Layers`
- **Cross-system communication:** Always use `SignalBus` signals, never direct references
- **Data-driven design:** Use `Resource` types (`TowerData`, `BulletData`, `Module`) for game data
- **Object pooling:** Use `BulletPool.spawn()` / `BulletPool.release()`, never instance bullets directly
- **Stat modifiers:** Use `StatAttribute` + `StatModifier` for composable stat changes

### Type Annotations
- Use static typing where possible:
  ```gdscript
  var health: int = 100
  var tower_data: TowerData = null
  func take_damage(amount: float) -> void:
  ```
- Use `:=` for type inference:
  ```gdscript
  var cells := grid_container.get_children()
  ```

### Error Handling
- Use `is_instance_valid()` before accessing potentially freed nodes
- Check `GameState.is_running()` in event handlers to prevent actions after game over
- Use `call_deferred()` for operations that must wait for next frame

### UI/Visual Considerations
- Consider z-index layering and CanvasLayer ordering
- Use CanvasLayer 100 for reward popups, 101 for game over popups
- Set `process_mode = ALWAYS` for popups that survive pause

## Collision Layers

| Layer | Purpose |
|-------|---------|
| 2 | Enemies |
| 3 | Bullets |
| 4 | Bullets mask (dead zones) |
| 5 | Grid border hitboxes |
| 8 | Dead zones (destroy bullets) |

## Key Files Reference

| File | Purpose |
|------|---------|
| `autoload/SignalBus.gd` | Central event bus — all cross-system signals |
| `autoload/GameState.gd` | Game state, coins, lives, wave tracking |
| `autoload/Paths.gd` | Centralized resource path constants |
| `core/GameLoopManager.gd` | State transitions, wave lifecycle |
| `entities/towers/tower.gd` | Tower logic, firing, modules |
| `entities/enemies/enemy_manager.gd` | Enemy spawning per wave |
| `grid/cell.gd` | Grid cell, drag/drop, tower placement |

## Documentation

- `CLAUDE.md` — Detailed architecture reference (same info, more depth)
- `doc/DEVELOPER.md` — Deep-dive architecture and algorithms
- `doc/DESIGN_V1.0.md` — v1.0 module/relic design
- `doc/IMPLEMENTATION_PLAN.md` — Development roadmap
