extends Control

## main.gd - 游戏主入口
## 职责：初始化所有管理器，协调高层逻辑

const GameOverPopupScene := preload("res://ui/popups/game_over_popup.tscn")
const RewardPopupScript := preload("res://ui/popups/reward_popup.gd")
const LayoutManager := preload("res://core/LayoutManager.gd")
const GameLoopManager := preload("res://core/GameLoopManager.gd")
const EffectManager := preload("res://core/EffectManager.gd")
const SimpleEmitterData := preload("res://resources/simple_emitter.tres")

@onready var game_content = $GameContent
@onready var start_stop_button = $GameContent/PanelContainer/StartStopButton
@onready var grid_root = $GameContent/CenterContainer/GridRoot
@onready var grid_container = $GameContent/CenterContainer/GridRoot/Grid
@onready var _tower_row = $GameContent/RemovalZonePanel/VBoxContainer/TowerRow
@onready var _module_row = $GameContent/RemovalZonePanel/VBoxContainer/ModuleRow
@onready var _deployment_vbox = $GameContent/RemovalZonePanel/VBoxContainer

var _layout_manager: LayoutManager
var _game_loop: GameLoopManager
var _effect_manager: EffectManager
var _game_over_popup: Control
var _reward_popup: Control
var _coin_label: Label
var _debug_stop_button: Button
var _reward_row: HBoxContainer

func _ready():
	_setup_managers()
	_setup_signals()
	_setup_ui()
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
	SignalBus.coins_changed.connect(_on_coins_changed)

	# 连接 grid_root 的敌人触碰信号到 SignalBus
	if grid_root.has_signal("enemy_breached_grid"):
		grid_root.enemy_breached_grid.connect(func(): SignalBus.enemy_reached_grid.emit())

func _setup_ui():
	start_stop_button.pressed.connect(_on_start_stop_pressed)

	# 隐藏原商店（改为通过奖励系统解锁道具）
	_tower_row.visible = false
	_module_row.visible = false

	# 奖励手牌行（放在最顶部）
	_reward_row = HBoxContainer.new()
	_reward_row.name = "RewardRow"
	_reward_row.add_theme_constant_override("separation", 10)
	_deployment_vbox.add_child(_reward_row)
	_deployment_vbox.move_child(_reward_row, 0)

	# 金币显示（左侧，版本号下方）
	_coin_label = Label.new()
	_coin_label.text = "金币: 0"
	_coin_label.layout_mode = 1
	_coin_label.anchor_left = 0.0
	_coin_label.anchor_right = 0.0
	_coin_label.anchor_top = 0.0
	_coin_label.anchor_bottom = 0.0
	_coin_label.offset_left = 10.0
	_coin_label.offset_top = 35.0
	_coin_label.offset_right = 150.0
	_coin_label.offset_bottom = 58.0
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_coin_label.add_theme_font_size_override("font_size", 16)
	add_child(_coin_label)

	# 调试用停止按钮（默认隐藏）
	_debug_stop_button = Button.new()
	_debug_stop_button.text = "[调试] 停止"
	_debug_stop_button.visible = false
	_debug_stop_button.layout_mode = 1
	_debug_stop_button.anchor_left = 0.0
	_debug_stop_button.anchor_right = 0.0
	_debug_stop_button.anchor_top = 0.0
	_debug_stop_button.anchor_bottom = 0.0
	_debug_stop_button.offset_left = 10.0
	_debug_stop_button.offset_top = 60.0
	_debug_stop_button.offset_right = 130.0
	_debug_stop_button.offset_bottom = 88.0
	_debug_stop_button.pressed.connect(_on_debug_stop_pressed)
	add_child(_debug_stop_button)

	_update_button_style()
	_create_game_over_popup()
	_create_reward_popup()

func _prepare_game():
	_game_loop.prepare_enemy_warnings()
	call_deferred("_try_place_initial_tower")

# ── 初始炮塔放置 ──────────────────────────────────────────────

func _try_place_initial_tower():
	if grid_container.get_child_count() < 25:
		await get_tree().create_timer(0.05).timeout
		call_deferred("_try_place_initial_tower")
		return
	_do_place_initial_tower()

func _do_place_initial_tower():
	var cells = grid_container.get_children()
	if cells.size() < 13:
		return
	var center_cell = cells[12]  # 5×5 网格正中心（行2列2）
	if is_instance_valid(center_cell) and not center_cell.is_occupied:
		center_cell.place_tower_data(SimpleEmitterData, 0)  # 朝上

# ── 按钮事件 ──────────────────────────────────────────────────

func _on_start_stop_pressed():
	# 运行中不允许手动停止（仅允许开始）
	if not GameState.is_running():
		_game_loop.start_game()

func _on_debug_stop_pressed():
	if GameState.is_running():
		_game_loop.stop_game()
		_game_loop.prepare_enemy_warnings()

# ── 游戏状态事件 ──────────────────────────────────────────────

func _on_game_started():
	_update_button_style()

func _on_game_stopped():
	_effect_manager.reset_position()
	_update_button_style()

# ── 敌人突破 → 立即 Game Over ────────────────────────────────

func _on_enemy_breached():
	if not GameState.is_running():
		return  # 已处理过（如同帧多次触发）
	_effect_manager.trigger_screen_shake()
	_game_loop.stop_game()
	_game_over_popup.show_defeat()

# ── 波次完成 → 奖励选择 ──────────────────────────────────────

func _on_all_enemies_defeated():
	if not GameState.is_running():
		return
	_game_loop.stop_game()
	_reward_popup.show_rewards()

func _on_reward_chosen(reward: Resource):
	_add_reward_to_hand(reward)
	_game_loop.prepare_enemy_warnings()
	_update_button_style()

func _add_reward_to_hand(reward: Resource) -> void:
	if reward is TowerData:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(80, 80)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.set_script(preload("res://ui/deployment/tower_icon.gd"))
		icon.tower_data = reward
		_reward_row.add_child(icon)
	elif reward is Module:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(80, 80)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.texture = preload("res://assets/bullet.svg")
		icon.set_script(preload("res://ui/deployment/module_icon.gd"))
		icon.module_data = reward
		match reward.module_name:
			"加速器": icon.modulate = Color(0.1, 0.9, 1.0)
			"乘法器": icon.modulate = Color(1.0, 0.6, 0.1)
		_reward_row.add_child(icon)

# ── 失败弹窗关闭 → 完整重置 ──────────────────────────────────

func _on_popup_closed():
	_game_loop.reset_wave()
	GameState.reset_coins()
	_clear_all_towers_from_grid()
	_clear_reward_items()
	_effect_manager.reset_position()
	_do_place_initial_tower()
	_game_loop.prepare_enemy_warnings()
	_update_button_style()

func _clear_all_towers_from_grid():
	for cell in grid_container.get_children():
		if cell.has_method("get_deployed_tower"):
			var tower = cell.get_deployed_tower()
			if is_instance_valid(tower):
				tower.queue_free()
			if cell.has_method("remove_tower_reference"):
				cell.remove_tower_reference()

func _clear_reward_items():
	for child in _reward_row.get_children():
		child.queue_free()

# ── 金币显示 ──────────────────────────────────────────────────

func _on_coins_changed(total: int):
	if is_instance_valid(_coin_label):
		_coin_label.text = "金币: " + str(total)

# ── 弹窗创建 ──────────────────────────────────────────────────

func _create_game_over_popup():
	var popup_layer = CanvasLayer.new()
	popup_layer.layer = 101  # 比奖励弹窗(100)更高，避免层级冲突
	add_child(popup_layer)

	_game_over_popup = GameOverPopupScene.instantiate()
	_game_over_popup.popup_closed.connect(_on_popup_closed)
	popup_layer.add_child(_game_over_popup)

func _create_reward_popup():
	# 用 CanvasLayer 确保弹窗始终渲染在最上层（高于任何 z_index 设置的节点）
	var popup_layer = CanvasLayer.new()
	popup_layer.layer = 100
	add_child(popup_layer)

	_reward_popup = Control.new()
	_reward_popup.set_script(RewardPopupScript)
	popup_layer.add_child(_reward_popup)
	_reward_popup.reward_chosen.connect(_on_reward_chosen)

# ── 按钮样式 ──────────────────────────────────────────────────

func _update_button_style():
	var is_running = GameState.is_running()
	# 运行中隐藏开始按钮（不允许手动停止）
	start_stop_button.visible = not is_running
	if not is_running:
		var next_wave = _game_loop.get_current_wave() + 1
		start_stop_button.text = "开始第" + str(next_wave) + "关"
		var style = _create_button_style()
		start_stop_button.add_theme_stylebox_override("normal", style.normal)
		start_stop_button.add_theme_stylebox_override("hover", style.hover)
		start_stop_button.add_theme_stylebox_override("pressed", style.pressed)

func _create_button_style() -> Dictionary:
	var base = StyleBoxFlat.new()
	base.border_width_left = 2
	base.border_width_top = 2
	base.border_width_right = 2
	base.border_width_bottom = 2
	base.border_color = Color.BLACK
	base.bg_color = Color(0.2, 0.8, 0.2)

	var hover = base.duplicate()
	hover.bg_color = base.bg_color.lightened(0.1)

	var pressed = base.duplicate()
	pressed.bg_color = base.bg_color.darkened(0.1)

	return {"normal": base, "hover": hover, "pressed": pressed}
