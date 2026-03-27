class_name DoubleShotRelic extends Relic

## 双发遗物：每次炮塔发射时额外生成一颗子弹
## 第二颗子弹直接通过 BulletPool 生成，不再触发 EventManager，避免递归

const TRAIL_OFFSET: float = 16.0  # 沿发射方向往后错开的距离（像素），形成连发感

func on_bullet_fired(bullet_data: BulletData, tower: Node) -> void:
	var parent := tower.get_tree().get_first_node_in_group("bullet_layer")
	if not is_instance_valid(parent):
		parent = tower.get_tree().root
	var forward := Vector2(0, -1).rotated(tower.rotation)
	# 第二颗从发射方向稍后方出发，追赶第一颗，形成连发视觉
	# 无需手动复制数据，BulletPool.spawn 统一处理数据独立性
	BulletPool.spawn(parent, tower.global_position - forward * TRAIL_OFFSET, forward, bullet_data)
