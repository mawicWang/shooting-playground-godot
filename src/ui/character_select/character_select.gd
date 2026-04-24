## Character select screen script.
## Displayed between Start Menu and main game. Player picks a character
## whose passive traits affect the entire run.

extends Control

const VERA: CharacterData = preload("res://src/resources/characters/vera.tres")
const MOX: CharacterData = preload("res://src/resources/characters/mox.tres")
const WREN: CharacterData = preload("res://src/resources/characters/wren.tres")
const ROSTER: Array = [VERA, MOX, WREN]

const CHARACTER_CARD_SCENE := preload("res://src/ui/character_select/character_card.tscn")

@onready var _card_row: HBoxContainer = $RootVBox/CardRow
@onready var _detail_name: Label = $RootVBox/DetailPanel/VBox/DetailName
@onready var _detail_tagline: Label = $RootVBox/DetailPanel/VBox/DetailTagline
@onready var _detail_description: Label = $RootVBox/DetailPanel/VBox/DetailDescription
@onready var _confirm_button: Button = $RootVBox/ConfirmButton
@onready var _back_button: Button = $RootVBox/TopBar/BackButton

var _cards: Array[CharacterCard] = []
var _selected_data: CharacterData = null

func _ready() -> void:
	for char_data in ROSTER:
		var card: CharacterCard = CHARACTER_CARD_SCENE.instantiate()
		card.data = char_data
		card.custom_minimum_size = Vector2(140.0, 140.0)
		_card_row.add_child(card)
		_cards.append(card)
		card.card_selected.connect(_on_card_selected)

	_confirm_button.pressed.connect(_on_confirm_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_confirm_button.custom_minimum_size = Vector2(0.0, 48.0)

	# Pre-select Vera and populate detail panel immediately
	_select_card(VERA)

func _on_card_selected(char_data: CharacterData) -> void:
	_select_card(char_data)

func _select_card(char_data: CharacterData) -> void:
	_selected_data = char_data
	for card in _cards:
		card.set_selected(card.data == char_data)
	_detail_name.text = char_data.display_name
	_detail_tagline.text = char_data.tagline
	_detail_description.text = char_data.description

func _on_confirm_pressed() -> void:
	GameState.character = _selected_data
	get_tree().change_scene_to_file("res://src/main.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/start_menu/start_menu.tscn")
