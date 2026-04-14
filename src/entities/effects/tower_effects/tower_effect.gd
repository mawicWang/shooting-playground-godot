class_name TowerEffect extends Resource

## 炮塔被子弹击中时触发
## 调用位置：tower.gd on_bullet_hit()
## 触发时机：BulletEffect.on_hit_tower 之后
func on_receive_bullet_hit(_bullet_data: BulletData, _tower: Node) -> void:
	pass
