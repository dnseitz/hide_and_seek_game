extends Node

var _current_scene_container: Node

func _enter_tree() -> void:
	_current_scene_container = get_tree().current_scene

func set_current_scene_container(node: Node) -> void:
	_current_scene_container = node

func switch_scene(file_path: String) -> void:
	await RenderingServer.frame_post_draw
	print("LOADING SCENE: ", file_path)
	await RenderingServer.frame_post_draw
	var load_start_time: int = Time.get_ticks_usec()

	var packed_scene: PackedScene = load(file_path)

	var load_end_time: int = Time.get_ticks_usec()
	var execution_time_us: int = load_end_time - load_start_time
	var execution_time_ms: float = execution_time_us / 1_000.0

	await RenderingServer.frame_post_draw
	print("LOADING TOOK: %s ms" % execution_time_ms)
	await RenderingServer.frame_post_draw

	await switch_scene_packed(packed_scene)

func switch_scene_packed(packed_scene: PackedScene) -> void:
	for child in _current_scene_container.get_children():
		child.queue_free()
	
	await RenderingServer.frame_post_draw
	print("ADDING SCENE")
	await RenderingServer.frame_post_draw
	var add_start_time: int = Time.get_ticks_usec()

	_current_scene_container.add_child(packed_scene.instantiate())

	var add_end_time: int = Time.get_ticks_usec()
	var execution_time_us: int = add_end_time - add_start_time
	var execution_time_ms: float = execution_time_us / 1_000.0

	await RenderingServer.frame_post_draw
	print("ADDING SCENE TOOK: %s ms" % execution_time_ms)
	await RenderingServer.frame_post_draw