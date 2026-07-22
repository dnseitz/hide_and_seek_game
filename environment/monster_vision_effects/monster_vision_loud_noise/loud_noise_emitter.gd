class_name LoudNoiseEmitter extends Node3D

const LOUD_NOISE_EFFECT := preload("monster_vision_loud_noise.tscn")

func emit_noise(loudness: float) -> void:
	if multiplayer.is_server() == false:
		return

	var effect: Node3D = LOUD_NOISE_EFFECT.instantiate()

	effect.scale = Vector3(loudness, loudness, loudness)
	effect.top_level = true
	add_child(effect, true)
	effect.global_position = global_position
	effect.reset_physics_interpolation()