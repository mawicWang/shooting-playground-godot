extends Node

## Paths.gd - 资源路径集中管理
## 避免硬编码路径，便于维护和重构

# ========== Scenes ==========
const TOWER_SCENE := "res://entities/towers/tower.tscn"
const BULLET_SCENE := "res://entities/bullets/bullet.tscn"
const ENEMY_SCENE := "res://entities/enemies/enemy.tscn"
const ENEMY_WARNING_SCENE := "res://entities/enemies/enemy_warning.tscn"
const GAME_OVER_POPUP_SCENE := "res://ui/popups/game_over_popup.tscn"

# ========== Scripts ==========
const DEAD_ZONE_MANAGER_SCRIPT := "res://core/dead_zone_manager.gd"
const ENEMY_MANAGER_SCRIPT := "res://entities/enemies/enemy_manager.gd"

# ========== Autoloads ==========
const MAIN_PATH := "/root/main"
