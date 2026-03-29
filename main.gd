extends Control

## main.gd - 游戏主入口
## 职责：初始化所有管理器，协调高层逻辑

const GameOverPopupScene := preload("res://ui/popups/game_over_popup.tscn")
const RewardPopupScript := preload("res://ui/popups/reward_popup.gd")
const LayoutManager := preload("res://core/LayoutManager.gd")
const GameLoopManager := preload("res://core/GameLoopManager.gd")
const EffectManager := preload("res://core/EffectManager.gd")
const SimpleEmitterData := preload("res://resources/simple_emitter.tres")
const Replenish1Data := preload("res://resources/module_data/replenish1.tres")
const TowerIconScript := preload("res://ui/deployment/tower_icon.gd")
const ModuleStackIconScript := preload("res://ui/deployment/module_stack_icon.gd")
const TowerReserveBarScript := preload("res://ui/deployment/tower_reserve_bar.gd")

# 开发者模式用：全量炮塔 & 模块资源
const _DEV_ALL_TOWERS := [
	preload("res://resources/simple_emitter.tres"),
	preload("res://resources/tower1010.tres"),
	preload("res://resources/tower1100.tres"),
	preload("res://resources/tower1110.tres"),
	preload("res://resources/tower1111.tres"),
]
const _DEV_ALL_MODULES := [
	preload("res://resources/module_data/accelerator.tres"),
	preload("res://resources/module_data/multiplier.tres"),
	preload("res://resources/module_data/rate_boost.tres"),
	preload("res://resources/module_data/replenish1.tres"),
	preload("res://resources/module_data/replenish2.tres"),
	preload("res://resources/module_data/heavy_ammo.tres"),
	preload("res://resources/module_data/cd_on_hit_enemy.tres"),
	preload("res://resources/module_data/cd_on_hit_tower_self.tres"),
	preload("res://resources/module_data/cd_on_hit_tower_target.tres"),
	preload("res://resources/module_data/cd_on_receive_hit.tres"),
]

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
var _lives_label: Label
var _coin_label: Label
var _debug_stop_button: Button

# 储备区
var _tower_reserve: HBoxContainer   # 炮塔行，最多 5 个，附 TowerReserveBarScript
var _module_reserve: HBoxContainer  # 模块行，叠加显示

# 暂存区（储备满时的溢出，左侧显示）
var _staging_panel: PanelContainer
var _staging_content: HBoxContainer
var _staging_icon: Node = null  # 当前暂存的图标节点（最多 1 个）

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
	SignalBus.lives_changed.connect(_on_lives_changed)
	SignalBus.light_shake_requested.connect(_on_light_shake_requested)

func _setup_ui():
	start_stop_button.pressed.connect(_on_start_stop_pressed)

	# 隐藏原商店
	_tower_row.visible = false
	_module_row.visible = false

	if GameState.is_dev_mode():
		_setup_dev_panel()
	else:
		_setup_normal_panel()

	# ── 暂存区（左侧，初始隐藏）──
	_create_staging_panel()

	# ── 生命值显示 ──
	_lives_label = Label.new()
	_lives_label.text = _build_lives_text(GameState.MAX_LIVES)
	_lives_label.layout_mode = 1
	_lives_label.anchor_left = 0.0
	_lives_label.anchor_right = 0.0
	_lives_label.anchor_top = 0.0
	_lives_label.anchor_bottom = 0.0
	_lives_label.offset_left = 10.0
	_lives_label.offset_top = 10.0
	_lives_label.offset_right = 180.0
	_lives_label.offset_bottom = 36.0
	_lives_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
	_lives_label.add_theme_font_size_override("font_size", 24)
	add_child(_lives_label)

	# ── 金币显示 ──
	_coin_label = Label.new()
	_coin_label.text = "金币: 0"
	_coin_label.layout_mode = 1
	_coin_label.anchor_left = 0.0
	_coin_label.anchor_right = 0.0
	_coin_label.anchor_top = 0.0
	_coin_label.anchor_bottom = 0.0
	_coin_label.offset_left = 10.0
	_coin_label.offset_top = 46.0
	_coin_label.offset_right = 180.0
	_coin_label.offset_bottom = 72.0
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_coin_label.add_theme_font_size_override("font_size", 24)
	add_child(_coin_label)

	# ── 调试停止按钮 ──
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

# ── 普通储备面板 ───────────────────────────────────────────────

func _setup_normal_panel() -> void:
	# ── 炮塔储备行（最多 5 格，可接受暂存 drop）──
	var tower_wrapper := HBoxContainer.new()
	tower_wrapper.name = "TowerWrapper"
	tower_wrapper.custom_minimum_size = Vector2(0, 80)
	tower_wrapper.add_theme_constant_override("separation", 8)
	tower_wrapper.add_child(_make_section_label("炮\n塔", Vector2(18, 100), 14, Color(0.9, 0.9, 0.9)))
	_tower_reserve = HBoxContainer.new()
	_tower_reserve.name = "TowerReserve"
	_tower_reserve.set_script(TowerReserveBarScript)
	_tower_reserve.add_theme_constant_override("separation", 8)
	_tower_reserve.staging_tower_received.connect(_on_staging_tower_to_reserve)
	tower_wrapper.add_child(_tower_reserve)
	_deployment_vbox.add_child(tower_wrapper)
	_deployment_vbox.move_child(tower_wrapper, 0)

	# ── 分割线 ──
	var row_separator := HSeparator.new()
	row_separator.modulate = Color(0.8, 0.8, 0.8, 0.5)
	_deployment_vbox.add_child(row_separator)
	_deployment_vbox.move_child(row_separator, 1)

	# ── 模块储备行（叠加显示，无上限）──
	var module_wrapper := HBoxContainer.new()
	module_wrapper.name = "ModuleWrapper"
	module_wrapper.custom_minimum_size = Vector2(0, 80)
	module_wrapper.add_theme_constant_override("separation", 8)
	module_wrapper.add_child(_make_section_label("模\n块", Vector2(18, 80), 14, Color(0.9, 0.9, 0.9)))
	_module_reserve = HBoxContainer.new()
	_module_reserve.name = "ModuleReserve"
	_module_reserve.add_theme_constant_override("separation", 8)
	module_wrapper.add_child(_module_reserve)
	_deployment_vbox.add_child(module_wrapper)
	_deployment_vbox.move_child(module_wrapper, 2)

# ── 开发者模式面板（横向滚动，全量炮塔+模块）──────────────────

func _setup_dev_panel() -> void:
	# 顶部标题栏
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var dev_label := Label.new()
	dev_label.text = "⚡ 开发者模式  ·  无限金币  ·  不掉血"
	dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dev_label.add_theme_font_size_override("font_size", 13)
	dev_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
	title_row.add_child(dev_label)
	_deployment_vbox.add_child(title_row)
	_deployment_vbox.move_child(title_row, 0)

	# 横向滚动容器
	var scroll := ScrollContainer.new()
	scroll.name = "DevScrollContainer"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 115)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deployment_vbox.add_child(scroll)
	_deployment_vbox.move_child(scroll, 1)

	var hbox := HBoxContainer.new()
	hbox.name = "DevItemContainer"
	hbox.add_theme_constant_override("separation", 6)
	# 高度撑满滚动区
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(hbox)

	# ── 炮塔区 ──
	hbox.add_child(_make_section_label("炮\n塔", Vector2(16, 0), 13, Color(0.8, 0.8, 0.8)))

	for tower_data in _DEV_ALL_TOWERS:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(80, 110)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.set_script(TowerIconScript)
		icon.tower_data = tower_data
		icon.entity_id = -1  # 每次拖拽动态生成
		hbox.add_child(icon)

	# ── 分隔线 ──
	var vsep := VSeparator.new()
	vsep.custom_minimum_size = Vector2(8, 0)
	vsep.modulate = Color(0.8, 0.8, 0.8, 0.5)
	hbox.add_child(vsep)

	# ── 模块区 ──
	hbox.add_child(_make_section_label("模\n块", Vector2(16, 0), 13, Color(0.8, 0.8, 0.8)))

	for mod_data in _DEV_ALL_MODULES:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(60, 60)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_script(ModuleStackIconScript)
		icon.module_data = mod_data
		icon.count = 1
		hbox.add_child(icon)

func _make_section_label(text: String, min_size: Vector2, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = min_size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

# ── 暂存区创建 ─────────────────────────────────────────────────

func _create_staging_panel() -> void:
	_staging_panel = PanelContainer.new()
	_staging_panel.name = "StagingPanel"
	_staging_panel.layout_mode = 1
	_staging_panel.anchor_left = 0.0
	_staging_panel.anchor_right = 0.0
	_staging_panel.anchor_top = 1.0
	_staging_panel.anchor_bottom = 1.0
	_staging_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_staging_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_staging_panel.offset_left = 5
	_staging_panel.offset_right = 100
	_staging_panel.offset_top = -270
	_staging_panel.offset_bottom = -170
	_staging_panel.visible = false

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = "待处理"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	vbox.add_child(label)

	_staging_content = HBoxContainer.new()
	_staging_content.name = "StagingContent"
	vbox.add_child(_staging_content)

	_staging_panel.add_child(vbox)
	game_content.add_child(_staging_panel)

# ── 初始炮塔放置 ──────────────────────────────────────────────

func _prepare_game():
	_game_loop.prepare_enemy_warnings()
	if GameState.is_dev_mode():
		GameState.add_coins(99999)
		return
	call_deferred("_try_place_initial_tower")

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
	if not (is_instance_valid(center_cell) and not center_cell.is_occupied):
		return

	# 在储备区创建对应图标（先加入树，_ready 后再 mark_deployed）
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.set_script(TowerIconScript)
	icon.tower_data = SimpleEmitterData
	icon.entity_id = GameState.generate_entity_id()
	_tower_reserve.add_child(icon)
	GameState.tower_reserve_count += 1  # 先计入

	# 直接部署到格子
	center_cell.place_tower_data(SimpleEmitterData, 0)

	# 将格子上的炮塔与储备图标绑定，并隐藏图标（会再减 1 count）
	var tower = center_cell.get_deployed_tower()
	if is_instance_valid(tower):
		tower.entity_id = icon.entity_id
		tower.source_icon = icon
		icon.mark_deployed(tower)

	# 初始模块储备：一个补充1
	_add_to_module_reserve(Replenish1Data)

# ── 奖励添加 ──────────────────────────────────────────────────

func _on_reward_chosen(reward: Resource):
	_add_reward_to_hand(reward)
	_game_loop.prepare_enemy_warnings()
	_update_button_style()

func _add_reward_to_hand(reward: Resource) -> void:
	if reward is TowerData:
		if GameState.is_tower_reserve_full():
			_add_to_staging(reward, GameState.generate_entity_id())
		else:
			_add_to_tower_reserve(reward, GameState.generate_entity_id())
	elif reward is Module:
		_add_to_module_reserve(reward)

func _add_to_tower_reserve(tower_data: TowerData, eid: int) -> void:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.set_script(TowerIconScript)
	icon.tower_data = tower_data
	icon.entity_id = eid
	_tower_reserve.add_child(icon)
	GameState.tower_reserve_count += 1
	_update_button_style()

func _add_to_staging(tower_data: TowerData, eid: int) -> void:
	# 暂存区只有一格，理论上调用时不应已有暂存
	if is_instance_valid(_staging_icon):
		return
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.set_script(TowerIconScript)
	icon.tower_data = tower_data
	icon.entity_id = eid
	icon.is_staging = true
	icon._on_state_changed = func(): _on_staging_state_changed()
	_staging_content.add_child(icon)
	_staging_icon = icon
	_staging_panel.visible = true
	_update_button_style()

func _add_to_module_reserve(mod: Module) -> void:
	# 查找同类型叠加图标（按 resource_path）
	var res_path := mod.resource_path
	for child in _module_reserve.get_children():
		if child.get("module_data") and child.module_data.resource_path == res_path:
			child.count += 1
			child.visible = true
			child.set_drag_enabled(true)
			child._update_count_label()
			return
	# 新建叠加图标
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(60, 60)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_script(ModuleStackIconScript)
	icon.module_data = mod
	icon.count = 1
	_module_reserve.add_child(icon)

# ── 暂存区事件 ────────────────────────────────────────────────

## 暂存图标部署到战场或被隐藏后触发
func _on_staging_state_changed() -> void:
	if not is_instance_valid(_staging_icon) or not _staging_icon.visible:
		_staging_panel.visible = false
		_staging_icon = null
	_update_button_style()

## 暂存图标被拖入储备区
func _on_staging_tower_to_reserve(tower_data: Resource, eid: int, old_icon: Node) -> void:
	if is_instance_valid(old_icon):
		old_icon.queue_free()
	_staging_icon = null
	_staging_panel.visible = false
	_add_to_tower_reserve(tower_data, eid)
	_update_button_style()

# ── 失败弹窗关闭 → 完整重置 ──────────────────────────────────

func _on_popup_closed():
	GameState.reset_to_deployment()
	_game_loop.reset_wave()
	GameState.reset_coins()
	GameState.reset_lives()
	_clear_all_towers_from_grid()
	_clear_reward_items()
	_effect_manager.reset_position()
	if GameState.is_dev_mode():
		GameState.add_coins(99999)
	else:
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

func _clear_reward_items() -> void:
	for child in _tower_reserve.get_children():
		child.queue_free()
	for child in _module_reserve.get_children():
		child.queue_free()
	if is_instance_valid(_staging_icon):
		_staging_icon.queue_free()
	_staging_icon = null
	_staging_panel.visible = false
	GameState.reset_reserve_count()

# ── 按钮事件 ──────────────────────────────────────────────────

func _on_start_stop_pressed():
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
	# GAME_OVER 路径：shake 即将由 _on_enemy_breached 启动，不提前 reset
	if not GameState.is_game_over() and not _effect_manager.is_shaking():
		_effect_manager.reset_position()
	_update_button_style()

func _on_light_shake_requested():
	_effect_manager.trigger_light_shake()

# ── 敌人突破 → 扣生命，归零才 Game Over ─────────────────────

func _on_enemy_breached():
	if not GameState.is_running():
		return
	var game_over := GameState.lose_life()
	_effect_manager.trigger_screen_shake()
	if game_over:
		# lose_life() 已将状态切换为 GAME_OVER 并同步发出 game_stopped（触发清理）
		# 此后任何事件处理器检查 is_running() 都返回 false，不会再误触发
		await _effect_manager.shake_finished
		_game_over_popup.show_defeat()

# ── 波次完成 → 奖励选择 ──────────────────────────────────────

func _on_all_enemies_defeated():
	if not GameState.is_running():
		return
	_game_loop.stop_game()
	# 若正在抖动（说明有敌人刚突破），等抖完再弹奖励，避免 popup 盖住 shake
	if _effect_manager.is_shaking():
		await _effect_manager.shake_finished
	if GameState.is_dev_mode():
		# 开发者模式跳过奖励弹窗，直接返回部署阶段
		_game_loop.prepare_enemy_warnings()
		_update_button_style()
		return
	_reward_popup.show_rewards()

# ── 金币显示 ──────────────────────────────────────────────────

func _on_coins_changed(total: int):
	if is_instance_valid(_coin_label):
		_coin_label.text = "金币: " + str(total)

# ── 生命值显示 ────────────────────────────────────────────────

func _on_lives_changed(remaining: int):
	if is_instance_valid(_lives_label):
		_lives_label.text = _build_lives_text(remaining)

func _build_lives_text(lives: int) -> String:
	return "生命: " + "♥ ".repeat(lives).strip_edges()

# ── 弹窗创建 ──────────────────────────────────────────────────

func _create_game_over_popup():
	var popup_layer = CanvasLayer.new()
	popup_layer.layer = 101
	add_child(popup_layer)
	_game_over_popup = GameOverPopupScene.instantiate()
	_game_over_popup.popup_closed.connect(_on_popup_closed)
	popup_layer.add_child(_game_over_popup)

func _create_reward_popup():
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
	start_stop_button.visible = not is_running
	if not is_running:
		var has_staging: bool = is_instance_valid(_staging_icon) and _staging_icon.visible
		start_stop_button.disabled = has_staging
		var next_wave = _game_loop.get_current_wave() + 1
		start_stop_button.text = "开始第" + str(next_wave) + "关"
		var style = _create_button_style(has_staging)
		start_stop_button.add_theme_stylebox_override("normal", style.normal)
		start_stop_button.add_theme_stylebox_override("hover", style.hover)
		start_stop_button.add_theme_stylebox_override("pressed", style.pressed)

func _create_button_style(greyed: bool = false) -> Dictionary:
	var base = StyleBoxFlat.new()
	base.border_width_left = 2
	base.border_width_top = 2
	base.border_width_right = 2
	base.border_width_bottom = 2
	base.border_color = Color.BLACK
	base.bg_color = Color(0.5, 0.5, 0.5) if greyed else Color(0.2, 0.8, 0.2)

	var hover = base.duplicate()
	hover.bg_color = base.bg_color.lightened(0.1)

	var pressed = base.duplicate()
	pressed.bg_color = base.bg_color.darkened(0.1)

	return {"normal": base, "hover": hover, "pressed": pressed}
