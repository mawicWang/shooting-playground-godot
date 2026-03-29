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
	if not (typeof(data) == TYPE_DICTIONARY and
			data.has("is_moving") and data.is_moving and
			data.has("tower_instance") and data.has("source_cell")):
		return false

	var source_icon = data.get("source_icon", null)
	if is_instance_valid(source_icon) and not ("is_staging" in source_icon and source_icon.is_staging):
		# 储备区的炮塔：只有储备未满才能回收
		return not GameState.is_tower_reserve_full()
	# 无 source_icon（初始炮塔、暂存区直接部署）= 允许永久删除
	return true

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

		# 退还塔上安装的所有模块图标
		if is_instance_valid(tower) and "modules" in tower:
			for mod in tower.modules:
				var mod_src_icon = mod.get_meta("source_icon", null) if mod.has_meta("source_icon") else null
				if is_instance_valid(mod_src_icon) and mod_src_icon.has_method("mark_returned"):
					mod_src_icon.mark_returned()

		if is_instance_valid(tower):
			tower.queue_free()

		# 有储备图标 → 回收到储备区；无图标 → 永久删除（如初始炮塔）
		if is_instance_valid(source_icon) and source_icon.has_method("mark_returned"):
			source_icon.mark_returned()

		DragManager.end_drag()
	else:
		printerr("Drop data invalid for removal zone.")
		DragManager.end_drag()
