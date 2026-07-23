class_name HumanUI extends CanvasLayer

@onready var _interaction_label: Label = %InteractionLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_interaction_text(text: String) -> void:
	_interaction_label.text = text