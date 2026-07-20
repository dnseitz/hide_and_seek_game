class_name PlayerInputControllerBase extends Node3D

@export var _mouse_sensitivity: float = 0.25
@export var _camera: Camera3D

var _cam_input_direction: Vector2 = Vector2.ZERO

var authority_peer_id: int = MultiplayerManager.HOST_PEER_ID:
	set(new_value):
		print(MultiplayerManager._current_peer_info.peer_id, " - ", get_parent().name, ": Setting authority peer ID: ", new_value)
		authority_peer_id = new_value
		set_multiplayer_authority(authority_peer_id)

		if is_node_ready():
			if is_multiplayer_authority():
				_camera.make_current()
			else:
				_camera.queue_free()

func _ready() -> void:
	pass
	# print(multiplayer.get_unique_id(), " - ", get_parent().name, ": Checking camera against authority: ", authority_peer_id)
	# if is_multiplayer_authority():
	# 	_camera.make_current()
	# if multiplayer.get_unique_id() == authority_peer_id:
	# 	print(authority_peer_id, " - ", get_parent().name, ": Making camera current")
	# 	_camera.make_current()
	# else:
	# 	_camera.current = false

func _unhandled_input(event: InputEvent) -> void:
	if is_multiplayer_authority() == false:
		return

	if event is InputEventMouseMotion == false:
		return
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var mouse_motion_event: InputEventMouseMotion = event
	
	_cam_input_direction = mouse_motion_event.screen_relative * _mouse_sensitivity

#region public methods
func consume_cam_input_direction() -> Vector2:
	var input_direction := _cam_input_direction
	_cam_input_direction = Vector2.ZERO
	return input_direction

func get_movement_input_direction() -> Vector2:
	return Input.get_vector("move_right", "move_left", "move_back", "move_forward")

func is_sprinting() -> bool:
	return Input.is_action_pressed("sprint_modifier")
#endregion
