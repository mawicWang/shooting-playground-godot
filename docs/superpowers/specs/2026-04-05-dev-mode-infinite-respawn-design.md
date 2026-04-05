# Dev Mode: Infinite Respawn & Stop-Anytime

**Date:** 2026-04-05  
**Scope:** Modify existing `GameMode.DEV` behavior only. No changes to normal/chaos modes.

## Goal

Make dev mode a pure sandbox:
- Player can stop the game at any time
- Enemies spawn from one fixed position (randomised once per session start)
- Each enemy immediately respawns at the same position after death
- No wave progression, no reward popup

## Changes

### 1. Stop button — `main.gd` `_update_button_style()`

Currently `_debug_stop_button` exists but is always `visible = false`.

Change: when `GameState.is_dev_mode()` and game is running, show `_debug_stop_button` and hide `start_stop_button`. When not running, hide stop button and show start button as normal.

No new nodes needed.

### 2. Fixed single spawn — `GameLoopManager.prepare_enemy_warnings()`

In dev mode, always set `enemy_count = 1` and fully-random direction (ignores `_accumulated_enemy_data`). The single `pending_enemy_data[0]` entry is stored as-is in `_pending_enemy_data`.

`GameLoopManager` exposes this via existing `get_pending_enemy_data()`.

### 3. Infinite respawn — `EnemyManager`

Add field `dev_spawn_info: Dictionary`. Populated in `spawn_enemies_from_data()` when `GameState.is_dev_mode()`: store the first (only) enemy info dict.

In `_on_enemy_destroyed()`:
- **Dev mode:** do NOT erase from `active_enemies` or emit `all_enemies_defeated`. Instead, check `GameState.is_running()` and immediately instantiate a new enemy from `dev_spawn_info`, connect its signals, add to tree, and put it in `active_enemies`. Coins are still awarded.
- **Normal mode:** unchanged.

### 4. No wave progression

`all_enemies_defeated` is never emitted in dev mode (see §3), so `GameLoopManager._on_all_enemies_defeated` and `main.gd._on_all_enemies_defeated` are never called. No wave counter increment, no reward popup.

## Data Flow (dev mode)

```
prepare_enemy_warnings()  →  1 random spawn position stored
start_game()              →  enemy spawned, _debug_stop_button shown
enemy destroyed           →  +1 coin, new enemy spawned at same position
_debug_stop_button press  →  stop_game() + prepare_enemy_warnings()
```

## Out of Scope

- Configurable spawn position UI
- Multiple simultaneous dev enemies
- Wave counter display changes
