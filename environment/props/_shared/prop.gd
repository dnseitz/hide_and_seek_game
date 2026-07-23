class_name EnvironmentProp extends RigidBody3D

const GROUP_NAME := &"environment_object"

var _meshes: Array[MeshInstance3D] = []
var _monster_vision_emitter: MonsterEnvironmentVisionEmitter

@onready var _multiplayer_synchronizer: MultiplayerSynchronizer = %MultiplayerSynchronizer

func _ready() -> void:
	if multiplayer.is_server() == false:
		if GameState.is_current_player_monster():
			# Clear collision layer if current player is monster, all collisions are handled on the server
			collision_layer = 0 
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
	
	sleeping_state_changed.connect(_on_sleeping_state_changed)

@rpc
func _client_sleep(sleep: bool) -> void:
	if sleep:
		_multiplayer_synchronizer.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		_multiplayer_synchronizer.process_mode = Node.PROCESS_MODE_INHERIT
	
#region callbacks
# TODO: Add upper bound on number of synchronizers that can be unfrozen at 
# a time? We'd have to play around with the number, ~30 seemed to start 
# causing issues, that or batch the physics objects into a single 
# synchronizer, maybe that improves performance?
# Too many causes serious desync issues, I think it's taking too much time
# processing in the tick loop and the rollback synchronization falls behind.
func _on_sleeping_state_changed() -> void:
	_client_sleep.rpc(sleeping)
	_client_sleep(sleeping)
	if sleeping:
		_multiplayer_synchronizer.public_visibility = false
	else:
		_multiplayer_synchronizer.public_visibility = true
#endregion