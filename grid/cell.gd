# cell.gd
extends PanelContainer

const COLOR_NORMAL = Color("#F2EAE0")       # 默认色
const COLOR_OCCUPIED = Color(0, 0.7, 0, 0.8) # 已放置炮塔的绿色
const COLOR_VALID = Color(0, 1, 0, 0.5)      # 拖拽可放置的高亮（半透明绿）
const COLOR_INVALID = Color(1, 0, 0, 0.5)    # 拖拽不可放置的高亮（半透明红）
const COLOR_DISABLED = Color(0.5, 0.5, 0.5, 0.5) # 禁用状态的颜色

# Rotation constants are now defined in DragManager.gd

var is_occupied = false
var is_drag_active = false
var is_being_dragged_from = false # 标记是否是当前拖拽的发源地
var drag_rotation_offset = 0.0 # Default rotation to UP (DragManager.ROT_UP)
var drag_enabled = true # 是否允许拖拽

var style_box: StyleBoxFlat
var tower_node: Node = null

# --- 模块槽位绘制（直接绘制到 Cell Canvas，避免 PanelContainer 子节点布局冲突）---
const SLOT_COUNT: int = 4
const SLOT_W: float = 14.0
const SLOT_H: float = 14.0
const SLOT_GAP: float = 3.0
const SLOT_MARGIN_BOTTOM: float = 4.0

var _empty_slot_style: StyleBoxFlat
var _slot_filled_styles: Array = []  # 随模块安装/卸载重建

func _ready():
	add_to_group("grid_cells")
	style_box = StyleBoxFlat.new()
	style_box.bg_color = COLOR_NORMAL
	style_box.set_border_width_all(5)
	style_box.border_color = Color.BLACK
	style_box.anti_aliasing = true
	add_theme_stylebox_override("panel", style_box)
	mouse_exited.connect(self._on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_empty_slot_style = StyleBoxFlat.new()
	_empty_slot_style.bg_color = Color(0.22, 0.22, 0.22, 0.88)
	_empty_slot_style.set_corner_radius_all(3)
	_empty_slot_style.set_border_width_all(1)
	_empty_slot_style.border_color = Color(0.5, 0.5, 0.5, 0.6)

# 返回 SLOT_COUNT 个槽位的局部坐标矩形（依赖 size，需在 layout 完成后调用）
func _get_slot_rects() -> Array:
	var rects: Array = []
	var total_w = SLOT_COUNT * SLOT_W + (SLOT_COUNT - 1) * SLOT_GAP
	var start_x = (size.x - total_w) * 0.5
	var y = size.y - SLOT_H - SLOT_MARGIN_BOTTOM
	for i in range(SLOT_COUNT):
		rects.append(Rect2(start_x + i * (SLOT_W + SLOT_GAP), y, SLOT_W, SLOT_H))
	return rects

func _draw() -> void:
	if not is_occupied:
		return
	var rects = _get_slot_rects()
	for i in range(SLOT_COUNT):
		if i < _slot_filled_styles.size():
			draw_style_box(_slot_filled_styles[i], rects[i])
		else:
			draw_style_box(_empty_slot_style, rects[i])

func _refresh_slot_dots() -> void:
	_slot_filled_styles.clear()
	if is_instance_valid(tower_node) and "modules" in tower_node:
		for mod in tower_node.modules:
			var color: Color = mod.slot_color if "slot_color" in mod else Color(0.5, 0.8, 0.5)
			var s := StyleBoxFlat.new()
			s.bg_color = color
			s.set_corner_radius_all(3)
			s.set_border_width_all(1)
			s.border_color = color.lightened(0.4)
			_slot_filled_styles.append(s)
	queue_redraw()

func _on_mouse_exited():
	# Only clear if this cell was the one being hovered
	if is_instance_valid(DragManager.get_hovered_valid_cell()) and DragManager.get_hovered_valid_cell() == self:
		DragManager.clear_hovered_valid_cell()

# --- Click handling for tower rotation (bypass Area2D issues) ---

var _click_start_time: int = 0
var _is_click_valid: bool = false
const CLICK_MAX_DURATION_MS: int = 300  # Max duration for a click (vs drag)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 优先检测是否点击了已填充的槽位 → 卸载模块
			if is_occupied and is_instance_valid(tower_node) and tower_node.has_method("uninstall_module"):
				var rects = _get_slot_rects()
				for i in range(_slot_filled_styles.size()):
					if rects[i].has_point(event.position):
						_is_click_valid = false
						# 卸载前先读取 source_icon，uninstall 会移除模块实例
						var mod = tower_node.modules[i]
						var src_icon = mod.get_meta("source_icon", null) if mod.has_meta("source_icon") else null
						tower_node.uninstall_module(i)
						_refresh_slot_dots()
						if is_instance_valid(src_icon) and src_icon.has_method("mark_returned"):
							src_icon.mark_returned()
						get_viewport().set_input_as_handled()
						return
			_click_start_time = Time.get_ticks_msec()
			_is_click_valid = true
		else:
			# Button released - check if it's a valid click (not a drag)
			var click_duration = Time.get_ticks_msec() - _click_start_time
			if _is_click_valid and click_duration < CLICK_MAX_DURATION_MS and GameState.is_deployment() and is_occupied and is_instance_valid(tower_node):
				# It's a click, trigger tower rotation
				if tower_node.has_method("_rotate_90_degrees"):
					tower_node._rotate_90_degrees()
					get_viewport().set_input_as_handled()

func _notification(what):
	match what:
		NOTIFICATION_DRAG_BEGIN:
			is_drag_active = true
			# print("Drag BEGIN on cell ", get_meta("index")) # Debug log
		NOTIFICATION_DRAG_END:
			is_drag_active = false
			# print("Drag END on cell ", get_meta("index")) # Debug log
			# If drag ends, reset being_dragged_from flag
			if is_being_dragged_from:
				is_being_dragged_from = false
			# Restore visibility if tower was hidden and drag failed/cancelled
			if is_instance_valid(tower_node) and tower_node.visible == false:
				tower_node.visible = true
			
			# Ensure visual state is updated after drag ends
			call_deferred("_update_visuals")
			# Inform DragManager that drag has ended
			DragManager.end_drag()

func _process(_delta):
	# Update visuals continuously while dragging
	if is_drag_active:
		# Only update rotation if this cell is the current drag source, OR if it's the hovered target
		if is_being_dragged_from or (is_instance_valid(DragManager.get_hovered_valid_cell()) and DragManager.get_hovered_valid_cell() == self):
			_update_drag_rotation() # Calculate and update rotation
	_update_visuals() # Update background color based on state

# This method will be called by DragManager to get the current rotation
func get_current_drag_rotation() -> float:
	return drag_rotation_offset # Return directly, no correction needed

# 核心旋转计算逻辑：根据鼠标相对于目标网格中心的偏移量决定朝向
func _update_drag_rotation():
	if not is_drag_active or not is_being_dragged_from:
		return

	var mouse_pos = get_global_mouse_position()
	var target_center = get_global_center() # 默认为自身中心
	var current_source_node = DragManager.get_drag_source_node()

	# 逻辑：如果鼠标悬停在一个有效的放置格子上，则以该格子的中心作为计算原点。
	# 这样拖拽时，鼠标移向格子的上方，炮塔就向上指，符合用户直觉。
	if is_instance_valid(DragManager.get_hovered_valid_cell()) and is_instance_valid(current_source_node) and current_source_node == self:
		target_center = DragManager.get_hovered_valid_cell().get_global_center()
	elif is_instance_valid(current_source_node) and current_source_node.has_method("get_global_center"):
		target_center = current_source_node.get_global_center()
	else:
		target_center = get_global_center()

	var offset = mouse_pos - target_center
	
	var angle = DragManager.ROT_UP
	var direction_string = "UP (Default)"

	# 四象限判定逻辑（通过斜对角线分割）
	if offset.length() < 3: # 鼠标非常靠近中心，保持默认朝上
		angle = DragManager.ROT_UP
		direction_string = "UP (Near Center)"
	elif abs(offset.x) > abs(offset.y): # 水平方向偏移更大
		if offset.x > 0: # 鼠标在右侧
			angle = DragManager.ROT_RIGHT
			direction_string = "RIGHT"
		else: # 鼠标在左侧
			angle = DragManager.ROT_LEFT
			direction_string = "LEFT"
	else: # 垂直方向偏移更大（或相等）
		if offset.y > 0: # 鼠标在下方 (Godot 坐标系 Y 向下增加)
			angle = DragManager.ROT_DOWN
			direction_string = "DOWN"
		else: # 鼠标在上方
			angle = DragManager.ROT_UP
			direction_string = "UP"
	
	drag_rotation_offset = angle
	#print( "Cell ", get_meta("index"), " - Drag Rotation: ", direction_string, " (", rad_to_deg(drag_rotation_offset), " degrees)") # Debug log

# Update the cell's background color
func _update_visuals():
	if not drag_enabled:
		# When drag is disabled, show disabled color
		style_box.bg_color = COLOR_DISABLED
		return
	
	if is_drag_active:
		# When dragging, always use DragManager.get_hovered_valid_cell()'s color if valid
		if is_instance_valid(DragManager.get_hovered_valid_cell()) and DragManager.get_hovered_valid_cell() == self:
			# Mouse is over this cell and it's a valid drop target
			if not is_occupied or is_being_dragged_from:
				style_box.bg_color = COLOR_VALID
			else:
				style_box.bg_color = COLOR_INVALID
		else:
			# Drag is active, but mouse is not over this cell (or it's not a valid target)
			style_box.bg_color = COLOR_OCCUPIED if is_occupied else COLOR_NORMAL
	else:
		# No active drag, show normal state
		style_box.bg_color = COLOR_OCCUPIED if is_occupied else COLOR_NORMAL

# --- Receiving Drag (Drop) ---

# Godot 内置回调：判断是否允许放置
func _can_drop_data(_at_position, data):
	if typeof(data) != TYPE_DICTIONARY:
		return false

	# 模块拖拽：只能安装到已有炮塔的格子，且槽位未满
	if data.has("module_data"):
		if not is_occupied or not is_instance_valid(tower_node):
			return false
		var tower_max: int = tower_node.max_slots if "max_slots" in tower_node else 4
		return tower_node.get_module_count() < tower_max

	# 检查数据是否来自商店（新炮塔）或网格（移动中）
	var can_drop_from_store = data.has("tower_data") and not data.get("is_moving", false)
	var can_drop_from_grid = data.has("is_moving") and data.is_moving

	var is_valid_drop_target = false
	if can_drop_from_store:
		# 新炮塔只能放在空位
		is_valid_drop_target = not is_occupied
	elif can_drop_from_grid:
		# 移动现有炮塔可以放回原位或新的空位
		is_valid_drop_target = not is_occupied or data.get("source_cell") == self

	# 如果是有效位置，通知 DragManager 更新悬停状态，用于旋转计算
	if is_valid_drop_target:
		DragManager.set_hovered_valid_cell(self)
	else:
		if is_instance_valid(DragManager.get_hovered_valid_cell()) and DragManager.get_hovered_valid_cell() == self:
			DragManager.clear_hovered_valid_cell()

	return is_valid_drop_target

signal tower_deployed(tower_instance)

func _drop_data(_at_position, data):
	# 模块安装
	if data.has("module_data"):
		if is_instance_valid(tower_node) and tower_node.has_method("install_module"):
			if tower_node.install_module(data.module_data):
				# 将 source_icon 写入已安装的模块实例（duplicate 后的副本）
				var installed = tower_node.modules.back()
				var src_icon = data.get("source_icon", null)
				if is_instance_valid(src_icon):
					installed.set_meta("source_icon", src_icon)
					src_icon.mark_deployed()
				_refresh_slot_dots()
		return

	var tower
	var source_cell_instance = data.get("source_cell", null) # The original cell that initiated the drag

	var final_rotation = DragManager.ROT_UP # Initialize with default rotation (Up)

	if data.has("is_moving") and data.is_moving:
		# Moving an existing tower from a cell
		tower = data.tower_instance
		# Use the rotation calculated during THIS drag operation by the SOURCE cell
		if is_instance_valid(source_cell_instance):
			final_rotation = source_cell_instance.drag_rotation_offset
		else:
			# Fallback if source_cell is null, try DragManager or default
			final_rotation = DragManager.get_current_drag_rotation() 

		if is_instance_valid(source_cell_instance) and source_cell_instance != self: # Only clean up if moving from a different cell
			source_cell_instance.remove_child(tower)
			source_cell_instance.remove_tower_reference() # Remove reference from old cell
	else:
		# Dragging a new tower from the store (TowerData-driven)
		var td: TowerData = data["tower_data"]
		var tower_scene = preload("res://entities/towers/tower.tscn")
		tower = tower_scene.instantiate()
		tower.data = td
		# 绑定实体 ID 和储备区图标引用
		tower.entity_id = data.get("entity_id", -1)
		tower.source_icon = data.get("source_icon", null)
		if is_instance_valid(tower.source_icon):
			tower.source_icon.mark_deployed(tower)
		final_rotation = DragManager.get_current_drag_rotation()

	# Add the tower to this cell
	add_child(tower)
	_setup_tower_visuals(tower) # Apply position, scale, and ensure visibility

	# Update cell state
	is_occupied = true
	tower_node = tower
	is_being_dragged_from = false # Reset flag after drop

	# Emit signal after tower is fully set up
	tower_deployed.emit(tower)

	# Apply the rotation determined (no correction needed here now)
	if is_instance_valid(tower) and tower.has_method("set_initial_direction"):
		# Convert rotation radians to direction index (0=UP, 1=RIGHT, 2=DOWN, 3=LEFT)
		var direction_index = _rotation_to_direction_index(final_rotation)
		tower.set_initial_direction(direction_index)
	elif is_instance_valid(tower) and tower is Node2D:
		tower.rotation = final_rotation # Keep as fallback 

	_update_visuals() # Update cell color to occupied green
	_refresh_slot_dots()

func get_deployed_tower():
	return tower_node

## 程序化放置炮塔（绕过拖拽系统，供初始化使用）
func place_tower_data(td: TowerData, direction_index: int = 0) -> void:
	if is_occupied:
		return
	var tower_scene = preload("res://entities/towers/tower.tscn")
	var tower = tower_scene.instantiate()
	tower.data = td
	add_child(tower)
	_setup_tower_visuals(tower)
	is_occupied = true
	tower_node = tower
	tower.set_initial_direction(direction_index)
	tower_deployed.emit(tower)
	_update_visuals()
	_refresh_slot_dots()

# Helper function to convert rotation radians to direction index
func _rotation_to_direction_index(rotation_rad: float) -> int:
	# Normalize rotation to 0-2π range
	var normalized = fmod(rotation_rad + TAU, TAU)
	# Determine direction based on angle (allowing some tolerance)
	if normalized < PI / 4.0 or normalized > 7.0 * PI / 4.0:
		return 0  # UP
	elif normalized < 3.0 * PI / 4.0:
		return 1  # RIGHT
	elif normalized < 5.0 * PI / 4.0:
		return 2  # DOWN
	else:
		return 3  # LEFT


func _setup_tower_visuals(tower):
	tower.visible = true # Ensure it's visible
	if is_instance_valid(tower) and tower is Node2D:
		tower.position = size / 2
		var sprite = tower if tower is Sprite2D else tower.get_node_or_null("Sprite2D")
		if is_instance_valid(sprite) and sprite.texture:
			var tex_size = sprite.texture.get_size()
			var target_size = size * 0.8 # Use 80% of cell size
			var scale_f = min(target_size.x / tex_size.x, target_size.y / tex_size.y)
			tower.scale = Vector2(scale_f, scale_f)
	elif is_instance_valid(tower) and tower is Control:
		tower.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		tower.custom_minimum_size = size * 0.8 # Limit control size

# --- Drag Enable/Disable ---

func set_drag_enabled(enabled: bool):
	drag_enabled = enabled
	_update_visuals()

func get_drag_enabled() -> bool:
	return drag_enabled

# --- Initiating Drag (Drag) ---

func _get_drag_data(_at_position):
	if not drag_enabled:
		return null
	if not is_occupied or not is_instance_valid(tower_node):
		return null
	
	# Mark this cell as the source of the drag
	is_being_dragged_from = true
	# Reset rotation before starting a new drag
	drag_rotation_offset = DragManager.ROT_UP # Default rotation to UP when starting drag

	# Inform DragManager to start custom drag preview
	var texture_to_drag: Texture2D = null
	if is_instance_valid(tower_node) and tower_node.has_node("Sprite2D"):
		texture_to_drag = (tower_node.get_node("Sprite2D") as Sprite2D).texture
	
	if is_instance_valid(texture_to_drag):
		DragManager.start_drag(texture_to_drag, self) # Pass self as source_node
	else:
		printerr("Cell: Could not find Sprite2D texture to start drag. Aborting drag.")
		is_being_dragged_from = false # Reset flag if drag couldn't start
		return null # Cannot start drag without texture

	var data = {
		"is_moving": true,
		"tower_instance": tower_node,
		"tower_data": tower_node.data if tower_node.get("data") != null else null,
		"source_cell": self,
		"rotation": drag_rotation_offset,
		"entity_id": tower_node.entity_id if "entity_id" in tower_node else -1,
		"source_icon": tower_node.source_icon if "source_icon" in tower_node else null
	}
	
	# Temporarily hide the original tower node to simulate it being picked up
	if is_instance_valid(tower_node):
		tower_node.visible = false
	
	return data # Return data for Godot's internal drop handling

# --- Utility functions for managing cell state ---

func remove_tower_reference():
	# Called by the drop target (another cell or removal zone)
	is_occupied = false
	tower_node = null
	is_being_dragged_from = false # Reset if it was being dragged from
	drag_rotation_offset = DragManager.ROT_UP    # Reset rotation to default (UP)
	_update_visuals() # Update visuals to normal/empty state
	_refresh_slot_dots()

# Helper to get the global center of the control
func get_global_center():
	return get_global_rect().position + size / 2

# --- Handling drag failure/cancellation ---
# This is called by Godot's drag-and-drop system if the drag is cancelled
# (e.g., mouse leaves window, or Esc is pressed).
# The _notification(NOTIFICATION_DRAG_END) should handle restoring visibility.
# If more specific failure handling is needed, we might need to track state.
