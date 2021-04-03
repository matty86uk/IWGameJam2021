extends RigidBody


var gravity = -10

var STATE_INSTANCED = 0
var STATE_READY = 1
var STATE_HAS_ORDERS = 2
var STATE_MOVING = 3
var STATE_WAITING = 4
var STATE_STOPPED = 5 
var state


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

var velocity1 = Vector3.ZERO
var acceleration = Vector3.ZERO
var engine_power = 6.0
var braking = -20

var drag = -2.0
var rotation_speed = 20
var mi_debug = MeshInstance.new()
var mat_debug = SpatialMaterial.new()

func _ready():
	friction = 1	
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
	mi_debug.material_override = mat_debug
	add_child(mi_debug)
	
	
func _physics_process(delta):
	acceleration.y = gravity	
	velocity1 += acceleration * delta
	
	if path.size() > 0 and path_index < path.size():
		velocity1.y = 0
		apply_friction(delta)
		var this_position = transform.origin
		var target_position = path[path_index]
		var rotation_transform = transform.looking_at(target_position, Vector3.UP)		
		var rotated_transform = transform.interpolate_with(rotation_transform, delta * rotation_speed)
		transform = rotated_transform
		var facing_direction = -rotated_transform.basis.z
		var d = facing_direction.dot(velocity1.normalized())
		if d > 0:
			velocity1 = facing_direction * velocity1.length()
		else:
			velocity1 = -facing_direction * velocity1.length()
	velocity1 = add_central_force(velocity1)

func apply_friction(delta):
	if velocity1.length() < 0.2 and acceleration.length() == 0:
		velocity1.x = 0
		velocity1.z = 0
	var friction_force = velocity1 * friction * delta
	var drag_force = velocity1 * velocity1.length() * drag * delta
	acceleration += drag_force + friction_force

func power():
	#if is_on_floor():	
	acceleration = -transform.basis.z * engine_power

func brake():
	acceleration = -transform.basis.z * braking

func set_path(new_path):
	path = new_path
