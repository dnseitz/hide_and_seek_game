extends Node

const LOADING_SCREEN := preload("res://menu/loading_screen/loading_screen.tscn")

signal scene_switched(new_scene: Node)

var _current_scene_container: Node

var _current_scene: Node

var _loading_screen: CanvasLayer
var _is_switching_scene: bool = false

func _enter_tree() -> void:
	_current_scene_container = get_tree().current_scene
	_current_scene = _current_scene_container

func get_current_scene() -> Node:
	return _current_scene

func set_current_scene_container(node: Node) -> void:
	_current_scene_container = node
	_current_scene = _current_scene_container.get_child(0)

func show_loading_screen() -> void:
	var loading_screen: CanvasLayer = LOADING_SCREEN.instantiate()
	get_tree().root.add_child(loading_screen)
	await RenderingServer.frame_post_draw
	_loading_screen = loading_screen

func hide_loading_screen() -> void:
	_loading_screen.queue_free()
	_loading_screen = null
	await RenderingServer.frame_post_draw

func switch_scene(file_path: String) -> void:
	if _is_switching_scene:
		push_error("Tried to switch scene while another scene switch is in progress!")
		return
	_is_switching_scene = true
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

	await _switch_scene_packed(packed_scene)

	_is_switching_scene = false

func _switch_scene_packed(packed_scene: PackedScene) -> void:
	for child in _current_scene_container.get_children():
		child.queue_free()
	
	await RenderingServer.frame_post_draw
	print("ADDING SCENE")
	await RenderingServer.frame_post_draw
	var add_start_time: int = Time.get_ticks_usec()

	var new_scene: Node = packed_scene.instantiate()
	_current_scene = new_scene
	_current_scene_container.add_child(new_scene)

	var add_end_time: int = Time.get_ticks_usec()
	var execution_time_us: int = add_end_time - add_start_time
	var execution_time_ms: float = execution_time_us / 1_000.0

	await RenderingServer.frame_post_draw
	print("ADDING SCENE TOOK: %s ms" % execution_time_ms)
	await RenderingServer.frame_post_draw

	scene_switched.emit(new_scene)