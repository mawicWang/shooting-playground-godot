extends CharacterBody2D

const SPEED = 100.0

var direction = Vector2.ZERO
var grid_cell_size = 80.0  # 网格单元大小，与grid一致

@onready var area = $Area2D

# 自定义信号
signal enemy_hit(body, enemy)

func _ready():
	# 确保Area2D监控开启
	area.monitoring = true
	area.monitorable = true
	# 连接碰撞检测信号
	area.body_entered.connect(_on_body_entered)
	area.area_entered.connect(_on_area_entered)

func _physics_process(delta):
	velocity = direction * SPEED
	move_and_slide()

func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()

func set_grid_aligned_position(pos: Vector2):
	# 对齐到网格中心
	global_position = pos

func _on_body_entered(body: Node2D):
	# 发出信号给管理器处理碰撞
	emit_signal("enemy_hit", body, self)

func _on_area_entered(area_entered: Area2D):
	# 处理Area2D碰撞（如子弹的Area2D）
	var parent = area_entered.get_parent()
	if parent != null:
		emit_signal("enemy_hit", parent, self)

func destroy():
	queue_free()
