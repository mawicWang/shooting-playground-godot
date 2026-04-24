# Character Selection — Design Spec

**Date:** 2026-04-16
**Status:** Approved (revised post-review)
**Prior review:** 2026-04-17 — MAJOR REVISION NEEDED (11 blocking items, 6/8 GDD sections missing) — all items addressed in this revision.

---

## 1. Overview

A character selection screen inserted between the Start Menu and the game. Before each run, the player picks one of three characters. Each character carries passive traits that shift playstyle. Only one character (Vera) is playable at launch; two slots (Mox, Wren) ship as visible but locked "Coming Soon" placeholders so the selection flow and data pipeline are in place when those characters become available.

---

## 2. Player Fantasy

Vera is the **precision tactician**. The intended feeling: every shot counts, every placement is a decision, and the satisfaction comes from landing devastating hits instead of spraying bullets. The player is not overwhelming enemies with volume — they are picking them apart one at a time. When it works, a single volley clears a wave; when it fails, a gap in coverage costs lives.

The future characters (Mox — economy, Wren — endurance) exist so the character identity layer visibly means something. They are shown locked on the selection screen so the player can see the roster is a real system, not a single-character dress-up.

---

## 3. Detailed Rules

### 3.1 Screen Flow

```
Start Menu
  ├─ Mode selector (混乱/普通) stays on Start Menu
  └─ [Start pressed]
     → Character Select Screen (new)
        ├─ [Back] → Start Menu (no selection saved)
        └─ [Confirm] → main.tscn (GameState.character set)
```

- Mode is chosen before character.
- `start_menu.gd._on_start_pressed` navigates to `character_select.tscn` instead of `main.tscn`.
- The selected character is written to `GameState.character` only when the player presses Confirm.
- Pressing Back returns to the Start Menu without changing `GameState.character`.
- Character selection persists for the full run (across waves, pauses, game-over popups). It resets to `null` when the player re-enters the Start Menu (see 3.6).

### 3.2 Character Roster

#### Vera — The Precise (playable)

| Field | Value |
|-------|-------|
| `id` | `&"vera"` |
| `display_name` | "Vera" |
| `tagline` | "One well-placed shot is enough." |
| `description` | "Vera's towers hit with devastating force, but patience is required between shots. A single well-timed volley can wipe a wave — a gap in coverage costs dearly." |
| `is_available` | `true` |
| `damage_multiplier` | `2.0` (+100% bullet damage) |
| `fire_rate_multiplier` | `0.5` (−50% fire rate) |
| `bonus_coins_per_kill` | `0` |
| `starting_lives_offset` | `0` |
| `portrait` | `res://assets/characters/vera_portrait.png` *(placeholder acceptable at ship)* |

**Design intent:** At baseline enemy health (3), Vera one-shots every standard enemy. Baseline characters need two shots. Net DPS is 1.0x baseline (2.0 × 0.5 = 1.0), but the feel is different: lethal-per-shot with a slower cadence.

#### Mox (Coming Soon — placeholder)

| Field | Value |
|-------|-------|
| `id` | `&"mox"` |
| `display_name` | "Mox" |
| `tagline` | "Every kill is an investment." |
| `is_available` | `false` |
| `damage_multiplier` | `1.0` |
| `fire_rate_multiplier` | `1.0` |
| `bonus_coins_per_kill` | `0` |
| `starting_lives_offset` | `0` |
| `portrait` | gray silhouette placeholder |

**Future concept:** economy specialist — bonus coins per kill.

#### Wren (Coming Soon — placeholder)

| Field | Value |
|-------|-------|
| `id` | `&"wren"` |
| `display_name` | "Wren" |
| `tagline` | "She's seen worse waves." |
| `is_available` | `false` |
| Everything else | neutral (as Mox) |

**Future concept:** endurance specialist — starting-lives bonus.

### 3.3 Passive Application Rules

All four character passives apply through the existing `StatAttribute` / `StatModifier` system or direct `GameState` fields. They are injected into each tower on placement, not baked into `TowerData`.

| Passive | Application point | Mechanism |
|---------|-------------------|-----------|
| `damage_multiplier` | `Tower._apply_data()` | Append a `StatModifier` with `multiplicative` type on `BULLET_ATTACK` stat |
| `fire_rate_multiplier` | `Tower._apply_data()` | Append a `StatModifier` with `multiplicative` type on `CD` stat (value = `1.0 / fire_rate_multiplier`, because CD is the inverse of rate) |
| `bonus_coins_per_kill` | Enemy death handler | Added to the normal coin reward via `GameState.add_coins()` |
| `starting_lives_offset` | `GameState.reset_lives()` | `player_lives = MAX_LIVES + offset` (clamped to `[0, MAX_LIVES + offset]`) |

**Stacking order:** the character StatModifier is pushed onto the `StatAttribute` stack **after** module modifiers. Existing module modifiers are evaluated first, then the character multiplier scales the result. This means the character is a global post-multiplier on whatever the tower's current stats are.

### 3.4 Shadow Tower Inheritance

Per `design/gdd/shadow-tower.md`, a shadow tower is spawned by `SpawnShadowTowerEffect` and inherits the parent's `TowerData` and modules. **Shadow towers also inherit the current character's passive modifiers.** Implementation note: `shadow_tower.gd` fully overrides `_do_fire()` and does not call `super()`. The shadow must therefore either (a) apply the same `StatModifier` stack on spawn, including the character modifier, or (b) read `GameState.get_character()` directly when computing damage and cooldown. Option (a) is preferred because it matches how the parent tower works.

### 3.5 Null-Safety: `GameState.get_character()` Accessor

To avoid spreading null-checks across every call site, `GameState` exposes an accessor:

```gdscript
var character: CharacterData = null
const _NEUTRAL_CHARACTER: CharacterData = preload("res://src/resources/characters/neutral.tres")

func get_character() -> CharacterData:
    return character if character != null else _NEUTRAL_CHARACTER
```

`neutral.tres` is a ship-with-code resource where all multipliers are `1.0` and offsets are `0`. All code that reads character data calls `GameState.get_character()` (not `GameState.character`). This is a hard rule: direct reads are forbidden.

### 3.6 Reset Behaviour

- `GameState.character = null` is set in `start_menu.gd._ready()`. Returning to the Start Menu after a run always clears the selection.
- **DEV mode:** if `GameState.is_dev_mode()` is true, the character select screen is skipped. `GameState.character = null` (accessor returns neutral). This matches how DEV mode bypasses other systems (`is_dev_mode()` guards).
- **Pause / game-over popup:** `GameState.character` is **not** reset during these states. The selection persists until the player returns to Start Menu.
- `GameState.reset_lives()` uses `get_character()`, so it is null-safe.

### 3.7 UI Rules

**Scene:** `src/ui/character_select/character_select.tscn`
**Script:** `src/ui/character_select/character_select.gd`

**Scene tree:**
```
CharacterSelect (Control)
├── BackButton (TextureButton)           — top-left, 48×48 min tap target
├── Title (Label)                         — "Choose Your Character"
├── CardRow (HBoxContainer)               — fills screen width, 8px separation
│   └── CharacterCard × 3                 — instantiated from CharacterCard.tscn
├── DetailPanel (PanelContainer)          — below cards
│   ├── DetailName (Label)
│   ├── DetailTagline (Label)
│   └── DetailDescription (Label)
└── ConfirmButton                         — bottom, min 48×48
```

**CharacterCard (reusable scene `src/ui/character_select/character_card.tscn`):**
```
CharacterCard (PanelContainer)
├── Avatar (TextureRect)                  — portrait or gray silhouette
├── NameLabel (Label)
├── TaglineLabel (Label)
├── PassiveList (VBoxContainer)           — visible only when is_available
└── ComingSoonBadge (Label)               — visible only when !is_available
```

**CharacterCard data passing:**
```gdscript
# Correct:
var card: CharacterCard = CHARACTER_CARD_SCENE.instantiate()
card.data = character_data   # set BEFORE add_child so _ready() sees it
card_row.add_child(card)
```
CharacterCard exports `@export var data: CharacterData`. Method-based setup after `add_child()` is forbidden.

**Card behaviour:**
- **Available card:** clickable, emits `card_selected(data)` signal. On selection: visual highlight (see below), populates `DetailPanel`.
- **Locked card:** not clickable via signal (clicking still triggers feedback — see below). Passive list hidden. "Coming Soon" badge visible. Portrait desaturated.
- **Selection highlight (colorblind-safe):** a 3px colored border **plus** a checkmark icon in the top-right corner of the selected card. Color alone is not sufficient.
- **Locked card tap feedback:** on tap, the card plays a 200ms horizontal shake animation and shows a 1.5-second tooltip above the card reading "Coming Soon". No tooltip on second tap within 2s (debounce).
- **Default state:** Vera is pre-selected when the screen opens. `DetailPanel` is pre-populated with Vera's data on `_ready()`, not on first click.

**Layout constraints:**
- Each `CharacterCard` has `custom_minimum_size = Vector2(140, 200)`.
- `ConfirmButton.custom_minimum_size = Vector2(0, 48)` (touch-target minimum).
- All interactive labels use font size ≥ 14px.
- Text contrast ratio ≥ 4.5:1 (WCAG AA) on locked-card labels, not just active cards.

**Navigation:**
- `BackButton` → `get_tree().change_scene_to_file("res://scenes/start_menu.tscn")`. `GameState.character` is **not** set.
- `ConfirmButton` → `GameState.character = selected_card.data`, then `get_tree().change_scene_to_file("res://src/main.tscn")`.
- `ConfirmButton` is always enabled (Vera is always pre-selected). The disabled-state code path is not implemented until a second playable character exists.

---

## 4. Formulas

### 4.1 Bullet damage (per shot)

```
final_damage = base_damage × Π(module_modifiers) × character.damage_multiplier
```

Where `base_damage` comes from `TowerData.bullet_data.damage`, module modifiers are the existing `StatModifier` stack on `BULLET_ATTACK`, and `character.damage_multiplier` is applied as the last multiplier in the stack.

### 4.2 Tower cooldown (time between shots)

```
base_cd = 1.0 / TowerData.firing_rate      # firing_rate is Hz
final_cd = base_cd × Π(module_cd_modifiers) × (1.0 / character.fire_rate_multiplier)
final_cd = max(final_cd, 0.01)             # existing clamp in tower.gd
```

The character modifier is the **inverse** of `fire_rate_multiplier` because it applies to CD (time), not rate. A `fire_rate_multiplier` of `0.5` multiplies CD by `2.0`.

### 4.3 Net DPS

```
net_DPS_multiplier = damage_multiplier × fire_rate_multiplier
```

For Vera: `2.0 × 0.5 = 1.0`. DPS is identical to baseline; the feel differs because shots-to-kill on 3-HP enemies drops from 2 to 1.

### 4.4 Bonus coins on kill

```
total_coins = base_reward + character.bonus_coins_per_kill
```
Applied on enemy death, after the normal reward is granted.

### 4.5 Starting lives

```
starting_lives = clamp(MAX_LIVES + character.starting_lives_offset, 0, MAX_LIVES + offset)
```

At `reset_lives()`. `MAX_LIVES = 3`.

### 4.6 Worked example: Vera with a `rate_boost` module

```
base_cd      = 1.0 / 1.0 = 1.0s   (TowerData.firing_rate = 1.0 Hz)
with rate_boost (-0.3 additive to CD in existing module):
  module_cd = 1.0 - 0.3 = 0.7s    (per existing module behaviour)
with Vera (fire_rate_multiplier = 0.5):
  final_cd = 0.7 × (1.0 / 0.5) = 0.7 × 2.0 = 1.4s
```

Vera with `rate_boost` fires every 1.4s vs baseline with `rate_boost` at 0.7s. The character identity is preserved — even with the module, Vera is slower than the same build on a neutral character.

---

## 5. Edge Cases

| Case | Expected behaviour |
|------|-------------------|
| Player enters game via DEV mode | Character select screen is skipped. `get_character()` returns neutral. Game plays as if no character was chosen. |
| `GameState.character` is null at runtime (e.g., test harness) | `get_character()` returns `_NEUTRAL_CHARACTER`. All multipliers evaluate to 1.0, offsets to 0. No crash. |
| Player presses Back without selecting | Returns to Start Menu. `GameState.character` is unchanged from its Start Menu state (null). |
| Player reaches Confirm with Vera pre-selected | Normal path. `GameState.character = vera.tres`, scene switches. |
| Player taps a locked card (Mox/Wren) | Card shakes, "Coming Soon" tooltip shows for 1.5s, selection does not change. |
| `damage_multiplier = 0` in a custom `.tres` | `@export_range(0.1, 5.0, 0.05)` prevents this in the editor. At runtime, if the guard is bypassed, towers deal zero damage (known failure mode, caller's responsibility). |
| `fire_rate_multiplier = 0` in a custom `.tres` | `@export_range(0.1, 3.0, 0.05)` prevents this. At runtime, `max(final_cd, 0.01)` in `tower.gd` still prevents divide-by-zero. |
| `starting_lives_offset = -3` | `@export_range(-2, 5, 1)` prevents going below `MAX_LIVES - 2 = 1` in the editor. |
| Shadow tower spawned by Vera's tower | Shadow inherits parent's `TowerData` and modules. Additionally, shadow applies the current `get_character()` modifiers (damage + CD) on `_do_fire()`. Character identity is consistent across both towers. |
| Mid-run character swap | Not supported. `GameState.character` is set once on Confirm and never changes during a run. If future features add this, towers already on the grid must call `_apply_data()` again to refresh their StatModifier stack. |
| Save/load (future) | `CharacterData.id` (StringName) is the save key. `ResourceLoader.load()` resolves it back to the resource on load. Resource paths are not saved. |

---

## 6. Dependencies

| System | File | Relationship |
|--------|------|--------------|
| `GameState` | `src/autoload/GameState.gd` | New `character` field, `get_character()` accessor, `reset_lives()` modified |
| `Tower` | `src/entities/towers/tower.gd` | `_apply_data()` pushes character StatModifiers onto `BULLET_ATTACK` and `CD` stacks |
| `ShadowTower` | `src/entities/towers/shadow_tower.gd` | `_do_fire()` applies character modifiers (see 3.4). Covered by `design/gdd/shadow-tower.md` |
| `StatAttribute` / `StatModifier` | `src/resources/StatAttribute.gd`, `src/resources/StatModifier.gd` | Existing system used for character passives |
| `Module` (all) | `src/entities/modules/*.gd` | Module modifiers stack with character modifiers; order: modules first, character last (see 3.3) |
| `EnemyManager` / `Enemy` | `src/entities/enemies/*.gd` | Enemy death handler adds `bonus_coins_per_kill` |
| `StartMenu` | `src/ui/start_menu/start_menu.gd` | `_on_start_pressed` navigates to character select; `_ready()` resets `GameState.character = null` |
| `SignalBus` | `src/autoload/SignalBus.gd` | No new signals required. Existing `coins_changed` / `lives_changed` cover the passive effects |

**Reverse dependencies:** none of the above systems need changes *because of* character selection other than the hooks listed. `design/gdd/shadow-tower.md` should be updated to note that shadow towers inherit character passives (pending a separate edit).

---

## 7. Tuning Knobs

| Knob | Location | Safe range | Effect |
|------|----------|-----------|--------|
| `damage_multiplier` | `CharacterData.tres` | `[0.1, 5.0]` via `@export_range` | Per-bullet damage scale. 1.0 = baseline. |
| `fire_rate_multiplier` | `CharacterData.tres` | `[0.1, 3.0]` via `@export_range` | Per-tower fire rate scale. 1.0 = baseline. Inverted when applied to CD. |
| `bonus_coins_per_kill` | `CharacterData.tres` | `[0, 10]` via `@export_range` | Extra coins per enemy killed. |
| `starting_lives_offset` | `CharacterData.tres` | `[-2, 5]` via `@export_range` | Offset from `GameState.MAX_LIVES` (3). |
| Locked-card shake duration | `character_card.gd` constant | 150–400ms | Visual feedback on locked tap. |
| Locked-card tooltip hold | `character_card.gd` constant | 1.0–3.0s | How long "Coming Soon" tooltip stays on. |

---

## 8. Acceptance Criteria

ACs are tagged `[Logic]` (BLOCKING, automated test required) or `[Visual]` (ADVISORY, screenshot evidence).

### Navigation & Screen Flow

1. **[Logic]** Pressing the Start Menu's Start button sets `get_tree().current_scene.scene_file_path` to `res://src/ui/character_select/character_select.tscn`. `main.tscn` is not loaded at this point.
2. **[Logic]** Pressing Confirm on the character select screen sets `get_tree().current_scene.scene_file_path` to `res://src/main.tscn`.
3. **[Logic]** Pressing Back on the character select screen returns to `res://scenes/start_menu.tscn` and leaves `GameState.character == null`.

### Selection State

4. **[Logic]** On scene `_ready()`, Vera's `CharacterCard` is in the "selected" state and `DetailPanel` labels show Vera's name, tagline, and description.
5. **[Logic]** Simulating a left-click `InputEventMouseButton` on Mox's locked card does NOT emit `card_selected` and does NOT change the selected card.
6. **[Visual]** Mox and Wren cards display a "Coming Soon" badge and desaturated portrait. Screenshot evidence in `production/qa/evidence/`.
7. **[Visual]** The selected card shows both a colored border and a checkmark icon (colorblind-safe). Screenshot evidence.
8. **[Visual]** Tapping a locked card triggers a shake animation and "Coming Soon" tooltip. Screenshot / video evidence.

### GameState Integration

9. **[Logic]** After confirming Vera, `GameState.character.id == &"vera"` and `GameState.character.damage_multiplier == 2.0`.
10. **[Logic]** `GameState.get_character()` returns `_NEUTRAL_CHARACTER` when `character` is null. All fields on the neutral resource: multipliers = 1.0, offsets = 0.
11. **[Logic]** `GameState.character` is set to `null` in `start_menu.gd._ready()`. Test: set `GameState.character = vera`, reload start menu, assert `GameState.character == null`.
12. **[Logic]** `GameState.character` persists across wave transitions. Test: set `GameState.character = vera`, emit `wave_started`, emit `wave_completed`, assert `GameState.character` still equals vera.
13. **[Logic]** `GameState.character` persists through pause/resume. Test: set, call `pause_game()`, call `resume_game()`, assert unchanged.

### Passive Effects

14. **[Logic]** With `GameState.character = vera`, a freshly placed tower's `_bullet_attack_stat.get_value()` equals `TowerData.bullet_data.damage × 2.0` (no other modules installed).
15. **[Logic]** With `GameState.character = vera`, a freshly placed tower's `_cd_stat.get_value()` equals `(1.0 / TowerData.firing_rate) × 2.0` (i.e., CD doubled; no other modules installed).
16. **[Logic]** With `GameState.character = vera` and a `rate_boost` module installed, the final CD equals `(base_cd − 0.3) × 2.0` (module first, character last).
17. **[Logic]** A shadow tower spawned by a Vera-owned parent applies the same damage and CD multipliers. Test: spawn shadow via `SpawnShadowTowerEffect`, assert shadow's effective damage and CD match the parent's computed values.
18. **[Logic]** With `GameState.character = neutral`, tower stats equal baseline (no multipliers applied).

### Lives & Economy

19. **[Logic]** `GameState.reset_lives()` with `get_character().starting_lives_offset == 0` sets `player_lives = 3`.
20. **[Logic]** `GameState.reset_lives()` when `GameState.character == null` does not crash and sets `player_lives = 3` (neutral offset).
21. **[Logic]** Enemy death with `GameState.character.bonus_coins_per_kill == 0` adds only the base coin reward.

### DEV Mode

22. **[Logic]** When `GameState.is_dev_mode()` returns true, the Start Menu's Start button navigates directly to `main.tscn`, bypassing the character select screen.

### Regression Guards

23. **[Logic]** `tests/gdunit/TowerAmmoResetTest.gd` and `tests/gdunit/ModuleStatTest.gd` add `GameState.character = null` to their teardown to prevent cross-test pollution.
24. **[Logic]** Existing ShadowTower tests pass unchanged when `GameState.character == null` (neutral fallback preserves prior behaviour).

---

## 9. Data Architecture Reference

### 9.1 `CharacterData.gd` (full declaration)

```gdscript
class_name CharacterData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var tagline: String = ""
@export_multiline var description: String = ""
@export var is_available: bool = false
@export var portrait: Texture2D = null
@export_range(0.1, 5.0, 0.05) var damage_multiplier: float = 1.0
@export_range(0.1, 3.0, 0.05) var fire_rate_multiplier: float = 1.0
@export_range(0, 10, 1) var bonus_coins_per_kill: int = 0
@export_range(-2, 5, 1) var starting_lives_offset: int = 0
```

### 9.2 Resource files (preload, not load)

```gdscript
# In character_select.gd:
const VERA: CharacterData = preload("res://src/resources/characters/vera.tres")
const MOX: CharacterData = preload("res://src/resources/characters/mox.tres")
const WREN: CharacterData = preload("res://src/resources/characters/wren.tres")
const ROSTER: Array[CharacterData] = [VERA, MOX, WREN]

# In GameState.gd:
const _NEUTRAL_CHARACTER: CharacterData = preload("res://src/resources/characters/neutral.tres")
```

`preload()` is used because the roster is a closed set and `load()` causes a frame hitch on web/mobile.

### 9.3 GameState additions

```gdscript
# New field
var character: CharacterData = null

# New accessor — all callers use this, never read `character` directly
func get_character() -> CharacterData:
    return character if character != null else _NEUTRAL_CHARACTER

# Modified reset
func reset_lives() -> void:
    player_lives = MAX_LIVES + get_character().starting_lives_offset
    SignalBus.lives_changed.emit(player_lives)
```

---

## 10. Review Resolution

Each blocking item from the 2026-04-16 design review:

| # | Blocker | Resolution |
|---|---------|------------|
| 1 | `class_name CharacterData` missing | Added to §9.1 |
| 2 | `@export` decorators missing | Added to §9.1 |
| 3 | `reset_lives()` null guard missing | Routed through `get_character()`; see §9.3 and §3.5 |
| 4 | Net DPS was 0.975x (loss) | Rebalanced to 2.0 / 0.5 → DPS 1.0x, shots-to-kill drops from 2 to 1 on 3-HP enemies |
| 5 | Shadow Tower didn't inherit passives | Explicit rule in §3.4; AC 17 verifies |
| 6 | Module interaction order unspecified | §3.3 specifies: modules first, character last |
| 7 | AC 4 "deal 50% more damage" untestable | Replaced with concrete ACs 14, 15, 16, 17 against actual `StatAttribute` values |
| 8 | Test teardown regression risk | AC 23 requires `GameState.character = null` teardown in existing tests |
| 9 | Locked card tap feedback | §3.7 specifies 200ms shake + 1.5s tooltip; AC 8 verifies |
| 10 | No back navigation | BackButton added in §3.7; AC 3 verifies |
| 11 | DetailPanel initial state | §3.7 specifies pre-population on `_ready()`; AC 4 verifies |
