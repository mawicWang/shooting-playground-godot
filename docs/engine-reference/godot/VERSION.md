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
