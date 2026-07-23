@abstract class_name Interactable extends Area3D

## If the interactable object can be interacted with.
@export var enabled: bool = true

@export var triggerables: Array[TriggerableComponent] = []

## Get the text to show in the UI when the player is able to interact with this object.
@abstract func get_interaction_text() -> String

## Called when the player interacts with this object.
func interact() -> void:
	_interact.rpc_id(MultiplayerManager.HOST_PEER_ID)

@rpc("any_peer", "call_local")
func _interact() -> void:
	for triggerable in triggerables:
		triggerable.trigger()