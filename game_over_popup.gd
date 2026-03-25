extends Control

signal popup_closed

@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var emoji_label = $Panel/VBoxContainer/EmojiLabel
@onready var message_label = $Panel/VBoxContainer/MessageLabel
@onready var ok_button = $Panel/VBoxContainer/OKButton

func _ready():
	ok_button.pressed.connect(_on_ok_pressed)
	# 默认隐藏
	visible = false
	# 设置为即使游戏暂停也能处理
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_victory():
	title_label.text = "夯爆了！"
	title_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	emoji_label.text = "WIN!"
	message_label.text = "所有敌人都被你消灭了！"
	visible = true
	# 暂停游戏
	get_tree().paused = true

func show_defeat():
	title_label.text = "太拉了！"
	title_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	emoji_label.text = "FAIL!"
	message_label.text = "敌人突破防线，游戏结束！"
	visible = true
	# 暂停游戏
	get_tree().paused = true

func _on_ok_pressed():
	visible = false
	get_tree().paused = false
	emit_signal("popup_closed")
