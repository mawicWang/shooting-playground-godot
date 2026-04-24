class_name CharacterCard
extends PanelContainer

## Character card displayed on the character select screen.
## Emits [member card_selected] when an available character is tapped.

signal card_selected(data: CharacterData)

@export var data: CharacterData:
	set(value):
		data = value
		if is_node_ready():
			_refresh()

@onready var _avatar: TextureRect = $VBox/Avatar
@onready var _name_label: Label = $VBox/NameLabel
@onready var _tagline_label: Label = $VBox/TaglineLabel
@onready var _passive_list: VBoxContainer = $VBox/PassiveList
@onready var _coming_soon_badge: Label = $VBox/ComingSoonBadge
@onready var _check_icon: Label = $CheckIcon

var _is_selected: bool = false
var _tooltip_timer: float = 0.0
const _TOOLTIP_DURATION: float = 1.5
const _SHAKE_DURATION: float = 0.2

## Colors for the light minimalist theme.
const _COLOR_BG_AVAILABLE := Color(1.0, 1.0, 1.0, 1.0)
const _COLOR_BG_LOCKED := Color(0.91, 0.91, 0.929, 1.0)
const _COLOR_BG_SELECTED := Color(0.96, 0.97, 1.0, 1.0)
const _COLOR_BORDER_SELECTED := Color(0.0, 0.478, 1.0, 1.0)
## Tagline color for available cards — dark enough for white bg.
const _COLOR_TAGLINE := Color(0.15, 0.15, 0.17, 1.0)
const _COLOR_TEXT_LOCKED := Color(0.45, 0.45, 0.47, 1.0)

func _ready() -> void:
	_refresh()
	gui_input.connect(_on_gui_input)

func _refresh() -> void:
	if not data:
		return
	_name_label.text = data.display_name
	_tagline_label.text = data.tagline
	_passive_list.visible = data.is_available
	_coming_soon_badge.visible = not data.is_available
	if data.portrait:
		_avatar.texture = data.portrait
	if not data.is_available:
		_avatar.modulate = Color(0.5, 0.5, 0.5, 1.0)
		_name_label.add_theme_color_override("font_color", _COLOR_TEXT_LOCKED)
		_tagline_label.add_theme_color_override("font_color", _COLOR_TEXT_LOCKED)
	else:
		_avatar.modulate = Color.WHITE
		_name_label.add_theme_color_override("font_color", _COLOR_TAGLINE)
		_tagline_label.add_theme_color_override("font_color", _COLOR_TAGLINE)
	# Re-apply selected state after refresh
	if _is_selected:
		_apply_selected_style()
	else:
		_apply_normal_style()

func _apply_normal_style() -> void:
	if data and data.is_available:
		add_theme_stylebox_override("panel", _make_style(_COLOR_BG_AVAILABLE))
	else:
		add_theme_stylebox_override("panel", _make_style(_COLOR_BG_LOCKED))

func _apply_selected_style() -> void:
	add_theme_stylebox_override("panel", _make_selected_style())

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_check_icon.visible = selected
	if selected:
		_apply_selected_style()
	else:
		_apply_normal_style()

func _make_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func _make_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = _COLOR_BORDER_SELECTED
	style.bg_color = _COLOR_BG_SELECTED
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if data == null:
		return
	if data.is_available:
		card_selected.emit(data)
	else:
		_play_locked_feedback()

func _play_locked_feedback() -> void:
	if _tooltip_timer > 0.0:
		return
	_tooltip_timer = _TOOLTIP_DURATION
	_coming_soon_badge.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x - 6.0, _SHAKE_DURATION * 0.25)
	tween.tween_property(self, "position:x", position.x + 6.0, _SHAKE_DURATION * 0.5)
	tween.tween_property(self, "position:x", position.x, _SHAKE_DURATION * 0.25)

func _process(delta: float) -> void:
	if _tooltip_timer > 0.0:
		_tooltip_timer -= delta
		if _tooltip_timer <= 0.0:
			_tooltip_timer = 0.0
