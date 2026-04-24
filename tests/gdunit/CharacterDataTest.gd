# CharacterDataTest — GameState character field, get_character() accessor, reset_lives()
# Covers ACs: 9, 10, 11, 12, 13, 18, 19, 20

class_name CharacterDataTest extends GdUnitTestSuite

const VERA: CharacterData = preload("res://src/resources/characters/vera.tres")
const NEUTRAL: CharacterData = preload("res://src/resources/characters/neutral.tres")

func after_test() -> void:
	GameState.character = null

# ── get_character() null-safety (AC 10) ────────────────────────────────────────

func test_get_character_returns_neutral_when_null() -> void:
	# Arrange
	GameState.character = null

	# Act
	var result := GameState.get_character()

	# Assert
	assert_object(result).is_not_null()
	assert_float(result.damage_multiplier).is_equal(1.0)
	assert_float(result.fire_rate_multiplier).is_equal(1.0)
	assert_int(result.bonus_coins_per_kill).is_equal(0)
	assert_int(result.starting_lives_offset).is_equal(0)

func test_get_character_returns_neutral_id_when_null() -> void:
	GameState.character = null
	assert_str(str(GameState.get_character().id)).is_equal("neutral")

# ── GameState.character assignment (AC 9) ──────────────────────────────────────

func test_confirming_vera_sets_character_id() -> void:
	# Arrange / Act
	GameState.character = VERA

	# Assert
	assert_str(str(GameState.character.id)).is_equal("vera")
	assert_float(GameState.character.damage_multiplier).is_equal(2.0)
	assert_float(GameState.character.fire_rate_multiplier).is_equal(0.5)

# ── character persists through wave transitions (AC 12) ────────────────────────

func test_character_persists_through_wave_transitions() -> void:
	GameState.character = VERA

	SignalBus.wave_started.emit(1)
	SignalBus.wave_completed.emit(1)

	assert_object(GameState.character).is_equal(VERA)

# ── character persists through pause/resume (AC 13) ────────────────────────────

func test_character_persists_through_pause_resume() -> void:
	GameState.character = VERA
	GameState.current_state = GameState.State.RUNNING

	GameState.pause_game()
	GameState.resume_game()

	assert_object(GameState.character).is_equal(VERA)
	GameState.current_state = GameState.State.DEPLOYMENT

# ── reset_lives() with character offset (AC 19, 20) ────────────────────────────

func test_reset_lives_neutral_sets_max_lives() -> void:
	# Arrange
	GameState.character = null

	# Act
	GameState.reset_lives()

	# Assert
	assert_int(GameState.player_lives).is_equal(3)

func test_reset_lives_null_character_does_not_crash() -> void:
	GameState.character = null
	GameState.reset_lives()
	assert_int(GameState.player_lives).is_equal(3)

# ── neutral character leaves stats at baseline (AC 18) ─────────────────────────

func test_neutral_character_damage_multiplier_is_one() -> void:
	assert_float(NEUTRAL.damage_multiplier).is_equal(1.0)

func test_neutral_character_fire_rate_multiplier_is_one() -> void:
	assert_float(NEUTRAL.fire_rate_multiplier).is_equal(1.0)

func test_neutral_character_bonus_coins_is_zero() -> void:
	assert_int(NEUTRAL.bonus_coins_per_kill).is_equal(0)

func test_neutral_character_lives_offset_is_zero() -> void:
	assert_int(NEUTRAL.starting_lives_offset).is_equal(0)
