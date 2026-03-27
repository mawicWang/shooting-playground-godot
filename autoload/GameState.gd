extends Node

## GameState.gd - 全局游戏状态管理
## 集中管理游戏阶段状态（DEPLOYMENT / RUNNING / PAUSED / GAME_OVER）
## 拖拽状态由 DragManager 单独负责，不在此重复

enum State { DEPLOYMENT, RUNNING, PAUSED, GAME_OVER }

var current_state: State = State.DEPLOYMENT
var current_wave: int = 0

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
