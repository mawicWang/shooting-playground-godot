extends Node

## Paths.gd - 资源路径集中管理
## 避免硬编码路径，便于维护和重构

# ========== Scenes ==========
const TOWER_SCENE := "res://src/entities/towers/tower.tscn"
const BULLET_SCENE := "res://src/entities/bullets/bullet.tscn"
const ENEMY_SCENE := "res://src/entities/enemies/enemy.tscn"
const ENEMY_WARNING_SCENE := "res://src/entities/enemies/enemy_warning.tscn"
const SHIELD_ENEMY_SCENE := "res://src/entities/enemies/shield_enemy.tscn"
const GAME_OVER_POPUP_SCENE := "res://src/ui/popups/game_over_popup.tscn"
const SETTINGS_SCENE := "res://src/ui/settings/settings.tscn"

# ========== Autoloads ==========
const MAIN_PATH := "/root/main"

# ========== Shaders ==========
const BULLET_COLOR_SHADER := "res://src/entities/bullets/bullet_color.gdshader"
const ENEMY_WARNING_DANGER_SHADER := "res://src/entities/enemies/enemy_warning_danger.gdshader"
const SHIELD_BUBBLE_SHADER := "res://src/entities/enemies/shield_bubble.gdshader"
