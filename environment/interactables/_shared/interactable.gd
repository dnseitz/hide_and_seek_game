@abstract class_name Interactable extends Node3D

## Get the text to show in the UI when the player is able to interact with this object.
@abstract func get_interaction_text() -> String

## Called when the player interacts with this object.
@abstract func interact() -> void