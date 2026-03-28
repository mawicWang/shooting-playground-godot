extends Node

## GameState.gd - 全局游戏状态管理
## 集中管理游戏阶段状态（DEPLOYMENT / RUNNING / PAUSED / GAME_OVER）
## 拖拽状态由 DragManager 单独负责，不在此重复

enum State { DEPLOYMENT, RUNNING, PAUSED, GAME_OVER }

var current_state: State = State.DEPLOYMENT
var current_wave: int = 0

# 实体 ID 计数器（全局唯一，跨部署/回收循环保持不变）
var _next_entity_id: int = 1

func generate_entity_id() -> int:
	var id = _next_entity_id
	_next_entity_id += 1
	return id

# 炮塔储备数量（最多 5 个）
var tower_reserve_count: int = 0
const TOWER_RESERVE_MAX: int = 5

func is_tower_reserve_full() -> bool:
	return tower_reserve_count >= TOWER_RESERVE_MAX

func reset_reserve_count() -> void:
	tower_reserve_count = 0

# 金币
var coins: int = 0

func add_coins(amount: int) -> void:
	coins += amount
	SignalBus.coins_changed.emit(coins)

func reset_coins() -> void:
	coins = 0
	SignalBus.coins_changed.emit(coins)

# 运行状态切换
func start_game():
	if current_state == State.DEPLOYMENT:
		current_state = State.RUNNING
		SignalBus.game_started.emit()

func stop_game():
	if current_state == State.RUNNING:
		current_state = State.DEPLOYMENT
		SignalBus.game_stopped.emit()

func pause_game():
	if current_state == State.RUNNING:
		current_state = State.PAUSED
		SignalBus.game_paused.emit()

func resume_game():
	if current_state == State.PAUSED:
		current_state = State.RUNNING
		SignalBus.game_resumed.emit()

# 便捷查询
func is_running() -> bool:
	return current_state == State.RUNNING

func is_deployment() -> bool:
	return current_state == State.DEPLOYMENT

func can_drag() -> bool:
	return current_state == State.DEPLOYMENT
