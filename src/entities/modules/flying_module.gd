class_name FlyingModule extends Module

## 飞行模组：安装后炮塔进入飞行状态。
## - 将 TowerBody 碰撞层切换为 AIR_TOWER_BODY（普通子弹无法命中）
## - 对炮塔精灵施加悬浮视觉动画（俯视视角下：放大、位移抖动、轻微旋转）

func _init() -> void:
	module_name = "飞行器"
	category = Category.SPECIAL
	description = "炮塔进入飞行状态，普通子弹无法命中"
	slot_color = Color(0.4, 0.8, 1.0)  # 天蓝色

const FLYING_SCALE_MULTIPLIER: float = 1.5

## 每个安装实例独立保存状态（Module 在 install_module 中已 duplicate()）
var _original_collision_layer: int = -1
var _original_tower_scale: Vector2 = Vector2.ONE
var _bob_tween: Tween = null
var _rot_tween: Tween = null

func on_install(tower: Node) -> void:
	super.on_install(tower)
	tower.is_flying = true

	# 切换 TowerBody 碰撞层到飞行层
	var tower_body: Area2D = tower.get_node_or_null("TowerBody")
	if is_instance_valid(tower_body):
		_original_collision_layer = tower_body.collision_layer
		tower_body.collision_layer = Layers.AIR_TOWER_BODY

	# 保存并放大炮塔精灵 scale（表现高度感）
	_original_tower_scale = tower.sprite.scale
	tower.sprite.scale = _original_tower_scale * FLYING_SCALE_MULTIPLIER

	# 启动悬浮动画
	_start_animation(tower)

func on_uninstall(tower: Node) -> void:
	super.on_uninstall(tower)
	tower.is_flying = false

	# 恢复 TowerBody 碰撞层
	if _original_collision_layer != -1:
		var tower_body: Area2D = tower.get_node_or_null("TowerBody")
		if is_instance_valid(tower_body):
			tower_body.collision_layer = _original_collision_layer
		_original_collision_layer = -1

	# 停止动画并重置精灵状态
	_stop_animation()

	var sprite: Node2D = tower.get_node_or_null("TowerVisual/Sprite2D")
	if is_instance_valid(sprite):
		sprite.position.y = 0.0
		sprite.rotation_degrees = 0.0

	# 恢复炮塔精灵 scale
	tower.sprite.scale = _original_tower_scale

func _start_animation(tower: Node) -> void:
	var sprite: Node2D = tower.get_node_or_null("TowerVisual/Sprite2D")
	if not is_instance_valid(sprite):
		return

	# 位移抖动：sprite.position.y 在 -3.5 ~ +3.5 之间循环，周期 2.2s
	_bob_tween = tower.create_tween()
	_bob_tween.set_loops()
	_bob_tween.set_trans(Tween.TRANS_SINE)
	_bob_tween.set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(sprite, "position:y", -3.5, 1.1)
	_bob_tween.tween_property(sprite, "position:y", 3.5, 1.1)

	# 轻微旋转：sprite.rotation_degrees 在 -2.5 ~ +2.5 之间循环，周期 3.0s
	_rot_tween = tower.create_tween()
	_rot_tween.set_loops()
	_rot_tween.set_trans(Tween.TRANS_SINE)
	_rot_tween.set_ease(Tween.EASE_IN_OUT)
	_rot_tween.tween_property(sprite, "rotation_degrees", -2.5, 1.5)
	_rot_tween.tween_property(sprite, "rotation_degrees", 2.5, 1.5)

func _stop_animation() -> void:
	if _bob_tween != null:
		_bob_tween.kill()
		_bob_tween = null
	if _rot_tween != null:
		_rot_tween.kill()
		_rot_tween = null
