extends Control

signal go_pressed

var scene_dictionary = {}
var fruit_data = {}
var drink_order = []
var fruits = []

func _ready():
	$GoButton.connect("pressed", self, "_go_pressed")

func _go_pressed():
	emit_signal("go_pressed")

func init(drink_order, fruit_data, scene_dictionary):
	self.drink_order = drink_order
	self.fruit_data = fruit_data
	self.scene_dictionary = scene_dictionary
	create_fruits()
	
func create_fruits():
	var starting_point = $Viewport/Spatial/Left
	print(scene_dictionary)
	for i in range(drink_order.size()):
		var fruit_scene = fruit_data[drink_order[i]]["scene"]
		var fruit = scene_dictionary[fruit_scene].instance()
		fruit.transform.origin += Vector3.RIGHT*0.75 + (i*Vector3.RIGHT/2)
		fruit.gravity_scale = 0
		fruits.push_back(fruit)
		starting_point.add_child(fruit)
		
func show_go():
	$GoButton.show()

func hide_go():
	$GoButton.hide()

func _process(delta):	
	for fruit in fruits:
		fruit.rotate_y(delta)
	$TextureRect.texture = $Viewport.get_texture()
