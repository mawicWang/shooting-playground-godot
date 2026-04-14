class_name ShieldBubble extends Node2D

const BUBBLE_SIZE := Vector2(56.0, 56.0)

var _sprite: Sprite2D
var _material: ShaderMaterial
var _max_layers: int = 1
var _current_intensity: float = 1.0


func setup(max_layers: int) -> void:
	_max_layers = max_layers

	# Create a plain white 64x64 texture for the shader to draw on
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)

	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.scale = BUBBLE_SIZE / Vector2(64.0, 64.0)

	var shader := load(Paths.SHIELD_BUBBLE_SHADER) as Shader
	_material = ShaderMaterial.new()
	_material.shader = shader
	_sprite.material = _material

	add_child(_sprite)

	update_layers(max_layers)


func update_layers(current_layers: int) -> void:
	if _material == null:
		return
	var ratio := float(current_layers) / float(_max_layers) if _max_layers > 0 else 0.0
	_current_intensity = clampf(ratio, 0.2, 1.0)
	_material.set_shader_parameter("layer_intensity", _current_intensity)


func play_ripple() -> void:
	if _material == null:
		return
	# Flash intensity to 1.0, then restore after ripple duration
	_material.set_shader_parameter("layer_intensity", 1.0)
	# Pass current TIME to ripple_time via a workaround: use script time tracking
	# In Godot 4 we can't read TIME from script, so we set ripple_time to the
	# engine's current process time modulo a large window so the shader can compute elapsed.
	_material.set_shader_parameter("ripple_time", Time.get_ticks_msec() / 1000.0)

	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func():
		if _material:
			_material.set_shader_parameter("layer_intensity", _current_intensity)
			_material.set_shader_parameter("ripple_time", -1.0)
	)


func play_break() -> void:
	if _sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
	)
