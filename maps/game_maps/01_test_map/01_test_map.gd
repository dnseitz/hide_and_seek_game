extends GameWorldBase

@export var _monster_spawn_positions: Array[Marker3D]
@export var _human_spawn_positions: Array[Marker3D]

func _start_game_custom_map_logic() -> void:
	if _monster_spawn_positions.is_empty() or _human_spawn_positions.is_empty():
		push_error("Not enough spawn positions on map!")
		return
	
	var monster_peer: MultiplayerManager.PeerInfo = MultiplayerManager.get_peers().pick_random()
	print("MONSTER PEER ID SELECTED: ", monster_peer.peer_id)

	var possible_human_spawn_positions: Array[Marker3D] = _human_spawn_positions.duplicate()

	for peer_info in MultiplayerManager.get_peers():
		print("SPAWNING PEER ID: ", peer_info.peer_id)
		if peer_info.peer_id == monster_peer.peer_id:
			var spawn_position: Marker3D = _monster_spawn_positions.pick_random()
			# Spawn monster
			spawn_player_scene(MONSTER_SCENE, peer_info.peer_id, spawn_position.global_position)
		else:
			if possible_human_spawn_positions.is_empty():
				possible_human_spawn_positions = _human_spawn_positions.duplicate()

			var spawn_position: Marker3D = possible_human_spawn_positions.pop_at(randi() % possible_human_spawn_positions.size())
			# Spawn human
			spawn_player_scene(HUMAN_SCENE, peer_info.peer_id, spawn_position.global_position)
