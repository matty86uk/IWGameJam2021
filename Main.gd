extends Node


var game = load("res://Scenes/Game.tscn").instance()

func _ready():	

	var vehicle_dictionary = load_vehicle_scenes()
	game.add_scene_dictionary(vehicle_dictionary, "vehicle", load_json_file("res://Data/vehicles.txt"))

	var pedestrian_dictionary = load_pedestrian_scenes()
	game.add_scene_dictionary(pedestrian_dictionary, "pedestrian", load_json_file("res://Data/pedestrians.txt"))
	
	var police_dictionary = load_police_scenes()
	game.add_scene_dictionary(police_dictionary, "police", load_json_file("res://Data/police.txt"))
	
	print("vehicle", vehicle_dictionary)
	print("pedestrian", pedestrian_dictionary)
	print("police", police_dictionary)
	
	add_child(game)

func load_vehicle_scenes():
	return load_directory("res://Entities/Vehicles", ".tscn")

func load_pedestrian_scenes():
	return load_directory("res://Entities/Pedestrians", ".tscn")

func load_police_scenes():
	var dictionary = {}
	dictionary["police.tscn"] = load("res://Entities/Vehicles/police.tscn")
	return dictionary

func load_directory(path, extension):
	var dictionary = {}
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(extension):
				dictionary[file_name] = load(path + "/" + file_name)
			file_name = dir.get_next()
	return dictionary
	
func load_json_file(path):
	var file = File.new()
	file.open(path, file.READ)
	var text = file.get_as_text()
	var p = JSON.parse(text)	
	file.close()
	return p.result
