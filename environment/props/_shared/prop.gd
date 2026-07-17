extends Node3D

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
	
	# if monster hide all meshes
	# else hide monster emitter
	for mesh in _meshes:
		mesh.visible = false
