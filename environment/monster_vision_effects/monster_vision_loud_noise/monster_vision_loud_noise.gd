extends MonsterEnvironmentNoise

## Just for animating the noise radius along with the other animations
@export var _noise_radius: float = 1.0

func _ready() -> void:
	# Always make this top level
	top_level = true

func get_noise_radius() -> float:
	return _noise_radius * maxf(scale.x, scale.z) * 5.0

func _noise_finished() -> void:
	if is_multiplayer_authority():
		queue_free()