class_name BulletData extends Resource

var energy: float = 1.0
var speed: float = 200.0
var transmission_chain: Array = []

func duplicate_with_mods(mods: Dictionary) -> BulletData:
	# 逐字段手动复制，避免依赖 Resource.duplicate() 对非 @export 变量的不可靠行为
	var copy := BulletData.new()
	copy.energy = energy
	copy.speed = speed
	copy.transmission_chain = transmission_chain.duplicate()
	for key in mods:
		copy.set(key, mods[key])
	return copy
