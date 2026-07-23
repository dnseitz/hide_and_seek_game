extends TriggerableComponent

func trigger(payload: Payload) -> void:
	var escaping_peer_id := payload.triggering_peer_id

	var player := GameState.get_player(escaping_peer_id)
	if player is HumanController == false:
		return
	
	var human: HumanController = player

	human.show_escape_screen.rpc_id(escaping_peer_id)