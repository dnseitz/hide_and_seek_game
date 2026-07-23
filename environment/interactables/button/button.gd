extends Interactable

@onready var _animation_player: AnimationPlayer = %AnimationPlayer

func get_interaction_text() -> String:
	# TODO: Localize
	return "Press"

func _will_interact() -> void:
	enabled = false

func _did_interact() -> void:
	_animation_player.play("press")