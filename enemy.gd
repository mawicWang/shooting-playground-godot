extends CharacterBody2D

const SPEED = 100.0

var direction = Vector2.ZERO
var grid_cell_size = 80.0  # 网格单元大小，与grid一致

@onready var hitbox = $Hitbox

# 自定义信号
signal enemy_hit(body, enemy)

func _ready():
	# 确保Hitbox监控开启
	hitbox.monitoring = true
	hitbox.monitorable = true
	# 连接碰撞检测信号
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	# 设置统一朝向（正立朝上）
	rotation = 0

func _physics_process(delta):
	# 不使用move_and_slide，直接修改位置避免物理碰撞
	global_position += direction * SPEED * delta

func set_direction(dir: Vector2):
	direction = dir.normalized()
	# 保持统一朝向，不随移动方向旋转
	# 如需调整朝向，修改下面的 rotation 值

func set_grid_aligned_position(pos: Vector2):
	# 对齐到网格中心
	global_position = pos

func _on_hitbox_body_entered(body: Node2D):
	# 发出信号给管理器处理碰撞
	emit_signal("enemy_hit", body, self)

func _on_hitbox_area_entered(area_entered: Area2D):
	# 处理Area2D碰撞（如子弹的Hitbox）
	var parent = area_entered.get_parent()
	if parent != null:
		emit_signal("enemy_hit", parent, self)

func destroy():
	queue_free()
