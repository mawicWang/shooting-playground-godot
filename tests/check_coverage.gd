## Coverage Checker — 检查测试覆盖率
## 运行方式: godot --headless --script res://tests/check_coverage.gd
##
## 此脚本扫描所有 Module 和 Relic 资源，检查哪些没有被测试覆盖

extends SceneTree

var _tested_modules: Array[String] = []
var _tested_relics: Array[String] = []
var _all_modules: Array[String] = []
var _all_relics: Array[String] = []

func _init() -> void:
	print("\n╔══════════════════════════════════════════════════════════════╗")
	print("║              Test Coverage Checker (覆盖率检查)               ║")
	print("╚══════════════════════════════════════════════════════════════╝\n")
	
	_scan_tested_items()
	_scan_all_resources()
	_print_coverage_report()
	
	quit(0)

func _scan_tested_items() -> void:
	# 从测试脚手架中提取已测试的项目
	# 这些应该与 effect_test_harness.gd 中的测试保持一致
	_tested_modules = [
		"accelerator",
		"multiplier",
		"flying",
		"anti_air",
	]
	
	_tested_relics = [
		# "double_shot",  # 由于 BulletPool 依赖，当前无法测试
	]

func _scan_all_resources() -> void:
	# 扫描所有模块资源
	var module_dir := DirAccess.open("res://resources/module_data/")
	if module_dir:
		module_dir.list_dir_begin()
		var file := module_dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				_all_modules.append(file.get_basename())
			file = module_dir.get_next()
		module_dir.list_dir_end()
	
	# 扫描所有遗物资源
	var relic_dir := DirAccess.open("res://resources/relic_data/")
	if relic_dir:
		relic_dir.list_dir_begin()
		var file := relic_dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				_all_relics.append(file.get_basename())
			file = relic_dir.get_next()
		relic_dir.list_dir_end()

func _print_coverage_report() -> void:
	print("━━━ Module Coverage ━━━")
	var module_covered := 0
	for module in _all_modules:
		var tested := module in _tested_modules
		var status := "✓" if tested else "✗"
		print("  %s %s" % [status, module])
		if tested:
			module_covered += 1
	
	var module_coverage: float = float(module_covered) / _all_modules.size() * 100 if _all_modules.size() > 0 else 0
	print("\nModule Coverage: %d/%d (%.1f%%)\n" % [module_covered, _all_modules.size(), module_coverage])
	
	print("━━━ Relic Coverage ━━━")
	var relic_covered := 0
	for relic in _all_relics:
		var tested := relic in _tested_relics
		var status := "✓" if tested else "✗"
		print("  %s %s" % [status, relic])
		if tested:
			relic_covered += 1
	
	var relic_coverage: float = float(relic_covered) / _all_relics.size() * 100 if _all_relics.size() > 0 else 0
	print("\nRelic Coverage: %d/%d (%.1f%%)\n" % [relic_covered, _all_relics.size(), relic_coverage])
	
	# 未覆盖的项目
	print("━━━ Untested Items ━━━")
	var untested_modules := _all_modules.filter(func(m): return not (m in _tested_modules))
	var untested_relics := _all_relics.filter(func(r): return not (r in _tested_relics))
	
	if untested_modules.size() > 0:
		print("Modules:")
		for m in untested_modules:
			print("  - %s" % m)
	
	if untested_relics.size() > 0:
		print("Relics:")
		for r in untested_relics:
			print("  - %s" % r)
	
	if untested_modules.size() == 0 and untested_relics.size() == 0:
		print("🎉 All items are tested!")
	
	print("\n" + "═".repeat(64))
	print("Total Coverage: %.1f%%" % ((module_covered + relic_covered) / float(_all_modules.size() + _all_relics.size()) * 100))
	print("═".repeat(64))
