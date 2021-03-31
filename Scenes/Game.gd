extends Spatial

var menu
var world = load("res://Scenes/World.tscn").instance()

var scene_dictionary = {}

func _ready():
	add_child(world)
	pass

func add_scene_dictionary(dictionary, key):
	scene_dictionary[key] = dictionary
