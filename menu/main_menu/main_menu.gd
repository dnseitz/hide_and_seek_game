extends Control

@onready var _host_button: Button = %HostButton
@onready var _lobby_code: LineEdit = %LobbyCodeLineEdit
@onready var _join_button: Button = %JoinButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)

#region callbacks
func _on_host_pressed() -> void:
	# TODO: Show loading indicator while setting up
	var error := await MultiplayerManager.host()

	if error != OK:
		return
	
	print("SUCCESSFULLY STARTED SERVER")
	await SceneSwitcher.switch_scene("res://menu/lobby/lobby.tscn")

func _on_join_pressed() -> void:
	var code := _lobby_code.text
	var error := await MultiplayerManager.join(code)

	if error != OK:
		return

	print("SUCCESSFULLY JOINED SERVER")
	await SceneSwitcher.switch_scene("res://menu/lobby/lobby.tscn")
#endregion
