extends Spatial

var shop_ui_scene = load("res://Scenes/ShopUI.tscn")

var lerping = false
var lerp_target_camera

var shop_open = false
var has_order = false

var order_time = 0
var order_max_time = 2
var order_taken = false
var drink_order = []
onready var current_camera = $MenuCamera

var fruit_data
var scene_dictionary

var shop_ui

func init(fruit_data, scene_dictionary):
	self.fruit_data = fruit_data
	self.scene_dictionary = scene_dictionary
	
func _ready():
	randomize()
	$Camera.transform = current_camera.transform
	$Camera.current = true
	
func _process(delta):
	if lerping:
		$Camera.transform = $Camera.transform.interpolate_with(lerp_target_camera.transform, delta)
		$Ground/Building/Shutter.transform.origin.y += delta
		if $Camera.transform.is_equal_approx(lerp_target_camera.transform):
			lerping = false
	if lerp_target_camera:
		if $Camera.transform.origin.distance_squared_to(lerp_target_camera.transform.origin) < 5 and not shop_open:
				shop_open = true
				order_time = OS.get_system_time_secs()
	
	if order_time:
		print((OS.get_system_time_secs() - order_time))
	
	if shop_open:
		if not order_taken:
			if (OS.get_system_time_secs() - order_time) > order_max_time:
				order_taken = true 
				order_time = 0
				order_arrived()
		
func order_arrived():
	$CashRegister.play()
	drink_order = random_order()
	shop_ui = shop_ui_scene.instance()	
	shop_ui.init(drink_order, fruit_data, scene_dictionary)
	add_child(shop_ui)

func random_order():

	var order = []
	var total = randi() % 3 + 4
	for i in range(total):
		order.push_back(randi() % fruit_data.size())
	return order
	
func shop_camera():
	lerp_target_camera = $ShopCamera
	lerping = true

