extends Node

## EffectManager.gd - 视觉效果管理
## 负责屏幕抖动、动画等视觉效果

const SHAKE_COUNT = 8
const SHAKE_INTENSITY = 5.0
const SHAKE_STEP_DURATION = 0.05

var _is_screen_shaking: bool = false
var _active_tween: Tween = null
var _game_content: Control

func setup(game_content: Control):
	_game_content = game_content

func trigger_screen_shake() -> Tween:
	if _is_screen_shaking:
		return _active_tween

	_is_screen_shaking = true
	var original_position = _game_content.position

	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_SINE)
	_active_tween.set_ease(Tween.EASE_IN_OUT)

	for i in range(SHAKE_COUNT):
		var offset = Vector2(randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY), randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY))
		_active_tween.tween_property(_game_content, "position", original_position + offset, SHAKE_STEP_DURATION)

	_active_tween.tween_property(_game_content, "position", original_position, SHAKE_STEP_DURATION)
	_active_tween.finished.connect(_on_shake_finished)

	return _active_tween

func _on_shake_finished():
	_is_screen_shaking = false
	_active_tween = null

func reset_position():
	if is_instance_valid(_active_tween) and _active_tween.is_running():
		_active_tween.kill()
	_active_tween = null
	_is_screen_shaking = false
	if _game_content:
		_game_content.position = Vector2.ZERO

func is_shaking() -> bool:
	return _is_screen_shaking
