class_name BulletData extends Resource

var energy: float = 1.0
var speed: float = 200.0
var transmission_chain: Array = []

func duplicate_with_mods(mods: Dictionary) -> BulletData:
	var copy: BulletData = self.duplicate()
	copy.transmission_chain = transmission_chain.duplicate()
	for key in mods:
		copy.set(key, mods[key])
	return copy
