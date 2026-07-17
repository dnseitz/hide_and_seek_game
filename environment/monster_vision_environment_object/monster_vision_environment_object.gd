@tool extends Node3D

@export var _mesh_instance: MeshInstance3D:
	set(new_value):
		_mesh_instance = new_value

		if Engine.is_editor_hint():
			update_configuration_warnings()

@onready var _particle_emitter: GPUParticles3D = %GPUParticles3D

func _get_configuration_warnings() -> PackedStringArray:
	if _mesh_instance == null or _mesh_instance.mesh == null:
		return ["Monster environment object must have a mesh instance set"]
	
	return []

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
