@tool class_name MonsterEnvironmentVisionEmitter extends Node3D

@export var _mesh_instance: MeshInstance3D:
	set(new_value):
		_mesh_instance = new_value

		if Engine.is_editor_hint():
			update_configuration_warnings()
		
		if is_node_ready() and _mesh_instance and _mesh_instance.mesh:
			_update_emission_points(_mesh_instance.mesh)
			_update_collision_bounding_box(_mesh_instance.mesh)

@export_group("Debug")

@export var continously_emit: bool = false

@export_tool_button("Emit") var debug_emit := func() -> void:
	_particle_emitter.restart()

@onready var _particle_emitter: GPUParticles3D = %GPUParticles3D
@onready var _collision_shape: CollisionShape3D = %CollisionShape3D

var _particle_process_material: ParticleProcessMaterial

func _get_configuration_warnings() -> PackedStringArray:
	if _mesh_instance == null or _mesh_instance.mesh == null:
		return ["Monster environment object must have a mesh instance set"]
	
	return []

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_particle_process_material = _particle_emitter.process_material

	if _mesh_instance and _mesh_instance.mesh:
		_update_emission_points(_mesh_instance.mesh)
		_update_collision_bounding_box(_mesh_instance.mesh)
	
	if continously_emit:
		_particle_emitter.restart()
		_particle_emitter.finished.connect(func() -> void:
			_particle_emitter.restart()
		)

## This object was hit by a monster vision pulse.
##
## - Paramter distance_ratio: A value between [0, 1] representing how close the object was
##     to the origin of the pulse vs the maximum range of the pulse.
func hit_by_pulse(distance_ratio: float) -> void:
	var emission_scale := remap(
		distance_ratio,
		0.0, 1.0,
		1.0, 2.0
	)
	_particle_process_material.emission_shape_scale = Vector3(emission_scale, emission_scale, emission_scale)
	_particle_process_material.initial_velocity_min = remap(
		distance_ratio,
		0.0, 1.0,
		0.05, 0.2
	)
	_particle_process_material.initial_velocity_max = remap(
		distance_ratio,
		0.0, 1.0,
		0.15, 0.5
	)
	_particle_emitter.lifetime = remap(
		distance_ratio,
		0.0, 1.0,
		5.0, 2.0
	)
	_particle_process_material.lifetime_randomness = remap(
		distance_ratio,
		0.0, 1.0,
		0.1, 0.8
	)
	_particle_emitter.restart()

func _update_collision_bounding_box(mesh: Mesh) -> void:
	var box_shape := BoxShape3D.new()
	box_shape.size = mesh.get_aabb().size
	_collision_shape.shape = box_shape
	_collision_shape.position = mesh.get_aabb().get_center()

#region emission point generation
func _update_emission_points(mesh: Mesh) -> void:
	var emission_points := _generate_emission_points(mesh)
	var emission_texture := _generate_point_texture(emission_points)
	_particle_process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	_particle_process_material.emission_point_texture = emission_texture

# These two methods below are AI generated translations of the C++ godot engine code
# for generating emission points for the volume of a mesh, it seems to work properly 
# but who knows :)
func _generate_emission_points(mesh: Mesh) -> PackedVector3Array:
	var geometry := mesh.get_faces()
	@warning_ignore("integer_division")
	var gcount: int = geometry.size() / 3 # Total number of faces

	if gcount == 0:
		push_warning(tr("The geometry doesn't contain any faces."))
		return []

	# 1. Calculate AABB manually from all vertices
	var aabb: AABB = AABB()
	if geometry.size() > 0:
		aabb.position = geometry[0]
		for i in range(1, geometry.size()):
			aabb = aabb.expand(geometry[i])

	# var emissor_count: int = emission_amount.get_value()
	var emissor_count := 512
	var r_points: PackedVector3Array = []

	# 2. Process emission points
	for i in range(emissor_count):
		var attempts: int = 5
		
		for j in range(attempts):
			var dir: Vector3 = Vector3.ZERO
			dir[randi() % 3] = 1.0
			
			var rand_vec: Vector3 = Vector3(randf(), randf(), randf())
			var ofs: Vector3 = (Vector3(1, 1, 1) - dir) * rand_vec * aabb.size + aabb.position
			var ofsv: Vector3 = ofs + aabb.size * dir
			
			# Space it a little
			ofs -= dir
			ofsv += dir
			
			var max_val: float = -1e7
			var min_val: float = 1e7
			var has_intersection: bool = false
			
			# Loop through faces using index steps of 3
			for k in range(gcount):
				var idx: int = k * 3
				var v0: Vector3 = geometry[idx]
				var v1: Vector3 = geometry[idx + 1]
				var v2: Vector3 = geometry[idx + 2]
				
				# Geometry3D.segment_intersects_triangle returns null or Vector3 hit point
				var res: Variant = Geometry3D.segment_intersects_triangle(ofs, ofsv, v0, v1, v2)
				
				if res != null:
					var hit_point: Vector3 = res - ofs
					var d: float = dir.dot(hit_point)
					
					if d < min_val:
						min_val = d
					if d > max_val:
						max_val = d
					has_intersection = true
			
			if not has_intersection or max_val < min_val:
				continue # Lost attempt
				
			var val: float = min_val + (max_val - min_val) * randf()
			var point: Vector3 = ofs + dir * val
			
			r_points.append(point)
			break # Found a valid point, exit attempts loop
	return r_points

func _generate_point_texture(points: PackedVector3Array) -> ImageTexture:
	var point_count: int = points.size()
	var w: int = 2048
	@warning_ignore("integer_division")
	var h: int = (point_count / 2048) + 1

	# Create a byte array sized for float data (4 bytes per float, 3 floats per pixel)
	var point_img: PackedByteArray = PackedByteArray()
	point_img.resize(w * h * 3 * 4) 
	point_img.fill(0) # Equivalent to memset

	# Copy Vector3 data into the byte array as raw floats
	for i in range(point_count):
		var byte_offset: int = i * 3 * 4
		var point: Vector3 = points[i]
		
		point_img.encode_float(byte_offset, point.x)
		point_img.encode_float(byte_offset + 4, point.y)
		point_img.encode_float(byte_offset + 8, point.z)

	# Create the image and texture
	var image: Image = Image.create_from_data(w, h, false, Image.FORMAT_RGBF, point_img)
	return ImageTexture.create_from_image(image)
#endregion