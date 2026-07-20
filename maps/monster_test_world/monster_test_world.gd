extends GameWorldBase

@onready var _test_loud_noise_emitter: LoudNoiseEmitter = %LoudNoiseEmitter
@onready var _test_loud_noise_timer: Timer = %LoudNoiseTimer

func _start_game_custom_map_logic() -> void:
	_test_loud_noise_timer.start()
	_test_loud_noise_timer.timeout.connect(_on_loud_noise_timer_fired)

func _on_loud_noise_timer_fired() -> void:
	_test_loud_noise_emitter.emit_noise(1.0)