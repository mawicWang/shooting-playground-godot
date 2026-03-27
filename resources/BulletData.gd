class_name BulletData extends Resource

var energy: float = 1.0
var speed: float = 200.0
var transmission_chain: Array = []
## 子弹击中炮塔时依次触发的效果列表（Array[BulletHitEffect]）
var hit_effects: Array = []

func duplicate_with_mods(mods: Dictionary) -> BulletData:
	# 逐字段手动复制，避免依赖 Resource.duplicate() 对非 @export 变量的不可靠行为
	var copy := BulletData.new()
	copy.energy = energy
	copy.speed = speed
	copy.transmission_chain = transmission_chain.duplicate()
	copy.hit_effects = hit_effects.duplicate()
	for key in mods:
		copy.set(key, mods[key])
	return copy
