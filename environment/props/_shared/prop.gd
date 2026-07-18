class_name EnvironmentProp extends Node3D

const GROUP_NAME := &"environment_object"

var _meshes: Array[MeshInstance3D] = []
var _monster_vision_emitter: MonsterEnvironmentVisionEmitter

func _ready() -> void:
	_meshes = []
	for child in get_children():
		if child is MeshInstance3D:
			_meshes.append(child)
		elif child is MonsterEnvironmentVisionEmitter:
			if _monster_vision_emitter != null:
				push_warning("Multiple monster vision emitters found")
			_monster_vision_emitter = child

func make_meshes_visible(mesh_visible: bool) -> void:
	for mesh in _meshes:
		mesh.visible = mesh_visible