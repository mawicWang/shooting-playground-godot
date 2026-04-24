# Character Selection — Review Log

Target spec: `design/gdd/character-selection.md` (moved from `docs/superpowers/specs/2026-04-16-character-selection-design.md` on 2026-04-17)

---

## Review — 2026-04-17 — Verdict: MAJOR REVISION NEEDED (addressed in revision pass, same day)

Scope signal: M (moderate — 1 new Resource, 1 new scene, 3 integration points, 2 subsystem interactions)
Specialists: game-designer, systems-designer, qa-lead, ux-designer, godot-specialist
Blocking items: 11 | Recommended: 8

Summary: First review found 2/8 required GDD sections present and 11 blocking items. Critical findings: (1) net DPS was 0.975x baseline — Vera was a penalty character, not a trade-off; (2) the character select screen provided no agency with only one unlocked slot; (3) engine-level gaps (`class_name CharacterData` missing, `@export` decorators missing on all fields) meant the spec as written could not compile; (4) Shadow Tower's overridden `_do_fire()` silently bypassed character passives; (5) module interaction order was unspecified, letting CD-reducing modules erase character identity mid-run. All 11 blocking items addressed in the same-day revision pass:

- DPS rebalanced to `2.0 × 0.5 = 1.0` net DPS, with a legible feel change (one-shot on 3-HP enemies)
- Selection screen kept (ship-now path chosen) but hardened with back button, locked-card feedback (200ms shake + 1.5s tooltip), and colorblind-safe selection highlight
- `class_name`, `@export`, `@export_range` all added to CharacterData
- Null handling consolidated behind a `GameState.get_character()` accessor returning a pre-built neutral resource
- Shadow Tower inheritance made explicit (AC 17 verifies)
- Stacking order locked to "modules first, character last"
- All ACs rewritten against concrete StatAttribute values and split into Logic (BLOCKING) and Visual (ADVISORY) classes
- 6 missing GDD sections added (Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs)

Prior verdict resolved: First review. Revision pass applied same day; awaiting re-review in a clean session.

---

## Review — 2026-04-17 (re-review of revision pass) — Verdict: MAJOR REVISION NEEDED

Scope signal: L (three subsystems need restructuring + prerequisite asset creation; not a polish pass)
Specialists: game-designer, systems-designer, qa-lead, ux-designer, godot-specialist, creative-director (senior)
Blocking items: 23 (clustered into 9 root causes) | Recommended: 13 | Advisory: 6

Summary: Same-day revision did NOT resolve the original 11 blockers — surface-patched symptoms while introducing new contradictions and leaving foundational issues intact. Five specialists converged independently on the same root concerns from different angles, which is itself diagnostic. Most serious unresolved issue is a compile-time crash hazard: the four CharacterData `.tres` resources do not exist on disk, yet `GameState.gd` is specified to `preload()` them as autoload constants — every scene fails to parse. Combined with the wrong scene path (`res://scenes/start_menu.tscn` vs. post-`src/`-migration `res://src/ui/start_menu/start_menu.tscn`), it is clear the spec was not validated against the current repo state.

Blocker clusters:
- **A. Resource & path prerequisite gap:** missing `.tres` files (compile crash via autoload preload), wrong scene path, missing evidence directory.
- **B. Modifier ordering myth:** "modules first, character last" is factually false. `StatAttribute.get_value()` groups by type and is commutative; insertion order doesn't affect result. `_apply_data()` runs in `_ready()` before any module install, so character mod is actually FIRST in array.
- **C. Modifier lifecycle contract:** `StatModifier.source` never specified → `remove_modifiers_from()` cannot work. `_apply_data()` is destructive (clears ammo queue), wrong tool for mid-run swap as §5 claims.
- **D. Numerical safety holes:** CD floor is 0.1 in code, spec says 0.01 (10× off). Divide-by-zero reachable when `fire_rate_multiplier = 0`. §4.5 lives clamp `clamp(X, 0, X)` is a no-op. §4.6 worked example correct by coincidence.
- **E. Shadow tower interaction:** §3.4 options (a)/(b) framing invites double-injection; super._apply_data() already inherits modifier for free.
- **F. Internal contradiction:** §3.6 places DEV-mode bypass in `character_select.gd._ready()`, AC 22 places it in `start_menu.gd._on_start_pressed()`. Latter is correct.
- **G. AC quality collapse:** scene transitions deferred (need `await`), "selected state" undefined, wrong click API, missing `monitor_signals()`, float `==` instead of `is_equal_approx`, fixtures unspecified.
- **H. Vera identity & balance:** Vera + rate_boost erodes "patience" fantasy (becomes DPS-equivalent). Generation-2 shadows inherit infinite-ammo + 2× damage — never explicitly addressed.
- **I. UX rule violations:** localization absent, keyboard nav missing, motion-reduce not respected, ConfirmButton width=0.

Prior verdict resolved: No — none of the 11 prior blockers are genuinely resolved. The fixes were stated in §10 (Review Resolution) but each one introduced a new contradiction or rested on a misread of the codebase. Spec needs structural rewrite of §3.3 (modifier model), §4 (math + corrected examples), §5 (lifecycle contract), §8 (full AC suite), plus prerequisite checklist for missing assets.
