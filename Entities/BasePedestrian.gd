extends RigidBody

var gravity = -10

var STATE_INSTANCED = 0
var STATE_READY = 1
var STATE_HAS_ORDERS = 2
var STATE_ENABLED = 3
var STATE_DISABLED = 4
var state


var MODE_WAITING = 0
var MODE_WANDERING = 1
var MODE_FLEEING = 2
var MODE_STUCK = 3
var pedestrian_mode

var path = []
var path_index = 0


var EMOTION_HAPPY = 0
var EMOTION_UNHAPPY = 1
var EMOTION_AFRAID = 2
var EMOTION_ANGRY = 3
var EMOTION_NERVOUS = 4

var emotion

var HOP_NORMAL = 1000
var HOP_SCARED = 500

var hop_delay = 1
var hop_time = 0

var velocity = Vector3.ZERO
var acceleration = Vector3.ZERO

func _ready():
	#randomize()
	hop_time = OS.get_ticks_msec() + randi() % 7000
	hop_delay = HOP_NORMAL
	connect("body_entered", self, "_body_entered")

func _body_entered(body):
	if body is KinematicBody:
#		or body is RigidBody:
#		if body is RigidBody and not body.get_meta("type") == "vehicle":
#			return
		if not $Ouch.is_playing():
			$Ouch.play()
	

func _physics_process(delta):	
	if OS.get_ticks_msec() > hop_time + hop_delay:
		hop()
		hop_time = OS.get_ticks_msec()

		
func hop():	
	apply_central_impulse((-transform.basis.z) + Vector3.UP*2)

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

func set_path(new_path):
	path = new_path
