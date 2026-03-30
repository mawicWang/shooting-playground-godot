class_name BulletEffect extends Resource

## 子弹击中炮塔时（子弹侧，bullet.gd 触发）
func on_hit_tower(_bullet_data: BulletData, _tower: Node) -> void:
	pass

## 子弹击中敌人时（enemy_manager.gd 触发）
func on_hit_enemy(_bullet_data: BulletData, _enemy: Node) -> void:
	pass

## 子弹造成伤害时（enemy_manager.gd 触发）
func on_deal_damage(_bullet_data: BulletData, _target: Node, _damage: float) -> void:
	pass

## 敌人被击杀时（enemy.gd take_damage 触发）
func on_killed_enemy(_bullet_data: BulletData, _enemy: Node) -> void:
	pass
