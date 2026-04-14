# CLAUDE.md

## General Principles

- Prefer simple, minimal solutions. Do not over-engineer.
- Avoid adding unrequested features.

## Development Workflow (MUST FOLLOW)

### Testing

All changes MUST pass the full GdUnit4 test suite. Run all tests after completing work:

```bash
# Run all gdUnit4 tests (in Godot Editor: GdUnit → Run Tests)
# Tests are in tests/gdunit/
```

- **New features**: Write GdUnit4 tests to protect the feature before considering it done.
- **Modifying existing features**: Write tests to protect existing behavior FIRST, then implement changes, then add tests for new behavior.
- **Bug fixes**: Add regression tests where appropriate.
- Prefer `GdUnitSceneRunner` for tests that need scene/node interaction.
- Test files go in `tests/gdunit/`, extend `GdUnitTestSuite`, function names start with `test_`.

### Documentation

All features must be documented in `docs/` and indexed in `docs/DOC_INDEX.md`.

- **New features**: Create or update the relevant doc in `docs/content/`, update `docs/DOC_INDEX.md`.
- **Bug fixes**: Update related docs if the fix changes documented behavior.
- **Missing docs**: If you discover undocumented functionality during development, document it.

### Debugging

When locating bugs, add `print()` logs to observe actual runtime behavior. Don't rely on static code analysis alone — runtime behavior often diverges from what the code appears to do. Check the full call chain, especially for Godot signals and collision callbacks.

## Tools

### Godot MCP

Prefer Godot MCP tools over manual file editing for scene and project operations:

- `mcp__godot__get_project_info` — inspect project structure
- `mcp__godot__create_scene` / `mcp__godot__add_node` / `mcp__godot__save_scene` — scene manipulation
- `mcp__godot__load_sprite` — attach sprites/textures
- `mcp__godot__run_project` / `mcp__godot__stop_project` — run/stop game
- `mcp__godot__get_debug_output` — read runtime logs
- `mcp__godot__get_uid` / `mcp__godot__update_project_uids` — manage UIDs

Fall back to direct file editing only when MCP tools cannot accomplish the task.

### Pixellab MCP

API Doc: @https://api.pixellab.ai/v2/llms.txt
MCP Doc: @https://api.pixellab.ai/mcp/docs

## Project Overview

Godot 4.4+ tower defense game prototype with drag-and-drop tower placement, 4-directional rotation, wave-based combat, coin economy, reward system, module/relic system, and responsive Web/mobile layout.

## Common Commands

```bash
# Run the game (main scene is start_menu.tscn)
godot --path . scenes/start_menu.tscn

# Web export
./build_web.sh
python3 -m http.server 8000 --directory web
```

## Architecture

GDScript project. Key patterns: autoloaded singletons, data-driven Resource types (TowerData, BulletData). Check if a manager is an autoload before referencing it globally.

### Autoload Singletons
- **`SignalBus`** (`autoload/SignalBus.gd`) — Central event bus. Prefer signals over direct cross-system calls.
- **`GameState`** (`autoload/GameState.gd`) — State machine (DEPLOYMENT/RUNNING/PAUSED/GAME_OVER). Tracks coins, waves, tower reserve.
- **`DragManager`** (`autoload/DragManager.gd`) — Drag-and-drop preview system.
- **`BulletPool`** (`autoload/BulletPool.gd`) — Object pool for bullets. Use `spawn()`/`release()`.
- **`EventManager`** (`autoload/EventManager.gd`) — Relic event dispatcher.

### Core Systems
- **`GameLoopManager`** (`core/GameLoopManager.gd`) — DEPLOYMENT↔RUNNING transitions, wave management.
- **`LayoutManager`** (`core/LayoutManager.gd`) — Responsive layout (720px max-width).
- **`EffectManager`** (`core/EffectManager.gd`) — Screen shake effects.
- **`DeadZoneManager`** (`core/dead_zone_manager.gd`) — Off-screen bullet cleanup.

### Grid System
- **`GridManager`** (`grid/grid_manager.gd`) — 5×5 grid, 80×80px cells.
- **`Cell`** (`grid/cell.gd`) — Tower placement, module installation, drag/drop.
- **`RemovalZone`** (`grid/removal_zone.gd`) — Tower deletion drop zone.

### Entities
- **`Tower`** (`entities/towers/tower.gd`) — TowerData + modules + firing. `entity_id` for identity tracking.
- **`Bullet`** (`entities/bullets/bullet.gd`) — CharacterBody2D, pooled via BulletPool.
- **`Enemy`** (`entities/enemies/enemy.gd`) — CharacterBody2D, health=3, speed=50.
- **`EnemyManager`** (`entities/enemies/enemy_manager.gd`) — Wave spawning, count = wave + 1.

### Module System
- **`Module`** (`entities/modules/module.gd`) — Base. Override `apply_effect()`, `on_install()`/`on_uninstall()`.
- Resources in `resources/module_data/`.

### Effect System
- **`BulletHitEffect`** → `BulletData.hit_effects` → `Tower.on_bullet_hit()`.
- See `docs/content/effects.md` and `docs/content/effect-matrix.md`.

### Collision Layers
| Layer | Purpose |
|-------|---------|
| 2 | Enemies |
| 3 | Bullets |
| 4 | Bullets mask (dead zones) |
| 5 | Grid border hitboxes |
| 8 | Dead zones |

### State Flow
```
StartMenu → main.tscn
DEPLOYMENT → [Start] → RUNNING → [all defeated]
  → breach? → GameOverPopup → DEPLOYMENT
  → no breach? → RewardPopup → DEPLOYMENT
  → [lives=0] → GameOverPopup
```

## Version

Stored in `project.godot` `application/config/version`. Read by `start_menu.gd`.

## Documentation

See `docs/DOC_INDEX.md` for full index.
