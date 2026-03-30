class_name FireEffect extends Resource

## 开火时自动 append 到 BulletData 的 BulletEffect
@export var bullet_effects: Array[BulletEffect] = []

## 开火时调用，修改 BulletData 参数，并自动挂载 bullet_effects
## 调用位置：tower.gd _do_fire()
## 子类若需修改属性（如 speed、attack），重写此方法并调用 super
func apply(_tower: Node, bd: BulletData) -> void:
	bd.effects.append_array(bullet_effects)
