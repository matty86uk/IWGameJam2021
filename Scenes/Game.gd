extends Spatial

var menu
var world = load("res://Scenes/FruitWorld.tscn").instance()

var scene_dictionary = {}
var game_data_dictionary = {}

func begin():
	world.generate_world(12345)
	add_child(world)
	
	for type in game_data_dictionary.keys():
		var subtypes = []
		var subtype_scenes = []
		for subtype in game_data_dictionary.get(type):
			
			var subtype_name = subtype["name"]
			var subtype_scene = subtype["scene"]
			print(subtype_scene)
			subtypes.push_back(subtype_name)
			subtype_scenes.push_back(scene_dictionary[type].get(subtype_scene))
		world.create_entity_types(type, subtypes, subtype_scenes)
	
	var occurences_dictionary = {}
	for type in game_data_dictionary.keys():
		pass


	

func _ready():
	begin()
	pass

func add_scene_dictionary(dictionary, key, game_data):
	scene_dictionary[key] = dictionary
	game_data_dictionary[key] = game_data

