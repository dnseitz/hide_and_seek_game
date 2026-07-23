class_name PlayerInputControllerBase extends Node3D

@export var _mouse_sensitivity: float = 0.25
@export var _camera: Camera3D

var camera_input_direction: Vector2 = Vector2.ZERO
var movement_input_direction: Vector2 = Vector2.ZERO
var is_sprinting: bool

var _movement_input_direction_buffer: Vector2 = Vector2.ZERO
var _movement_input_direction_samples: int = 0

var authority_peer_id: int = MultiplayerManager.HOST_PEER_ID:
	set(new_value):
		print(MultiplayerManager._current_peer_info.peer_id, " - ", get_parent().name, ": Setting authority peer ID: ", new_value)
		authority_peer_id = new_value
		set_multiplayer_authority(authority_peer_id)

		if is_node_ready():
			_configure_for_authority(authority_peer_id)

func _ready() -> void:
	NetworkTime.before_tick_loop.connect(func() -> void:
		if is_multiplayer_authority() == false:
			return
		
		_gather()
	)

	NetworkTime.after_tick.connect(func(_delta: float, _tick: int) -> void:
		if is_multiplayer_authority() == false:
			return
		
		_gather_always()
	)

## For continuous inputs
func _gather() -> void:
	if _movement_input_direction_samples > 0:
		movement_input_direction = _movement_input_direction_buffer / _movement_input_direction_samples
	else:
		movement_input_direction = Vector2.ZERO
	# movement_input_direction = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	is_sprinting = Input.is_action_pressed("sprint_modifier")

	# Reset accumulation buffers
	_movement_input_direction_buffer = Vector2.ZERO
	_movement_input_direction_samples = 0

## For one-off button press inputs
func _gather_always() -> void:
	pass

func _process(_delta: float) -> void:
	_movement_input_direction_buffer += Vector2(
		Input.get_axis("move_right", "move_left"),
		Input.get_axis("move_back", "move_forward")
	)
	_movement_input_direction_samples += 1

func _input(_event: InputEvent) -> void:
	# Common override point for subclasses
	return

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

func _configure_for_authority(_peer_id: int) -> void:
	# TODO: Fix this so we don't have to free the camera (or do we not care?)
	if is_multiplayer_authority():
		_camera.make_current()
	else:
		_camera.queue_free()