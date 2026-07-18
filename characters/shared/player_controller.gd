@abstract class_name PlayerController extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var _input_controller: PlayerInputControllerBase:
	set(new_value):
		_input_controller = new_value
		update_configuration_warnings()

@export_group("Movement")
@export var _acceleration: float = 100.0
@export var _deceleration: float = 100.0

@export var _walk_speed: float = 5.0
@export var _sprint_speed: float = 8.0

@export_group("Look")
# TODO: Radian slider in editor
@export var tilt_upper_limit := PI / 2.0
@export var tilt_lower_limit := -PI / 2.0

@onready var _camera_pivot: Node3D = $CameraPivot

func _ready() -> void:
	# Left as a common override point in the future
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_released("debug_left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_released("debug_esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	_handle_camera_input(delta)
	_handle_movement_input(delta)

func _handle_camera_input(delta: float) -> void:
	var cam_input_direction := _input_controller.consume_cam_input_direction()
	_camera_pivot.rotation.x += cam_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	rotation.y -= cam_input_direction.x * delta
	# _camera_pivot.rotation.y -= _cam_input_direction.x * delta

func _handle_movement_input(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	# if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	# 	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := _input_controller.get_movement_input_direction()
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var movement_speed := _get_target_movement_speed()
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * movement_speed, _acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * movement_speed, _acceleration * delta)# direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, _deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, _deceleration * delta)

	move_and_slide()

func _get_target_movement_speed() -> float:
	if _input_controller.is_sprinting():
		return _sprint_speed
	return _walk_speed