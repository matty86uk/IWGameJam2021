extends "res://Entities/BasePlayer.gd"

var weapon_ballista_scene = preload("res://Entities/Weapons/gltf/weapon_ballista.glb")

var weapon
var weapon_target
var weapon_target_collider
var weapon_projectile_start

var projectile_root
var projectile_rope
var projectile
var projectile_scene
onready var weapon_point = $WeaponPoint
onready var mat = SpatialMaterial.new()	
	
var fired = false
var released = false
var caught_object

var player_camera : Camera

var fruit_data
var scene_dictionary
var drink_order

var required_fruits = []

func _ready():	
	weapon = weapon_ballista_scene.instance()
	weapon_point.add_child(weapon)
	mat.vertex_color_use_as_albedo = true
	mat.flags_unshaded = true
	weapon_projectile_start = weapon.get_node("tmpParent/weapon_ballista/bow/arrow")

func init(projectile_root : Spatial, projectile_rope : MeshInstance, projectile_scene : PackedScene, player_camera : Camera, fruit_data, scene_dictionary, drink_order):
	self.projectile_root = projectile_root
	self.projectile_rope = projectile_rope
	self.projectile_scene = projectile_scene
	self.player_camera = player_camera
	self.fruit_data = fruit_data
	self.scene_dictionary = scene_dictionary
	self.drink_order = drink_order
	print(drink_order)
	
	for drink in drink_order:
		required_fruits.push_back(fruit_data[drink]["name"])
	print(required_fruits)
	
func get_input():
	var turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_angle = turn * deg2rad(steering_limit)
	$wheel_frontRight.rotation.y = steer_angle*2
	$wheel_frontLeft.rotation.y = steer_angle*2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate"):
		acceleration = -transform.basis.z * engine_power
	if Input.is_action_pressed("brake"):
		acceleration = -transform.basis.z * braking

func _input(event):
	if event.is_action_pressed("fire"):
		fired = true
	elif event.is_action_pressed("reel"):	
		fired = false

func _physics_process(delta):
	var space_state = get_world().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = player_camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + player_camera.project_ray_normal(mouse_position) * 2000
	var intersection = space_state.intersect_ray(ray_origin, ray_end)
	
	if not intersection.empty():
		var pos = intersection.position
		var weapon_pos = weapon_point.global_transform.origin
		var dir = weapon_pos.direction_to(pos)
		var cross = weapon_pos.cross(dir)
		$Label.text = str("", $WeaponPoint.rotation)
		$Label2.text = str("", cross.y)
		$Label3.text = str("", weapon_point.get_rotation().y)
		weapon_point.look_at(pos, Vector3.UP)
		weapon_point.set_rotation(Vector3(0, weapon_point.get_rotation().y, 0))
	
	if fired:
		released = true
		if projectile:
			projectile.queue_free()
		fired = false
		weapon_projectile_start.hide()
		projectile = projectile_scene.instance()
		projectile.connect("on_reloaded", self, "_on_reloaded")
		projectile.connect("on_collision", self, "_on_collision")
		projectile.init(self, weapon_projectile_start)
		add_collision_exception_with(projectile)
		projectile.global_transform = weapon_projectile_start.global_transform
		projectile_root.add_child(projectile)
		if not intersection.empty():
			projectile.look_at(intersection.position, Vector3.UP)
	else:
		pass

func _on_collision(has_caught, caught_object):
	print("collided ", has_caught, " -> ", caught_object)
	if has_caught:
		self.caught_object = caught_object
		print(caught_object.get_meta("type"))
		print(caught_object.get_meta("subtype"))

func _on_reloaded():
	released = false
	projectile_rope.mesh = null
	projectile.queue_free()
	weapon_projectile_start.show()
	if caught_object:
		caught_object.linear_velocity = Vector3.ZERO
	caught_object = null
	pass

func _process(delta):
	if released:
		render_rope_to(weapon_projectile_start, projectile)
	if caught_object:
		pass
	pass


func render_rope_to(from, to):
	var from_point = from.global_transform.origin
	var to_point = to.global_transform.origin + to.global_transform.basis.z/2
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_color(Color.brown)
	st.add_vertex(from_point)
	st.add_vertex(to_point)
	var mesh = st.commit()
	projectile_rope.mesh = mesh
	projectile_rope.material_override = mat
	
