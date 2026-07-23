class_name InteractionComponent extends Node3D

signal can_interact(interactable: Interactable)

@onready var _interaction_ray_cast: RayCast3D = %InteractionRayCast3D

var _current_interactable: Interactable:
	set(new_value):
		if _current_interactable == new_value:
			return

		_current_interactable = new_value
		can_interact.emit(_current_interactable)

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority() == false:
		if _interaction_ray_cast.enabled == true:
			_interaction_ray_cast.enabled = false
		return
	
	if _interaction_ray_cast.is_colliding():
		var hit_object := _interaction_ray_cast.get_collider()

		if hit_object is Interactable == false:
			return
		
		_current_interactable = hit_object
	else:
		_current_interactable = null

func get_interactable() -> Interactable:
	return _current_interactable