extends Node

## EffectManager.gd - 视觉效果管理
## 负责屏幕抖动、动画等视觉效果

var _is_screen_shaking: bool = false
var _game_content: Control

func setup(game_content: Control):
    _game_content = game_content

func trigger_screen_shake() -> Tween:
    if _is_screen_shaking:
        return null
    
    _is_screen_shaking = true
    var original_position = _game_content.position
    
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    
    for i in range(8):
        var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
        tween.tween_property(_game_content, "position", original_position + offset, 0.05)
    
    tween.tween_property(_game_content, "position", original_position, 0.05)
    tween.finished.connect(func(): _is_screen_shaking = false)
    
    return tween

func reset_position():
    """重置位置，取消任何正在进行的抖动"""
    var tree = get_tree()
    if tree:
        tree.create_tween().kill()
    
    if _game_content:
        _game_content.position = Vector2.ZERO

func is_shaking() -> bool:
    return _is_screen_shaking
