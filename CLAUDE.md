# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Godot 4.4+ tower defense game prototype ("shooting playground") with drag-and-drop tower placement, 4-directional tower rotation, wave-based enemy combat, module/relic system, and responsive Web/mobile layout.

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
- **`GameState`** (`autoload/GameState.gd`) — Tracks current state (`DEPLOYMENT`/`RUNNING`/`PAUSED`/`GAME_OVER`). Use `GameState.is_running()`, `is_deployment()`, `can_drag()` for state queries.
- **`DragManager`** (`autoload/DragManager.gd`) — Custom drag-and-drop preview system. Creates a floating TextureRect preview that follows the mouse. Caches last rotation during drag. Use `start_drag()`, `end_drag()`, `get_current_drag_rotation()`, `get_drag_source_node()`.
- **`BulletPool`** (`autoload/BulletPool.gd`) — Object pool for bullets. Reduces GC pressure. Use `BulletPool.spawn()` / `BulletPool.release()` instead of instancing bullets directly.
- **`EventManager`** (`autoload/EventManager.gd`) — Relic event dispatcher. Manages active relics and notifies them via `notify_bullet_fired()`, `notify_wave_start()`. Use `register_relic()` / `unregister_relic()`.

### Core Managers (instantiated by `main.gd`)
- **`GameLoopManager`** (`core/GameLoopManager.gd`) — Controls DEPLOYMENT↔RUNNING state transitions, starts/stops towers, creates dead zones, manages EnemyManager lifecycle.
- **`LayoutManager`** (`core/LayoutManager.gd`) — Responsive layout with 720px max-width constraint. Recalculates margins on window resize.
- **`EffectManager`** (`core/EffectManager.gd`) — Screen shake (8-frame, 5px offset, 0.05s each frame).
- **`DeadZoneManager`** (`core/dead_zone_manager.gd`) — 4 off-screen collision zones that destroy bullets leaving the play area.

### Grid System
- **`GridManager`** (`grid/grid_manager.gd`) — Generates a 5×5 grid of 80×80px cells. Border cells (row/col 0 or 4) have `Area2D` hitboxes on collision layer 5 to detect enemies reaching the grid.
- **`Cell`** (`grid/cell.gd`) — Handles drag/drop targeting, tower placement, module installation, and visual state feedback. Module slots displayed as 4 dots at cell bottom.
- **`RemovalZone`** (`grid/removal_zone.gd`) — Drop zone for deleting towers. Only accepts towers being moved (not new deployments).

### Entities
- **`Tower`** (`entities/towers/tower.gd`) — Has `TowerData`, `firing_rate_stat` (StatAttribute), and up to 4 `modules`. Fires bullets via timer; applies module effects to BulletData before spawning. Methods: `install_module()`, `uninstall_module()`, `start_firing()`, `stop_firing()`, `set_initial_direction()`.
- **`Bullet`** (`entities/bullets/bullet.gd`) — `CharacterBody2D` with `BulletData`. Managed by `BulletPool`; call `reset()` before reuse.
- **`Enemy`** (`entities/enemies/enemy.gd`) — `CharacterBody2D` with `max_health=3`, `SPEED=50`. Has HealthBar child and uses noise shader for visual jitter.
- **`EnemyManager`** (`entities/enemies/enemy_manager.gd`) — Spawns 3 enemies per wave from random edges. `prepare_enemies()` pre-generates positions; `spawn_enemies_from_data()` instantiates them.

### Module System
- **`Module`** (`entities/modules/module.gd`) — Base resource class. Override `apply_effect(bullet_data)` to modify bullets per shot, `on_install()` / `on_uninstall()` for stat modifier lifecycle.
- **`AcceleratorModule`** — Adds speed bonus (default +150) to bullet speed. Slot color: cyan.
- **`MultiplierModule`** — Multiplies bullet energy (default ×1.5). Slot color: orange.
- Module resources stored in `resources/module_data/`.

### Relic System
- **`Relic`** (`relics/relic.gd`) — Base class. Override `on_bullet_fired()` and `on_wave_start()`. Register with `EventManager`.
- **`DoubleShotRelic`** — Fires an extra bullet (offset 16px behind) on each tower fire. Uses `BulletPool` directly (does NOT re-notify EventManager to avoid recursion).
- Relic resources stored in `resources/relic_data/`.

### Resources (Data Classes)
- **`TowerData`** — `tower_name`, `sprite`, `icon`, `firing_rate`
- **`BulletData`** — `energy`, `speed`, `transmission_chain` (prevents self-targeting). Use `duplicate_with_mods()` for per-shot copies.
- **`StatAttribute`** — Base value + modifier array. `get_value()` applies additive + multiplicative mods. Use `remove_modifiers_from(source)` for cleanup.
- **`StatModifier`** — ADDITIVE or MULTIPLICATIVE modifier with source reference for cleanup.

### UI Components
- **`tower_icon.gd`** / **`module_icon.gd`** / **`relic_icon.gd`** (`ui/deployment/`) — Draggable store icons. Each has `set_drag_enabled()` with alpha feedback.
- **`HealthBar`** (`ui/hud/health_bar.gd`) — Drawn above enemy (48×6px). Color: green >50%, yellow >25%, red ≤25%.
- **`DamageNumber`** (`ui/hud/damage_number.gd`) — Floating damage popup; rises 45px over 0.85s then auto-deletes.
- **`GameOverPopup`** (`ui/popups/game_over_popup.gd`) — Victory ("夯爆了!") / Defeat ("太拉了!") popup. Signal: `popup_closed`.

### Drag-and-Drop Flow
1. User drags from `tower_icon.gd` (store) or `cell.gd` (existing tower) → calls `DragManager.start_drag()`
2. Drag preview follows mouse each frame
3. On hover over valid cell: rotation calculated from mouse-offset quadrant (abs(x) vs abs(y)) relative to cell center
4. On drop: `cell._drop_data()` retrieves rotation from `DragManager.get_current_drag_rotation()`, places/moves tower
5. Drag tower to `RemovalZone` to delete it

### Collision Layers
| Layer | Purpose |
|-------|---------|
| 2 | Enemies |
| 3 | Bullets |
| 4 | Bullets mask (used by dead zones) |
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
- Bullet fired: `tower._on_fire_timer_timeout()` → `BulletPool.spawn()` → `EventManager.notify_bullet_fired()` → relics react

## Version
版本号显示在 `main.tscn` 的 `VersionLabel` 节点上。更新版本时直接修改该节点的 `text` 属性。

## Resource Paths
All scene/script paths are centralized in `autoload/Paths.gd`. Use these constants instead of hardcoded strings.

## Documentation
- `doc/DEVELOPER.md` — Deep-dive architecture and algorithm details
- `doc/DESIGN_V1.0.md` — Planned v1.0 module/relic system design
- `doc/IMPLEMENTATION_PLAN.md` — Development roadmap
