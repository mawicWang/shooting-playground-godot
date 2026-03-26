extends Node

# Rotation constants (for Godot's CCW rotation, where 0 is visually UP)
const PI = 3.14159
const ROT_UP = 0.0          # Asset default direction (0 degrees)
const ROT_RIGHT = PI / 2.0 # Rotate CW 90 degrees from UP
const ROT_DOWN = PI         # Rotate 180 degrees from UP
const ROT_LEFT = -PI / 2.0   # Rotate CCW 90 degrees from UP

var _drag_preview_node: Control = null # 拖拽预览的根节点（Control 类型，便于浮动显示）
var _drag_texture_rect: TextureRect = null # 预览中的纹理显示节点
var _drag_source_node: Node = null # 拖拽发起的节点引用（cell 或 tower_icon）
var hovered_valid_cell: Node = null # 当前鼠标悬停的有效网格单元引用（用于辅助旋转计算）
var last_known_drag_rotation = ROT_UP # 存储最后一次计算得到的旋转弧度（用于在 Drop 时应用）

func _ready():
	set_process(false) # Start with process disabled

func _process(_delta):
	if _drag_preview_node and _drag_source_node:
		# 更新自定义拖拽预览的位置，使其跟随鼠标并居中
		_drag_preview_node.global_position = get_viewport().get_mouse_position() - Vector2(30, 30)
		
		# 从发起拖拽的源节点（Icon 或 Cell）获取实时的旋转偏移量
		var current_rotation = ROT_UP
		if is_instance_valid(_drag_source_node) and _drag_source_node.has_method("get_current_drag_rotation"):
			current_rotation = _drag_source_node.get_current_drag_rotation()

		# 将旋转值应用到预览纹理，并缓存最后一次已知的旋转状态
		if _drag_texture_rect:
			_drag_texture_rect.rotation = current_rotation # 弧度制
			last_known_drag_rotation = current_rotation # 缓存，供 Drop 阶段使用

## 开启拖拽流程，由源节点调用
func start_drag(texture: Texture2D, source_node: Node):
	# Clear any existing preview and reset state
	end_drag() # Ensure any previous drag is ended cleanly

	if not texture or not is_instance_valid(source_node):
		printerr("DragManager: Cannot start drag with null texture or invalid source_node.")
		return

	# print("DragManager: Starting drag from node: ", source_node.name) # Debug log

	# Create the custom drag preview node
	_drag_preview_node = Control.new()
	_drag_preview_node.name = "CustomDragPreview"
	_drag_preview_node.mouse_filter = Control.MOUSE_FILTER_IGNORE # 忽略鼠标事件，让事件穿透到下层
	
	_drag_texture_rect = TextureRect.new()
	_drag_texture_rect.texture = texture
	_drag_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # 同样忽略
	_drag_preview_node.add_child(_drag_texture_rect) # Add texture to the preview container

	# Set properties for the TextureRect preview
	_drag_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_drag_texture_rect.custom_minimum_size = Vector2(60, 60)
	_drag_texture_rect.modulate.a = 0.6
	_drag_texture_rect.pivot_offset = Vector2(30,30) # Set pivot for rotation

	# Add to the root of the scene tree (Viewport) to float above all UI
	get_viewport().add_child(_drag_preview_node)
	
	_drag_source_node = source_node # Store the node that initiated the drag
	set_process(true) # Enable _process to update preview position and rotation

func end_drag():
	if _drag_preview_node:
		_drag_preview_node.queue_free()
		_drag_preview_node = null
	if _drag_texture_rect:
		_drag_texture_rect = null # Clear texture rect reference

	_drag_source_node = null # IMPORTANT: Clear source node reference
	hovered_valid_cell = null # Clear hovered cell reference
	set_process(false) # Disable _process
	# print("DragManager: Drag ended.") # Debug log

# Public getter for the current drag rotation (delegates to source_node)
func get_current_drag_rotation() -> float:
	# Return the last known rotation, as _drag_source_node might be nullified by the time drop occurs
	return last_known_drag_rotation

func set_hovered_valid_cell(cell: Node):
	hovered_valid_cell = cell

func clear_hovered_valid_cell():
	hovered_valid_cell = null

# NEW: Get the currently hovered valid cell
func get_hovered_valid_cell() -> Node:
	return hovered_valid_cell

# NEW: Get the drag source node
func get_drag_source_node() -> Node:
	return _drag_source_node
