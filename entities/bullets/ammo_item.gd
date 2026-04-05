class_name AmmoItem

## {tower_entity_id (int) → 已贡献次数 (int)}
## Tower 开火时追加自身 bullet_effects 前检查此计数。
var effect_contribution_counts: Dictionary = {}

## {tower_entity_id (int) → tower_effects 已触发次数 (int)}
## bullet.gd 击中炮塔时检查此计数，决定是否触发 tower_effects。
var tower_effect_trigger_counts: Dictionary = {}
