extends Spatial

signal finished_loading
var loading_thread = Thread.new()

var world = load("res://Scenes/FruitWorld.tscn").instance()
#var blender_scene = load("res://Scenes/BlenderScene.tscn")
var shop_world_scene = load("res://Scenes/ShopWorld.tscn")
var main_menu_scene = load("res://Scenes/MainMenu.tscn")

var main_menu
var shop_world

var scene_dictionary = {}
var game_data_dictionary = {}
var game_data_total_entities = {"vehicle":200, "pedestrian":600, "police":10}


var music_dictionary = {
	"happy":["happy1"],
	"getaway":["getaway1", "getaway2"],
	"normal":["normal1", "normal2", "normal3", "normal4"]
}

var music_type = "happy"
var music = "happy1"

func _ready():
	main_menu_scene()
	
func _load_fruit_world():
	connect("finished_loading", self, "_finished_loading")
	print("load world")
	world.connect("normal_music", self, "_set_music_normal")
	world.connect("getaway_music", self, "_set_music_getaway")
	fruit_world_scene("")
	_finished_loading()
	shop_world.hide_ui()
	shop_world.hide()
	world.show_player_ui()

func fruit_world_scene(userdata):
	world.generate_world(12345)
	
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
	print("loaded")
	#emit_signal("finished_loading")
	
func _finished_loading():

	#print("Thread Active:", loading_thread.is_active())
	print("finished loading")
	add_child(world)
	world.spawn_player(game_data_dictionary["pedestrian"], scene_dictionary["pedestrian"], shop_world.get_drink_order())
	world.move_camera("Start")
	world.set_current_camera()
	world.transition_camera("Final")
	print("drink order:", shop_world.get_drink_order())	

	
#func blender_scene():
#	var blender = blender_scene.instance()
#	var fruits = random_fruits()
#	var fruit_data = {}
#
#	for fruit in fruits:	
#		var fruit_scene_key = str(fruit, ".tscn")
#		var fruit_scene	=  scene_dictionary["pedestrian"].get(fruit_scene_key)
#		fruit_data[fruit] = fruit_scene
#
#	blender.init(fruits, fruit_data)
#	add_child(blender)
#	blender.start()

func main_menu_scene():
	shop_world = shop_world_scene.instance()
	shop_world.init(game_data_dictionary["pedestrian"], scene_dictionary["pedestrian"])
	main_menu = main_menu_scene.instance()
	main_menu.connect("start_game", self, "_start_game")
	
	shop_world.connect("load_fruit_world", self, "_load_fruit_world")
	add_child(shop_world)
	add_child(main_menu)

func _start_game():
	print("start game")
	remove_child(main_menu)
	shop_world.shop_camera()

func random_fruits():
	var chosen_fruits = []
	var fruits = game_data_dictionary["pedestrian"]
	var total = randi() % 6 + 3
	for i in range(total):
		var random_fruit = fruits[randi() % fruits.size()]
		chosen_fruits.push_back(random_fruit["name"])
	return chosen_fruits

func add_scene_dictionary(dictionary, key, game_data):
	scene_dictionary[key] = dictionary
	game_data_dictionary[key] = game_data
	
func set_music_happy():
	music_type = "happy"

func _set_music_getaway():
	music_type = "getaway"
	$Music.stop()

func _set_music_normal():
	music_type = "normal"
	$Music.stop()

func _process(delta):
	if not $Music.playing:
		change_music()

func change_music():
	var new_music_list = music_dictionary[music_type]
	music = new_music_list[randi() % new_music_list.size()-1]
	
	$Music.stream = load(str("res://Music/", music, ".wav"))
	$Music.playing = true
	

