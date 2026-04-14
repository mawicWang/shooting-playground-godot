class_name FireEffect extends Resource

## 模块安装到炮塔时调用，供子类初始化（如设置 origin_entity_id）
func on_module_install(_tower: Node) -> void:
	pass

## 调用位置：tower.gd _do_fire()
func apply(_tower: Node, bd: BulletData) -> void:
	pass
