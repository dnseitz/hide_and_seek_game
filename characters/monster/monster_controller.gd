extends PlayerController

## Proposed Monster mechanics:
##   Audio:
##     Audio is muffled/distorted. It should be relatively uniform in "sound" but vary in "loudness"
##     so monster player can make some distinction but not automatically know what sound is being
##     made.
##   Vision:
##     Monster's screen is black, "loud" noises always pop up as red pings in the view so monster 
##     can "hear" them (along with audio queues to actually hear). To see the environment the monster
##     can send out a sonic ping to reveal the terrain around it. Objects in the environment show up
##     as a cloud of bright points, so monster can see "something is there" but doesn't necessarily
##     know what it is.
##   Movement:
##     Monster walk speed is faster than human "silent-walk" speed, but slower than normal walk speed.
##     Monster sprint speed is similar (need to play around if faster or slower or same is best for gameplay) 
##     than human sprint speed. Humans get stuck on obstacles, monster barrels through them while sprinting.
##     
##     While monster is pinging is slows them down or stops them, so to see the environment the monster needs
##     to slow down. Monster cannot ping while sprinting. While walking monster cannot push world objects so
##     they cannot push objects to see if it is a player or not.

@export var _max_push_force: float = 15.0

@export_group("Debug")

@export var _debug_environment_prop_meshes_visible: bool = false:
	set(new_value):
		_debug_environment_prop_meshes_visible = new_value

		if is_node_ready():
			_set_environment_props_mesh_visibile(_debug_environment_prop_meshes_visible)

@export var _debug_monster_vision_disabled: bool = false:
	set(new_value):
		_debug_monster_vision_disabled = new_value

		if is_node_ready():
			_monster_vision_post_processing_quad.visible = !_debug_monster_vision_disabled

## The post-processing quad used to show "monster vision"
@onready var _monster_vision_post_processing_quad: MeshInstance3D = %MonsterVisionPostProcessingQuad

@onready var _monster_input_controller: MonsterInputController = %MonsterInputController

func _ready() -> void:
	super._ready()

	_monster_vision_post_processing_quad.visible = !_debug_monster_vision_disabled
	_set_environment_props_mesh_visibile(_debug_environment_prop_meshes_visible)

	_monster_input_controller.vision_pulse_started.connect(func() -> void:
		print("VISION PULSE STARTED")
	)
	_monster_input_controller.vision_pulse_ended.connect(func() -> void:
		print("VISION PULSE ENDED")
	)

func _physics_process(delta: float) -> void:
	# Get speed before calculating updated velocity
	var current_speed := velocity.length()

	super._physics_process(delta)

	# Push rigid bodies when sprinting
	if _is_sprinting():
	# if current_speed > _walk_speed:
		var push_force := _max_push_force
		# 	current_speed,
		# 	_walk_speed, _sprint_speed,
		# 	0.0, _max_push_force
		# )
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			var collider := c.get_collider()
			if collider is RigidBody3D:
				var rigid_body: RigidBody3D = collider
				var contact_point := c.get_position()
				var local_collision_position := contact_point - rigid_body.global_position

				var impulse := -c.get_normal() * push_force * current_speed
				# Launch objects upwards cause it looks cooler :^)
				impulse.y = abs(impulse.y * 1.5)
				print("SPEED: ", current_speed)
				print("PUSH FORCE: ", push_force)
				print("IMPULSE: ", impulse)

				rigid_body.apply_impulse(impulse, local_collision_position)

func _get_target_movement_speed() -> float:
	if _monster_input_controller.get_is_pulsing():
		return _walk_speed * 0.5
	
	return super._get_target_movement_speed()

func _set_environment_props_mesh_visibile(prop_visible: bool) -> void:
	for child in get_tree().get_nodes_in_group(EnvironmentProp.GROUP_NAME):
		if child is EnvironmentProp == false:
			push_error("Node in %s group but is not a type of `EnvironmentProp`" % EnvironmentProp.GROUP_NAME)
			continue
		
		var environment_prop: EnvironmentProp = child
		environment_prop.make_meshes_visible(prop_visible)
