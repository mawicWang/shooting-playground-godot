extends Node2D

const ANIMATION_SPEED = 3.0  # 上下移动速度
const ANIMATION_AMPLITUDE = 5.0  # 上下移动幅度（像素）

var direction: Vector2 = Vector2.ZERO
var base_position: Vector2 = Vector2.ZERO

func _ready():
	# 强制朝上，不随方向旋转
	rotation = 0
	base_position = position

func _process(delta):
	# 上下移动动画 - 使用 TIME 确保流畅
	var offset_y = sin(Time.get_time_dict_from_system()["second"] * ANIMATION_SPEED) * ANIMATION_AMPLITUDE
	position.y = base_position.y + offset_y

func set_direction(dir: Vector2):
	direction = dir
	# 不旋转，保持朝上

func set_base_position(pos: Vector2):
	base_position = pos
	position = pos
