extends KinematicBody

signal on_reloaded
signal on_collision(has_caught, caught_object)

var collided = false
var return_node

func init(node_to_exclude, return_node):
	add_collision_exception_with(node_to_exclude)
	self.return_node = return_node

func _ready():
	pass

func _physics_process(delta):	
	if not collided:
		var collision = move_and_collide(-transform.basis.z * delta * 100, false)
		if collision:
			collided = true
			
			if collision.collider is RigidBody:
				emit_signal("on_collision", true, collision.collider)
				$PinJoint.set_node_b(collision.collider.get_path())
			else:
				emit_signal("on_collision", false, null)
			
	else:
		if  global_transform.origin.distance_squared_to(return_node.global_transform.origin) > 0.1:
			var return_velocity = global_transform.origin.direction_to(return_node.global_transform.origin)
			move_and_slide(return_velocity * 20, Vector3.UP)
			look_at(return_node.global_transform.origin, Vector3.UP)
			self.rotate_object_local(Vector3(0,1,0), 3.14)
		else:
			emit_signal("on_reloaded")
