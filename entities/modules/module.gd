class_name Module extends Resource

enum Category { COMPUTATIONAL, LOGICAL, SPECIAL }

@export var module_name: String = ""
@export var category: Category = Category.COMPUTATIONAL
@export var description: String = ""
@export var icon: Texture2D
@export var slot_color: Color = Color(0.5, 0.5, 0.5)

## 安装到炮塔时，自动将 fire_effects / tower_effects 装载进去
@export var fire_effects: Array[FireEffect] = []
@export var tower_effects: Array[TowerEffect] = []

func on_install(tower: Node) -> void:
	tower.fire_effects.append_array(fire_effects)
	tower.tower_effects.append_array(tower_effects)

## 模块被从炮塔卸载时调用，负责清理对该塔施加的所有效果
func on_uninstall(tower: Node) -> void:
	for e in fire_effects:
		tower.fire_effects.erase(e)
	for e in tower_effects:
		tower.tower_effects.erase(e)
