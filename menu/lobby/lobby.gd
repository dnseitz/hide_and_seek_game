extends Control

@onready var _player_list_container: VBoxContainer = %PlayerListContainer

@onready var _start_button: Button = %StartButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_player_list()
	MultiplayerManager.peers_changed.connect(_on_peers_changed)

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

func _on_start_pressed() -> void:
	MultiplayerManager.will_start_loading_new_map()
	MultiplayerManager.load_map.rpc("res://maps/monster_test_world/monster_test_world.tscn")
#endregion
