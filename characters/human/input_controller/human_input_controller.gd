class_name HumanInputController extends PlayerInputControllerBase

@export_group("Components")
@export var _interaction_component: InteractionComponent

@export_group("UI")
@export var _ui: HumanUI

var is_sneaking: bool

func _ready() -> void:
	super._ready()

	_interaction_component.can_interact.connect(_on_can_interact)

func _gather() -> void:
	super._gather()
	is_sneaking = Input.is_action_pressed("sneak_modifier")

func _input(event: InputEvent) -> void:
	super._input(event)
	if is_multiplayer_authority() == false:
		return

	if event.is_action_released("interact"):
		_handle_interaction()

func _handle_interaction() -> void:
	var interactable := _interaction_component.get_interactable()
	if interactable == null:
		return
	
	interactable.interact()

func _configure_for_authority(peer_id: int) -> void:
	super._configure_for_authority(peer_id)
	_interaction_component.set_multiplayer_authority(peer_id)

	if is_multiplayer_authority():
		_ui.visible = true
	else:
		_ui.visible = false

#region callbacks
func _on_can_interact(interactable: Interactable) -> void:
	if is_multiplayer_authority() == false:
		return
	
	if interactable != null and interactable.enabled:
		_ui.set_interaction_text(interactable.get_interaction_text())
	else:
		_ui.set_interaction_text("")
#endregion
