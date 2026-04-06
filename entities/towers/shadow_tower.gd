extends "res://entities/towers/tower.gd"

## 影子团队ID（起源炮塔的 entity_id）
var shadow_team_id: int = -1

func _ready() -> void:
	super._ready()
	# 深色半透明影子外观
	modulate = Color(0.15, 0.15, 0.2, 0.65)
	SignalBus.game_stopped.connect(_on_game_stopped)
	SignalBus.wave_completed.connect(_on_wave_completed)

## 覆盖弹药初始化：影子炮塔始终无限弹药
func _apply_data() -> void:
	super._apply_data()
	ammo = -1
	ammo_queue.clear()
	ammo_cursor = 0
	_update_ammo_label()

## 获取影子团队ID（供子弹碰撞检测使用）
func get_shadow_team_id() -> int:
	return shadow_team_id

## 覆盖炮塔体设置：使用 SHADOW_TOWER_BODY 层
func _setup_tower_body() -> void:
	_tower_body = Area2D.new()
	_tower_body.name = "TowerBody"
	_tower_body.collision_layer = Layers.SHADOW_TOWER_BODY
	_tower_body.collision_mask = 0
	_tower_body.monitoring = false
	_tower_body.monitorable = true
	add_child(_tower_body)
	call_deferred("_init_tower_body_shape")

## 覆盖开火逻辑：设置子弹的 shadow_team_id 和碰撞遮罩
func _do_fire() -> void:
	# 取当前弹药项（无限弹药每次创建空 AmmoItem，保持全新链）
	var ammo_item: AmmoItem
	if ammo == -1:
		ammo_item = AmmoItem.new()
	else:
		ammo_item = ammo_queue[ammo_cursor]
	consume_ammo()

	# 额外弹药消耗
	var extra := int(_ammo_extra_stat.get_value())
	for _i in range(extra):
		consume_ammo()

	var bd := BulletData.new()
	bd.attack = _bullet_attack_stat.get_value()
	bd.speed  = _bullet_speed_stat.get_value()
	bd.transmission_chain = [self]
	bd.shadow_team_id = shadow_team_id
	bd.tower_body_mask = Layers.SHADOW_TOWER_BODY  # 只检测影子炮塔

	# 触发 FireEffect（开火时效果，如影子炮塔生成）
	for effect in fire_effects:
		effect.apply(self, bd)

	# 从弹药项继承链追踪状态
	bd.effect_contribution_counts = ammo_item.effect_contribution_counts.duplicate()
	bd.tower_effect_trigger_counts = ammo_item.tower_effect_trigger_counts.duplicate()

	# 检查本 tower 是否还能贡献 bullet_effects 和基础弹药传递
	var contrib_count = bd.effect_contribution_counts.get(entity_id, 0)
	if contrib_count < bullet_effect_max_chain:
		bd.effects.append_array(bullet_effects)
		bd.effect_contribution_counts[entity_id] = contrib_count + 1
		# default_replenish 也受链次数限制，与 bullet_effects 共享同一计数
		var default_replenish := HitTowerTargetReplenishEffect.new()
		bd.effects.append(default_replenish)

	# 设置子弹碰撞层以反映飞行/反空状态
	if is_flying:
		bd.tower_body_mask = Layers.AIR_TOWER_BODY | Layers.SHADOW_TOWER_BODY
	elif has_anti_air:
		bd.tower_body_mask = Layers.TOWER_BODY | Layers.AIR_TOWER_BODY | Layers.SHADOW_TOWER_BODY

	var cd := _get_effective_cd()
	_cooldown_remaining = cd
	_current_full_cooldown = cd
	_update_cd_overlay()

	var parent := get_tree().get_first_node_in_group("bullet_layer")
	if not is_instance_valid(parent):
		parent = get_tree().root

	var directions: PackedVector2Array
	if data and data.barrel_directions.size() > 0:
		directions = data.barrel_directions
	else:
		directions = PackedVector2Array([Vector2(0, -1)])

	for local_dir in directions:
		BulletPool.spawn(parent, global_position, local_dir.rotated(_tower_visual.rotation), bd)

	EventManager.notify_bullet_fired(bd, self)

func _cleanup() -> void:
	# 清理父格子的占用状态，然后移除自身
	var parent_cell = get_parent()
	if is_instance_valid(parent_cell) and parent_cell.has_method("remove_tower_reference"):
		parent_cell.remove_tower_reference()
	queue_free()

func _on_game_stopped() -> void:
	_cleanup()

func _on_wave_completed(_wave_number: int) -> void:
	_cleanup()
