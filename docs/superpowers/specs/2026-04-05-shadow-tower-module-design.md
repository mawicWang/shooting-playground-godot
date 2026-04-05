# Shadow Tower Module Design

**Date**: 2026-04-05  
**Status**: Draft  
**Author**: Claude Code (Brainstorming Session)

## 1. Overview

A new module that causes a tower to spawn shadow towers after firing 5 bullets. Shadow towers are semi-transparent blue clones of the parent tower, placed in adjacent 3×3 cells (excluding the center cell), with the same modules and direction. They can be hit by bullets from shadow towers of the same origin, but not by bullets from normal towers or shadow towers of different origins.

## 2. Requirements

### 2.1 Core Behavior

- **Spawning trigger**: Every 5th bullet fired by a tower (or shadow tower) triggers a shadow tower spawn
- **Spawning accumulation**: Multiple shadow towers can accumulate (5 bullets → 1st shadow, 10 → 2nd, 15 → 3rd, etc.)
- **Placement**: Random empty cell within 3×3 grid centered on parent tower (excluding the center cell itself)
- **Skip if full**: If no empty cell in 3×3 range, spawn is skipped (no spillover to farther cells)
- **Inheritance**: Shadow tower inherits all modules from parent, including the ShadowTowerModule itself
- **Appearance**: Semi-transparent blue tint (modulate with `Color(0.4, 0.4, 1.0, 0.7)`)
- **Team isolation**: Shadow towers can only be hit by bullets from shadow towers of the same origin (same "ancestor tower")
- **Wave cleanup**: All shadow towers are removed at the end of the RUNNING phase (when `game_stopped` signal fires)

### 2.2 Shadow Team Definition

- **Origin tower**: The original physical tower that first installed the ShadowTowerModule
- **Shadow team ID**: The `entity_id` of the origin tower used as team identifier
- **Team membership**: All shadow towers spawned directly or indirectly (via chain) from the same origin tower share the same `shadow_team_id`
- **Bullet team**: Bullets fired by shadow towers carry the same `shadow_team_id`
- **Collision rules**:
  - Bullet with `shadow_team_id = X` can only hit shadow tower with `shadow_team_id = X`
  - Bullet with `shadow_team_id = -1` (normal bullet) cannot hit any shadow tower (passes through)
  - Normal towers cannot be hit by shadow tower bullets (their bullets have `shadow_team_id = -1`)

## 3. Architecture

### 3.1 Collision Layer Strategy (Recommended Approach A)

Add a new collision layer `SHADOW_TOWER_BODY = 128` (Layer 8, currently unused):

| Layer | Name | Usage |
|-------|------|-------|
| 8 | SHADOW_TOWER_BODY | Shadow tower hitboxes |
| 6 | TOWER_BODY | Normal tower hitboxes |
| 7 | AIR_TOWER_BODY | Flying tower hitboxes |

**Implementation**:
1. Shadow tower body uses `SHADOW_TOWER_BODY` layer (not `TOWER_BODY`)
2. Normal bullet mask = `TOWER_BODY | AIR_TOWER_BODY` (default, unchanged)
3. Shadow bullet mask = `SHADOW_TOWER_BODY` (added in shadow tower firing logic)
4. Bullet collision callback filters by `shadow_team_id` after layer passes

**Advantages**:
- Normal bullets skip shadow towers at collision layer level (no callback overhead)
- Clear separation in collision matrix
- Only one new layer needed regardless of number of origin towers

### 3.2 Component Overview

1. **`ShadowTowerModule`** (extends `Module`)
   - Category: `SPECIAL`
   - Slot color: Dark blue (`Color(0.2, 0.2, 0.8)`)
   - Contains a `SpawnShadowTowerEffect` in its `fire_effects` array
   - No stat modifiers

2. **`SpawnShadowTowerEffect`** (extends `FireEffect`)
   - Tracks bullet count per tower
   - Spawns shadow tower every 5 bullets
   - Manages team ID propagation
   - References origin tower's `entity_id`

3. **`shadow_tower.gd`** (extends `tower.gd` or reuses tower scene)
   - Overrides `_ready()` to set semi-transparent blue tint
   - Sets collision layer to `SHADOW_TOWER_BODY`
   - Stores `shadow_team_id` (origin tower's `entity_id`)
   - Listens to `SignalBus.game_stopped` for cleanup
   - Overrides `_do_fire()` to set bullet's `shadow_team_id` and mask

4. **`BulletData` extension**
   - Add `shadow_team_id: int = -1` field (-1 = normal bullet)

5. **`bullet.gd` modification**
   - In `_on_hitbox_area_entered()`, check `shadow_team_id` match for shadow collisions

### 3.3 Module Installation Flow

```
Tower.install_module(ShadowTowerModule)
  → Module.on_install(tower)
    → Add SpawnShadowTowerEffect to tower.fire_effects
    → SpawnShadowTowerEffect.origin_entity_id = tower.entity_id
```

### 3.4 Shadow Spawning Flow

```
Tower fires bullet
  → _do_fire() calls fire_effects
    → SpawnShadowTowerEffect.apply(tower, bullet_data)
      → Increment bullet_counter[tower.entity_id]
      → If bullet_counter % 5 == 0:
        → Get 3×3 adjacent cells (excluding center)
        → Filter to empty cells
        → If any empty:
          → Pick random cell
          → Instantiate shadow_tower.tscn
          → Copy all modules from parent (duplicate)
          → Set shadow_team_id = origin_entity_id
          → Set direction = parent.current_rotation_index
          → Place in cell
          → Start firing if game is RUNNING
```

### 3.5 Shadow Tower Bullet Flow

```
Shadow tower fires bullet
  → _do_fire() override
    → Set bullet_data.shadow_team_id = self.shadow_team_id
    → Set bullet_data.tower_body_mask = Layers.SHADOW_TOWER_BODY
    → Call super._do_fire()
```

### 3.6 Bullet Collision Logic

```
Bullet hits Area2D
  → If bullet.shadow_team_id == -1 (normal bullet):
    → Skip if target is shadow tower (layer SHADOW_TOWER_BODY)
    → Continue normal collision
  → Else (shadow bullet):
    → Skip if target is not shadow tower (layer != SHADOW_TOWER_BODY)
    → Skip if target.shadow_team_id != bullet.shadow_team_id
    → Apply hit
```

### 3.7 Cleanup Flow

```
SignalBus.game_stopped emitted
  → All shadow towers receive signal
  → Each shadow tower.queue_free()
```

## 4. Detailed Component Specifications

### 4.1 ShadowTowerModule Resource

```gdscript
# resources/module_data/shadow_tower_module.tres (to be created)
# Properties:
#   module_name: "幻影炮塔"
#   category: Module.Category.SPECIAL
#   description: "每发射5颗子弹，在周围3×3范围内生成一个影子炮塔。影子炮塔拥有本体的所有模块，回合结束后消失。影子炮塔之间可以互相击中。"
#   icon: (new icon texture)
#   slot_color: Color(0.2, 0.2, 0.8)
#   fire_effects: [SpawnShadowTowerEffect.new()]
```

### 4.2 SpawnShadowTowerEffect Class

```gdscript
class_name SpawnShadowTowerEffect extends FireEffect

# Static dictionary tracking bullet counts per origin tower
var _bullet_counters: Dictionary = {}  # entity_id -> count

# The origin tower's entity_id (set when effect is installed)
var origin_entity_id: int = -1

func apply(tower: Node, bd: BulletData) -> void:
    # Initialize counter if needed
    if not _bullet_counters.has(origin_entity_id):
        _bullet_counters[origin_entity_id] = 0
    
    # Increment counter
    _bullet_counters[origin_entity_id] += 1
    
    # Check if it's time to spawn
    if _bullet_counters[origin_entity_id] % 5 == 0:
        _try_spawn_shadow(tower)

func _try_spawn_shadow(parent_tower: Node) -> void:
    # Get parent cell position
    var parent_cell = _find_parent_cell(parent_tower)
    if not parent_cell:
        return
    
    # Find adjacent empty cells
    var empty_cells = _get_adjacent_empty_cells(parent_cell)
    if empty_cells.is_empty():
        return
    
    # Spawn shadow tower
    var target_cell = empty_cells.pick_random()
    _spawn_shadow_at_cell(parent_tower, target_cell)

# Helper methods to be implemented...
```

### 4.3 Shadow Tower Scene

Reuse `tower.tscn` with a different root script `shadow_tower.gd` that:

1. Sets `modulate = Color(0.4, 0.4, 1.0, 0.7)` in `_ready()`
2. Overrides `_setup_tower_body()` to use `SHADOW_TOWER_BODY` layer
3. Stores `shadow_team_id` property
4. Connects to `SignalBus.game_stopped` for cleanup
5. Overrides `_do_fire()` to set bullet team ID and mask

### 4.4 BulletData Extension

Add to `resources/BulletData.gd`:
```gdscript
var shadow_team_id: int = -1  # -1 = normal bullet, ≥0 = shadow team ID
```

### 4.5 bullet.gd Modification

Add team filtering in `_on_hitbox_area_entered()`:
```gdscript
# After checking transmission_chain...
if data and data.shadow_team_id >= 0:
    # Shadow bullet: only hit shadow towers with same team
    if not parent.has_method("get_shadow_team_id"):
        return  # Not a shadow tower
    if parent.get_shadow_team_id() != data.shadow_team_id:
        return  # Different team
elif parent.has_method("get_shadow_team_id"):
    # Normal bullet hitting shadow tower: skip
    return
```

## 5. Implementation Sequence

1. **Extend Layers.gd** with `SHADOW_TOWER_BODY = 128`
2. **Extend BulletData** with `shadow_team_id` field
3. **Create SpawnShadowTowerEffect** class
4. **Create ShadowTowerModule** resource
5. **Create shadow_tower.gd** script and scene variant
6. **Modify bullet.gd** collision logic
7. **Test** basic spawning and team collision
8. **Add visual polish** (blue tint, transparency)

## 6. Testing Requirements

- [ ] Module can be installed/uninstalled properly
- [ ] Bullet counter increments correctly
- [ ] Shadow tower spawns at 5th bullet
- [ ] Spawns in adjacent empty cells only
- [ ] Skips spawn when no adjacent empty cells
- [ ] Shadow tower inherits all parent modules
- [ ] Shadow tower has blue semi-transparent appearance
- [ ] Shadow bullet only hits shadow towers of same team
- [ ] Normal bullet passes through shadow towers
- [ ] Shadow towers are cleaned up at wave end
- [ ] Chain spawning works (shadow → shadow → shadow)
- [ ] Multiple origin towers have independent shadow teams

## 7. Open Questions

None - all clarified during brainstorming.

## 8. Rationale for Design Choices

1. **Collision Layer Approach (A)**: Chosen over pure code filtering (B) for performance and clarity. Normal bullets won't even trigger callbacks for shadow towers.

2. **Single SHADOW_TOWER_BODY layer**: Sufficient because team filtering happens in code. Don't need separate layers per team.

3. **Entity ID as team identifier**: Already unique per tower, readily available, no new ID generation needed.

4. **3×3 adjacency**: Matches intuitive "surrounding" area while keeping implementation simple with existing grid system.

5. **Skip when full**: Prevents unfair advantage of searching farther cells; encourages strategic placement.

6. **Wave cleanup**: Shadow towers are temporary tactical assets, not permanent placements.