@abstract class_name Trigger extends Area3D

const Payload := TriggerableComponent.Payload

## If the interactable object can be interacted with.
@export var enabled: bool = true

@export var triggerables: Array[TriggerableComponent] = []

func trigger(payload: Payload) -> void:
	if multiplayer.is_server() == false:
		return

	for triggerable in triggerables:
		triggerable.trigger(payload)