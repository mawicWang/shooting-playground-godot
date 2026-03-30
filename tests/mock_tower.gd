## MockTower — 用于测试的轻量 Tower 模拟对象
##
## 设计原则:
##   - 不依赖任何 autoload (GameState, BulletPool, EventManager 等)
##   - 只实现 Module/Relic 交互所需的最小接口
##   - 可以手动验证属性变化

class_name MockTower extends Node

# Tower 核心属性（复制自 tower.gd）
var data: TowerData
var ammo: int = 0
var modules: Array = []
var fire_effects: Array = []
var tower_effects: Array = []
var bullet_effects: Array = []

# StatAttribute 系统
var _cd_stat: StatAttribute
var _bullet_speed_stat: StatAttribute
var _bullet_attack_stat: StatAttribute
var _ammo_extra_stat: StatAttribute

# 特殊状态标志（供特定模块使用）
var is_flying: bool = false
var has_anti_air: bool = false

# 状态追踪（用于测试验证）
var install_calls: Array = []      # 记录 install_module 调用
var uninstall_calls: Array = []    # 记录 uninstall_module 调用
var ammo_consumed: int = 0         # 记录弹药消耗
var ammo_added: int = 0            # 记录弹药补充

func _init(tower_data: TowerData = null) -> void:
	data = tower_data if tower_data else TowerData.new()
	ammo = data.initial_ammo
	
	var base_cd := 1.0 / maxf(data.firing_rate, 0.01)
	_cd_stat = StatAttribute.new(base_cd)
	_bullet_speed_stat = StatAttribute.new(200.0)
	_bullet_attack_stat = StatAttribute.new(1.0)
	_ammo_extra_stat = StatAttribute.new(0.0)

# ═══════════════════════════════════════════════════════════════════════════════
# StatAttribute 接口（复制自 tower.gd）
# ═══════════════════════════════════════════════════════════════════════════════

func get_stat(stat: TowerStatModifierRes.Stat) -> StatAttribute:
	match stat:
		TowerStatModifierRes.Stat.CD:            return _cd_stat
		TowerStatModifierRes.Stat.BULLET_SPEED:  return _bullet_speed_stat
		TowerStatModifierRes.Stat.BULLET_ATTACK: return _bullet_attack_stat
		TowerStatModifierRes.Stat.AMMO_EXTRA:    return _ammo_extra_stat
		_:
			push_error("MockTower.get_stat: unknown stat %d" % stat)
			return null
	return null

func get_cd() -> float:
	return _cd_stat.get_value()

func get_bullet_speed() -> float:
	return _bullet_speed_stat.get_value()

func get_bullet_attack() -> float:
	return _bullet_attack_stat.get_value()

# ═══════════════════════════════════════════════════════════════════════════════
# Module 系统接口（复制自 tower.gd）
# ═══════════════════════════════════════════════════════════════════════════════

func install_module(mod: Module) -> bool:
	if modules.size() >= 4:  # max_slots = 4
		return false
	
	var instance: Module = mod.duplicate()
	modules.append(instance)
	instance.on_install(self)
	
	install_calls.append({
		"module": instance.module_name,
		"timestamp": Time.get_ticks_msec()
	})
	
	return true

func uninstall_module(index: int) -> void:
	if index < 0 or index >= modules.size():
		return
	
	var mod: Module = modules[index]
	mod.on_uninstall(self)
	modules.remove_at(index)
	
	uninstall_calls.append({
		"module": mod.module_name,
		"index": index,
		"timestamp": Time.get_ticks_msec()
	})

func get_module_count() -> int:
	return modules.size()

# ═══════════════════════════════════════════════════════════════════════════════
# 弹药系统接口
# ═══════════════════════════════════════════════════════════════════════════════

func has_ammo() -> bool:
	return ammo == -1 or ammo > 0

func consume_ammo() -> void:
	if ammo == -1:
		return
	ammo = max(0, ammo - 1)
	ammo_consumed += 1

func add_ammo(amount: int) -> void:
	if ammo == -1:
		return
	ammo += amount
	ammo_added += amount

# ═══════════════════════════════════════════════════════════════════════════════
# 测试辅助方法
# ═══════════════════════════════════════════════════════════════════════════════

## 获取所有属性值（用于快速断言）
func get_stats_snapshot() -> Dictionary:
	return {
		"cd": get_cd(),
		"bullet_speed": get_bullet_speed(),
		"bullet_attack": get_bullet_attack(),
		"ammo": ammo,
	}

## 重置状态追踪
func reset_tracking() -> void:
	install_calls.clear()
	uninstall_calls.clear()
	ammo_consumed = 0
	ammo_added = 0

## 打印当前状态（调试用）
func print_state() -> void:
	print("MockTower state:")
	print("  Stats: cd=%.2f, speed=%.2f, attack=%.2f" % [get_cd(), get_bullet_speed(), get_bullet_attack()])
	print("  Ammo: %d (consumed: %d, added: %d)" % [ammo, ammo_consumed, ammo_added])
	print("  Modules: %d installed" % modules.size())
	for i in modules.size():
		print("    [%d] %s" % [i, modules[i].module_name])
