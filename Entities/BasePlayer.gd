extends KinematicBody

# Car behavior parameters, adjust as needed

export var gravity = -20.0
export var wheel_base = 0.6  # distance between front/rear axles
export var steering_limit = 10.0  # front wheel max turning angle (deg)
export var engine_power = 6.0
export var braking = -9.0
export var friction = -2.0
export var drag = -2.0
export var max_speed_reverse = 3.0

# Car state properties

var acceleration = Vector3.ZERO  # current acceleration
var velocity = Vector3.ZERO  # current velocity
var steer_angle  # current wheel angle

func _ready():
	steer_angle = 0.0

func _physics_process(delta):
	if is_on_floor():
		get_input()
		apply_friction(delta)
		calculate_steering(delta)
	acceleration.y = gravity
	velocity += acceleration * delta
	
#	var collider = collision["collider"]
#	if collider is KinematicBody:
#		collider.collide(transform.basis.z * (velocity * 0.2), collision["position"])
	var collision = move_and_collide(velocity, false, true, true)
	if collision:
		if collision.collider:
			if collision.collider is KinematicBody:
				var kbody = collision.collider
				if kbody.get_meta("type") == "police":
					kbody.alert()
					emit_signal("police_alerted")

	velocity = move_and_slide_with_snap(velocity, -transform.basis.y, Vector3.UP, true) 

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force

func calculate_steering(delta):
	var rear_wheel = transform.origin + transform.basis.z * wheel_base / 2.0
	var front_wheel = transform.origin - transform.basis.z * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(transform.basis.y, steer_angle) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)

	var d = new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = new_heading * velocity.length()
		$Reverse.stop()
	if d < 0:		
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
		emit_signal("reverse_camera")
		if not $Reverse.is_playing():
			$Reverse.play()
	look_at(transform.origin + new_heading, transform.basis.y)

func get_input():
	pass
