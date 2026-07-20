extends GameWorldBase

func _start_game_custom_map_logic() -> void:
	var monster_peer: MultiplayerManager.PeerInfo = MultiplayerManager.get_peers().pick_random()
	print("MONSTER PEER ID SELECTED: ", monster_peer.peer_id)

	for peer_info in MultiplayerManager.get_peers():
		print("SPAWNING PEER ID: ", peer_info.peer_id)
		if peer_info.peer_id == monster_peer.peer_id:
			# Spawn monster
			spawn_player_scene(MONSTER_SCENE, peer_info.peer_id, Vector3.ZERO)
		else:
			# Spawn human
			spawn_player_scene(HUMAN_SCENE, peer_info.peer_id, Vector3(5.0, 0.0, 5.0))
