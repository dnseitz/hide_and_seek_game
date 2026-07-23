extends TriggerableComponent

@export var _objects_to_hide: Array[Node3D] = []

func trigger() -> void:
	for object in _objects_to_hide:
		object.visible = false