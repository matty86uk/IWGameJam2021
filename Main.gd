extends Node


var game = load("res://Scenes/Game.tscn").instance()

func _ready():	
	var vehicle_dictionary = load_vehicle_scenes()	
	game.add_scene_dictionary(vehicle_dictionary, "vehicles")
	game.set_subtypes("vehicles", load_json_file("res://Data/vehicles.tres"))
	
	add_child(game)

func load_vehicle_scenes():
	return load_directory("res://Vehicles/Vehicles", ".tscn")

func load_directory(path, extension):
	var dictionary = {}
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(extension):
				dictionary[file_name] = load(path + "//" + file_name)
			file_name = dir.get_next()
	return dictionary
	
func load_json_file(path):
	var file = File.new()
	file.open(path, file.READ)
	var text = file.get_as_text()
	var p = JSON.parse(text)	
	file.close()
	return p.result
