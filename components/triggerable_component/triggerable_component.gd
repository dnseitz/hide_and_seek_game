@abstract class_name TriggerableComponent extends Node

class Payload extends RefCounted:
	var triggering_peer_id: int

	func _init(init_triggering_peer_id: int) -> void:
		triggering_peer_id = init_triggering_peer_id

## Do something when the component is triggered
@abstract func trigger(payload: Payload) -> void