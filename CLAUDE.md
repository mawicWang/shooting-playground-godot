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
