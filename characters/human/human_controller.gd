extends PlayerController

const LOUD_STEP_SPEED_THRESHOLD := 3.0

const WALK_STEP_NOISE_COOLDOWN_TIME := 1.0
const RUN_STEP_NOISE_COOLDOWN_TIME := 0.5

const MICROSECONDS_IN_SECOND := 1_000_000.0

@export_group("Movement")
@export var _sneak_speed: float = 2.5

@onready var _loud_noise_emitter: LoudNoiseEmitter = %LoudNoiseEmitter

var _human_input_controller: HumanInputController:
	get:
		return _input_controller as HumanInputController

var _step_cooldown_time: float = WALK_STEP_NOISE_COOLDOWN_TIME
var _last_loud_noise_emitted_time_usec: int = 0

func _physics_process(_delta: float) -> void:
	if multiplayer.is_server() == false:
		return

	var current_speed := velocity.length()
	if current_speed < _walk_speed:
		return

	# TODO: We could attach this loud step logic to the walk/run animation, might be a more natural timing?
	var current_time_usec := Time.get_ticks_usec()

	var seconds_since_last_emission: float = (current_time_usec - _last_loud_noise_emitted_time_usec) / MICROSECONDS_IN_SECOND

	if seconds_since_last_emission >= _step_cooldown_time:
		_last_loud_noise_emitted_time_usec = current_time_usec
		var loudness := clampf(remap(
			current_speed,
			LOUD_STEP_SPEED_THRESHOLD, _sprint_speed,
			0.3, 1.5
		), 0.3, 1.5)
		_loud_noise_emitter.emit_noise(loudness)

		if _input_controller.is_sprinting:
			_step_cooldown_time = RUN_STEP_NOISE_COOLDOWN_TIME
		else:
			_step_cooldown_time = WALK_STEP_NOISE_COOLDOWN_TIME

func _get_target_movement_speed() -> float:
	if _human_input_controller.is_sneaking:
		return _sneak_speed
	
	return super._get_target_movement_speed()