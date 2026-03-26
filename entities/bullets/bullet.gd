extends CharacterBody2D

const SPEED = 200
const MAX_LIFETIME = 15.0  # 最大存活时间15秒

var direction = Vector2.RIGHT
var lifetime: float = 0.0
var warned: bool = false  # 是否已经打印过警告

func _ready():
	add_to_group("bullets")
	# 启用Hitbox监控以便敌人检测
	$Hitbox.monitoring = true
	$Hitbox.monitorable = true
	# 注意：碰撞检测由敌人处理，子弹只负责移动

func _physics_process(delta):
	velocity = direction * SPEED
	move_and_slide()
	
	# 更新存活时间
	lifetime += delta
	
	# 检查是否超过15秒（仅在调试模式下警告）
	if lifetime > MAX_LIFETIME and not warned:
		warned = true
		if OS.is_debug_build():
			push_warning("[BULLET] Bullet has been alive for %.1f seconds. Position: %s" % [lifetime, global_position])


func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()
