extends KinematicBody


var gravity = -10

var STATE_INSTANCED = 0
var STATE_READY = 1
var STATE_HAS_ORDERS = 2
var STATE_ENABLED = 3
var STATE_DISABLED = 4
var STATE_MODE_CHANGED = 5
var state


var MODE_PATROL = 0
var MODE_CHASE = 1
var mode

var patrol_path = []
var patrol_path_index = 0

var chase_path = []
var chase_path_index = 0

var chase_point
var chase_direct = false

var velocity = Vector3.ZERO
var acceleration = Vector3.ZERO
var engine_power = 4
var braking = -20
var friction = -2.0
var drag = -2.0
var rotation_speed = 5

var red_light_off = load("res://Entities/Vehicles/material/siren_red_lights_lit.material")
var red_light_on = load("res://Entities/Vehicles/material/siren_red_lights_unlit.material")
var blue_light_off = load("res://Entities/Vehicles/material/siren_blue_lights_lit.material")
var blue_light_on = load("res://Entities/Vehicles/material/siren_blue_lights_unlit.material")

var siren_timer
var siren_index = 0

func _ready():
	siren_timer = Timer.new()
	add_child(siren_timer)
	siren_timer.connect("timeout", self, "_on_timer_timeout")
	siren_timer.set_wait_time(0.5)
	siren_timer.set_one_shot(false) # Make sure it loops
	siren_timer.start()
	
	pass

func _on_timer_timeout():
	if mode == MODE_CHASE:
		if siren_index == 0:
			siren_index = 1
		else:
			siren_index = 0
		
		if siren_index == 0:
			get_node("tmpParent").get_child(0).get_node("body").set_surface_material(4, red_light_off)
			get_node("tmpParent").get_child(0).get_node("body").set_surface_material(7, blue_light_on)
		else:
			get_node("tmpParent").get_child(0).get_node("body").set_surface_material(4, red_light_on)
			get_node("tmpParent").get_child(0).get_node("body").set_surface_material(7, blue_light_off)
	else:
		get_node("tmpParent").get_child(0).get_node("body").set_surface_material(4, red_light_off)
		get_node("tmpParent").get_child(0).get_node("body").set_surface_material(7, blue_light_off)
	
func _physics_process(delta):
	if is_on_floor():
		acceleration.y = 0
		apply_friction(delta)
		
		var can_move = false
		if mode == MODE_PATROL:
			var has_obstacle = false
			var obstacle = $ForwardCast.get_collider()
			if not obstacle or obstacle is StaticBody:
				has_obstacle = false
			else:
				has_obstacle = true
			can_move = has_valid_path() and not has_obstacle
		elif mode == MODE_CHASE:
			can_move = has_valid_path()
			
		if can_move:
			forward(delta)
			var this_position = transform.origin
			var target_position = current_path()
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
				brake()
				#velocity = -facing_direction * velocity.length()
	else:
		acceleration.y = gravity
		velocity += acceleration * delta
	if velocity.length() > 0:
		if not $Engine.is_playing():
			$Engine.playing = true
	if mode == MODE_PATROL:
		velocity = move_and_slide(velocity, Vector3.UP, false)
	elif mode == MODE_CHASE:
		velocity = move_and_slide(velocity, Vector3.UP, false)

func _process(delta):
	if mode == MODE_CHASE:
		if not $Siren.is_playing():
			$Siren.playing = true
	else:
		$Siren.stop()

func current_path():
	if mode == MODE_PATROL:
		return patrol_path[patrol_path_index]
	elif mode == MODE_CHASE:
		if chase_direct:
			return chase_point
		return chase_path[chase_path_index]
	return global_transform.origin

func forward(delta):
	if mode == MODE_PATROL:
		acceleration = -transform.basis.z * engine_power * delta
		if velocity.length() < 1:
			acceleration += -transform.basis.z
	elif mode == MODE_CHASE:
		acceleration = -transform.basis.z * engine_power * delta * 10
		if velocity.length() < 1:
			acceleration += -transform.basis.z * 2
func brake():
	velocity = Vector3.ZERO

func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force

func has_valid_path():
	if mode == MODE_PATROL:
		if patrol_path.size() > 0 and patrol_path_index < patrol_path.size():
			return true
	elif mode == MODE_CHASE:
		if chase_direct:
			return true
		if chase_path.size() > 0 and chase_path_index < chase_path.size():
			return true
	return false

func set_path(new_path):
	if mode == MODE_PATROL:
		patrol_path = new_path
	elif mode == MODE_CHASE:
		chase_path = new_path
		#render_path(new_path)

func render_path(the_path):
	var mat = SpatialMaterial.new()
	mat.vertex_color_use_as_albedo = true
	mat.flags_unshaded = true
	var st = SurfaceTool.new()	
	st.begin(Mesh.PRIMITIVE_LINES)
	var last_p = the_path[0]
	for p in the_path:
		st.add_color(Color.blue)
		st.add_vertex(last_p + (Vector3.UP * 0.5))
		st.add_vertex(p + (Vector3.UP * 0.5))
		last_p = p
	$MeshInstance.mesh = st.commit()
	$MeshInstance.material_override = mat

func set_path_index(value):
	if mode == MODE_PATROL:
		patrol_path_index = value
	elif mode == MODE_CHASE:
		chase_path_index = value
		
func can_see_player(player):
	$PlayerCast.look_at(player.global_transform.origin, Vector3.UP)
	var collider =  $PlayerCast.get_collider()
	if collider is KinematicBody and collider.get_meta("type") == "player":
		return true
	return false

func alert():
	mode = MODE_CHASE
	state = STATE_MODE_CHANGED

func unalert():
	mode = MODE_PATROL
	state = STATE_MODE_CHANGED
