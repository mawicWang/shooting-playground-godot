# removal_zone.gd
extends PanelContainer

var drop_enabled = true

func set_drag_enabled(enabled: bool):
	drop_enabled = enabled
	# Visual feedback
	modulate.a = 1.0 if enabled else 0.5

func _can_drop_data(_at_position, data):
	if not drop_enabled:
		return false
	
	# Allow dropping if:
	# 1. It's a valid tower drag (dict with "is_moving": true, "tower_instance", "source_cell")
	return (typeof(data) == TYPE_DICTIONARY and 
		data.has("is_moving") and data.is_moving and
		data.has("tower_instance") and 
		data.has("source_cell"))

func _drop_data(_at_position, data):
	if data.has("tower_instance") and data.has("source_cell"):
		var tower = data.tower_instance
		var source_cell = data.get("source_cell", null)
		var source_icon = data.get("source_icon", null)

		# 从格子中移除炮塔节点和引用
		if is_instance_valid(source_cell) and source_cell.has_method("remove_tower_reference"):
			source_cell.remove_tower_reference()
			if is_instance_valid(tower) and tower.get_parent() == source_cell:
				source_cell.remove_child(tower)

		if is_instance_valid(tower):
			tower.queue_free()

		# 有储备图标 → 回收到储备区；无图标 → 永久删除（如初始炮塔）
		if is_instance_valid(source_icon) and source_icon.has_method("mark_returned"):
			source_icon.mark_returned()

		DragManager.end_drag()
	else:
		printerr("Drop data invalid for removal zone.")
		DragManager.end_drag()
