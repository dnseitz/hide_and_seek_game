class_name PlayerInputControllerBase extends Node3D

@export var _mouse_sensitivity: float = 0.25

var _cam_input_direction: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
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