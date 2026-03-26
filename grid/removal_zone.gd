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
		
		# From grid, remove tower reference and node
		if is_instance_valid(source_cell) and source_cell.has_method("remove_tower_reference"):
			source_cell.remove_tower_reference()
			# Ensure the tower is removed from its original parent if it's still there
			if is_instance_valid(tower) and tower.get_parent() == source_cell:
				source_cell.remove_child(tower)

		# Destroy the tower node
		if is_instance_valid(tower):
			tower.queue_free()
			print("Tower removed/sold by dropping into the removal zone!")
		DragManager.end_drag() # Notify DragManager that drag has ended
	else:
		printerr("Drop data invalid for removal zone.")
		DragManager.end_drag() # Even if invalid, drag operation has ended
