# relic_icon.gd
# 可点击的遗物图标，点击切换激活/停用
# 激活时不透明，停用时半透明
extends Panel

@export var relic_res_path: String = ""

var relic: Relic = null
var _active: bool = false
var _label: Label

const COLOR_ACTIVE := Color(0.75, 0.1, 0.1, 1.0)
const COLOR_INACTIVE := Color(0.4, 0.08, 0.08, 1.0)

func _ready() -> void:
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)

	if relic_res_path != "":
		relic = load(relic_res_path) as Relic
	if relic:
		tooltip_text = "%s\n%s" % [relic.relic_name, relic.description]
		_label.text = relic.relic_name
	_update_visual()

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
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_ACTIVE if _active else COLOR_INACTIVE
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.4, 0.4, 1.0) if _active else Color(0.6, 0.2, 0.2, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)
	modulate.a = 1.0 if _active else 0.5
