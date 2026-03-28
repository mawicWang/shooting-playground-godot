# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Godot 4.4+ tower defense game prototype ("shooting playground") with drag-and-drop tower placement, 4-directional tower rotation, wave-based enemy combat, coin economy, wave reward system, module/relic system, and responsive Web/mobile layout.

## Common Commands

```bash
# Run the game (open in Godot Editor, then press F5)
# Main scene is start_menu.tscn (not main.tscn)
godot --path . scenes/start_menu.tscn

# Web export
./build_web.sh
# Then serve locally:
python3 -m http.server 8000 --directory web
```

## Architecture

### Autoload Singletons (globally accessible)
- **`SignalBus`** (`autoload/SignalBus.gd`) — Central event bus. All cross-system communication goes through here. Prefer emitting signals over direct calls between systems. Key signals: `coins_changed(new_total)`, `lives_changed(remaining)`, `enemy_reached_grid`, `game_stopped`.
- **`GameState`** (`autoload/GameState.gd`) — Tracks current state (`DEPLOYMENT`/`RUNNING`/`PAUSED`/`GAME_OVER`). Use `GameState.is_running()`, `is_deployment()`, `can_drag()` for state queries. Also tracks `coins`, `current_wave`, `tower_reserve_count` (max 5). Key methods: `lose_life()` (atomic life deduction → auto game-over), `reset_to_deployment()`, `add_coins(amount)`, `generate_entity_id()`.
- **`DragManager`** (`autoload/DragManager.gd`) — Custom drag-and-drop preview system. Creates a floating TextureRect preview that follows the mouse. Caches last rotation during drag. Use `start_drag()`, `end_drag()`, `get_current_drag_rotation()`, `get_drag_source_node()`.
- **`BulletPool`** (`autoload/BulletPool.gd`) — Object pool for bullets. Reduces GC pressure. Use `BulletPool.spawn()` / `BulletPool.release()` instead of instancing bullets directly.
- **`EventManager`** (`autoload/EventManager.gd`) — Relic event dispatcher. Manages active relics and notifies them via `notify_bullet_fired()`, `notify_wave_start()`. Use `register_relic()` / `unregister_relic()`.

### Core Managers (instantiated by `main.gd`)
- **`GameLoopManager`** (`core/GameLoopManager.gd`) — Controls DEPLOYMENT↔RUNNING state transitions, starts/stops towers, creates dead zones, manages EnemyManager lifecycle. Tracks `current_wave` (completed waves). `prepare_enemy_warnings()` shows warning indicators at spawn edges before wave starts.
- **`LayoutManager`** (`core/LayoutManager.gd`) — Responsive layout with 720px max-width constraint. Recalculates margins on window resize.
- **`EffectManager`** (`core/EffectManager.gd`) — Screen shake (8-frame, 5px offset, 0.05s each frame). Emits `shake_finished` when done. Prevents overlapping shakes.
- **`DeadZoneManager`** (`core/dead_zone_manager.gd`) — 4 off-screen collision zones that destroy bullets leaving the play area.

### Grid System
- **`GridManager`** (`grid/grid_manager.gd`) — Generates a 5×5 grid of 80×80px cells. Border cells (row/col 0 or 4) have `Area2D` hitboxes on collision layer 5 to detect enemies reaching the grid.
- **`Cell`** (`grid/cell.gd`) — Handles drag/drop targeting, tower placement, module installation, and visual state feedback. Module slots displayed as 4 dots at cell bottom.
- **`RemovalZone`** (`grid/removal_zone.gd`) — Drop zone for deleting towers. Only accepts towers being moved (`is_moving=true`, not new deployments). Calls `queue_free()` on tower and returns icon to reserve.

### Entities
- **`Tower`** (`entities/towers/tower.gd`) — Has `TowerData`, `firing_rate_stat` (StatAttribute), and up to 4 `modules`. Also has `entity_id` (unique int from `GameState.generate_entity_id()`) and `source_icon` (backreference to reserve/staging icon). Fires bullets via timer; applies module effects to BulletData before spawning. Supports multi-barrel via `TowerData.barrel_directions`. Methods: `install_module()`, `uninstall_module()`, `start_firing()`, `stop_firing()`, `set_initial_direction()`, `on_bullet_hit(bullet_data)`.
- **`Bullet`** (`entities/bullets/bullet.gd`) — `CharacterBody2D` with `BulletData`. Managed by `BulletPool`; call `reset()` before reuse.
- **`Enemy`** (`entities/enemies/enemy.gd`) — `CharacterBody2D` with `max_health=3`, `SPEED=50`. Has HealthBar child and uses noise shader for visual jitter.
- **`EnemyManager`** (`entities/enemies/enemy_manager.gd`) — Spawns enemies per wave; count = `current_wave + 1` (wave 1 → 1 enemy, wave 5 → 5 enemies). `prepare_enemies()` pre-generates positions into `pending_enemies`; `spawn_enemies_from_data()` instantiates them. Each defeated enemy adds 1 coin via `GameState.add_coins(1)`.
- **`EnemyWarning`** (`entities/enemies/enemy_warning.gd`) — Warning indicator shown at spawn edges before wave starts. Created by `GameLoopManager.prepare_enemy_warnings()`, cleared when wave begins.

### Module System
- **`Module`** (`entities/modules/module.gd`) — Base resource class. Override `apply_effect(bullet_data)` to modify bullets per shot, `on_install()` / `on_uninstall()` for stat modifier lifecycle.
- **`AcceleratorModule`** — Adds speed bonus (default +150) to bullet speed. Slot color: cyan.
- **`MultiplierModule`** — Multiplies bullet energy (default ×1.5). Slot color: orange.
- Module resources stored in `resources/module_data/`.

### Relic System
- **`Relic`** (`relics/relic.gd`) — Base class. Override `on_bullet_fired()` and `on_wave_start()`. Register with `EventManager`.
- **`DoubleShotRelic`** — Fires an extra bullet (offset 16px behind) on each tower fire. Uses `BulletPool` directly (does NOT re-notify EventManager to avoid recursion).
- Relic resources stored in `resources/relic_data/`.

### BulletHitEffect System
- **`BulletHitEffect`** (`entities/bullets/bullet_hit_effect.gd`) — Base class. Override `apply(tower, bullet_data)` for per-hit logic.
- **`AmmoReplenishEffect`** (`entities/bullets/ammo_replenish_effect.gd`) — Restores 1 ammo to a tower on bullet hit (default effect).
- `BulletData.hit_effects: Array` stores effects applied when bullet hits a tower.
- `Tower.on_bullet_hit(bullet_data)` is called by bullet on collision to run all hit effects.

### Resources (Data Classes)
- **`TowerData`** — `tower_name`, `sprite`, `icon`, `firing_rate`, `initial_ammo` (-1 = infinite), `barrel_directions` (PackedVector2Array of local fire directions, default `[Vector2(0,-1)]`). Multi-barrel towers define multiple directions.
- **`BulletData`** — `energy`, `speed`, `transmission_chain` (prevents self-targeting), `hit_effects: Array`. Use `duplicate_with_mods()` for per-shot copies.
- **`StatAttribute`** — Base value + modifier array. `get_value()` applies additive + multiplicative mods. Use `remove_modifiers_from(source)` for cleanup.
- **`StatModifier`** — ADDITIVE or MULTIPLICATIVE modifier with source reference for cleanup.

### UI Components
- **`tower_icon.gd`** (`ui/deployment/`) — Draggable reserve/staging icon for a specific tower instance. Has `entity_id` linking to its tower, `is_staging` flag, `set_drag_enabled()`. Call `mark_deployed()` / `mark_returned()` to track placement state.
- **`module_icon.gd`** (`ui/deployment/`) — Draggable single-module icon.
- **`module_stack_icon.gd`** (`ui/deployment/`) — Draggable icon for multiple copies of the same module type. Shows count ("x2", "x3"). `mark_deployed()` decrements count (auto-hides at 0); `mark_returned()` increments.
- **`relic_icon.gd`** (`ui/deployment/`) — Clickable toggle for relics. Click to activate (bright red) / deactivate (dark red). Calls `EventManager.register_relic()` / `unregister_relic()`.
- **`tower_reserve_bar.gd`** (`ui/deployment/`) — Visual bar showing tower reserve slots (max 5).
- **`HealthBar`** (`ui/hud/health_bar.gd`) — Drawn above enemy (48×6px). Color: green >50%, yellow >25%, red ≤25%.
- **`DamageNumber`** (`ui/hud/damage_number.gd`) — Floating damage popup; rises 45px over 0.85s then auto-deletes.
- **`GameOverPopup`** (`ui/popups/game_over_popup.gd`) — Victory ("夯爆了!") / Defeat ("太拉了!") popup. On CanvasLayer 101. Signal: `popup_closed`.
- **`RewardPopup`** (`ui/popups/reward_popup.gd`) — Post-wave reward selection. On CanvasLayer 100. Pauses game tree. Shows 3 random cards from REWARD_POOL (5 towers + 2 modules). Emits `reward_chosen(item)` on selection.

### Wave & Reward System
After each wave (all enemies defeated, no breach):
1. `EnemyManager.all_enemies_defeated` → `main.gd`
2. `main.gd` checks breach flag: if breach → defeat popup; else → `RewardPopup.show_popup()`
3. Player selects 1 of 3 reward cards (tower or module)
4. `reward_chosen` signal → `main.gd` adds item to hand (tower creates `tower_icon`, module updates `module_stack_icon` count)
5. Popup hides → state returns to DEPLOYMENT

### Economy & Tower Reserve System
- **Coins**: Each defeated enemy = +1 coin via `GameState.add_coins(1)`. Displayed as "金币: X" in HUD. Signal: `SignalBus.coins_changed(new_total)`.
- **Tower Reserve**: `GameState.tower_reserve_count` (max `TOWER_RESERVE_MAX = 5`). Visual: `tower_reserve_bar.gd`. Each reserve tower has a `tower_icon.gd` in the hand panel.
- **Staging Area**: Overflow slot (bottom-left panel, max 1 tower). Staging tower blocks the Start button.
- Game starts with 1 tower pre-placed at center cell (index 12) and 1 AcceleratorModule in hand.

### Tower Identity Tracking
Each tower has an `entity_id` (int) generated by `GameState.generate_entity_id()` and a `source_icon` backreference. This allows:
- `tower_icon.mark_deployed()` / `mark_returned()` to stay in sync when tower moves between cells
- `RemovalZone` to notify the correct icon when a tower is deleted
- Staging → Reserve migration to find the right icon

### Drag-and-Drop Flow
1. User drags from `tower_icon.gd` (reserve/staging) or `cell.gd` (existing tower) → calls `DragManager.start_drag()`
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
StartMenu → main.tscn loaded
DEPLOYMENT → [Start button] → RUNNING → [all enemies defeated]
  → breach? → GameOverPopup (defeat) → DEPLOYMENT
  → no breach? → RewardPopup → [reward chosen] → DEPLOYMENT
  → [lives = 0] → GameOverPopup (defeat, auto-triggered by lose_life())
```

### Key Signal Chains
- Enemy breach: `grid cell hitbox` → `SignalBus.enemy_reached_grid` → `main.gd` → `EffectManager.trigger_screen_shake()` + set breach flag
- Wave complete: `EnemyManager.all_enemies_defeated` → `main.gd` → check breach flag → `RewardPopup` or defeat `GameOverPopup`
- Reward chosen: `RewardPopup.reward_chosen` → `main.gd` → add item to hand → return to DEPLOYMENT
- Game over popup closed: `game_over_popup.popup_closed` → `main.gd` → `GameState.reset_to_deployment()`, re-enable drag, prepare next wave warnings
- Bullet fired: `tower._on_fire_timer_timeout()` → `BulletPool.spawn()` → `EventManager.notify_bullet_fired()` → relics react
- Life lost: `GameState.lose_life()` → emits `lives_changed` → if 0 lives: emits `game_stopped` + transitions to GAME_OVER

### Canvas Layers
- `RewardPopup`: CanvasLayer 100, `process_mode = ALWAYS` (survives pause)
- `GameOverPopup`: CanvasLayer 101, `process_mode = ALWAYS`
- Reward popup pauses game tree (`get_tree().paused = true`); game over popup does not (game already stopped)

## Version
版本号显示在 `main.tscn` 的 `VersionLabel` 节点上。更新版本时直接修改该节点的 `text` 属性。

## Resource Paths
All scene/script paths are centralized in `autoload/Paths.gd`. Use these constants instead of hardcoded strings.

## Documentation
- `doc/DEVELOPER.md` — Deep-dive architecture and algorithm details
- `doc/DESIGN_V1.0.md` — Planned v1.0 module/relic system design
- `doc/IMPLEMENTATION_PLAN.md` — Development roadmap
