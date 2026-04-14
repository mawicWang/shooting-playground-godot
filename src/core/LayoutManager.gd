extends Node

## LayoutManager.gd - 响应式布局管理
## 负责处理窗口大小变化和 UI 布局计算

const MAX_WIDTH := 720.0

var _game_content: Control
var _panel: Control
var _center: Control
var _removal: Control

func setup(game_content: Control):
	_game_content = game_content
	_panel = game_content.get_node("PanelContainer")
	_center = game_content.get_node("CenterContainer")
	_removal = game_content.get_node("RemovalZonePanel")
	
	# 监听窗口大小变化
	game_content.get_tree().root.size_changed.connect(_on_window_resize)
	_on_window_resize()

func _on_window_resize():
	var window_size = _game_content.get_viewport_rect().size
	var target_width = min(window_size.x, MAX_WIDTH)
	var margin_left = (window_size.x - target_width) / 2
	var margin_right = margin_left
	
	_apply_margins(_panel, margin_left, margin_right)
	_apply_margins(_center, margin_left, margin_right)
	_apply_margins(_removal, margin_left, margin_right)

func _apply_margins(control: Control, left: float, right: float):
	control.anchor_left = 0.0
	control.anchor_right = 1.0
	control.offset_left = left
	control.offset_right = -right
