extends Node

func get_player(peer_id: int) -> PlayerController:
	for node in get_tree().get_nodes_in_group(PlayerController.PLAYER_GROUP_NAME):
		if node is PlayerController == false:
			push_error("Non-PlayerController node in `%s` group" % PlayerController.PLAYER_GROUP_NAME)
			continue
		
		var player: PlayerController = node

		if player.get_player_input_authority() == peer_id:
			return player
	
	return null

func is_player_monster(peer_id: int) -> bool:
	return get_player(peer_id) is MonsterController

func is_player_human(peer_id: int) -> bool:
	return get_player(peer_id) is HumanController