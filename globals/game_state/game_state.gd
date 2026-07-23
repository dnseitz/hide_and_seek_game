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

func is_current_player_monster() -> bool:
	return is_player_monster(MultiplayerManager.get_current_peer_info().peer_id)

func is_player_monster(peer_id: int) -> bool:
	return get_player(peer_id) is MonsterController

func is_current_player_human() -> bool:
	return is_player_human(MultiplayerManager.get_current_peer_info().peer_id)

func is_player_human(peer_id: int) -> bool:
	return get_player(peer_id) is HumanController