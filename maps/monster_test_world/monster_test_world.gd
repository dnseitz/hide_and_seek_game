extends Node3D

@onready var _test_loud_noise_emitter: LoudNoiseEmitter = %LoudNoiseEmitter
@onready var _test_loud_noise_timer: Timer = %LoudNoiseTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_test_loud_noise_timer.timeout.connect(_on_loud_noise_timer_fired)
	pass # Replace with function body.

func _on_loud_noise_timer_fired() -> void:
	print("TIMER FIRED")
	_test_loud_noise_emitter.emit_noise(1.0)
