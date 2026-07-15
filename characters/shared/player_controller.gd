class_name PlayerController extends Node3D

# TODO: Pull this from settings menu
@export var mouse_sensitivity: float = 0.25
# TODO: Radian slider in editor
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 6.0

# @export 

@onready var _character_body: CharacterBody3D = $CharacterBody3D
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D

var _cam_input_direction := Vector2.ZERO

# func _process(delta: float) -> void:
# 	_handle_movement(delta)

func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x += _cam_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y -= _cam_input_direction.x * delta

	_cam_input_direction = Vector2.ZERO

	var raw_direction := _get_raw_movement_direction()
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x

	var direction = forward * raw_direction.z + right * raw_direction.x
	if direction.length() > 0.0:
		direction = direction.normalized()

	_character_body.velocity = direction * 5.0
	_character_body.move_and_slide()
	print("CHARACTER VELOCITY: ", _character_body.velocity)
	global_position = _character_body.global_position

func _input(event: InputEvent) -> void:
	if event.is_action_released("debug_left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_released("debug_esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion == false:
		return
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var mouse_motion_event: InputEventMouseMotion = event
	
	_cam_input_direction = mouse_motion_event.screen_relative * mouse_sensitivity

func _get_raw_movement_direction() -> Vector3:
	# var target_velocity := Vector3.ZERO

	var raw_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	return Vector3(
		raw_input.x,
		0.0,
		raw_input.y
	)
