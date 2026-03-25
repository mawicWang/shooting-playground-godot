extends Node

## SignalBus.gd - 全局信号总线
## 用于解耦系统间的直接引用，所有全局事件都在这里定义

# ==================== 游戏状态事件 ====================
signal game_started
signal game_stopped
signal game_paused
signal game_resumed

# ==================== 拖拽系统事件 ====================
signal drag_started(source_node: Node, texture: Texture2D)
signal drag_ended
signal drag_valid_target_entered(cell: Node)
signal drag_valid_target_exited(cell: Node)

# ==================== 网格系统事件 ====================
signal tower_deployed(tower: Node, cell: Node)
signal tower_removed(tower: Node, cell: Node)
signal grid_initialized(grid_root: Node)

# ==================== 战斗系统事件 ====================
signal bullet_fired(bullet: Node, source_tower: Node)
signal bullet_hit(bullet: Node, target: Node)
signal enemy_spawned(enemy: Node)
signal enemy_destroyed(enemy: Node)
signal enemy_reached_grid(enemy: Node)

# ==================== 遗物系统事件 (预留) ====================
signal relic_acquired(relic: Resource)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
