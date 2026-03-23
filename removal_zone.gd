# removal_zone.gd
extends PanelContainer

# 假设 PanelContainer 的样式（背景、边框）已经在编辑器中设置好。

func _can_drop_data(_at_position, data):
	# 允许放置的条件：
	# 1. 拖拽的数据是有效的字典
	# 2. 包含 "is_moving" 并且为 true (表示是从格子中拖出来的)
	# 3. 包含 "tower_instance" (炮塔节点)
	# 4. 包含 "source_cell" (炮塔的原格子)
	return (typeof(data) == TYPE_DICTIONARY and 
		data.has("is_moving") and data.is_moving and
		data.has("tower_instance") and 
		data.has("source_cell"))

func _drop_data(_at_position, data):
	if data.has("tower_instance") and data.has("source_cell"):
		var tower = data.tower_instance
		var source_cell = data.source_cell
		
		# 从源格子移除炮塔的引用和节点
		if source_cell and source_cell.has_method("remove_tower_reference"):
			source_cell.remove_tower_reference()
		
		# 销毁炮塔节点
		tower.queue_free()
		print("Tower removed/sold by dropping into the removal zone!")
	else:
		print("Drop data invalid for removal zone.")
