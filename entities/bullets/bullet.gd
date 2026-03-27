extends CharacterBody2D

const MAX_LIFETIME = 15.0

var data: BulletData = null
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _warned: bool = false

func _ready():
	add_to_group("bullets")
	$Hitbox.monitoring = true
	$Hitbox.monitorable = true

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
	velocity = Vector2.ZERO

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()
