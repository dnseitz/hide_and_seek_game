extends Node

@onready var current_scene_container: Node = %CurrentSceneContainer

func _ready() -> void:
	SceneSwitcher.set_current_scene_container(current_scene_container)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			MultiplayerManager.close_server_if_needed()
			get_tree().quit()
