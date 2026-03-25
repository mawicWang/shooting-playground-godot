extends Node

## GameState.gd - 全局游戏状态管理
## 替代 DragManager 的全局功能，集中管理游戏状态

enum GameState { DEPLOYMENT, RUNNING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.DEPLOYMENT
var current_wave: int = 0
var is_drag_active: bool = false
var dragged_source: Node = null

# 运行状态切换
func start_game():
    if current_state == GameState.DEPLOYMENT:
        current_state = GameState.RUNNING
        SignalBus.game_started.emit()

func stop_game():
    if current_state == GameState.RUNNING:
        current_state = GameState.DEPLOYMENT
        SignalBus.game_stopped.emit()

func pause_game():
    if current_state == GameState.RUNNING:
        current_state = GameState.PAUSED
        SignalBus.game_paused.emit()

func resume_game():
    if current_state == GameState.PAUSED:
        current_state = GameState.RUNNING
        SignalBus.game_resumed.emit()

# 拖拽状态管理
func start_drag(source_node: Node):
    is_drag_active = true
    dragged_source = source_node

func end_drag():
    is_drag_active = false
    dragged_source = null
    SignalBus.drag_ended.emit()

# 便捷查询
func is_running() -> bool:
    return current_state == GameState.RUNNING

func is_deployment() -> bool:
    return current_state == GameState.DEPLOYMENT

func can_drag() -> bool:
    return current_state == GameState.DEPLOYMENT and not is_drag_active
