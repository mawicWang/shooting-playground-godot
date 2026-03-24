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

func _physics_process(delta):
	# 不使用move_and_slide，直接修改位置避免物理碰撞
	var new_position = global_position + direction * SPEED * delta
	
	# 检查是否会进入grid区域
	var grid_rect = get_node_or_null("/root/main/GameContent/CenterContainer/GridRoot/Grid")?.get_global_rect()
	if grid_rect != null:
		# 获取敌人的碰撞大小（近似值）
		var enemy_radius = 20.0
		var enemy_rect = Rect2(new_position - Vector2(enemy_radius, enemy_radius), Vector2(enemy_radius * 2, enemy_radius * 2))
		
		# 如果新位置会与grid重叠，则停止移动并触发碰撞
		if grid_rect.intersects(enemy_rect):
			# 不移动，保持在当前位置
			# 碰撞检测由hitbox信号处理
			return
	
	global_position = new_position

func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()

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
