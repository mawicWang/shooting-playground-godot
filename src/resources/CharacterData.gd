class_name CharacterData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var tagline: String = ""
@export_multiline var description: String = ""
@export var is_available: bool = false
@export var portrait: Texture2D = null
@export_range(0.1, 5.0, 0.05) var damage_multiplier: float = 1.0
@export_range(0.1, 3.0, 0.05) var fire_rate_multiplier: float = 1.0
@export_range(0, 10, 1) var bonus_coins_per_kill: int = 0
@export_range(-2, 5, 1) var starting_lives_offset: int = 0
