extends CharacterBody2D

const MAX_LIFETIME = 15.0

var data: BulletData = null
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _warned: bool = false
var _pending_release: bool = false

func _ready():
	add_to_group("bullets")
	$Hitbox.monitoring = true
	$Hitbox.monitorable = true
	$Hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(delta):
	var speed := data.speed if data else 200.0
	velocity = direction * speed
	move_and_slide()

	_lifetime += delta
	if _lifetime > MAX_LIFETIME and not _warned:
		_warned = true
		if OS.is_debug_build():
			push_warning("[BULLET] Bullet alive %.1fs at %s" % [_lifetime, global_position])

## 从对象池取出时重置运行时状态
func reset() -> void:
	_lifetime = 0.0
	_warned = false
	_pending_release = false
	velocity = Vector2.ZERO
	set_physics_process(true)

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

## 检测是否击中炮塔
func _on_hitbox_area_entered(other_area: Area2D) -> void:
	if _pending_release:
		return
	var parent = other_area.get_parent()
	if not is_instance_valid(parent) or not parent.is_in_group("towers"):
		return
	# 不击中自己发射的炮塔
	if data and data.transmission_chain.has(parent):
		return
	_pending_release = true
	visible = false
	set_physics_process(false)
	# 1. 触发子弹击中效果
	if data:
		for effect in data.hit_effects:
			effect.apply(data, parent)
	# 2. 触发炮塔被击中效果
	parent.on_bullet_hit(data)
	# 3. 延迟回收，避免在物理回调中直接修改场景树
	BulletPool.release.call_deferred(self)
