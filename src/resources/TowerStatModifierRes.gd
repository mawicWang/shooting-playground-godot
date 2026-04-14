class_name TowerStatModifierRes extends Resource

enum Stat { CD, BULLET_SPEED, BULLET_ATTACK, AMMO_EXTRA }
## 与 StatModifier.Type 保持相同顺序：0=ADDITIVE，1=MULTIPLICATIVE
enum ModifierType { ADDITIVE, MULTIPLICATIVE }

@export var stat: Stat = Stat.CD
@export var value: float = 0.0
@export var modifier_type: ModifierType = ModifierType.ADDITIVE
