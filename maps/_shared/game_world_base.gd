@abstract class_name GameWorldBase extends Node3D

const HUMAN_SCENE := preload("res://characters/human/human.tscn")
const MONSTER_SCENE := preload("res://characters/monster/monster.tscn")

## A container node for players to be spawned into. 
##
## There is a multiplayer spawner observing this node to synchronize between clients.
@onready var _players_container: Node3D = %PlayersContainer

## Should only be called once by the server once all players have loaded into 
## the map.
##
## All players are ready to receive RPCs on this level.
##
## This will only be called on the server.
func start_game() -> void:
	_start_game_custom_map_logic()
	hide_loading_screen.rpc()

func spawn_player_scene(packed_scene: PackedScene, peer_id: int, global_spawn_position: Vector3) -> void:
	var player_node: PlayerController = packed_scene.instantiate()
	player_node.name = "PLAYER <%d>" % peer_id

	_players_container.add_child(player_node)
	player_node.set_player_input_authority.rpc(peer_id)
	player_node.global_position = global_spawn_position

@rpc("any_peer", "call_local", "reliable")
func hide_loading_screen() -> void:
	await SceneSwitcher.hide_loading_screen()

@abstract func _start_game_custom_map_logic() -> void
