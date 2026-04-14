## 敌人生成选择器
## 用权重决定每波生成普通敌人还是强敌
class_name EnemySpawnPicker

const ENEMY_SCENE = preload("res://entities/enemies/enemy.tscn")
const STRONG_ENEMY_SCENE = preload("res://entities/enemies/strong_enemy.tscn")
const SHIELD_ENEMY_SCENE = preload("res://entities/enemies/shield_enemy.tscn")

const BASE_ENEMY_WEIGHT: int = 5        # 普通敌人固定权重
const STRONG_ENEMY_START_WAVE: int = 3  # 第几波开始生成强敌
const STRONG_ENEMY_BASE_WEIGHT: int = 5 # 强敌初始权重
const STRONG_ENEMY_WEIGHT_PER_WAVE: int = 1 # 每波增加的权重
const SHIELD_ENEMY_START_WAVE: int = 5  # 第几波开始生成护盾敌人
const SHIELD_ENEMY_BASE_WEIGHT: int = 3 # 护盾敌人初始权重
const SHIELD_ENEMY_WEIGHT_PER_WAVE: int = 1 # 每波增加的权重

## 计算强敌权重（前 2 波为 0）
static func _get_strong_enemy_weight(wave: int) -> int:
	if wave < STRONG_ENEMY_START_WAVE:
		return 0
	return STRONG_ENEMY_BASE_WEIGHT + (wave - STRONG_ENEMY_START_WAVE) * STRONG_ENEMY_WEIGHT_PER_WAVE

## 计算护盾敌人权重（前 4 波为 0）
static func _get_shield_enemy_weight(wave: int) -> int:
	if wave < SHIELD_ENEMY_START_WAVE:
		return 0
	return SHIELD_ENEMY_BASE_WEIGHT + (wave - SHIELD_ENEMY_START_WAVE) * SHIELD_ENEMY_WEIGHT_PER_WAVE

## 根据权重返回敌人场景（正常模式）
static func pick(wave: int) -> PackedScene:
	var strong_w = _get_strong_enemy_weight(wave)
	var shield_w = _get_shield_enemy_weight(wave)
	var base_w = BASE_ENEMY_WEIGHT
	var total = strong_w + shield_w + base_w
	var roll = randi() % total
	print("[ENEMY_PICK] wave=%s base=%s strong=%s shield=%s total=%s roll=%s" % [wave, base_w, strong_w, shield_w, total, roll])
	if roll < shield_w:
		print("[ENEMY_PICK] result: SHIELD")
		return SHIELD_ENEMY_SCENE
	if roll < shield_w + strong_w:
		print("[ENEMY_PICK] result: STRONG")
		return STRONG_ENEMY_SCENE
	print("[ENEMY_PICK] result: BASE")
	return ENEMY_SCENE

## Dev mode：随机返回任意敌人场景（无视波次权重）
static func pick_for_dev() -> PackedScene:
	var roll = randi() % 3
	if roll == 0:
		return STRONG_ENEMY_SCENE
	elif roll == 1:
		return SHIELD_ENEMY_SCENE
	return ENEMY_SCENE
