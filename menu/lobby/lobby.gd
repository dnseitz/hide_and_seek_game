extends Control

@onready var _player_list_container: VBoxContainer = %PlayerListContainer
@onready var _lobby_code_button: Button = %LobbyCodeValueButton

@onready var _start_button: Button = %StartButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_player_list()
	MultiplayerManager.peers_changed.connect(_on_peers_changed)

	var current_lobby_code := MultiplayerManager.get_current_lobby_code()
	_lobby_code_button.text = current_lobby_code
	_lobby_code_button.pressed.connect(_on_copy_lobby_code.bind(current_lobby_code))

	if multiplayer.is_server():
		_start_button.visible = true
		_start_button.pressed.connect(_on_start_pressed)
	else:
		_start_button.visible = false

func _update_player_list() -> void:
	var peers := MultiplayerManager.get_peers()
	print("NEW PEERS LIST: ", peers)
	for child in _player_list_container.get_children():
		child.queue_free()

	for peer_info in peers:
		var label := Label.new()
		label.text = "%d - %s" % [peer_info.peer_id, peer_info.peer_name]
		# label.text = peer_info.peer_name if peer_info.peer_name != "" else "<Peer %d>" % peer_info.peer_id
		_player_list_container.add_child(label)

#region callbacks
func _on_peers_changed() -> void:
	_update_player_list()

func _on_copy_lobby_code(lobby_code: String) -> void:
	print("COPIED LOBBY CODE: ", lobby_code)
	DisplayServer.clipboard_set(lobby_code)

func _on_start_pressed() -> void:
	MultiplayerManager.will_start_loading_new_map()
	MultiplayerManager.load_map.rpc("res://maps/game_maps/01_test_map/01_test_map.tscn")
#endregion
