class_name ReplenishEffect extends BulletEffect

## 子弹击中炮塔时补充弹药
## 由 ReplenishModule / ReplenishModule2 在 apply_effect 中附加到子弹

var ammo_amount: int = 1

func on_hit_tower(_bullet_data: BulletData, tower: Node) -> void:
	if not tower.has_method("add_ammo"):
		return
	tower.add_ammo(ammo_amount)
	var dn := DamageNumber.new()
	tower.get_tree().root.add_child(dn)
	dn.show_text(tower.global_position + Vector2(0.0, -42.0), "+%d" % ammo_amount, Color.CYAN)
