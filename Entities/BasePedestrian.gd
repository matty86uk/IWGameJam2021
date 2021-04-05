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


func _physics_process(delta):
	if $RayCast.is_colliding():
		linear_velocity.y = 0
