class_name AmmoReplenishEffect extends BulletHitEffect

@export var ammo_amount: int = 1

func apply(_bullet_data: BulletData, target_tower: Node) -> void:
	if target_tower.has_method("add_ammo"):
		target_tower.add_ammo(ammo_amount)
		var dn := DamageNumber.new()
		target_tower.get_tree().root.add_child(dn)
		dn.show_text(target_tower.global_position + Vector2(0.0, -42.0), "+%d" % ammo_amount, Color.CYAN)
