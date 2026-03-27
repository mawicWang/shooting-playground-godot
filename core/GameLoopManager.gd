extends Node

## GameLoopManager.gd - 游戏循环管理
## 负责游戏状态转换和核心游戏逻辑

const DeadZoneManager = preload("res://core/dead_zone_manager.gd")
const EnemyManager = preload("res://entities/enemies/enemy_manager.gd")

const CELL_SIZE = 80.0

signal tower_deployed(tower: Node)
signal all_enemies_defeated

var _grid_container: Control
var _dead_zone_manager: Node = null
var _enemy_manager: Node = null
var _pending_enemy_data: Array = []

## 已完成的波次数（0 = 还未完成任何波次，下一波是第1关）
var current_wave: int = 0

func setup(grid_container: Control):
    _grid_container = grid_container

    # 监听游戏状态变化
    SignalBus.game_started.connect(_on_game_started)
    SignalBus.game_stopped.connect(_on_game_stopped)

func start_game():
    GameState.start_game()

func stop_game():
    GameState.stop_game()

func _on_game_started():
    _set_drag_enabled(false)
    _create_dead_zones()
    _create_enemy_manager()
    _start_all_towers()
    SignalBus.wave_started.emit(current_wave + 1)

func _on_game_stopped():
    _stop_all_towers()
    _clear_all_bullets()
    _remove_dead_zones()
    _remove_enemy_manager()
    _set_drag_enabled(true)
    # 注意：prepare_enemy_warnings() 由 main.gd 在合适时机显式调用

func _set_drag_enabled(enabled: bool):
    for cell in _grid_container.get_children():
        if cell.has_method("set_drag_enabled"):
            cell.set_drag_enabled(enabled)

func _start_all_towers():
    for cell in _grid_container.get_children():
        if cell.has_method("get_deployed_tower"):
            var tower = cell.get_deployed_tower()
            if is_instance_valid(tower) and tower.has_method("start_firing"):
                tower.start_firing()

func _stop_all_towers():
    for cell in _grid_container.get_children():
        if cell.has_method("get_deployed_tower"):
            var tower = cell.get_deployed_tower()
            if is_instance_valid(tower) and tower.has_method("stop_firing"):
                tower.stop_firing()

func _create_dead_zones():
    if is_instance_valid(_dead_zone_manager):
        _dead_zone_manager.queue_free()
    _dead_zone_manager = DeadZoneManager.new()
    _dead_zone_manager.name = "DeadZoneManager"
    add_child(_dead_zone_manager)

func _remove_dead_zones():
    if is_instance_valid(_dead_zone_manager):
        _dead_zone_manager.clear_all()
        _dead_zone_manager.queue_free()
        _dead_zone_manager = null

func prepare_enemy_warnings():
    if not is_instance_valid(_grid_container):
        push_error("[GameLoopManager] Grid container not valid!")
        return

    var grid_rect = _grid_container.get_global_rect()
    if grid_rect.size == Vector2.ZERO:
        # Grid 还没准备好，延迟重试
        await get_tree().create_timer(0.1).timeout
        call_deferred("prepare_enemy_warnings")
        return

    if is_instance_valid(_enemy_manager):
        _enemy_manager.queue_free()

    _enemy_manager = EnemyManager.new()
    _enemy_manager.name = "EnemyManager"
    add_child(_enemy_manager)

    _enemy_manager.set_grid_info(grid_rect, CELL_SIZE)
    _enemy_manager.enemy_count = current_wave + 1  # 第N关 = N个敌人
    _pending_enemy_data = _enemy_manager.prepare_enemies()

func _create_enemy_manager():
    if is_instance_valid(_enemy_manager):
        _enemy_manager.queue_free()

    _enemy_manager = EnemyManager.new()
    _enemy_manager.name = "EnemyManager"
    add_child(_enemy_manager)

    var grid_rect = _grid_container.get_global_rect()
    _enemy_manager.set_grid_info(grid_rect, CELL_SIZE)
    _enemy_manager.spawn_enemies_from_data(_pending_enemy_data)

    _enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)

func _remove_enemy_manager():
    if is_instance_valid(_enemy_manager):
        _enemy_manager.clear_enemies()
        _enemy_manager.queue_free()
        _enemy_manager = null

func _clear_all_bullets():
    var bullets = get_tree().get_nodes_in_group("bullets")
    for bullet in bullets:
        if is_instance_valid(bullet):
            bullet.queue_free()

func _on_all_enemies_defeated():
    current_wave += 1
    all_enemies_defeated.emit()

func reset_wave():
    current_wave = 0

func get_current_wave() -> int:
    return current_wave

func get_pending_enemy_data() -> Array:
    return _pending_enemy_data
