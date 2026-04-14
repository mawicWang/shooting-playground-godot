# CCGS Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adopt the Claude Code Game Studios directory structure, studio infra (.claude/ agents/skills/hooks), and distribute existing CLAUDE.md architecture content into the canonical template locations.

**Architecture:** Two commits — Phase 1 installs .claude/ infra without touching source, Phase 2 restructures directories, migrates docs, and replaces CLAUDE.md. A third deferred session fixes broken res:// paths after the src/ move.

**Tech Stack:** GDScript / Godot 4.4+, Claude Code Game Studios v0.4.1, bash for file operations.

---

## File Map

### Phase 1 — New files added

| File | Action |
|------|--------|
| `.claude/agents/` (49 files) | Create — copy from CCGS template |
| `.claude/hooks/` (12 scripts) | Create — copy from CCGS template |
| `.claude/rules/` (11 files) | Create — copy from CCGS template |
| `.claude/docs/` (all files) | Create — copy from CCGS template |
| `.claude/statusline.sh` | Create — copy from CCGS template |
| `.claude/skills/` (72 dirs) | Create — add alongside existing `commit/` |
| `.claude/settings.json` | Replace with CCGS template version |

### Phase 2 — Moved, created, modified

| File | Action |
|------|--------|
| `autoload/` → `src/autoload/` | Move |
| `core/` → `src/core/` | Move |
| `entities/` → `src/entities/` | Move |
| `grid/` → `src/grid/` | Move |
| `components/` → `src/components/` | Move |
| `relics/` → `src/relics/` | Move |
| `ui/` → `src/ui/` | Move |
| `resources/` → `src/resources/` | Move |
| `docs/content/*.md` → `design/gdd/` | Move (8 files) |
| `design/gdd/systems-index.md` | Create |
| `design/CLAUDE.md` | Create — copy from CCGS template |
| `src/CLAUDE.md` | Create — copy from CCGS template |
| `docs/CLAUDE.md` | Create — copy from CCGS template |
| `docs/DOC_INDEX.md` | Modify |
| `CLAUDE.md` | Replace |
| `.claude/docs/technical-preferences.md` | Replace (fill in project content) |
| `docs/engine-reference/godot/VERSION.md` | Create |
| `.gitignore` | Modify (add production/session-state/, session-logs/) |

---

## Task 1: Copy .claude infra — agents, hooks, rules, docs, statusline

**Files:**
- Create: `.claude/agents/` (from `~/Projects/Claude-Code-Game-Studios/.claude/agents/`)
- Create: `.claude/hooks/` (from `~/Projects/Claude-Code-Game-Studios/.claude/hooks/`)
- Create: `.claude/rules/` (from `~/Projects/Claude-Code-Game-Studios/.claude/rules/`)
- Create: `.claude/docs/` (from `~/Projects/Claude-Code-Game-Studios/.claude/docs/`)
- Create: `.claude/statusline.sh`

- [ ] **Step 1: Copy agents, hooks, rules, docs, statusline**

```bash
cd ~/Projects/shooting-playground-godot
cp -r ~/Projects/Claude-Code-Game-Studios/.claude/agents .claude/
cp -r ~/Projects/Claude-Code-Game-Studios/.claude/hooks .claude/
cp -r ~/Projects/Claude-Code-Game-Studios/.claude/rules .claude/
cp -r ~/Projects/Claude-Code-Game-Studios/.claude/docs .claude/
cp ~/Projects/Claude-Code-Game-Studios/.claude/statusline.sh .claude/
```

- [ ] **Step 2: Verify copy**

```bash
ls .claude/agents/ | wc -l   # expect 49
ls .claude/hooks/             # expect 12 .sh files
ls .claude/rules/             # expect 11 files
ls .claude/docs/              # expect agents-roster.md, templates/, etc.
ls .claude/statusline.sh      # expect file exists
```

---

## Task 2: Copy skills and replace settings.json

**Files:**
- Create: `.claude/skills/` (72 new skill dirs alongside existing `commit/`)
- Replace: `.claude/settings.json`

- [ ] **Step 1: Copy all template skills into .claude/skills/**

```bash
cd ~/Projects/shooting-playground-godot
cp -r ~/Projects/Claude-Code-Game-Studios/.claude/skills/. .claude/skills/
```

- [ ] **Step 2: Verify your existing commit skill is still present**

```bash
ls .claude/skills/commit/
# expect: SKILL.md (your existing skill, untouched)
```

- [ ] **Step 3: Replace settings.json**

```bash
cp ~/Projects/Claude-Code-Game-Studios/.claude/settings.json .claude/settings.json
```

- [ ] **Step 4: Verify settings.json has CCGS hooks**

```bash
grep -c "session-start\|detect-gaps\|validate-commit" .claude/settings.json
# expect: 3
```

---

## Task 3: Commit Phase 1

- [ ] **Step 1: Stage and commit**

```bash
cd ~/Projects/shooting-playground-godot
git add .claude/
git commit -m "chore: install Claude Code Game Studios infra"
```

- [ ] **Step 2: Verify commit**

```bash
git log --oneline -1
# expect: chore: install Claude Code Game Studios infra
git diff HEAD~1 --name-only | grep "^.claude/" | wc -l
# expect: large number (agents + hooks + rules + docs + skills)
```

---

## Task 4: Create new directory scaffold

**Files:**
- Create: `src/`, `design/gdd/`, `design/ux/`, `design/narrative/`, `design/levels/`, `design/balance/`, `design/quick-specs/`
- Create: `production/session-state/`, `production/session-logs/`
- Create: `prototypes/`, `docs/architecture/`, `docs/engine-reference/godot/`

- [ ] **Step 1: Create all new directories with .gitkeep**

```bash
cd ~/Projects/shooting-playground-godot
mkdir -p src
mkdir -p design/gdd design/ux design/narrative design/levels design/balance design/quick-specs
mkdir -p production/session-state production/session-logs
mkdir -p prototypes
mkdir -p docs/architecture
mkdir -p docs/engine-reference/godot
touch design/.gitkeep design/ux/.gitkeep design/narrative/.gitkeep
touch design/levels/.gitkeep design/balance/.gitkeep design/quick-specs/.gitkeep
touch production/session-state/.gitkeep production/session-logs/.gitkeep
touch prototypes/.gitkeep docs/architecture/.gitkeep
```

- [ ] **Step 2: Add production session dirs to .gitignore**

Open `.gitignore` and add these lines at the end:

```
# CCGS production session state (ephemeral, not committed)
production/session-state/
production/session-logs/
```

- [ ] **Step 3: Verify directories exist**

```bash
ls design/
# expect: gdd/ ux/ narrative/ levels/ balance/ quick-specs/ .gitkeep
ls production/
# expect: session-state/ session-logs/
```

---

## Task 5: Move source directories into src/

**Files:**
- Move: `autoload/` `core/` `entities/` `grid/` `components/` `relics/` `ui/` `resources/` → `src/`

> **Warning:** After this task the game will not run. All `res://` paths are broken until the deferred path-fix session. Do not run the game or Godot editor until that session is complete.

- [ ] **Step 1: git mv each source directory**

```bash
cd ~/Projects/shooting-playground-godot
git mv autoload src/autoload
git mv core src/core
git mv entities src/entities
git mv grid src/grid
git mv components src/components
git mv relics src/relics
git mv ui src/ui
git mv resources src/resources
```

- [ ] **Step 2: Verify moves are staged**

```bash
git status --short | grep "^R" | head -20
# expect: lines like "R  autoload/SignalBus.gd -> src/autoload/SignalBus.gd"
ls src/
# expect: autoload/ core/ entities/ grid/ components/ relics/ ui/ resources/
```

---

## Task 6: Migrate docs/content/ to design/gdd/

**Files:**
- Move: `docs/content/towers.md` → `design/gdd/towers.md`
- Move: `docs/content/modules.md` → `design/gdd/modules.md`
- Move: `docs/content/effects.md` → `design/gdd/effects.md`
- Move: `docs/content/effect-matrix.md` → `design/gdd/effect-matrix.md`
- Move: `docs/content/shadow-tower.md` → `design/gdd/shadow-tower.md`
- Move: `docs/content/shield-enemy.md` → `design/gdd/shield-enemy.md`
- Move: `docs/content/variants.md` → `design/gdd/variants.md`
- Move: `docs/content/item-pool.md` → `design/gdd/item-pool.md`

- [ ] **Step 1: git mv all content docs**

```bash
cd ~/Projects/shooting-playground-godot
git mv docs/content/towers.md design/gdd/towers.md
git mv docs/content/modules.md design/gdd/modules.md
git mv docs/content/effects.md design/gdd/effects.md
git mv docs/content/effect-matrix.md design/gdd/effect-matrix.md
git mv docs/content/shadow-tower.md design/gdd/shadow-tower.md
git mv docs/content/shield-enemy.md design/gdd/shield-enemy.md
git mv docs/content/variants.md design/gdd/variants.md
git mv docs/content/item-pool.md design/gdd/item-pool.md
```

- [ ] **Step 2: Verify**

```bash
ls design/gdd/
# expect: towers.md modules.md effects.md effect-matrix.md
#         shadow-tower.md shield-enemy.md variants.md item-pool.md
ls docs/content/ 2>/dev/null || echo "empty or gone"
# expect: empty or gone
```

---

## Task 7: Add directory-scoped CLAUDE.md files

**Files:**
- Create: `design/CLAUDE.md`
- Create: `src/CLAUDE.md`
- Create: `docs/CLAUDE.md`

- [ ] **Step 1: Copy all three from CCGS template**

```bash
cd ~/Projects/shooting-playground-godot
cp ~/Projects/Claude-Code-Game-Studios/design/CLAUDE.md design/CLAUDE.md
cp ~/Projects/Claude-Code-Game-Studios/src/CLAUDE.md src/CLAUDE.md
cp ~/Projects/Claude-Code-Game-Studios/docs/CLAUDE.md docs/CLAUDE.md
```

- [ ] **Step 2: Verify**

```bash
head -3 design/CLAUDE.md   # expect: # Design Directory
head -3 src/CLAUDE.md      # expect: # Source Directory
head -3 docs/CLAUDE.md     # expect: # Docs Directory
```

---

## Task 8: Create design/gdd/systems-index.md

**Files:**
- Create: `design/gdd/systems-index.md`

- [ ] **Step 1: Write systems-index.md**

Create `design/gdd/systems-index.md` with this content:

```markdown
# Systems Index

All game design documents for this project. Update this index when adding a new GDD.

**Design order:** Foundation → Core → Feature → Presentation → Polish

| System | GDD | Category | Status |
|--------|-----|----------|--------|
| Towers | [towers.md](towers.md) | Foundation | Documented |
| Modules | [modules.md](modules.md) | Core | Documented |
| Effects | [effects.md](effects.md) | Core | Documented |
| Effect Matrix | [effect-matrix.md](effect-matrix.md) | Core | Documented |
| Item Pool | [item-pool.md](item-pool.md) | Core | Documented |
| Shadow Tower | [shadow-tower.md](shadow-tower.md) | Feature | Documented |
| Shield Enemy | [shield-enemy.md](shield-enemy.md) | Feature | Documented |
| Variants | [variants.md](variants.md) | Presentation | Documented |
```

---

## Task 9: Update docs/DOC_INDEX.md

**Files:**
- Modify: `docs/DOC_INDEX.md`

- [ ] **Step 1: Replace DOC_INDEX.md with updated content**

Replace the full contents of `docs/DOC_INDEX.md` with:

```markdown
# DOC_INDEX.md

项目文档系统统一入口。

---

## 游戏设计文档（`design/gdd/`）

面向 agent 的权威设计参考，定义所有游戏机制和系统规格。系统索引见 [`design/gdd/systems-index.md`](../design/gdd/systems-index.md)。

| 文件 | 说明 |
|------|------|
| [`design/gdd/systems-index.md`](../design/gdd/systems-index.md) | 所有 GDD 系统索引 |
| [`design/gdd/towers.md`](../design/gdd/towers.md) | 4 座塔的完整规格（firing_rate、炮管数、初始弹药、命名规则） |
| [`design/gdd/modules.md`](../design/gdd/modules.md) | 14 个模块的完整规格，分 3 类（COMPUTATIONAL / LOGICAL / SPECIAL） |
| [`design/gdd/effects.md`](../design/gdd/effects.md) | 效果系统接口文档（BulletEffect / TowerEffect / FireEffect） |
| [`design/gdd/effect-matrix.md`](../design/gdd/effect-matrix.md) | 触发时机 × 触发效果矩阵 |
| [`design/gdd/shadow-tower.md`](../design/gdd/shadow-tower.md) | 影子炮塔系统完整参考 |
| [`design/gdd/shield-enemy.md`](../design/gdd/shield-enemy.md) | 护盾敌人系统 |
| [`design/gdd/variants.md`](../design/gdd/variants.md) | 炮塔变体系统 |
| [`design/gdd/item-pool.md`](../design/gdd/item-pool.md) | Item Pool — 统一 tower/module 注册表 |

---

## 技术架构文档（`docs/architecture/`）

ADR（架构决策记录）存放于此。使用 `/architecture-decision` 创建新 ADR。

*暂无 ADR — 使用 `/architecture-decision` 创建第一个。*

---

## 测试文档（`docs/tests/`）

| 文件 | 说明 |
|------|------|
| [`tests/HOW_TO_RUN_TESTS.md`](tests/HOW_TO_RUN_TESTS.md) | 如何运行 GdUnit4 测试，测试套件概览 |
| [`tests/gdunit_testing.md`](tests/gdunit_testing.md) | GdUnit4 测试框架详细文档 |

---

## 开发计划（`docs/superpowers/plans/`）

| 文件 | 说明 |
|------|------|
| [`superpowers/plans/2026-04-14-ccgs-migration.md`](superpowers/plans/2026-04-14-ccgs-migration.md) | CCGS 目录结构迁移实施计划 |
| [`superpowers/plans/2026-04-02-tower-module-test-framework.md`](superpowers/plans/2026-04-02-tower-module-test-framework.md) | Tower/Module 测试框架实施计划（已完成） |

---

## 过时文档（`docs/outdated/`）

| 文件 | 说明 |
|------|------|
| [`outdated/DESIGN_V1.0.md`](outdated/DESIGN_V1.0.md) | v1.0 模块/遗物设计文档 |
| [`outdated/DEVELOPER.md`](outdated/DEVELOPER.md) | 旧版架构和算法深入文档 |
| [`outdated/EFFECT_SYSTEM.md`](outdated/EFFECT_SYSTEM.md) | 旧版效果系统文档 |
| [`outdated/IMPLEMENTATION_PLAN.md`](outdated/IMPLEMENTATION_PLAN.md) | 旧版开发路线图 |
```

---

## Task 10: Write .claude/docs/technical-preferences.md

**Files:**
- Replace: `.claude/docs/technical-preferences.md`

- [ ] **Step 1: Replace technical-preferences.md with project content**

Replace the full contents of `.claude/docs/technical-preferences.md` with:

```markdown
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
```

---

## Task 11: Replace root CLAUDE.md

**Files:**
- Replace: `CLAUDE.md`

- [ ] **Step 1: Replace CLAUDE.md**

Replace the full contents of `CLAUDE.md` with:

```markdown
# Claude Code Game Studios — Shooting Playground

Godot 4.4+ tower defense game managed through specialized Claude Code subagents.
Drag-and-drop tower placement, wave-based combat, module/relic system, Web/mobile layout.

## Technology Stack

- **Engine**: Godot 4.4+
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: Godot export pipeline + `build_web.sh`
- **Asset Pipeline**: Godot native

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question → Options → Decision → Draft → Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md

## General Principles

- Prefer simple, minimal solutions. Do not over-engineer.
- Avoid adding unrequested features.

## Development Workflow

### Testing

All changes MUST pass the full GdUnit4 test suite (`tests/gdunit/`).

- **New features**: Write tests before considering done.
- **Existing features**: Write tests to protect behavior FIRST, then change.
- **Bug fixes**: Add regression tests where appropriate.
- Prefer `GdUnitSceneRunner` for scene/node interaction tests.

### Documentation

New features → create or update GDD in `design/gdd/`, update `design/gdd/systems-index.md`.
Update `docs/DOC_INDEX.md` when adding docs.

### Debugging

Add `print()` logs to observe runtime behavior. Don't rely on static analysis alone.
Check the full call chain, especially for Godot signals and collision callbacks.

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

## Common Commands

```bash
# Run the game
godot --path . scenes/start_menu.tscn

# Web export
./build_web.sh
python3 -m http.server 8000 --directory web
```
```

---

## Task 12: Create docs/engine-reference/godot/VERSION.md

**Files:**
- Create: `docs/engine-reference/godot/VERSION.md`

- [ ] **Step 1: Write VERSION.md**

Create `docs/engine-reference/godot/VERSION.md` with:

```markdown
# Godot Engine Version Reference

**Pinned Version:** Godot 4.4+
**Language:** GDScript 2.0 (Godot 4.x syntax)

> The LLM's training data may predate this engine version.
> Always check this file before using engine APIs.

## Key API Patterns (Godot 4.x)

- Signals: `signal_name.connect(callable)` — not the Godot 3 string form
- CharacterBody2D: `velocity` is a property; `move_and_slide()` takes no arguments
- Exports: `@export var foo: Type`
- Node refs: `@onready var foo = $NodeName`
- Packed scenes: `preload("res://path/to/scene.tscn")` returns `PackedScene`
- Resources: extend `Resource`, use `@export` for fields

## Project Addons

- **GdUnit4** — test framework (`addons/gdUnit4/`) — version pinned by `addons/` contents
```

---

## Task 13: Commit Phase 2

- [ ] **Step 1: Stage all Phase 2 changes**

```bash
cd ~/Projects/shooting-playground-godot
git add src/
git add design/
git add production/
git add prototypes/
git add docs/
git add CLAUDE.md
git add .claude/docs/technical-preferences.md
git add .gitignore
```

- [ ] **Step 2: Verify staging looks right**

```bash
git status --short | head -40
# expect: new files in src/, design/, production/, prototypes/
# expect: modified CLAUDE.md, .claude/docs/technical-preferences.md
# expect: moved docs/content/* -> design/gdd/*
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: adopt Claude Code Game Studios directory structure"
```

- [ ] **Step 4: Verify final state**

```bash
git log --oneline -3
# expect:
# chore: adopt Claude Code Game Studios directory structure
# chore: install Claude Code Game Studios infra
# docs: add CCGS migration design spec

ls src/
# expect: autoload/ core/ entities/ grid/ components/ relics/ ui/ resources/

ls design/gdd/
# expect: towers.md modules.md effects.md effect-matrix.md shadow-tower.md
#         shield-enemy.md variants.md item-pool.md systems-index.md
```

---

## Deferred: Phase 3 — Fix res:// Path References

This is a **separate session**. After this plan is complete, all `res://` paths in the project are broken because source directories moved into `src/`. Do not run Godot until this is done.

What needs fixing (to be planned separately):
- `project.godot` — autoload paths (e.g. `res://autoload/SignalBus.gd` → `res://src/autoload/SignalBus.gd`)
- `.tscn` files — `[ext_resource path="res://entities/..."]` references
- `.gd` files — any `preload("res://core/...")` or `load("res://...")` calls
- `export_presets.cfg` — if it references source paths
