class_name BulletData extends Resource

var attack: float = 1.0         ## 对敌人造成的伤害值
var energy: float = 1.0         ## 子弹能量（供 MultiplierModule 等模块使用）
var speed: float = 200.0        ## 飞行速度（像素/秒）
var chain_count: int = 0        ## 连锁次数（预留，暂无逻辑）
var knockback: float = 150.0
var knockback_decay: float = 25.0
var transmission_chain: Array = []
## 效果列表（Array[BulletEffect]），子弹携带，各触发时机依次调用
var effects: Array = []
var tower_body_mask: int = 32   ## 子弹 Hitbox 碰撞遮罩（默认 TOWER_BODY 层，FlyingModule 可扩展为 32|64）

func duplicate_with_mods(mods: Dictionary) -> BulletData:
	var copy := BulletData.new()
	copy.attack = attack
	copy.energy = energy
	copy.speed = speed
	copy.chain_count = chain_count
	copy.knockback = knockback
	copy.knockback_decay = knockback_decay
	copy.transmission_chain = transmission_chain.duplicate()
	copy.effects = effects.duplicate()
	copy.tower_body_mask = tower_body_mask
	for key in mods:
		copy.set(key, mods[key])
	return copy
