extends Spatial

var weapon_ballista_scene = preload("res://Entities/Weapons/gltf/weapon_ballista.glb")

func _ready():	
	var weapon = weapon_ballista_scene.instance()
	$WeaponPoint.add_child(weapon)	
