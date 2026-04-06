extends "res://entities/enemies/enemy.gd"

var shield_layers: int = 2
var max_shield_layers: int = 2
var _shield_bubble: Node2D = null
var _shield_bar: Node2D = null
var _is_stunned: bool = false

func _ready():
	speed = 25.0
	max_health = 4.0
	super._ready()
	_setup_shield_visuals()

func _setup_shield_visuals() -> void:
	var ShieldBubble := preload("res://entities/enemies/shield_bubble.gd")
	_shield_bubble = ShieldBubble.new()
	add_child(_shield_bubble)
	_shield_bubble.setup(max_shield_layers)

	var ShieldBar := preload("res://ui/hud/shield_bar.gd")
	_shield_bar = ShieldBar.new()
	add_child(_shield_bar)
	_shield_bar.update(shield_layers, max_shield_layers)

func take_damage(amount: float, bullet_data: BulletData = null) -> void:
	if _is_dying or _is_stunned:
		return
	_last_bullet_data = bullet_data
	if shield_layers > 0:
		shield_layers -= 1
		_shield_bar.update(shield_layers, max_shield_layers)
		SignalBus.enemy_damaged.emit(self, 0.0, current_health, max_health)
		if shield_layers == 0:
			_break_shield()
		else:
			_shield_bubble.play_ripple()
			_shield_bubble.update_layers(shield_layers)
		var dn := DamageNumber.new()
		get_tree().root.add_child(dn)
		dn.show_damage(global_position + Vector2(0, -42), 0.0)
		return
	super.take_damage(amount, bullet_data)

func _break_shield() -> void:
	_is_stunned = true
	_shield_bubble.play_break()
	var effect := ShieldBreakEffect.new()
	get_tree().root.add_child(effect)
	effect.play(global_position)
	speed = 0.0
	var tween := create_tween()
	tween.tween_interval(0.25)
	tween.tween_callback(func():
		_is_stunned = false
		speed = 25.0
	)
