extends KinematicBody

var gravity = -10

var STATE_INSTANCED = 0
var STATE_READY = 1
var STATE_HAS_ORDERS = 2
var STATE_ENABLED = 3
var STATE_DISABLED = 4
var state


var MODE_WAITING = 0
var MODE_ACCELLERATING = 1
var MODE_DECELLERATING = 2
var MODE_STUCK = 3
var mode


#var _valid = false
#var velocity := Vector3.ZERO
#var angular_velocity := 0.0
#var linear_drag := 0.1
#var angular_drag := 0.1
#var drag = 0.1
#
#var acceleration  := GSAITargetAcceleration.new()
#onready var agent := GSAIKinematicBody3DAgent.new(self)
#onready var look := GSAILookWhereYouGo.new(agent)
#onready var path := GSAIPath.new(
#	[
#		global_transform.origin,
#		global_transform.origin
#	],
#	true
#)
#onready var follow := GSAIFollowPath.new(agent, path, 0, 0)
#onready var blend = GSAIBlend.new(agent)

var path = []
var path_index = 0

var velocity = Vector3.ZERO
var acceleration = Vector3.ZERO
var engine_power = 2
var braking = -20
var friction = -2.0
var drag = -2.0
var rotation_speed = 20
var mi_debug = MeshInstance.new()
var mat_debug = SpatialMaterial.new()

var frame_count = 0
var next_physics_frame = 1

func _ready():
	pass
#	agent.linear_acceleration_max = 40
#	agent.linear_speed_max = 600
#	agent.linear_drag_percentage = drag	
#	follow.path_offset = 0.5
#	follow.prediction_time = 0.3
#	follow.deceleration_radius = 1
#	#look.alignment_tolerance = deg2rad(2)	
#	look.deceleration_radius = deg2rad(60)
#	blend.add(look, 1)
#	blend.add(follow, 1)
	mat_debug.vertex_color_use_as_albedo  = true
	mat_debug.flags_unshaded = true
	mat_debug.flags_use_point_size = true
	mat_debug.params_point_size = 4
	mi_debug.material_override = mat_debug
	
	add_child(mi_debug)
	
	
func _physics_process(delta):
#
	frame_count+=1
	if frame_count > next_physics_frame:
		frame_count=0
		
		var is_on_floor = is_on_floor()
		
		if is_on_floor():
			acceleration.y = 0
			apply_friction(delta)
			if has_valid_path():
				var this_position = transform.origin
				var target_position = path[path_index]
				target_position.y = this_position.y
				
				
				var diff = target_position - this_position
				var rotation_transform = transform.looking_at(target_position, Vector3.UP)
				var rotated_transform = transform.interpolate_with(rotation_transform, delta * rotation_speed)
				transform = rotated_transform
	
				var facing_direction = -transform.basis.z
				var d = facing_direction.dot(velocity.normalized())
				if d > 0:
					velocity = facing_direction * velocity.length()
				else:
					velocity = -facing_direction * velocity.length()
		else:
			acceleration.y = gravity
			velocity += acceleration * delta
			
		velocity = move_and_slide(velocity, Vector3.UP)
		
		
#		if path.size() > 0 and path_index < path.size() and is_on_floor():
#			velocity.y = 0
#			apply_friction(delta)
#			var this_position = transform.origin
#			var target_position = path[path_index]
#			target_position.y = this_position.y
#			var diff = target_position - this_position
#			#if abs(diff.length()) > 0.6:
#			var rotation_transform = transform.looking_at(target_position, Vector3.UP)
#			var rotated_transform = transform.interpolate_with(rotation_transform, delta * rotation_speed)				
#			transform = rotated_transform
##			transform.basis.x = rotated_transform.basis.x
##			transform.basis.z = rotated_transform.basis.z
#			var facing_direction = -transform.basis.z
#			var d = facing_direction.dot(velocity.normalized())
#			if d > 0:
#				velocity = facing_direction * velocity.length()
#			else:
#				velocity = -facing_direction * velocity.length()
##		var collision = move_and_collide(Vector3(velocity.x, 1, velocity.z), false, true, true)
##		if !collision:
#			velocity = move_and_slide(velocity, Vector3.UP)
##		else:
##			velocity.x = 0
##			velocity.y = 0

func has_valid_path():
	if path.size() > 0 and path_index < path.size():
		return true
	return false

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force

func forward():
	if is_on_floor():
		acceleration = -transform.basis.z * engine_power

func reverse():
	acceleration = -transform.basis.z * braking

func set_path(new_path):
	path = new_path

