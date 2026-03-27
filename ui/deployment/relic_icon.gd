# relic_icon.gd
# 可点击的遗物图标，点击切换激活/停用
# 激活时不透明，停用时半透明
extends TextureRect

@export var relic_res_path: String = ""

var relic: Relic = null
var _active: bool = false

func _ready() -> void:
	if relic_res_path != "":
		relic = load(relic_res_path) as Relic
	_update_visual()
	if relic:
		tooltip_text = "%s\n%s" % [relic.relic_name, relic.description]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if relic:
			_toggle()
			accept_event()

func _toggle() -> void:
	_active = not _active
	if _active:
		EventManager.register_relic(relic)
	else:
		EventManager.unregister_relic(relic)
	_update_visual()

func _update_visual() -> void:
	modulate.a = 1.0 if _active else 0.35
