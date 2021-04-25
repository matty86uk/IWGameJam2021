extends "res://Entities/BasePlayer.gd"

signal forward_camera
signal reverse_camera

var weapon_ballista_scene = preload("res://Entities/Weapons/gltf/weapon_ballista.glb")
var player_ui_scene = preload("res://Scenes/PlayerUI.tscn")

var player_ui
var player_van_cam_texture

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
var reloaded = false
var caught_object

var player_camera : Camera

var fruit_data
var scene_dictionary
var drink_order

var required_fruits = {}
var collected_fruits = []

var brake_light_off_material = load("res://Entities/Vehicles/material/brake_lights_unlit.material")
var brake_light_on_material = load("res://Entities/Vehicles/material/brake_lights_lit.material")

func _ready():
	weapon = weapon_ballista_scene.instance()
	weapon_point.add_child(weapon)
	mat.vertex_color_use_as_albedo = true
	mat.flags_unshaded = true
	weapon_projectile_start = weapon.get_node("tmpParent/weapon_ballista/bow/arrow")
	player_ui = player_ui_scene.instance()
	player_ui.hide()
	player_van_cam_texture = player_ui.get_node("CamPanel/CamTexture")
	add_child(player_ui)

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
		var drink_name = fruit_data[drink]["name"]
		if not required_fruits.has(drink_name):
			required_fruits[drink_name] = 1
		else:
			required_fruits[drink_name] = required_fruits[drink_name] + 1
	print(required_fruits)
	
func show_player_ui():
	player_ui.show()
	
func hide_player_ui():
	pass

func brake_lights(value):
	if value:
		$body.set_surface_material(0, brake_light_off_material)
	else:
		$body.set_surface_material(0, brake_light_on_material)
		
func get_input():
	if not $Engine.is_playing():
			$Engine.playing = true
	var turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_angle = turn * deg2rad(steering_limit)
	$wheel_frontRight.rotation.y = steer_angle*2
	$wheel_frontLeft.rotation.y = steer_angle*2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate"):
		acceleration = -transform.basis.z * engine_power		
		emit_signal("forward_camera")		
	if Input.is_action_pressed("brake"):	
		acceleration = -transform.basis.z * braking
		brake_lights(true)
	
	if Input.is_action_just_released("brake"):
		brake_lights(false)
		
		
	var velocity_length = velocity.length()
	$Engine.set_unit_db(velocity_length)
	$Engine.set_pitch_scale( 1 + (velocity_length/3))
	
#	if abs(turn) >= 1:
#		if velocity_length > 2.5:
#			if not $Tyre.is_playing():
#				$Tyre.play()
	
func _input(event):
	if event.is_action_pressed("fire"):
		fired = true

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
			projectile_root.remove_child(projectile)
		fired = false
		##if in range		
		if not intersection.empty():
			print("fired")
			if weapon_projectile_start.global_transform.origin.distance_to(intersection.position) < 25:
				weapon_projectile_start.hide()
				projectile = projectile_scene.instance()
				projectile.connect("on_reloaded", self, "_on_reloaded")
				projectile.connect("on_collision", self, "_on_collision")
				projectile.init(self, weapon_projectile_start)
				add_collision_exception_with(projectile)
				projectile.global_transform = weapon_projectile_start.global_transform
				projectile_root.add_child(projectile)		
				projectile.look_at(intersection.position, Vector3.UP)
		else:
			released = false
	else:
		pass
	if reloaded:
		reloaded = false
	if released:
		render_rope_to(weapon_projectile_start, projectile)
		
func _on_collision(has_caught, caught_object):
	print("collided ", has_caught, " -> ", caught_object)
	if has_caught:
		self.caught_object = caught_object

func _on_reloaded():
	released = false
	projectile_rope.mesh = null
	if projectile:
		projectile_root.remove_child(projectile)
	weapon_projectile_start.show()
	if caught_object:
		if caught_object.get_meta("type") == "pedestrian":
			var fruit = caught_object.get_meta("subtype")
			if required_fruits.has(fruit):
				if required_fruits.get(fruit) > 0:
					caught_object.global_transform.origin = $DropPoint.global_transform.origin
					required_fruits[fruit] = required_fruits[fruit] - 1
		caught_object.linear_velocity = Vector3.ZERO
	caught_object = null

func _process(delta):
	
	if caught_object:
		pass
	$VanCamViewPort/VanCam.global_transform = $VanCameraPoint.global_transform
	player_van_cam_texture.texture =  $VanCamViewPort.get_texture()
	


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
	
