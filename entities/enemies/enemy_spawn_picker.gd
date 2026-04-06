## 敌人生成选择器
## 用权重决定每波生成普通敌人还是强敌
class_name EnemySpawnPicker

const ENEMY_SCENE = preload("res://entities/enemies/enemy.tscn")
const STRONG_ENEMY_SCENE = preload("res://entities/enemies/strong_enemy.tscn")

const BASE_ENEMY_WEIGHT: int = 5        # 普通敌人固定权重
const STRONG_ENEMY_START_WAVE: int = 3  # 第几波开始生成强敌
const STRONG_ENEMY_BASE_WEIGHT: int = 5 # 强敌初始权重
const STRONG_ENEMY_WEIGHT_PER_WAVE: int = 1 # 每波增加的权重

## 计算强敌权重（前 2 波为 0）
static func _get_strong_enemy_weight(wave: int) -> int:
	if wave < STRONG_ENEMY_START_WAVE:
		return 0
	return STRONG_ENEMY_BASE_WEIGHT + (wave - STRONG_ENEMY_START_WAVE) * STRONG_ENEMY_WEIGHT_PER_WAVE

## 根据权重返回敌人场景（正常模式）
static func pick(wave: int) -> PackedScene:
	var strong_w = _get_strong_enemy_weight(wave)
	var base_w = BASE_ENEMY_WEIGHT
	var total = strong_w + base_w
	if total == 0 or randi() % total >= strong_w:
		return ENEMY_SCENE
	return STRONG_ENEMY_SCENE

## Dev mode：随机返回任意敌人场景（无视波次权重）
static func pick_for_dev() -> PackedScene:
	if randi() % 2 == 0:
		return ENEMY_SCENE
	return STRONG_ENEMY_SCENE
