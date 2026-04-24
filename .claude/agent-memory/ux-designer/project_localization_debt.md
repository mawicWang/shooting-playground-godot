---
name: Localization system is not implemented; ui-code.md rule is unenforced
description: Project has a hard rule requiring tr() for all UI strings, but no localization infrastructure exists and the rule is violated in start_menu.gd and the character selection spec
type: project
---

The `.claude/rules/ui-code.md` rule states "All UI text must go through the localization system — no hardcoded user-facing strings." However:

- `start_menu.gd` hardcodes Chinese strings (`"混乱模式"`, `"普通模式"`, `"游戏模式"`) with no `tr()` wrapping.
- No `.pot` file, `TranslationServer` configuration, or `tr()` usage exists anywhere in `src/`.
- The character selection spec (2026-04-16) defines `CharacterData` with raw `String` fields (`display_name`, `tagline`, `description`) rather than translation keys — structurally prevents localization without a model change.

**Why:** The localization system was written into the rules before infrastructure was built. The gap was confirmed during the 2026-04-17 UX adversarial review of the character selection spec.

**How to apply:** When reviewing or authoring any UI spec or UI code, flag all hardcoded user-facing strings as a BLOCKING rule violation. When the localization system is eventually built, all string fields in CharacterData and all scene-tree Label text will need to be migrated to translation keys.
