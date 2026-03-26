extends Node

## GameLoopManager.gd - 游戏循环管理
## 负责游戏状态转换和核心游戏逻辑

signal tower_deployed(tower: Node)
signal all_enemies_defeated

var _grid_container: Control
var _dead_zone_manager: Node = null
var _enemy_manager: Node = null
var _pending_enemy_data: Array = []
var _enemy_breached_grid: bool = false

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
    _enemy_breached_grid = false
    _set_drag_enabled(false)
    _create_dead_zones()
    _create_enemy_manager()
    _start_all_towers()
    SignalBus.wave_started.emit(1)

func _on_game_stopped():
    _stop_all_towers()
    _clear_all_bullets()
    _remove_dead_zones()
    _remove_enemy_manager()
    _set_drag_enabled(true)
    _prepare_enemy_warnings()

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
    _dead_zone_manager = Node2D.new()
    _dead_zone_manager.name = "DeadZoneManager"
    _dead_zone_manager.set_script(load(Paths.DEAD_ZONE_MANAGER_SCRIPT))
    add_child(_dead_zone_manager)

func _remove_dead_zones():
    if is_instance_valid(_dead_zone_manager):
        _dead_zone_manager.clear_all()
        _dead_zone_manager.queue_free()
        _dead_zone_manager = null

func _prepare_enemy_warnings():
    if not is_instance_valid(_grid_container):
        push_error("[GameLoopManager] Grid container not valid!")
        return
    
    var grid_rect = _grid_container.get_global_rect()
    if grid_rect.size == Vector2.ZERO:
        push_error("[GameLoopManager] Grid rect size is zero!")
        return
    
    if is_instance_valid(_enemy_manager):
        _enemy_manager.queue_free()
    
    _enemy_manager = Node2D.new()
    _enemy_manager.name = "EnemyManager"
    _enemy_manager.set_script(load(Paths.ENEMY_MANAGER_SCRIPT))
    add_child(_enemy_manager)
    
    _enemy_manager.set_grid_info(grid_rect, 80.0)
    _pending_enemy_data = _enemy_manager.prepare_enemies()

func _create_enemy_manager():
    if is_instance_valid(_enemy_manager):
        _enemy_manager.queue_free()
    
    _enemy_manager = Node2D.new()
    _enemy_manager.name = "EnemyManager"
    _enemy_manager.set_script(load(Paths.ENEMY_MANAGER_SCRIPT))
    add_child(_enemy_manager)
    
    var grid_rect = _grid_container.get_global_rect()
    _enemy_manager.set_grid_info(grid_rect, 80.0)
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
    all_enemies_defeated.emit()

func on_enemy_breached_grid():
    _enemy_breached_grid = true

func has_enemy_breached() -> bool:
    return _enemy_breached_grid

func reset_breach_status():
    _enemy_breached_grid = false

func get_pending_enemy_data() -> Array:
    return _pending_enemy_data
