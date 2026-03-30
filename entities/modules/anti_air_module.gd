class_name AntiAirModule extends Module

## 防空模组：安装后炮塔的子弹同时携带 TOWER_BODY 和 AIR_TOWER_BODY 遮罩，
## 可命中普通炮塔与飞行炮塔。

func _init() -> void:
	module_name = "防空炮"
	category = Category.SPECIAL
	description = "子弹可命中飞行炮塔"
	slot_color = Color(1.0, 0.9, 0.2)  # 黄色

func on_install(tower: Node) -> void:
	tower.has_anti_air = true

func on_uninstall(tower: Node) -> void:
	tower.has_anti_air = false
