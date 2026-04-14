extends Control

## settings.gd - 游戏设置页面
## 使用 ConfigFile 持久化保存设置

signal settings_closed

const SETTINGS_PATH := "user://settings.cfg"

# 设置项
var master_volume: float = 1.0
var fullscreen: bool = false
var show_fps: bool = true

@onready var master_slider = $Panel/VBoxContainer/AudioSection/MasterRow/MasterSlider
@onready var fullscreen_check = $Panel/VBoxContainer/VideoSection/FullscreenCheck
@onready var fps_check = $Panel/VBoxContainer/GameSection/FpsCheck
@onready var back_button = $Panel/VBoxContainer/BackButton

func _ready() -> void:
	_load_settings()
	_setup_ui()
	_apply_settings()
	
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fps_check.toggled.connect(_on_fps_toggled)

func _setup_ui() -> void:
	master_slider.value = master_volume
	fullscreen_check.button_pressed = fullscreen
	fps_check.button_pressed = show_fps

# ── 设置变更处理 ─────────────────────────────────────────────

func _on_master_changed(value: float) -> void:
	master_volume = value
	_apply_audio_settings()
	_save_settings()

func _on_fullscreen_toggled(pressed: bool) -> void:
	fullscreen = pressed
	_apply_video_settings()
	_save_settings()

func _on_fps_toggled(pressed: bool) -> void:
	show_fps = pressed
	_save_settings()

# ── 应用设置 ─────────────────────────────────────────────────

func _apply_settings() -> void:
	_apply_audio_settings()
	_apply_video_settings()

func _apply_audio_settings() -> void:
	# 设置主音量（线性转dB）
	var master_db = linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)

func _apply_video_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# ── 持久化存储 ───────────────────────────────────────────────

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("game", "show_fps", show_fps)
	config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return  # 首次运行，使用默认值
	
	master_volume = config.get_value("audio", "master_volume", 1.0)
	fullscreen = config.get_value("video", "fullscreen", false)
	show_fps = config.get_value("game", "show_fps", true)

# ── 返回按钮 ─────────────────────────────────────────────────

func _on_back_pressed() -> void:
	settings_closed.emit()
	get_tree().change_scene_to_file("res://src/ui/start_menu/start_menu.tscn")
