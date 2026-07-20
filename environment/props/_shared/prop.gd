class_name EnvironmentProp extends RigidBody3D

const GROUP_NAME := &"environment_object"

var _meshes: Array[MeshInstance3D] = []
var _monster_vision_emitter: MonsterEnvironmentVisionEmitter

func _ready() -> void:
	if multiplayer.is_server() == false:
		freeze = true
	_meshes = []
	for child in get_children():
		if child is MeshInstance3D:
			var mesh: MeshInstance3D = child
			mesh.layers = Constants.Visibility.HUMAN_VISION_LAYER
			_meshes.append(mesh)
		elif child is MonsterEnvironmentVisionEmitter:
			if _monster_vision_emitter != null:
				push_warning("Multiple monster vision emitters found")
			_monster_vision_emitter = child