class_name PlayerInputControllerBase extends Node3D

@export var _mouse_sensitivity: float = 0.25
@export var _camera: Camera3D

var camera_input_direction: Vector2 = Vector2.ZERO
var movement_input_direction: Vector2
var is_sprinting: bool

var authority_peer_id: int = MultiplayerManager.HOST_PEER_ID:
	set(new_value):
		print(MultiplayerManager._current_peer_info.peer_id, " - ", get_parent().name, ": Setting authority peer ID: ", new_value)
		authority_peer_id = new_value
		set_multiplayer_authority(authority_peer_id)

		if is_node_ready():
			# TODO: Fix this so we don't have to free the camera (or do we not care?)
			if is_multiplayer_authority():
				_camera.make_current()
			else:
				_camera.queue_free()

func _ready() -> void:
	NetworkTime.before_tick_loop.connect(_gather)

func _gather() -> void:
	if is_multiplayer_authority() == false:
		return
	
	movement_input_direction = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	is_sprinting = Input.is_action_pressed("sprint_modifier")

func _unhandled_input(event: InputEvent) -> void:
	if is_multiplayer_authority() == false:
		return

	if event is InputEventMouseMotion == false:
		return
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var mouse_motion_event: InputEventMouseMotion = event
	
	camera_input_direction = mouse_motion_event.screen_relative * _mouse_sensitivity

#region public methods
func consume_cam_input_direction() -> Vector2:
	var input_direction := camera_input_direction
	camera_input_direction = Vector2.ZERO
	return input_direction
#endregion
