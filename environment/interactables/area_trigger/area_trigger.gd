extends Trigger

func _ready() -> void:
	if multiplayer.is_server() == false:
		monitoring = false
		return

	monitoring = true
	print("SETTING UP BODY ENTERED MONITOR")
	body_entered.connect(_on_body_entered)

#region callbacks
func _on_body_entered(body: Node3D) -> void:
	print("BODY ENTERED")
	if body is PlayerController == false:
		return
	
	var player: PlayerController = body

	var payload := Payload.new(player.get_player_input_authority())
	trigger(payload)
	print("PLAYER ENTERED AREA: ", player.get_player_input_authority())
#endregion