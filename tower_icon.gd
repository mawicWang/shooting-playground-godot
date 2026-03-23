# tower_icon.gd
extends TextureRect

@export var tower_scene: PackedScene = preload("res://tower.tscn") # 你的炮塔预制体

func _get_drag_data(_at_position):
	# 商店产生的拖拽
	var data = {"scene": tower_scene, "icon": texture, "is_moving": false}
	
	var drag_preview = TextureRect.new()
	drag_preview.texture = texture
	drag_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	drag_preview.custom_minimum_size = Vector2(60, 60)
	drag_preview.modulate.a = 0.5 
	drag_preview.position = -Vector2(30, 30) # 居中
	
	set_drag_preview(drag_preview)
	return data
