extends Control

const MODE_NAMES = ["混乱模式", "普通模式"]
var _selected_mode: int = 0
var _mode_label: Label

func _ready() -> void:
	_build_mode_selector()
	$CenterContainer/StartButton.pressed.connect(_on_start_pressed)

func _build_mode_selector() -> void:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "游戏模式"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	vbox.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)

	var left_btn := Button.new()
	left_btn.text = "<"
	left_btn.custom_minimum_size = Vector2(48, 48)
	left_btn.add_theme_font_size_override("font_size", 28)
	left_btn.pressed.connect(_on_left_pressed)

	_mode_label = Label.new()
	_mode_label.custom_minimum_size = Vector2(200, 48)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mode_label.add_theme_font_size_override("font_size", 28)
	_mode_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))

	var right_btn := Button.new()
	right_btn.text = ">"
	right_btn.custom_minimum_size = Vector2(48, 48)
	right_btn.add_theme_font_size_override("font_size", 28)
	right_btn.pressed.connect(_on_right_pressed)

	hbox.add_child(left_btn)
	hbox.add_child(_mode_label)
	hbox.add_child(right_btn)
	vbox.add_child(hbox)

	var center = $CenterContainer
	center.add_child(vbox)
	center.move_child(vbox, 1)  # Logo(0) → ModeSelector(1) → StartButton(2)

	_update_mode_label()

func _on_left_pressed() -> void:
	_selected_mode = (_selected_mode - 1 + MODE_NAMES.size()) % MODE_NAMES.size()
	_update_mode_label()

func _on_right_pressed() -> void:
	_selected_mode = (_selected_mode + 1) % MODE_NAMES.size()
	_update_mode_label()

func _update_mode_label() -> void:
	_mode_label.text = MODE_NAMES[_selected_mode]

func _on_start_pressed() -> void:
	GameState.game_mode = GameState.GameMode.CHAOS if _selected_mode == 0 else GameState.GameMode.NORMAL
	get_tree().change_scene_to_file("res://main.tscn")
