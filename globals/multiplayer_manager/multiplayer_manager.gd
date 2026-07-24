extends Node

const TEST_NAMES := [
	"Llama", "Stumpo", "DJMotto"
]

const NORAY_SERVER_ADDRESS := "192.255.141.212"
const NORAY_SERVER_COMMAND_PORT := 8890

const UNCONNECTED_PEER_ID := -1
const HOST_PEER_ID := 1

# const DEFAULT_PORT := 8970
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

var _current_lobby_code: String

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_successful_connect)
	multiplayer.connection_failed.connect(_on_failed_connect)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	Noray.on_connect_nat.connect(_handle_punchthrough_connect)
	Noray.on_connect_relay.connect(_handle_punchthrough_connect)

func get_current_lobby_code() -> String:
	return _current_lobby_code

func close_server_if_needed() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		multiplayer.multiplayer_peer.close()

func host() -> Error:
	# Connect to noray server
	var error := await _connect_to_noray()

	if error != OK:
		push_error("Failed to connect to noray server: ", error_string(error))
		return error

	var peer := ENetMultiplayerPeer.new()
	error = peer.create_server(Noray.local_port, PLAYER_COUNT)
	if error != OK:
		push_error("Failed to start server: ", error_string(error))
		return error

	_current_lobby_code = Noray.oid

	print("STARTED SERVER ON PORT: ", Noray.local_port)

	multiplayer.multiplayer_peer = peer

	_current_peer_info.peer_id = HOST_PEER_ID
	_current_peer_info.peer_name = TEST_NAMES.pick_random()
	_register_peer(_current_peer_info.peer_id, _current_peer_info.peer_name)
	server_started.emit()

	return OK

func join(lobby_code: String) -> Error:
	var error := await _connect_to_noray()

	if error != OK:
		push_error("Failed to connect to noray server: ", error_string(error))
		return error

	Noray.connect_nat(lobby_code)

	var winner: Signal = await await_either(multiplayer.connected_to_server, multiplayer.connection_failed)

	if winner == multiplayer.connection_failed:
		push_warning("Failed to connect to remote server with NAT punchthrough, falling back to relay")

		Noray.connect_relay(lobby_code)

		winner = await await_either(multiplayer.connected_to_server, multiplayer.connection_failed)

		if winner == multiplayer.connection_failed:
			push_warning("Failed to connect to remote server with relay")
			return ERR_UNAVAILABLE
	
	_current_lobby_code = lobby_code

	return OK

func get_current_peer_info() -> PeerInfo:
	return _current_peer_info

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

func _connect_to_noray() -> Error:
	var error := await Noray.connect_to_host(NORAY_SERVER_ADDRESS, NORAY_SERVER_COMMAND_PORT)
	if error != OK:
		return error
	
	print("CONNECTED TO NORAY HOST")
	
	print("REGISTERING HOST")
	error = Noray.register_host()
	if error != OK:
		return error
	await Noray.on_pid

	print("HOST REGISTERED - PID: ", Noray.pid)

	error = await Noray.register_remote()
	if error != OK:
		return error
	
	return OK

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
	print("CONNECTED TO SERVER! _on_successful_connect callback")
	_current_peer_info.peer_id = multiplayer.get_unique_id()
	_current_peer_info.peer_name = TEST_NAMES.pick_random()
	_register_peer(_current_peer_info.peer_id, _current_peer_info.peer_name)

func _on_failed_connect() -> void:
	print("FAILED TO CONNECT TO SERVER! _on_failed_connect callback")
	_remove_multiplayer_peer()

func _on_server_disconnected() -> void:
	_remove_multiplayer_peer()
	server_disconnected.emit()

	push_error("Server disconnected")
	# TODO: Return to main menu with message

## Handle connection to a peer by NAT-punchthrough or relay.
func _handle_punchthrough_connect(address: String, port: int) -> Error:
	var existing_peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer

	if existing_peer and multiplayer.is_server():
		# Server punchthrough to client
		# var error := await PacketHandshake.over_enet_peer(existing_peer, address, port)
		var error := await PacketHandshake.over_enet(existing_peer.host, address, port)

		if error != OK:
			# Server closed
			return error
		
		return OK
	else:
		# Client punchthrough and connect to server

		# Do UDP handshake
		var udp := PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(address, port)

		var error := await PacketHandshake.over_packet_peer(udp)
		udp.close()

		print("UDP HANDSHAKE ERROR: ", error, " - ", error_string(error))
		if error != OK and error != ERR_BUSY:
			push_error("Failed UDP packet handshake: ", error_string(error))
			return error
		
		# Connect to host
		var peer := ENetMultiplayerPeer.new()

		error = peer.create_client(address, port, 0, 0, 0, Noray.local_port)

		if error != OK:
			push_error("Failed to connect to server: ", error_string(error))
			_remove_multiplayer_peer()
			return error
		
		multiplayer.multiplayer_peer = peer
		print("PEER CONNECTION STATUS: ", peer.get_connection_status())
		# print("CONNECTED TO SERVER SUCCESSFULLY: %s:%s" % [address, port])

		return OK
#endregion

# This only works if both signals take no arguments
func await_either(signal_a: Signal, signal_b: Signal) -> Signal:
	var proxy := Object.new()
	proxy.add_user_signal("finished")

	var trigger := func(winning_signal: Signal) -> void:
		if is_instance_valid(proxy):
			proxy.emit_signal("finished", winning_signal)
	
	signal_a.connect(trigger.bind(signal_a), CONNECT_ONE_SHOT)
	signal_b.connect(trigger.bind(signal_b), CONNECT_ONE_SHOT)

	var result: Signal = await Signal(proxy, "finished")

	return result