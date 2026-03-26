extends Control

## main.gd - 游戏主入口
## 职责：初始化所有管理器，协调高层逻辑

const GameOverPopupScene := preload("res://ui/popups/game_over_popup.tscn")
const LayoutManager := preload("res://core/LayoutManager.gd")
const GameLoopManager := preload("res://core/GameLoopManager.gd")
const EffectManager := preload("res://core/EffectManager.gd")

@onready var game_content = $GameContent
@onready var start_stop_button = $GameContent/PanelContainer/StartStopButton
@onready var grid_root = $GameContent/CenterContainer/GridRoot
@onready var grid_container = $GameContent/CenterContainer/GridRoot/Grid

var _layout_manager: LayoutManager
var _game_loop: GameLoopManager
var _effect_manager: EffectManager
var _game_over_popup: Control

func _ready():
	_setup_managers()
	_setup_signals()
	_setup_ui()
	
	# 延迟准备敌人警告
	call_deferred("_prepare_game")

func _setup_managers():
	_layout_manager = LayoutManager.new()
	_layout_manager.setup(game_content)
	add_child(_layout_manager)
	
	_game_loop = GameLoopManager.new()
	_game_loop.setup(grid_container)
	_game_loop.all_enemies_defeated.connect(_on_all_enemies_defeated)
	add_child(_game_loop)
	
	_effect_manager = EffectManager.new()
	_effect_manager.setup(game_content)
	add_child(_effect_manager)

func _setup_signals():
	SignalBus.game_started.connect(_on_game_started)
	SignalBus.game_stopped.connect(_on_game_stopped)
	SignalBus.enemy_reached_grid.connect(_on_enemy_breached)
	
	# 连接 cell 信号到 SignalBus
	for cell in grid_container.get_children():
		if cell.has_signal("tower_deployed"):
			cell.tower_deployed.connect(_on_tower_deployed)
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower):
				_on_tower_deployed(tower)

func _setup_ui():
	start_stop_button.pressed.connect(_on_start_stop_pressed)
	_update_button_style()
	_create_game_over_popup()

func _prepare_game():
	_game_loop._prepare_enemy_warnings()

func _on_start_stop_pressed():
	if GameState.is_running():
		_game_loop.stop_game()
	else:
		_game_loop.start_game()
	_update_button_style()

func _on_game_started():
	_update_button_style()

func _on_game_stopped():
	_effect_manager.reset_position()
	_update_button_style()

func _on_tower_deployed(tower: Node):
	if not is_instance_valid(tower):
		return
	if GameState.is_running() and tower.has_method("start_firing"):
		tower.start_firing()
	elif tower.has_method("stop_firing"):
		tower.stop_firing()

func _on_enemy_breached():
	_game_loop.on_enemy_breached_grid()
	if not _effect_manager.is_shaking():
		_effect_manager.trigger_screen_shake()

func _on_all_enemies_defeated():
	# 等待屏幕抖动完成
	while _effect_manager.is_shaking():
		await get_tree().process_frame
	
	if not GameState.is_running():
		return
	
	# 显示结果
	if _game_loop.has_enemy_breached():
		_game_over_popup.show_defeat()
	else:
		_game_over_popup.show_victory()
	
	_game_loop.stop_game()
	_update_button_style()

func _create_game_over_popup():
	_game_over_popup = GameOverPopupScene.instantiate()
	_game_over_popup.popup_closed.connect(_on_popup_closed)
	add_child(_game_over_popup)

func _on_popup_closed():
	_game_loop.reset_breach_status()
	_game_loop.stop_game()
	_effect_manager.reset_position()
	_game_loop._prepare_enemy_warnings()
	_update_button_style()

func _update_button_style():
	var is_running = GameState.is_running()
	start_stop_button.text = "停止" if is_running else "开始"
	
	var style = _create_button_style(is_running)
	start_stop_button.add_theme_stylebox_override("normal", style.normal)
	start_stop_button.add_theme_stylebox_override("hover", style.hover)
	start_stop_button.add_theme_stylebox_override("pressed", style.pressed)

func _create_button_style(is_running: bool) -> Dictionary:
	var base = StyleBoxFlat.new()
	base.border_width_left = 2
	base.border_width_top = 2
	base.border_width_right = 2
	base.border_width_bottom = 2
	base.border_color = Color.BLACK
	base.bg_color = Color(0.9, 0.2, 0.2) if is_running else Color(0.2, 0.8, 0.2)
	
	var hover = base.duplicate()
	hover.bg_color = base.bg_color.lightened(0.1)
	
	var pressed = base.duplicate()
	pressed.bg_color = base.bg_color.darkened(0.1)
	
	return {"normal": base, "hover": hover, "pressed": pressed}
