extends MonsterEnvironmentNoise

# @onready var _particle_emitter: GPUParticles3D = %GPUParticles3D

## Just for animating the noise radius along with the other animations
@export var _noise_radius: float = 1.0

func _ready() -> void:
	# Always make this top level
	top_level = true
	# print("LOUD NOISE ADDED")
	# _particle_emitter.finished.connect(func() -> void:
	# 	print("LOUD NOISE REMOVED")
	# 	queue_free()
	# )

func get_noise_radius() -> float:
	return _noise_radius * maxf(scale.x, scale.z) * 5.0