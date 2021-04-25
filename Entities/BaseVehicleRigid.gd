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
var next_physics_frame = 4

var forward_cast_check_time = 0
var forward_cast_check_time_max = 2000
var last_check_obstacle = false

func _ready():
	mat_debug.vertex_color_use_as_albedo  = true
	mat_debug.flags_unshaded = true
	mat_debug.flags_use_point_size = true
	mat_debug.params_point_size = 4
	mi_debug.material_override = mat_debug
	forward_cast_check_time = OS.get_ticks_msec() + randi() % 10000
	add_child(mi_debug)
	
	frame_count = randi() % 4
	
	$Engine.set_pitch_scale(1 + (randf() * 0.05))
	$Engine.playing = true
	
	connect("body_entered", self, "_body_entered")
	
func _process(delta):
	pass
#	if randi() % 10000 > 9990:		
#		$Beep.set_pitch_scale(1 + (randf() * 0.1))
#		$Beep.play()
	
func _physics_process(delta):
	#var is_on_floor = $RayCast.is_colliding()	
	#$ForwardCast.enabled = true
	var obstacle = $ForwardCast.get_collider()
	#print("check")
	#$ForwardCast.enabled = false
	if not obstacle or obstacle is StaticBody:
		apply_central_impulse(-transform.basis.z * delta * 6)
	else:		
		if randi() % 10 > 8:
			if not $Beep.is_playing():
				$Beep.play()


func _body_entered(body):
	if body is KinematicBody or body is RigidBody:
		if body is RigidBody:
			if not body.get_meta("type") == "vehicle":
				return 
		if not $Crash.is_playing():
			$Crash.play()
	pass

func look_follow(state, current_transform, target_position):
	if has_valid_path():
			var position = global_transform.origin
			var current_direction = -global_transform.basis.z
			var required_direction = position.direction_to(target_position)
			var cross = current_direction.cross(required_direction)
			var d = current_direction.dot(required_direction)
			if d < 0.99:
				if cross.y < 0:
					state.set_angular_velocity(-Vector3.UP * (0.08 / state.get_step()))
				else:
					state.set_angular_velocity(Vector3.UP * (0.08 / state.get_step()))

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
