@abstract class_name GameWorldBase extends Node3D

## Should only be called once by the server once all players have loaded into 
## the map.
##
## All players are ready to receive RPCs on this level.
##
## This will only be called on the server.
func start_game() -> void:
	_start_game_custom_map_logic()
	hide_loading_screen.rpc()

@rpc("any_peer", "call_local", "reliable")
func hide_loading_screen() -> void:
	await SceneSwitcher.hide_loading_screen()

@abstract func _start_game_custom_map_logic() -> void