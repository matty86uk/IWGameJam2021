extends KinematicBody


var STATE_INSTANCED = 0
var STATE_READY = 1
var STATE_HAS_ORDERS = 2
var STATE_MOVING = 3
var STATE_WAITING = 4
var STATE_STOPPED = 5 
var state

var _valid = false

onready var agent := GSAIKinematicBody3DAgent.new(self)
onready var path := GSAIPath.new([
	global_transform.origin, 
	global_transform.origin
], true)
onready var follow := GSAIFollowPath.new(agent,path, 0, 0)
onready var accel := GSAITargetAcceleration.new()

func _ready():
	follow.path_offset = 1
	follow.prediction_time = 0.3
	follow.deceleration_radius = 50
	follow.arrival_tolerance = 1

	agent.linear_acceleration_max = 10
	agent.linear_speed_max = 100
	agent.linear_drag_percentage = 0.05
	
func _physics_process(delta):
	if _valid:
		follow.calculate_steering(accel)
		agent._apply_steering(accel, delta)
		var ahead = -transform.basis.z * Vector3.FORWARD
		var rotation_transform = transform.looking_at(ahead, Vector3.UP)
		var rotated_transform = transform.interpolate_with(rotation_transform, delta * 5)
		transform = rotated_transform
	pass

func set_path(new_path):
	path.create_path(new_path)
	_valid = true
