extends CharacterBody2D

const MAX_HEALTH := 3.0

var speed: float = 30.0
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
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_decay: float = 7.0

var _last_bullet_data: BulletData = null

func _ready():
	add_to_group("enemies")
	current_health = max_health
	hitbox.monitoring = true
	hitbox.monitorable = true
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	rotation = 0

	_health_bar = HealthBar.new()
	add_child(_health_bar)
	_health_bar.update(current_health, max_health)

func _physics_process(delta):
	global_position += direction * speed * delta
	if _knockback_velocity != Vector2.ZERO:
		global_position += _knockback_velocity * delta
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, _knockback_decay * delta)

func set_direction(dir: Vector2):
	direction = dir.normalized()

func set_grid_aligned_position(pos: Vector2):
	global_position = pos

	var sprite = $Sprite2D
	if sprite.material != null:
		var unique_seed = pos.x * 10.0 + pos.y
		sprite.set_instance_shader_parameter("noise_seed", unique_seed)
		sprite.set_instance_shader_parameter("time_offset", randf_range(0.0, 2.0))

## amount: 伤害量；bullet_data: 击中子弹的数据（可为 null，如荆棘伤害）
func take_damage(amount: float, bullet_data: BulletData = null) -> void:
	if _is_dying:
		return
	_last_bullet_data = bullet_data
	current_health = maxf(current_health - amount, 0.0)
	SignalBus.enemy_damaged.emit(self, amount, current_health, max_health)
	_health_bar.update(current_health, max_health)
	_flash_hit()
	var dn := DamageNumber.new()
	get_tree().root.add_child(dn)
	dn.show_damage(global_position + Vector2(0.0, -42.0), amount)
	if current_health <= 0.0:
		_is_dying = true
		# 3. 敌人死亡时触发效果
		if _last_bullet_data:
			for effect in _last_bullet_data.effects:
				effect.on_killed_enemy(_last_bullet_data, self)
		destroy()

func apply_knockback(impulse: Vector2, decay: float) -> void:
	_knockback_velocity += impulse
	_knockback_decay = decay

func _flash_hit() -> void:
	var sprite = $Sprite2D
	sprite.set_instance_shader_parameter("hit_flash_intensity", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float):
		sprite.set_instance_shader_parameter("hit_flash_intensity", v),
		1.0, 0.0, 0.15)

func _on_hitbox_body_entered(body: Node2D):
	emit_signal("enemy_hit", body, self)

func _on_hitbox_area_entered(area_entered: Area2D):
	var parent = area_entered.get_parent()
	if parent != null:
		emit_signal("enemy_hit", parent, self)

func destroy():
	emit_signal("enemy_destroyed", self)
	queue_free()
