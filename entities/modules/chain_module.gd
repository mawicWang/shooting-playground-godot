class_name ChainModule extends Module

## 连锁+1 模组：本炮塔的 bullet_effects 和 tower_effects
## 在同一传递链上各可额外多触发一次。

func on_install(tower: Node) -> void:
	super.on_install(tower)
	tower.bullet_effect_max_chain += 1
	tower.tower_effect_max_chain += 1

func on_uninstall(tower: Node) -> void:
	super.on_uninstall(tower)
	tower.bullet_effect_max_chain -= 1
	tower.tower_effect_max_chain -= 1
