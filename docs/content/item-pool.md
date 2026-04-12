# Item Pool

All towers and modules available in the game are registered in `resources/item_pool.gd` (`class_name ItemPool`).

## Adding a new tower or module

1. Create the `.tres` resource file.
2. Set `in_normal_pool` and `in_dev_pool` in the Godot Editor Inspector.
3. Add one `preload(...)` line to `ALL_ITEMS` in `resources/item_pool.gd`.

No other files need updating.

## Pool flags

| Flag | Controls |
|------|----------|
| `in_normal_pool` | Appears in the wave-end reward popup (3-choice selection) |
| `in_dev_pool` | Appears in the developer mode sidebar |

Both flags default to `true`, so new resources are visible in both modes unless explicitly excluded.

## API

| Method | Returns |
|--------|---------|
| `ItemPool.normal_pool()` | All items with `in_normal_pool = true` |
| `ItemPool.dev_towers()` | All `TowerData` with `in_dev_pool = true` |
| `ItemPool.dev_modules()` | All `Module` with `in_dev_pool = true` |
