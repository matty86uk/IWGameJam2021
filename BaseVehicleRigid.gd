extends RigidBody

#var gravity = -10

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
#var mode

var path = []
var path_index = 0

var velocity = Vector3.ZERO
var acceleration = Vector3.ZERO
var engine_power = 2
var braking = -20
#var friction = -2.0
var drag = -2.0
var rotation_speed = 20
var mi_debug = MeshInstance.new()
var mat_debug = SpatialMaterial.new()

var frame_count = 0
var next_physics_frame = 1

func _ready():
	mat_debug.vertex_color_use_as_albedo  = true
	mat_debug.flags_unshaded = true
	mat_debug.flags_use_point_size = true
	mat_debug.params_point_size = 4
	mi_debug.material_override = mat_debug
	
	add_child(mi_debug)
	
	
func _physics_process(delta):
	var is_on_floor = $RayCast.is_colliding()
	apply_central_impulse(-transform.basis.z * delta * 6)
#	if is_on_floor:
#		print("on floor")
#		#set_axis_lock(PhysicsServer.BODY_AXIS_LINEAR_Y, true)		
		
		

func look_follow(state, current_transform, target_position):
	if has_valid_path():			
			var position = global_transform.origin
			var current_direction = -global_transform.basis.z
			var required_direction = position.direction_to(target_position)
			var cross = current_direction.cross(required_direction)
			var d = current_direction.dot(required_direction)
			if d < 0.99:
				if cross.y < 0:
					state.set_angular_velocity(-Vector3.UP * (0.02 / state.get_step()))
				else:
					state.set_angular_velocity(Vector3.UP * (0.02 / state.get_step()))

func _integrate_forces(state):	
	if has_valid_path():
		var target_position = path[path_index]
		look_follow(state, get_global_transform(), target_position)
	
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
	#if $RayCast.is_colliding():
	acceleration = -transform.basis.z * engine_power

func reverse():
	acceleration = -transform.basis.z * braking

func set_path(new_path):
	path = new_path
