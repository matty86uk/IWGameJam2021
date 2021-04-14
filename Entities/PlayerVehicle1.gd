extends "res://Entities/BasePlayer.gd"

var weapon_ballista_scene = preload("res://Entities/Weapons/gltf/weapon_ballista.glb")




var rope_on = false
var weapon
var weapon_target
var weapon_target_collider
var mi_rope
var mi_projectile
onready var weapon_point = $WeaponPoint

var fired = false

func _ready():	
	weapon = weapon_ballista_scene.instance()
	weapon_point.add_child(weapon)


func init(rope : MeshInstance, projectile : MeshInstance):
	mi_rope = rope
	mi_projectile = projectile
	mi_projectile.hide()

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

func _physics_process(delta):
	var space_state = get_world().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = $Camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + $Camera.project_ray_normal(mouse_position) * 2000
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
		fired = false
		if not rope_on:
			rope_on = true
			if not intersection.empty():
				weapon_target_collider = intersection["collider"]
				weapon_target = intersection.position
				if weapon_target_collider is StaticBody:
					print("miss")
				elif weapon_target_collider is RigidBody:
					print("hit")
					pass
				mi_projectile.global_transform.origin = weapon_point.global_transform.origin
				mi_projectile.look_at(weapon_target, Vector3.UP)
				mi_projectile.show()
		elif rope_on:
			rope_on = false

func _process(delta):
	if rope_on:
		var t = weapon_target
		var f = weapon_point.transform.origin
		var r = mi_projectile.global_transform.origin
		var dir = t.direction_to(f)
		var r_dir = r.direction_to(t)
		if r.distance_squared_to(t) > 0.2:
			mi_projectile.global_transform.origin = mi_projectile.global_transform.origin + (r_dir.normalized() * delta * 20)
	
