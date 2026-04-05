extends CharacterBody2D

const MAX_LIFETIME = 15.0

var data: BulletData = null
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _warned: bool = false
var _pending_release: bool = false

func _ready():
	add_to_group("bullets")
	$Hitbox.monitoring = true
	$Hitbox.monitorable = true
	$Hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(delta):
	var speed := data.speed if data else 200.0
	velocity = direction * speed
	move_and_slide()

	_lifetime += delta
	if _lifetime > MAX_LIFETIME and not _warned:
		_warned = true
		if OS.is_debug_build():
			push_warning("[BULLET] Bullet alive %.1fs at %s" % [_lifetime, global_position])

## 从对象池取出时重置运行时状态
func reset() -> void:
	_lifetime = 0.0
	_warned = false
	_pending_release = false
	velocity = Vector2.ZERO
	set_physics_process(true)
	if data and has_node("Hitbox"):
		$Hitbox.collision_mask = data.tower_body_mask

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

## 检测是否击中炮塔
func _on_hitbox_area_entered(other_area: Area2D) -> void:
	if _pending_release:
		return
	var parent = other_area.get_parent()
	if not is_instance_valid(parent) or not parent.is_in_group("towers"):
		return
	# 不击中自己发射的炮塔（transmission_chain 防止自碰）
	if data and data.transmission_chain.has(parent):
		return
	_pending_release = true
	visible = false
	set_physics_process(false)
	# 碰撞特效
	var impact := BulletImpact.new()
	get_tree().root.add_child(impact)
	impact.spawn(global_position, BulletImpact.COLORS_TOWER)

	# 受击动画：每次击中都播，不受 chain 限制
	parent.play_hit_effect()

	# 记录弹药基线（用于命中后弹药回复浮动数字）
	var ammo_before: int = parent.ammo_count() if parent.has_method("ammo_count") else -1

	# 1. 触发 BulletEffect.on_hit_tower（子弹侧，顺序不变）
	if data:
		for effect in data.effects:
			effect.on_hit_tower(data, parent)

	# 2. TowerEffect：检查目标 tower 是否还有触发次数
	if data and parent.get("entity_id") != null and parent.get("tower_effect_max_chain") != null:
		var te_count = data.tower_effect_trigger_counts.get(parent.entity_id, 0)
		if te_count < parent.tower_effect_max_chain:
			data.tower_effect_trigger_counts[parent.entity_id] = te_count + 1
			for te in parent.tower_effects:
				te.on_receive_bullet_hit(data, parent)

	# 3. 弹药回复浮动数字（在所有效果跑完后统一显示）
	var ammo_after: int = parent.ammo_count() if parent.has_method("ammo_count") else -1
	if ammo_before != -1 and ammo_after != -1 and ammo_after > ammo_before:
		var an := AmmoNumber.new()
		get_tree().root.add_child(an)
		an.show_ammo(parent.global_position, ammo_after - ammo_before)

	# 4. 延迟回收，避免在物理回调中直接修改场景树
	BulletPool.release.call_deferred(self)
