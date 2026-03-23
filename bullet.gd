extends CharacterBody2D

const SPEED = 200
const MAX_LIFETIME = 15.0  # 最大存活时间15秒

var direction = Vector2.RIGHT
var lifetime: float = 0.0
var warned: bool = false  # 是否已经打印过警告

func _ready():
	# 启用Area2D监控以便敌人检测
	$Area2D.monitoring = true
	$Area2D.monitorable = true

func _physics_process(delta):
	velocity = direction * SPEED
	move_and_slide()
	
	# 更新存活时间
	lifetime += delta
	
	# 检查是否超过15秒
	if lifetime > MAX_LIFETIME and not warned:
		warned = true
		push_error("[BULLET ERROR] Bullet has been alive for %.1f seconds without being destroyed! Position: %s" % [lifetime, global_position])
		print("[BULLET ERROR] Bullet has been alive for %.1f seconds without being destroyed! Position: %s" % [lifetime, global_position])

func _exit_tree():
	print("[BULLET] Destroyed after %.2f seconds" % lifetime)

func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()
