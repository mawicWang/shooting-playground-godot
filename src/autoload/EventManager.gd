extends Node

## EventManager - 遗物事件分发器
## 管理所有激活的遗物，在关键游戏事件时逐一调用遗物钩子

var relics: Array = []  # Array[Relic]

func register_relic(relic: Relic) -> void:
	relics.append(relic)

func unregister_relic(relic: Relic) -> void:
	relics.erase(relic)

func clear_relics() -> void:
	relics.clear()

## 炮塔发射子弹时调用，分发给所有遗物
func notify_bullet_fired(bullet_data: BulletData, tower: Node) -> void:
	for relic in relics:
		relic.on_bullet_fired(bullet_data, tower)

## 波次开始时调用
func notify_wave_start() -> void:
	for relic in relics:
		relic.on_wave_start()
