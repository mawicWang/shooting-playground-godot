extends CharacterBody2D

const SPEED = 30.0
const MAX_HEALTH := 3.0

var direction = Vector2.ZERO
var grid_cell_size = 80.0  # 网格单元大小，与grid一致
var max_health: float = MAX_HEALTH
var current_health: float = MAX_HEALTH
var _is_dying: bool = false

@onready var hitbox = $Hitbox

# 自定义信号
signal enemy_hit(body, enemy)
signal enemy_destroyed(enemy)  # 敌人被销毁信号

var _health_bar: HealthBar

func _ready():
	add_to_group("enemies")
	current_health = max_health
	# 确保Hitbox监控开启
	hitbox.monitoring = true
	hitbox.monitorable = true
	# 连接碰撞检测信号
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	# 设置统一朝向（正立朝上）
	rotation = 0

	# 种子将在 set_grid_aligned_position 中设置

	# 创建血量条
	_health_bar = HealthBar.new()
	add_child(_health_bar)
	_health_bar.update(current_health, max_health)

func _physics_process(delta):
	# 不使用move_and_slide，直接修改位置避免物理碰撞
	global_position += direction * SPEED * delta

func set_direction(dir: Vector2):
	direction = dir.normalized()
	# 保持统一朝向，不随移动方向旋转

func set_grid_aligned_position(pos: Vector2):
	# 对齐到网格中心
	global_position = pos

	# 设置位置后，使用位置生成唯一种子
	var sprite = $Sprite2D
	if sprite.material != null:
		var unique_seed = pos.x * 10.0 + pos.y
		sprite.set_instance_shader_parameter("noise_seed", unique_seed)
		# 随机时间偏移，让每个敌人在不同时刻触发抖动帧
		sprite.set_instance_shader_parameter("time_offset", randf_range(0.0, 2.0))

func take_damage(amount: float) -> void:
	if _is_dying:
		return
	current_health = maxf(current_health - amount, 0.0)
	SignalBus.enemy_damaged.emit(self, amount, current_health, max_health)
	_health_bar.update(current_health, max_health)
	# 生成伤害数字
	var dn := DamageNumber.new()
	get_tree().root.add_child(dn)
	dn.show_damage(global_position + Vector2(0.0, -42.0), amount)
	if current_health <= 0.0:
		_is_dying = true
		destroy()

func _on_hitbox_body_entered(body: Node2D):
	# 发出信号给管理器处理碰撞
	emit_signal("enemy_hit", body, self)

func _on_hitbox_area_entered(area_entered: Area2D):
	# 处理Area2D碰撞（如子弹的Hitbox）
	var parent = area_entered.get_parent()
	if parent != null:
		emit_signal("enemy_hit", parent, self)

func destroy():
	emit_signal("enemy_destroyed", self)
	queue_free()
