class_name BulletEffect extends Resource

## BulletEffect - 子弹效果基类
## 所有触发效果都继承此类，子弹携带效果列表，在各触发时机依次调用。
##
## 触发顺序：
## 1.1 子弹击中敌人时 → 子弹造成伤害时 → 敌人死亡时
## 1.2 子弹击中炮塔时 → 炮塔被击中时
## 1.3 敌人碰到荆棘时 → 子弹造成伤害时(荆棘伤害也触发) → 敌人死亡时

## 子弹击中炮塔时（子弹侧，bullet.gd 触发）
func on_hit_tower(_bullet_data: BulletData, _tower: Node) -> void:
	pass

## 炮塔被子弹击中时（炮塔侧，tower.gd 触发）
func on_tower_hit(_bullet_data: BulletData, _tower: Node) -> void:
	pass

## 子弹击中敌人时（enemy_manager.gd 触发）
func on_hit_enemy(_bullet_data: BulletData, _enemy: Node) -> void:
	pass

## 子弹造成伤害时（enemy_manager.gd 或荆棘系统触发）
func on_deal_damage(_bullet_data: BulletData, _target: Node, _damage: float) -> void:
	pass

## 敌人死亡时（enemy.gd 内 take_damage 触发）
func on_enemy_died(_bullet_data: BulletData, _enemy: Node) -> void:
	pass

## 敌人碰到荆棘时（预留，荆棘系统后补）
func on_enemy_hit_thorns(_bullet_data: BulletData, _enemy: Node) -> void:
	pass
