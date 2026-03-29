extends Control

## reward_popup.gd - 波次奖励选择弹窗
## 每波结束后弹出，玩家从3个随机选项中选择一个奖励（炮塔或模块）

signal reward_chosen(reward: Resource)

const REWARD_POOL: Array = [
    preload("res://resources/simple_emitter.tres"),
    preload("res://resources/tower1010.tres"),
    preload("res://resources/tower1100.tres"),
    preload("res://resources/tower1110.tres"),
    preload("res://resources/tower1111.tres"),
    preload("res://resources/module_data/accelerator.tres"),
    preload("res://resources/module_data/multiplier.tres"),
    preload("res://resources/module_data/replenish1.tres"),
    preload("res://resources/module_data/replenish2.tres"),
    preload("res://resources/module_data/rate_boost.tres"),
]
const FALLBACK_MODULE_TEX = preload("res://assets/bullet.svg")

var _cards_row: HBoxContainer = null

func _ready():
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    # 半透明遮罩背景
    var bg := ColorRect.new()
    bg.layout_mode = 1
    bg.anchor_right = 1.0
    bg.anchor_bottom = 1.0
    bg.color = Color(0, 0, 0, 0.75)
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(bg)

    # 居中容器
    var center := CenterContainer.new()
    center.layout_mode = 1
    center.anchor_right = 1.0
    center.anchor_bottom = 1.0
    add_child(center)

    var vbox := VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 24)
    center.add_child(vbox)

    var title := Label.new()
    title.text = "选择奖励"
    title.add_theme_font_size_override("font_size", 44)
    title.add_theme_color_override("font_color", Color.WHITE)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)

    _cards_row = HBoxContainer.new()
    _cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
    _cards_row.add_theme_constant_override("separation", 24)
    vbox.add_child(_cards_row)

func show_rewards():
    var pool := REWARD_POOL.duplicate()
    pool.shuffle()
    var choices := pool.slice(0, min(3, pool.size()))

    for child in _cards_row.get_children():
        child.free()

    for reward in choices:
        _cards_row.add_child(_make_card(reward))

    visible = true
    get_tree().paused = true

func _make_card(reward: Resource) -> Button:
    var btn := Button.new()
    btn.custom_minimum_size = Vector2(190, 250)
    _apply_card_styles(btn)

    var vbox := VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 8)
    vbox.layout_mode = 1
    vbox.anchor_right = 1.0
    vbox.anchor_bottom = 1.0
    vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    btn.add_child(vbox)

    vbox.add_child(_make_icon(reward))
    vbox.add_child(_make_label(
        reward.tower_name if reward is TowerData else reward.module_name,
        22, Color(0.1, 0.1, 0.1), true))

    if reward is Module:
        vbox.add_child(_make_label(reward.description, 17, Color(0.3, 0.3, 0.3), true))
        vbox.add_child(_make_label("【模块】", 17, Color(0.0, 0.5, 0.8)))
    else:
        var ammo_text := "初始弹药：无限" if reward.initial_ammo == -1 else "初始弹药：%d" % reward.initial_ammo
        vbox.add_child(_make_label(ammo_text, 17, Color(0.3, 0.3, 0.3), true))
        vbox.add_child(_make_label("【炮塔】", 17, Color(0.0, 0.6, 0.1)))

    btn.pressed.connect(func(): _on_card_selected(reward))
    return btn

func _make_icon(reward: Resource) -> TextureRect:
    var rect := TextureRect.new()
    rect.custom_minimum_size = Vector2(80, 80)
    rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if reward is TowerData:
        rect.texture = reward.icon
    elif reward is Module:
        rect.texture = reward.icon if reward.icon else FALLBACK_MODULE_TEX
        rect.modulate = _get_module_color(reward)
    return rect

func _make_label(text: String, size: int, color: Color, autowrap: bool = false) -> Label:
    var lbl := Label.new()
    lbl.text = text
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.add_theme_font_size_override("font_size", size)
    lbl.add_theme_color_override("font_color", color)
    lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if autowrap:
        lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return lbl

func _apply_card_styles(btn: Button) -> void:
    var normal_style := StyleBoxFlat.new()
    normal_style.bg_color = Color.WHITE
    normal_style.set_border_width_all(2)
    normal_style.border_color = Color(0.7, 0.7, 0.8, 1.0)
    normal_style.set_corner_radius_all(10)
    normal_style.content_margin_top = 10
    normal_style.content_margin_bottom = 10
    normal_style.content_margin_left = 10
    normal_style.content_margin_right = 10
    btn.add_theme_stylebox_override("normal", normal_style)

    var hover_style := normal_style.duplicate()
    hover_style.bg_color = Color(0.92, 0.95, 1.0)
    hover_style.border_color = Color(0.3, 0.5, 0.9)
    btn.add_theme_stylebox_override("hover", hover_style)

    var pressed_style := hover_style.duplicate()
    pressed_style.bg_color = Color(0.85, 0.88, 0.96)
    btn.add_theme_stylebox_override("pressed", pressed_style)

func _get_module_color(mod: Module) -> Color:
    match mod.module_name:
        "加速器": return Color(0.1, 0.9, 1.0)
        "乘法器": return Color(1.0, 0.6, 0.1)
        _: return Color.WHITE

func _on_card_selected(reward: Resource) -> void:
    visible = false
    get_tree().paused = false
    reward_chosen.emit(reward)
