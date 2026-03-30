## Headless validation script — run with:
##   godot --headless --script res://tests/validate.gd
##
## Checks:
##   1. All .gd scripts parse without errors (via ResourceLoader)
##   2. Key scenes load and instantiate without crashing
##
## Exit codes: 0 = all pass, 1 = at least one failure

extends SceneTree

const KEY_SCENES: Array[String] = [
	"res://main.tscn",
	"res://entities/towers/tower.tscn",
	"res://entities/enemies/enemy.tscn",
	"res://entities/bullets/bullet.tscn",
	"res://ui/start_menu/start_menu.tscn",
	"res://ui/popups/game_over_popup.tscn",
	# reward_popup has no .tscn — it is built programmatically in main.gd
]

var _errors: PackedStringArray = []
var _pass_count: int = 0
var _fail_count: int = 0


func _init() -> void:
	print("\n╔══════════════════════════════════════╗")
	print("║       Godot Project Validator         ║")
	print("╚══════════════════════════════════════╝\n")

	_scan_scripts("res://")
	_check_scenes()
	_print_summary()

	quit(1 if _fail_count > 0 else 0)


# ── Script parse checks ────────────────────────────────────────────────────────

func _scan_scripts(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		_record_fail("Cannot open directory: " + dir_path)
		return

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name == "." or name == "..":
			name = dir.get_next()
			continue

		var full_path := dir_path.path_join(name)

		if dir.current_is_dir():
			# Skip .godot cache and test directory itself to avoid self-loading issues
			if name != ".godot":
				_scan_scripts(full_path)
		elif name.ends_with(".gd"):
			_check_script(full_path)

		name = dir.get_next()
	dir.list_dir_end()


func _check_script(path: String) -> void:
	var res = ResourceLoader.load(path, "GDScript")
	if res == null:
		_record_fail("[SCRIPT] Load failed: " + path)
	else:
		_record_pass("[SCRIPT] " + path)


# ── Scene instantiation checks ─────────────────────────────────────────────────

func _check_scenes() -> void:
	print("\n── Key scene checks ──")
	for scene_path in KEY_SCENES:
		_check_scene(scene_path)


func _check_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		_record_fail("[SCENE ] Not found: " + path)
		return

	var packed = ResourceLoader.load(path, "PackedScene")
	if packed == null:
		_record_fail("[SCENE ] Load failed: " + path)
		return

	# Instantiate but don't add to tree — avoids running _ready()
	var instance = packed.instantiate()
	if instance == null:
		_record_fail("[SCENE ] Instantiate failed: " + path)
		return

	instance.free()
	_record_pass("[SCENE ] " + path)


# ── Helpers ────────────────────────────────────────────────────────────────────

func _record_pass(label: String) -> void:
	_pass_count += 1
	print("  PASS  " + label)


func _record_fail(label: String) -> void:
	_fail_count += 1
	_errors.append(label)
	print("  FAIL  " + label)


func _print_summary() -> void:
	var total := _pass_count + _fail_count
	print("\n── Summary ──")
	print("Passed: %d / %d" % [_pass_count, total])

	if _fail_count > 0:
		print("\nFailed (%d):" % _fail_count)
		for err in _errors:
			print("  • " + err)
		print("\n[RESULT] VALIDATION FAILED")
	else:
		print("\n[RESULT] ALL CHECKS PASSED")
