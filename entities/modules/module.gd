class_name Module extends Resource

enum Category { COMPUTATIONAL, LOGICAL, SPECIAL }

@export var module_name: String = ""
@export var category: Category = Category.COMPUTATIONAL
@export var description: String = ""
@export var icon: Texture2D
@export var slot_color: Color = Color(0.5, 0.5, 0.5)  # 槽位填充色

## 每次炮塔发射时调用，可修改 bullet_data 后返回
## 注意：实例通过 install_module() 的 duplicate() 已隔离，可在此安全存储每塔状态
func apply_effect(_tower: Node, bullet_data: BulletData) -> BulletData:
	return bullet_data

## 模块被安装到炮塔时调用
func on_install(_tower: Node) -> void:
	pass

## 模块被从炮塔卸载时调用，负责清理对该塔施加的所有 Modifier
func on_uninstall(_tower: Node) -> void:
	pass
