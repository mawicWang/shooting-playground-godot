# cell.gd
extends PanelContainer

const COLOR_NORMAL = Color("#F2EAE0")       # 默认色
const COLOR_OCCUPIED = Color(0, 0.7, 0, 0.8) # 已放置炮塔的绿色
const COLOR_VALID = Color(0, 1, 0, 0.5)      # 拖拽可放置的高亮（半透明绿）
const COLOR_INVALID = Color(1, 0, 0, 0.5)    # 拖拽不可放置的高亮（半透明红）

var is_occupied = false
var is_drag_active = false
var is_being_dragged_from = false # 标记是否是当前拖拽的发源地
var style_box: StyleBoxFlat
var tower_node: Node = null 

func _ready():
	style_box = StyleBoxFlat.new()
	style_box.bg_color = COLOR_NORMAL
	style_box.set_border_width_all(5)
	style_box.border_color = Color.BLACK
	style_box.anti_aliasing = true
	add_theme_stylebox_override("panel", style_box)

func _notification(what):
	match what:
		NOTIFICATION_DRAG_BEGIN:
			is_drag_active = true
		NOTIFICATION_DRAG_END:
			is_drag_active = false
			is_being_dragged_from = false # 结束时重置
			if is_occupied and tower_node:
				tower_node.visible = true
			call_deferred("_update_visuals")

func _process(_delta):
	_update_visuals()

func _update_visuals():
	if is_drag_active:
		if get_global_rect().has_point(get_global_mouse_position()):
			# 如果是空格子，或者虽然有炮塔但正是我自己抓出来的那个，就显示绿色
			if not is_occupied or is_being_dragged_from:
				style_box.bg_color = COLOR_VALID
			else:
				style_box.bg_color = COLOR_INVALID
		else:
			style_box.bg_color = COLOR_OCCUPIED if is_occupied else COLOR_NORMAL
	else:
		style_box.bg_color = COLOR_OCCUPIED if is_occupied else COLOR_NORMAL

# --- 接收拖拽 ---

func _can_drop_data(_at_position, data):
	var can_drop = typeof(data) == TYPE_DICTIONARY and data.has("scene")
	# 允许条件：1. 没被占用 2. 或者是从自己这里拖出来的（放回原位）
	return can_drop and (not is_occupied or is_being_dragged_from)

func _drop_data(_at_position, data):
	var tower
	if data.has("is_moving") and data.is_moving:
		tower = data.tower_instance
		# 如果是移动到新位置，先清理旧位置的引用
		if tower.get_parent():
			var old_cell = tower.get_parent()
			if old_cell.has_method("remove_tower_reference"):
				old_cell.remove_tower_reference()
			old_cell.remove_child(tower)
	else:
		var tower_scene = data["scene"]
		tower = tower_scene.instantiate()
	
	add_child(tower)
	_setup_tower_visuals(tower)
	
	is_occupied = true
	tower_node = tower
	is_being_dragged_from = false # 放置成功，清除标记
	_update_visuals()

func _setup_tower_visuals(tower):
	tower.visible = true # 确保可见
	if tower is Node2D:
		tower.position = size / 2
		var sprite = tower if tower is Sprite2D else tower.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			var tex_size = sprite.texture.get_size()
			var target_size = size * 0.8
			var scale_f = min(target_size.x / tex_size.x, target_size.y / tex_size.y)
			tower.scale = Vector2(scale_f, scale_f)
	elif tower is Control:
		tower.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		tower.custom_minimum_size = size * 0.8

# --- 发起拖拽 ---

func _get_drag_data(_at_position):
	if not is_occupied or tower_node == null:
		return null
	
	is_being_dragged_from = true # 标记为发源地
	
	var data = {
		"is_moving": true,
		"tower_instance": tower_node,
		"scene": load("res://tower.tscn"), 
		"source_cell": self
	}
	
	var drag_preview = Control.new()
	var preview_sprite = TextureRect.new()
	var sprite = tower_node if tower_node is Sprite2D else tower_node.get_node_or_null("Sprite2D")
	if sprite and sprite.texture:
		preview_sprite.texture = sprite.texture
	
	preview_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	preview_sprite.custom_minimum_size = Vector2(60, 60)
	preview_sprite.modulate.a = 0.6
	preview_sprite.position = -Vector2(30, 30)
	drag_preview.add_child(preview_sprite)
	
	set_drag_preview(drag_preview)
	tower_node.visible = false
	
	return data

func remove_tower_reference():
	is_occupied = false
	tower_node = null
	is_being_dragged_from = false
