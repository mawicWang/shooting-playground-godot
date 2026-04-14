extends Node

## EffectManager.gd - 视觉效果管理
## 负责屏幕抖动、动画等视觉效果

const SHAKE_COUNT = 8
const SHAKE_INTENSITY = 5.0
const SHAKE_STEP_DURATION = 0.05

const LIGHT_SHAKE_COUNT = 4
const LIGHT_SHAKE_INTENSITY = 2.0
const LIGHT_SHAKE_STEP_DURATION = 0.03

signal shake_finished  # 每次震动结束（正常完成或被 reset_position 中断）时发出

var _is_screen_shaking: bool = false
var _active_tween: Tween = null
var _game_content: Control

func setup(game_content: Control):
	_game_content = game_content

## 触发屏幕震动。若已在震动中，则重启（每次受击都有反馈）。
func trigger_screen_shake() -> void:
	if _is_screen_shaking and is_instance_valid(_active_tween):
		_active_tween.kill()
		_game_content.position = Vector2.ZERO
		_is_screen_shaking = false

	_is_screen_shaking = true

	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_SINE)
	_active_tween.set_ease(Tween.EASE_IN_OUT)

	for i in range(SHAKE_COUNT):
		var offset = Vector2(randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY), randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY))
		_active_tween.tween_property(_game_content, "position", Vector2.ZERO + offset, SHAKE_STEP_DURATION)

	_active_tween.tween_property(_game_content, "position", Vector2.ZERO, SHAKE_STEP_DURATION)
	_active_tween.finished.connect(_on_shake_finished)

## 轻量级受击震动（2px），不打断全屏震动。
func trigger_light_shake() -> void:
	if _is_screen_shaking or not _game_content:
		return
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	for i in range(LIGHT_SHAKE_COUNT):
		var offset = Vector2(randf_range(-LIGHT_SHAKE_INTENSITY, LIGHT_SHAKE_INTENSITY), randf_range(-LIGHT_SHAKE_INTENSITY, LIGHT_SHAKE_INTENSITY))
		tween.tween_property(_game_content, "position", offset, LIGHT_SHAKE_STEP_DURATION)
	tween.tween_property(_game_content, "position", Vector2.ZERO, LIGHT_SHAKE_STEP_DURATION)

func _on_shake_finished():
	_is_screen_shaking = false
	_active_tween = null
	shake_finished.emit()

func reset_position():
	var was_shaking := _is_screen_shaking
	if is_instance_valid(_active_tween) and _active_tween.is_running():
		_active_tween.kill()
	_active_tween = null
	_is_screen_shaking = false
	if _game_content:
		_game_content.position = Vector2.ZERO
	if was_shaking:
		shake_finished.emit()  # 解除任何正在 await shake_finished 的协程

func is_shaking() -> bool:
	return _is_screen_shaking
