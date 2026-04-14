# Technical Preferences

## Engine & Language

- **Engine**: Godot 4.4+
- **Language**: GDScript 2.0 (Godot 4.x syntax)
- **Rendering**: CanvasItem (2D)
- **Physics**: Godot built-in CharacterBody2D

## Input & Platform

- **Target Platforms**: Web, Mobile
- **Input Methods**: Touch (primary on mobile), Mouse/Keyboard (web)
- **Primary Input**: Touch
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: 720px max-width responsive layout managed by LayoutManager

## Naming Conventions

- **Classes**: PascalCase (e.g. `TowerData`, `BulletPool`)
- **Variables/Functions**: snake_case (e.g. `firing_rate`, `on_bullet_hit`)
- **Signals/Events**: past-tense snake_case (e.g. `coin_changed`, `wave_started`)
- **Files**: snake_case (e.g. `grid_manager.gd`, `dead_zone_manager.gd`)
- **Scenes**: snake_case (e.g. `main.tscn`, `start_menu.tscn`)
- **Constants**: UPPER_SNAKE_CASE

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: ~16ms
- **Bullets**: Pooled via BulletPool — always use `spawn()`/`release()`, never instantiate directly
- **Enemies**: Managed by EnemyManager

## Testing

- **Framework**: GdUnit4 (addons/gdUnit4/)
- **Test location**: `tests/gdunit/`
- **Base class**: `GdUnitTestSuite`
- **Function prefix**: `test_`
- **Scene interaction**: Prefer `GdUnitSceneRunner`
- **Coverage**: Write tests before considering a feature done

## Architecture

### Key Patterns
- Autoloaded singletons for cross-system communication
- Data-driven Resource types (`TowerData`, `BulletData`) — no hardcoded gameplay values
- Check if a manager is an autoload before referencing it globally

### Autoload Singletons
| Autoload | File | Responsibility |
|----------|------|----------------|
| `SignalBus` | `src/autoload/SignalBus.gd` | Central event bus — prefer signals over direct cross-system calls |
| `GameState` | `src/autoload/GameState.gd` | State machine (DEPLOYMENT/RUNNING/PAUSED/GAME_OVER), coins, waves, tower reserve |
| `DragManager` | `src/autoload/DragManager.gd` | Drag-and-drop preview system |
| `BulletPool` | `src/autoload/BulletPool.gd` | Object pool for bullets — use `spawn()`/`release()` |
| `EventManager` | `src/autoload/EventManager.gd` | Relic event dispatcher |

### Core Systems
| System | File | Responsibility |
|--------|------|----------------|
| `GameLoopManager` | `src/core/GameLoopManager.gd` | DEPLOYMENT↔RUNNING transitions, wave management |
| `LayoutManager` | `src/core/LayoutManager.gd` | Responsive layout (720px max-width) |
| `EffectManager` | `src/core/EffectManager.gd` | Screen shake effects |
| `DeadZoneManager` | `src/core/dead_zone_manager.gd` | Off-screen bullet cleanup |

### Grid System
| System | File | Responsibility |
|--------|------|----------------|
| `GridManager` | `src/grid/grid_manager.gd` | 5×5 grid, 80×80px cells |
| `Cell` | `src/grid/cell.gd` | Tower placement, module installation, drag/drop |
| `RemovalZone` | `src/grid/removal_zone.gd` | Tower deletion drop zone |

### Entities
| Entity | File | Notes |
|--------|------|-------|
| `Tower` | `src/entities/towers/tower.gd` | TowerData + modules + firing; `entity_id` for identity |
| `Bullet` | `src/entities/bullets/bullet.gd` | CharacterBody2D, pooled via BulletPool |
| `Enemy` | `src/entities/enemies/enemy.gd` | CharacterBody2D, health=3, speed=50 |
| `EnemyManager` | `src/entities/enemies/enemy_manager.gd` | Wave spawning, count = wave + 1 |

### Module System
- Base class: `src/entities/modules/module.gd`
- Override: `apply_effect()`, `on_install()`, `on_uninstall()`
- Resources in: `src/resources/module_data/`

### Effect System
- Flow: `BulletHitEffect` → `BulletData.hit_effects` → `Tower.on_bullet_hit()`
- See: `design/gdd/effects.md` and `design/gdd/effect-matrix.md`

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
DEPLOYMENT → [Start] → RUNNING → [all enemies defeated]
  → breach? → GameOverPopup → DEPLOYMENT
  → no breach? → RewardPopup → DEPLOYMENT
  → [lives=0] → GameOverPopup (final)
```

### Version
Stored in `project.godot` under `application/config/version`. Read by `start_menu.gd`.

## Forbidden Patterns
- Hardcoded gameplay values (use TowerData/BulletData resources)
- Direct cross-system calls without signals (use SignalBus)
- Instantiating bullets directly (use BulletPool.spawn())

## Allowed Libraries / Addons
- GdUnit4 — test framework (`addons/gdUnit4/`)
- Godot MCP — development tooling (scene/project operations)

## Engine Specialists

- **Primary**: `godot-specialist`
- **Language/Code**: `gdscript-specialist`
- **UI**: `ui-programmer`
- **Shader**: `godot-specialist`

### File Extension Routing

| File Type | Specialist |
|-----------|-----------|
| `.gd` (GDScript) | `gdscript-specialist` |
| `.tscn` (scenes) | `godot-specialist` |
| `.tres` / `.res` (resources) | `godot-specialist` |
| `.gdshader` | `godot-specialist` |
| UI screens | `ui-programmer` |
| Architecture review | `godot-specialist` |
