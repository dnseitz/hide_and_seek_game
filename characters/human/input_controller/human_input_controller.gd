class_name HumanInputController extends PlayerInputControllerBase

var is_sneaking: bool

func _gather() -> void:
	super._gather()
	is_sneaking = Input.is_action_pressed("sneak_modifier")