extends Node

## BulletPool - 子弹对象池
## 管理子弹复用，减少运行时 instantiate/queue_free 的 GC 压力
## 使用：BulletPool.spawn() 创建，BulletPool.release() 回收

const BulletScene := preload("res://entities/bullets/bullet.tscn")

var _pool: Array = []

## 从池中取出（或新建）一颗子弹，添加到 parent，初始化状态后返回
func spawn(parent: Node, pos: Vector2, direction: Vector2, bullet_data: BulletData) -> Node:
	var bullet: Node
	if _pool.size() > 0:
		bullet = _pool.pop_back()
		parent.add_child(bullet)
	else:
		bullet = BulletScene.instantiate()
		parent.add_child(bullet)

	# 每颗子弹持有独立副本，防止外部对 bullet_data 的后续修改影响飞行中的子弹
	bullet.data = bullet_data.duplicate_with_mods({})
	bullet.visible = true
	bullet.set_process_mode(Node.PROCESS_MODE_INHERIT)
	bullet.global_position = pos
	bullet.set_direction(direction)
	bullet.reset()
	return bullet

## 将子弹归还对象池，隐藏并停止处理
func release(bullet: Node) -> void:
	if not is_instance_valid(bullet):
		return
	bullet.visible = false
	bullet.set_process_mode(Node.PROCESS_MODE_DISABLED)
	var parent := bullet.get_parent()
	if parent:
		parent.remove_child(bullet)
	_pool.append(bullet)

## 清空池（关卡结束 / 场景切换时调用）
func clear_pool() -> void:
	for bullet in _pool:
		if is_instance_valid(bullet):
			bullet.queue_free()
	_pool.clear()
