extends Node

const TEST_NAMES := [
	"Llama", "Stumpo", "DJMotto"
]

const UNCONNECTED_PEER_ID := -1
const HOST_PEER_ID := 1

const DEFAULT_PORT := 8970
const PLAYER_COUNT := 5

signal server_started

signal server_disconnected

signal peers_changed

class PeerInfo extends RefCounted:
	var peer_id: int
	var peer_name: String

	func _init(init_peer_id: int) -> void:
		peer_id = init_peer_id

var _current_peer_info := PeerInfo.new(UNCONNECTED_PEER_ID)
var _connected_peers: Dictionary[int, PeerInfo]

var _loaded_players: Array[int] = []

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_successful_connect)
	multiplayer.connection_failed.connect(_on_failed_connect)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func close_server_if_needed() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		multiplayer.multiplayer_peer.close()

func host() -> int:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(DEFAULT_PORT, PLAYER_COUNT)
	if error != OK:
		push_error("Failed to start server: ", error_string(error))
		return error

	multiplayer.multiplayer_peer = peer

	_current_peer_info.peer_id = HOST_PEER_ID
	_current_peer_info.peer_name = TEST_NAMES.pick_random()
	_register_peer(_current_peer_info.peer_id, _current_peer_info.peer_name)
	server_started.emit()

	return OK

func join(addr: String) -> int:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(addr, DEFAULT_PORT)
	if error != OK:
		push_error("Failed to join %s: %s" % [addr, error_string(error)])
		return error
	
	multiplayer.multiplayer_peer = peer
	
	return OK

func get_peers() -> Array[PeerInfo]:
	var peers := _connected_peers.values().duplicate()
	peers.sort_custom(func(a: PeerInfo, b: PeerInfo) -> bool:
		return a.peer_id < b.peer_id
	)
	return peers

func will_start_loading_new_map() -> void:
	if multiplayer.is_server() == false:
		return

	_loaded_players = []

@rpc("call_local", "reliable")
func load_map(file_path: String) -> void:
	print("PEER ID: %d - LOAD MAP STARTED" % multiplayer.get_unique_id())
	await SceneSwitcher.show_loading_screen()
	await SceneSwitcher.switch_scene(file_path)

	loading_finished.rpc_id(HOST_PEER_ID)

@rpc("any_peer", "call_local", "reliable")
func loading_finished() -> void:
	if multiplayer.is_server() == false:
		return
	
	_loaded_players.append(multiplayer.get_remote_sender_id())

	if _loaded_players.size() >= _connected_peers.size() and _loaded_players.all(func(peer_id: int) -> bool:
		return _connected_peers.has(peer_id)
	):
		var loaded_map := SceneSwitcher.get_current_scene()
		if loaded_map is GameWorldBase == false:
			push_error("Unexpected map loaded, must be subclass of `GameWorldBase`")
			return
		var game_world: GameWorldBase = loaded_map	

		game_world.start_game()

@rpc("any_peer", "reliable")
func _register_peer(peer_id: int, peer_name: String) -> void:
	var peer_info := PeerInfo.new(peer_id)
	peer_info.peer_name = peer_name
	_connected_peers[peer_info.peer_id] = peer_info

	peers_changed.emit()

func _unregister_peer(peer_id: int) -> void:
	_connected_peers.erase(peer_id)

	peers_changed.emit()

func _remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_current_peer_info.peer_id = UNCONNECTED_PEER_ID
	_connected_peers.clear()

#region callbacks
func _on_peer_connected(peer_id: int) -> void:
	_register_peer.rpc_id(
		peer_id, 
		multiplayer.get_unique_id(), 
		_current_peer_info.peer_name
	)

func _on_peer_disconnected(peer_id: int) -> void:
	_unregister_peer(peer_id)
	# TODO: Need to handle disconnects during loading screen

func _on_successful_connect() -> void:
	_current_peer_info.peer_id = multiplayer.get_unique_id()
	_current_peer_info.peer_name = TEST_NAMES.pick_random()
	_register_peer(_current_peer_info.peer_id, _current_peer_info.peer_name)

func _on_failed_connect() -> void:
	_remove_multiplayer_peer()

func _on_server_disconnected() -> void:
	_remove_multiplayer_peer()
	server_disconnected.emit()

	push_error("Server disconnected")
	# TODO: Return to main menu with message
#endregion