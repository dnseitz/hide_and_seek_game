extends Node3D

@onready var _particle_emitter: GPUParticles3D = %GPUParticles3D

func _ready() -> void:
	print("LOUD NOISE ADDED")
	_particle_emitter.finished.connect(func() -> void:
		print("LOUD NOISE REMOVED")
		queue_free()
	)
