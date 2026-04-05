class_name Module extends Resource

enum Category { COMPUTATIONAL, LOGICAL, SPECIAL }

@export var module_name: String = ""
@export var category: Category = Category.COMPUTATIONAL
@export var description: String = ""
@export var icon: Texture2D
@export var slot_color: Color = Color(0.5, 0.5, 0.5)

## 安装到炮塔时，自动将 fire_effects 装载进去
@export var fire_effects: Array[FireEffect] = []
## 安装到炮塔时，自动将 tower_effects 装载进去
@export var tower_effects: Array[TowerEffect] = []
## 安装到炮塔时，自动将  bullet_effects 装载进去
@export var bullet_effects: Array[BulletEffect] = []

## 炮塔属性修改器（通过 StatAttribute 修改 CD / 子弹速度 / 攻击 / 额外弹药消耗）
@export var stat_modifiers: Array[TowerStatModifierRes] = []

func on_install(tower: Node) -> void:
	tower.fire_effects.append_array(fire_effects)
	for e in fire_effects:
		e.on_module_install(tower)
	tower.tower_effects.append_array(tower_effects)
	tower.bullet_effects.append_array(bullet_effects)
	for entry in stat_modifiers:
		var attr: StatAttribute = tower.get_stat(entry.stat)
		if attr:
			attr.add_modifier(StatModifier.new(entry.value, entry.modifier_type as StatModifier.Type, self))

## 模块被从炮塔卸载时调用，负责清理对该塔施加的所有效果
func on_uninstall(tower: Node) -> void:
	for e in fire_effects:
		tower.fire_effects.erase(e)
	for e in tower_effects:
		tower.tower_effects.erase(e)
	for e in bullet_effects:
		tower.bullet_effects.erase(e)
	for entry in stat_modifiers:
		var attr: StatAttribute = tower.get_stat(entry.stat)
		if attr:
			attr.remove_modifiers_from(self)
