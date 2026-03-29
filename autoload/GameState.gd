extends Node

## GameState.gd - 全局游戏状态管理
## 集中管理游戏阶段状态（DEPLOYMENT / RUNNING / PAUSED / GAME_OVER）
## 拖拽状态由 DragManager 单独负责，不在此重复

enum State { DEPLOYMENT, RUNNING, PAUSED, GAME_OVER }
enum GameMode { CHAOS, NORMAL, DEV }

var game_mode: GameMode = GameMode.CHAOS

func is_dev_mode() -> bool:
	return game_mode == GameMode.DEV

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
	if is_dev_mode():
		return false
	return tower_reserve_count >= TOWER_RESERVE_MAX

func reset_reserve_count() -> void:
	tower_reserve_count = 0

# 玩家生命值
const MAX_LIVES: int = 3
var player_lives: int = MAX_LIVES

## 扣除一条生命。
## 归零时立即切换到 GAME_OVER 状态并同步发出 game_stopped（触发各系统清理），
## 返回 true 表示生命归零。这样所有事件处理器只需检查 is_running() 即可，
## 无需额外标志或手动调 stop_game()。
func lose_life() -> bool:
	if is_dev_mode():
		return false
	player_lives -= 1
	player_lives = max(player_lives, 0)
	SignalBus.lives_changed.emit(player_lives)
	if player_lives <= 0:
		current_state = State.GAME_OVER
		SignalBus.game_stopped.emit()
		return true
	return false

## 游戏结束弹窗关闭后调用，将 GAME_OVER 重置回 DEPLOYMENT
func reset_to_deployment() -> void:
	current_state = State.DEPLOYMENT

func reset_lives() -> void:
	player_lives = MAX_LIVES
	SignalBus.lives_changed.emit(player_lives)

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

func is_game_over() -> bool:
	return current_state == State.GAME_OVER

func can_drag() -> bool:
	return current_state == State.DEPLOYMENT
