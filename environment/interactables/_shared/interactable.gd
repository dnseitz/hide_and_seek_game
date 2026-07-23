@abstract class_name Interactable extends Trigger

## Get the text to show in the UI when the player is able to interact with this object.
@abstract func get_interaction_text() -> String

## Do something when this is interacted with (like show an animation, make a noise, etc.)
##
## Called on all clients.
@rpc("call_local")
@abstract func _did_interact() -> void

## Do some setup when this is interacted with, but before any triggers are run.
##
## This is only called on the server.
@abstract func _will_interact() -> void

## Called when the player interacts with this object.
func interact() -> void:
	_interact.rpc_id(MultiplayerManager.HOST_PEER_ID)

@rpc("any_peer", "call_local")
func _interact() -> void:
	if multiplayer.is_server() == false:
		push_error("Interaction logic called outside of server instance")
		return

	var payload := Payload.new(multiplayer.get_remote_sender_id())
	_will_interact()
	trigger(payload)
	_did_interact.rpc()