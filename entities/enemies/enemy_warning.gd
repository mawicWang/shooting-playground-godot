extends Node2D

const ANIMATION_SPEED = 6.0  # 上下移动速度
const ANIMATION_AMPLITUDE = 8.0  # 上下移动幅度（像素）

var direction: Vector2 = Vector2.ZERO
var base_position: Vector2 = Vector2.ZERO
var time_accumulator: float = 0.0  # 时间累积器
var _danger_material: ShaderMaterial = null

func _ready():
	# 强制朝上，不随方向旋转
	rotation = 0
	base_position = position

func _process(delta):
	# 上下移动动画 - 累积时间确保连续流畅
	time_accumulator += delta
	var offset_y = sin(time_accumulator * ANIMATION_SPEED) * ANIMATION_AMPLITUDE
	position.y = base_position.y + offset_y

func set_direction(dir: Vector2):
	direction = dir
	# 不旋转，保持朝上

func set_grid_aligned_position(pos: Vector2):
	base_position = pos
	position = pos

func set_danger(is_danger: bool) -> void:
	var sprite := $Sprite2D
	if is_danger:
		if _danger_material == null:
			_danger_material = ShaderMaterial.new()
			_danger_material.shader = load("res://entities/enemies/enemy_warning_danger.gdshader")
		sprite.material = _danger_material
	else:
		sprite.material = null
