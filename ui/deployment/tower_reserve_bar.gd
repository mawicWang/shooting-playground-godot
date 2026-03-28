# tower_reserve_bar.gd
# 炮塔储备栏：接受暂存区图标 drop → 移入储备
extends HBoxContainer

## 暂存图标被拖入储备时发出，由 main.gd 处理
signal staging_tower_received(tower_data: Resource, entity_id: int, old_staging_icon: Node)

func _can_drop_data(_at_position, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	# 只接受来自暂存区的图标（非移动中的炮塔）
	if not data.get("is_staging", false):
		return false
	if data.get("is_moving", false):
		return false
	if not data.has("tower_data"):
		return false
	return not GameState.is_tower_reserve_full()

func _drop_data(_at_position, data) -> void:
	var src_icon = data.get("source_icon", null)
	staging_tower_received.emit(data.get("tower_data"), data.get("entity_id", -1), src_icon)
