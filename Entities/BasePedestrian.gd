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


var EMOTION_HAPPY = 0
var EMOTION_UNHAPPY = 1
var EMOTION_AFRAID = 2
var EMOTION_ANGRY = 3
var EMOTION_NERVOUS = 4

var emotion

var hop_delay = 1
var hop_time = 0

var velocity = Vector3.ZERO
var acceleration = Vector3.ZERO

func _ready():
	hop_time = 0 - randf() * 4 

func _physics_process(delta):
	hop_time+=delta
	if hop_time < hop_delay:
		return
	if $RayCast.is_colliding():
		if hop_time > hop_delay:
			hop()
			hop_time = 0
		pass
		#linear_velocity.y = 0
		#hop()
	

func hop():
	#print("hop")
	apply_central_impulse((-transform.basis.z) + Vector3.UP*2)
	#add_force((-transform.basis.z * 5) + Vector3.UP , get_node("CollisionShape").transform.origin)
