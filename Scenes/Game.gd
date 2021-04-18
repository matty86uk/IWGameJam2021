extends Spatial

var menu
var world = load("res://Scenes/FruitWorld.tscn").instance()
var blender_scene = load("res://Scenes/BlenderScene.tscn")

var scene_dictionary = {}
var game_data_dictionary = {}
var game_data_total_entities = {"vehicle":200, "pedestrian":500}

func fruit_world_scene():
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
		var subtype_list = []
		for subtype in game_data_dictionary.get(type):
			var occurence = subtype["occurence"]
			for i in range(occurence):
				subtype_list.push_back(subtype["name"])
		occurences_dictionary[type] = subtype_list
	
	for type in occurences_dictionary:
		var index=0
		var total = game_data_total_entities.get(type)
		var subtype_list = occurences_dictionary.get(type)
		while index < total:
			for subtype in subtype_list:
				world.create_entity(type, subtype)
				index += 1

	world.spawn_player()

func blender_scene():
	var blender = blender_scene.instance()
	var fruits = random_fruits()
	var fruit_data = {}
	
	for fruit in fruits:	
		var fruit_scene_key = str(fruit, ".tscn")
		var fruit_scene	=  scene_dictionary["pedestrian"].get(fruit_scene_key)
		fruit_data[fruit] = fruit_scene
	
	blender.init(fruits, fruit_data)
	add_child(blender)
	blender.start()
	

func random_fruits():
	var chosen_fruits = []
	var fruits = game_data_dictionary["pedestrian"]
	var total = randi() % 6 + 3
	for i in range(total):
		var random_fruit = fruits[randi() % fruits.size()]
		chosen_fruits.push_back(random_fruit["name"])
	return chosen_fruits

func _ready():
	blender_scene()
	#fruit_world_scene()


func add_scene_dictionary(dictionary, key, game_data):
	scene_dictionary[key] = dictionary
	game_data_dictionary[key] = game_data

