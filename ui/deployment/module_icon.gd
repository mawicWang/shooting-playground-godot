# module_icon.gd
# 可拖拽的模块图标，放置在底部工具栏
# 可通过 module_data 直接赋值，或通过 module_res_path 在运行时加载
extends TextureRect

@export var module_data: Module
@export var module_res_path: String = ""  # 运行时加载路径（用于 tscn 中避免 UID 依赖）

var drag_enabled: bool = true

func _ready() -> void:
	if module_res_path != "" and not module_data:
		module_data = load(module_res_path) as Module
	if module_data:
		if module_data.icon:
			texture = module_data.icon
		tooltip_text = "%s\n%s" % [module_data.module_name, module_data.description]

func set_drag_enabled(enabled: bool) -> void:
	drag_enabled = enabled
	modulate.a = 1.0 if enabled else 0.5

func _get_drag_data(_at_position) -> Variant:
	if not drag_enabled or not module_data or not GameState.can_drag():
		return null

	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = Vector2(60, 60)
	preview.modulate.a = 0.7
	set_drag_preview(preview)

	return {"module_data": module_data}
