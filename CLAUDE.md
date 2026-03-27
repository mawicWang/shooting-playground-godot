# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Godot 4.4+ tower defense game prototype ("shooting playground") with drag-and-drop tower placement, 4-directional tower rotation, wave-based enemy combat, and responsive Web/mobile layout.

## Common Commands

```bash
# Run the game (open in Godot Editor, then press F5)
# Or via CLI:
godot --path . main.tscn

# Web export
./build_web.sh
# Then serve locally:
python3 -m http.server 8000 --directory web
```

## Architecture

### Autoload Singletons (globally accessible)
- **`SignalBus`** (`autoload/SignalBus.gd`) — Central event bus. All cross-system communication goes through here. Prefer emitting signals over direct calls between systems.
- **`GameState`** (`autoload/GameState.gd`) — Tracks current state (`DEPLOYMENT`/`RUNNING`/`PAUSED`/`GAME_OVER`), drag state, and hovered cell. Use `GameState.is_running()`, `is_deployment()`, `can_drag()` for state queries.
- **`DragManager`** (`autoload/DragManager.gd`) — Custom drag-and-drop preview system. Creates a floating TextureRect preview that follows the mouse. Caches last rotation during drag. Use `start_drag()`, `end_drag()`, `get_current_drag_rotation()`.

### Core Managers (instantiated by `main.gd`)
- **`GameLoopManager`** (`core/GameLoopManager.gd`) — Controls DEPLOYMENT↔BATTLE state transitions, starts/stops towers, creates dead zones, manages EnemyManager lifecycle.
- **`LayoutManager`** (`core/LayoutManager.gd`) — Responsive layout with 720px max-width constraint. Recalculates margins on window resize.
- **`EffectManager`** (`core/EffectManager.gd`) — Screen shake (8-frame, 5px offset, 0.05s each frame).
- **`DeadZoneManager`** (`core/dead_zone_manager.gd`) — 4 off-screen collision zones that destroy bullets leaving the play area.

### Grid System
- **`GridManager`** (`grid/grid_manager.gd`) — Generates a 5×5 grid of 80×80px cells. Border cells (row/col 0 or 4) have `Area2D` hitboxes on collision layer 5 to detect enemies reaching the grid.
- **`Cell`** (`grid/cell.gd`) — Handles drag/drop targeting, tower placement, and visual state feedback (beige → green/red during drag).

### Drag-and-Drop Flow
1. User drags from `tower_icon.gd` (store) or `cell.gd` (existing tower) → calls `DragManager.start_drag()`
2. Drag preview follows mouse each frame
3. On hover over valid cell: rotation calculated from mouse-offset quadrant (abs(x) vs abs(y)) relative to cell center
4. On drop: `cell._drop_data()` retrieves rotation from `DragManager.get_current_drag_rotation()`, places/moves tower

### Collision Layers
| Layer | Purpose |
|-------|---------|
| 2 | Enemies |
| 3 | Bullets |
| 5 | Grid border hitboxes (detect enemies) |
| 8 | Dead zones (destroy bullets) |

### State Flow
```
DEPLOYMENT → [Start button] → RUNNING → [all enemies defeated OR enemy breaches grid] → popup → DEPLOYMENT
```

### Key Signal Chains
- Enemy breach: `grid cell hitbox` → `SignalBus.enemy_reached_grid` → `main.gd` → screen shake + breach flag
- Wave complete: `EnemyManager.all_enemies_defeated` → `main.gd` → check breach flag → victory/defeat popup
- Popup closed: `game_over_popup.popup_closed` → `main.gd` → reset state, re-enable drag, prepare next wave warnings

## Version
版本号显示在 `main.tscn` 的 `VersionLabel` 节点上。更新版本时直接修改该节点的 `text` 属性。

## Resource Paths
All scene/script paths are centralized in `autoload/Paths.gd`. Use these constants instead of hardcoded strings.

## Documentation
- `doc/DEVELOPER.md` — Deep-dive architecture and algorithm details
- `doc/DESIGN_V1.0.md` — Planned v1.0 module/relic system design
- `doc/IMPLEMENTATION_PLAN.md` — Development roadmap
