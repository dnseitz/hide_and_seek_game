@tool class_name MonsterInputController extends PlayerInputControllerBase

const ENVIRONMENT_NOISE_GROUP_NAME := &"environment_noise"
const ENVIRONMENT_NOISES_MAX_COUNT := 64

const SHADER_ENVIRONMENT_NOISES_DATA_PARAM := "environment_noises"
const SHADER_ENVIRONMENT_NOISES_COUNT_PARAM := "environment_noises_count"

const VISION_PULSE_IN_DURATION := 0.5
const VISION_PULSE_OUT_DURATION := 3.5
const VISION_PULSE_TOTAL_DURATION := VISION_PULSE_IN_DURATION + VISION_PULSE_OUT_DURATION

const VISION_PULSE_MAX_RADIUS := 30.0

const SHADER_PULSE_START_POINT_PARAM := "pulse_start_point"

const SHADER_PULSE_RADIUS_PARAM := "pulse_radius"
const SHADER_PULSE_BRIGHTNESS_PARAM := "pulse_brightness"

const SHADER_ENVIRONMENT_VISIBILITY_PARAM := "environment_visibility"
const SHADER_VISIBLE_RADIUS_PARAM := "visible_radius"
const SHADER_VISIBLE_RADIUS_START_FEATHER_PARAM := "visible_radius_start_feather"
const SHADER_VISIBLE_RADIUS_END_FEATHER_PARAM := "visible_radius_end_feather"

signal vision_pulse_started
signal vision_pulse_ended

@export var _monster_vision_post_processing_quad: MeshInstance3D:
	set(new_value):
		_monster_vision_post_processing_quad = new_value
		update_configuration_warnings()

# Vision Pulse
var _monster_vision_shader_material: ShaderMaterial

var _pulse_start_point: Vector3:
	set(new_value):
		if _monster_vision_shader_material == null:
			return
		
		_pulse_start_point = new_value
		_monster_vision_shader_material.set_shader_parameter(SHADER_PULSE_START_POINT_PARAM, new_value)

var _pulse_radius: float = 0.0:
	set(new_value):
		if _monster_vision_shader_material == null:
			print("VALUE NOT SET")
			return
		
		_pulse_radius = new_value
		_monster_vision_shader_material.set_shader_parameter(SHADER_PULSE_RADIUS_PARAM, new_value)
var _visibility_radius: float = 0.0:
	set(new_value):
		if _monster_vision_shader_material == null:
			return
		
		_visibility_radius = new_value
		_monster_vision_shader_material.set_shader_parameter(SHADER_VISIBLE_RADIUS_PARAM, new_value)
var _visibility_start_fade: float = 0.0:
	set(new_value):
		if _monster_vision_shader_material == null:
			return
		
		_visibility_start_fade = new_value
		_monster_vision_shader_material.set_shader_parameter(SHADER_VISIBLE_RADIUS_START_FEATHER_PARAM, new_value)
var _visibility_end_fade: float = 0.0:
	set(new_value):
		if _monster_vision_shader_material == null:
			return
		
		_visibility_end_fade = new_value
		_monster_vision_shader_material.set_shader_parameter(SHADER_VISIBLE_RADIUS_END_FEATHER_PARAM, new_value)

var _pulse_brightness: float = 0.0:
	set(new_value):
		if _monster_vision_shader_material == null:
			return
		
		_pulse_brightness = new_value
		_monster_vision_shader_material.set_shader_parameter(SHADER_PULSE_BRIGHTNESS_PARAM, new_value)

var _environment_visibility: float = 0.0:
	set(new_value):
		if _monster_vision_shader_material == null:
			return
		
		_environment_visibility = new_value
		_monster_vision_shader_material.set_shader_parameter(SHADER_ENVIRONMENT_VISIBILITY_PARAM, new_value)

var _current_pulse_shapes_hit_rids: Array[RID] = []

var is_pulsing: bool = false

func _get_configuration_warnings() -> PackedStringArray:
	if _monster_vision_post_processing_quad == null \
		or _monster_vision_post_processing_quad.mesh == null \
		or  _monster_vision_post_processing_quad.mesh.surface_get_material(0) == null \
		or _monster_vision_post_processing_quad.mesh.surface_get_material(0) is ShaderMaterial == false:
			return ["Post processing quad should be set in the editor with a ShaderMaterial"]
	
	return []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

	# get_viewport().use_debanding = true
	# RenderingServer.material_set_use_debanding(true)

	_monster_vision_shader_material = _monster_vision_post_processing_quad.mesh.surface_get_material(0)
	_monster_vision_post_processing_quad.visible = true

	_reset_pulse_parameters()

func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority() == false:
		return

	_handle_environment_noises()
	_handle_pulse()

func _gather() -> void:
	super._gather()

func _input(event: InputEvent) -> void:
	super._input(event)

	if is_multiplayer_authority() == false:
		return

	if event is InputEventMouseButton == false:
		return
	
	var mouse_button_event: InputEventMouseButton = event

	# TODO: Make pulse button re-bindable in settings
	if is_pulsing == false and mouse_button_event.button_index == MOUSE_BUTTON_RIGHT and mouse_button_event.is_released():
		is_pulsing = true
		vision_pulse_started.emit()
		_pulse_start_point = global_position

		var pulse_radius_tween := create_tween()
		pulse_radius_tween.set_ease(Tween.EASE_OUT)
		var pulse_brightness_tween := create_tween()
		pulse_brightness_tween.set_ease(Tween.EASE_OUT)

		pulse_radius_tween.tween_property(self, "_pulse_radius", VISION_PULSE_MAX_RADIUS, VISION_PULSE_IN_DURATION)
		pulse_brightness_tween.tween_property(self, "_pulse_brightness", 1000.0, VISION_PULSE_IN_DURATION / 2.0)
		pulse_brightness_tween.chain().tween_property(self, "_pulse_brightness", 0.0, VISION_PULSE_IN_DURATION / 2.0)
		pulse_radius_tween.chain().tween_callback(func() -> void:
			_pulse_radius = 0.0
		)

		var visibility_tween := create_tween()

		visibility_tween.tween_property(self, "_environment_visibility", 1.0, VISION_PULSE_IN_DURATION / 4.0)
		visibility_tween.parallel().tween_property(self, "_visibility_radius", VISION_PULSE_MAX_RADIUS, VISION_PULSE_IN_DURATION)
		visibility_tween.parallel().tween_property(self, "_visibility_start_fade", VISION_PULSE_MAX_RADIUS * 2.0, VISION_PULSE_IN_DURATION) 
		visibility_tween.parallel().tween_property(self, "_visibility_end_fade", VISION_PULSE_MAX_RADIUS / 2.0, VISION_PULSE_IN_DURATION)

		visibility_tween.chain().tween_property(self, "_environment_visibility", 0.0, VISION_PULSE_OUT_DURATION)
		visibility_tween.parallel().tween_property(self, "_visibility_end_fade", 0.0, VISION_PULSE_OUT_DURATION)
		visibility_tween.parallel().tween_property(self, "_visibility_start_fade", 0.0, VISION_PULSE_OUT_DURATION)

		visibility_tween.chain().tween_callback(func() -> void:
			_reset_pulse_parameters()
			vision_pulse_ended.emit()
		)

func get_is_pulsing() -> bool:
	return is_pulsing

func _handle_environment_noises() -> void:
	var environment_noises: Array[MonsterEnvironmentNoise]
	for node in get_tree().get_nodes_in_group(ENVIRONMENT_NOISE_GROUP_NAME):
		if node is MonsterEnvironmentNoise == false:
			push_warning("Non-noise node in environment noise group")
			continue
		
		var noise: MonsterEnvironmentNoise = node
		environment_noises.append(noise)

	if environment_noises.size() > ENVIRONMENT_NOISES_MAX_COUNT:
		environment_noises.sort_custom(func(noise_a: MonsterEnvironmentNoise, noise_b: MonsterEnvironmentNoise) -> bool:
			return noise_a.global_position.distance_squared_to(global_position) < noise_b.global_position.distance_squared_to(global_position)
		)
		environment_noises = environment_noises.slice(0, ENVIRONMENT_NOISES_MAX_COUNT)
	
	var environment_noise_data: PackedVector4Array = []
	for noise in environment_noises:
		environment_noise_data.append(Vector4(
			noise.global_position.x,
			noise.global_position.y,
			noise.global_position.z,
			noise.get_noise_radius()
		))
	
	_monster_vision_shader_material.set_shader_parameter(SHADER_ENVIRONMENT_NOISES_DATA_PARAM, environment_noise_data)
	_monster_vision_shader_material.set_shader_parameter(SHADER_ENVIRONMENT_NOISES_COUNT_PARAM, environment_noise_data.size())

func _handle_pulse() -> void:
	if is_pulsing == false or _pulse_radius <= 0.0:
		return

	var space_state := get_world_3d().direct_space_state

	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = _pulse_radius

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere_shape
	query.collision_mask = 1 << 3 # monster vision environment object layer
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.transform = Transform3D(Basis(), _pulse_start_point)
	query.motion = Vector3.ZERO
	query.exclude = _current_pulse_shapes_hit_rids

	var result: Array[Dictionary] = space_state.intersect_shape(query)

	if result.size() > 0:
		for hit in result:
			var collider: CollisionObject3D = hit["collider"]
			_current_pulse_shapes_hit_rids.append(collider.get_rid())
			var parent: Node = collider.get_parent()
			if parent is MonsterEnvironmentVisionEmitter:
				var emitter: MonsterEnvironmentVisionEmitter = parent
				emitter.hit_by_pulse(_pulse_radius / VISION_PULSE_MAX_RADIUS)

func _reset_pulse_parameters() -> void:
	_visibility_radius = 0.0
	_pulse_start_point = Vector3.ZERO
	_pulse_radius = 0.0
	_pulse_brightness = 0.0
	_environment_visibility = 0.0
	_visibility_start_fade = 0.0
	_visibility_end_fade = 0.0
	_current_pulse_shapes_hit_rids = []
	is_pulsing = false
