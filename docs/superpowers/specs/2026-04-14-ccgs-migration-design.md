# CCGS Migration Design

**Date:** 2026-04-14
**Status:** Approved
**Scope:** Adopt Claude Code Game Studios directory structure and studio infra into the existing Godot tower defense project.

---

## Overview

Migrate the project to match the Claude Code Game Studios (CCGS) template structure. This gives the project 49 specialized agents, 72 studio skills, 12 automated hooks, and 11 coding-standard rules, organized into a structured game studio workflow. The migration is split into two commits (phases), with a third deferred task for fixing `res://` path references.

---

## Phase 1 — Install Template Infra

**Goal:** Get the full CCGS agent/skill/hook infrastructure into `.claude/` without touching source or docs.

**Source:** `~/Projects/Claude-Code-Game-Studios/`

| Action | Details |
|--------|---------|
| Copy `.claude/agents/` | 49 agent definitions |
| Copy `.claude/hooks/` | 12 hook scripts |
| Copy `.claude/rules/` | 11 path-scoped coding standards |
| Copy `.claude/docs/` | Workflow docs + 39 templates |
| Copy `.claude/statusline.sh` | Pipeline breadcrumb status line |
| Copy `.claude/skills/` | 72 skills; existing `commit/` skill is kept |
| Replace `.claude/settings.json` | Use CCGS version (hooks + permission rules) |

**Commit message:** `chore: install Claude Code Game Studios infra`

---

## Phase 2 — Restructure Directories, Migrate Docs, Replace CLAUDE.md

**Goal:** Adopt CCGS directory layout, move game design docs to their canonical locations, and distribute existing CLAUDE.md content into the right template files.

### 2a — Source Directory Restructuring

Move GDScript source directories into `src/`:

| From (root) | To |
|-------------|-----|
| `autoload/` | `src/autoload/` |
| `core/` | `src/core/` |
| `entities/` | `src/entities/` |
| `grid/` | `src/grid/` |
| `components/` | `src/components/` |
| `relics/` | `src/relics/` |
| `ui/` | `src/ui/` |
| `resources/` | `src/resources/` |

**Stay at root** (CCGS expects these locations):
- `assets/`, `tests/`, `addons/`, `web/`

**⚠️ Deferred:** All `res://` path references in `.tscn`, `.gd`, `project.godot`, and autoload entries will break after this move. Path fixing is a separate follow-up task — do NOT run the game between Phase 2 commit and the path-fix session.

Create new scaffold directories:
```
design/gdd/
design/ux/
design/narrative/
design/levels/
design/balance/
design/quick-specs/
production/session-state/    ← gitignored
production/session-logs/     ← gitignored
prototypes/
docs/architecture/
docs/engine-reference/godot/
```

### 2b — Doc Migration

Move existing game design content from `docs/content/` into `design/gdd/`:

| From | To |
|------|----|
| `docs/content/towers.md` | `design/gdd/towers.md` |
| `docs/content/modules.md` | `design/gdd/modules.md` |
| `docs/content/effects.md` | `design/gdd/effects.md` |
| `docs/content/effect-matrix.md` | `design/gdd/effect-matrix.md` |
| `docs/content/shadow-tower.md` | `design/gdd/shadow-tower.md` |
| `docs/content/shield-enemy.md` | `design/gdd/shield-enemy.md` |
| `docs/content/variants.md` | `design/gdd/variants.md` |
| `docs/content/item-pool.md` | `design/gdd/item-pool.md` |

Stay in place:
- `docs/tests/` — test tooling documentation
- `docs/outdated/` — archived historical docs
- `docs/superpowers/` — superpowers plans and specs

Create `design/gdd/systems-index.md` — index of all GDDs, following CCGS template pattern.

Update `docs/DOC_INDEX.md` to reflect the new structure.

Add directory-scoped CLAUDE.md files from the CCGS template:
- `design/CLAUDE.md` — enforces 8-section GDD structure, file naming, design order
- `src/CLAUDE.md` — engine version warning, coding standards, ADR requirements
- `docs/CLAUDE.md` — ADR format/lifecycle, TR registry rules, engine reference usage

### 2c — CLAUDE.md Replacement and Content Distribution

**Replace** root `CLAUDE.md` with the CCGS template version, filled in for this project:

```
# Technology Stack
- Engine: Godot 4.4+
- Language: GDScript
- Version Control: Git / trunk-based
```

Retain these project-specific sections that the template does not provide:
- `## Tools` — Godot MCP tool list + Pixellab MCP reference (critical for this project)
- `## Common Commands` — build/run commands

**Distribute** architecture content from the old CLAUDE.md into `.claude/docs/technical-preferences.md`:
- Autoload singletons (SignalBus, GameState, DragManager, BulletPool, EventManager) with file paths
- Core systems (GameLoopManager, LayoutManager, EffectManager, DeadZoneManager)
- Grid system (GridManager, Cell, RemovalZone)
- Entity types (Tower, Bullet, Enemy, EnemyManager)
- Module system and Effect system overview
- Collision layer table (layers 2–8)
- State flow (StartMenu → main.tscn → DEPLOYMENT/RUNNING/PAUSED/GAME_OVER)

Create `docs/engine-reference/godot/VERSION.md` with pinned Godot version (4.4+).

**Commit message:** `chore: adopt Claude Code Game Studios directory structure`

---

## Phase 3 — Path Fix (Deferred)

Separate follow-up session. Fix all broken `res://` references caused by the `src/` move:
- `project.godot` autoload paths
- `.tscn` scene node script paths
- `preload()` / `load()` calls in `.gd` files
- Any `export` resource paths

This phase is intentionally not part of this migration plan.

---

## Out of Scope

- Translating Chinese docs to English
- Filling in all CCGS template placeholders (run `/setup-engine` and design skills after migration)
- Game feature changes of any kind
