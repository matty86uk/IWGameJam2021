extends Spatial

signal load_fruit_world

var shop_ui_scene = load("res://Scenes/ShopUI.tscn")

var terminal

var terminal_text = [
	"cd ~/portal_machine",
	"./portal_machine_open.sh",
	"Loading...",
	"Fruitiverse frequency calculated",
	"Frequency= [@seed]",
	"Aligning...",
	"Portal Opening"
]
var terminal_line = 0
var terminal_text_index = 0
var terminal_character_max_rate = 1
var terminal_character_time = 0
var computer_max_delay = 2
var computer_time = 0
var computer_on = false

var lerping = false
var lerp_target_camera
var lerp_target_camera_reached = false

var shop_open = false
var has_order = false
var portal_room = false
var portal_open = false
var car_on = false

var car_speed = 0
var car_acceleration = 0

onready var portal_mi = $Ground/Building/Computer/Portal
onready var portal_target = $Ground/Building/Computer/PortalTarget
onready var portal_mi_material = SpatialMaterial.new()
var portal_colors = [
	Color.red,
	Color.green,
	Color.blue,
	Color.yellow,
	Color.white,
	Color.pink,
	Color.orange,
	Color.purple
]

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
	portal_mi_material.albedo_color = Color.black
	#portal_mi.material_override = portal_mi_material
	
	terminal = $Ground/Building/Spatial/ComputerScreen/Viewport/Control/ViewportContainer/Terminal
	
func _process(delta):
	if lerping:
		$Camera.global_transform = $Camera.global_transform.interpolate_with(lerp_target_camera.global_transform, delta)
		$Ground/Building/Shutter.transform.origin.y += delta
		if $Camera.global_transform.is_equal_approx(lerp_target_camera.global_transform):
			lerping = false
	if lerp_target_camera:
		if $Camera.transform.origin.distance_squared_to(lerp_target_camera.transform.origin) < 5 and not lerp_target_camera_reached:
			camera_positioned()
			lerp_target_camera_reached = true
			

	if shop_open:
		if not order_taken:
			if (OS.get_system_time_secs() - order_time) > order_max_time:
				order_taken = true 
				order_time = 0
				order_arrived()
	
	if computer_on:
		if computer_time > computer_max_delay:
			if OS.get_system_time_msecs() >  terminal_character_time + terminal_character_max_rate:
				terminal_character_time = OS.get_system_time_msecs()
				if terminal_line < terminal_text.size():
					terminal.grab_focus()
					if terminal_text_index >= terminal_text[terminal_line].length():
						terminal.text = str(terminal.text, "\n")
						terminal_text_index=0
						terminal_line+=1
						terminal_character_time = OS.get_system_time_msecs() + terminal_character_max_rate * 5
					else:
						var next_character = terminal_text[terminal_line].substr(terminal_text_index, 1)
						terminal_text_index+=1
						terminal.text = str(terminal.text, next_character)
					var cl = terminal.get_line_count()+1
					terminal.cursor_set_line(cl)
				else:
					computer_on = false
					portal_open()
		else:
			computer_time+=delta
	
	if portal_open:
		portal_mi.transform = portal_mi.transform.interpolate_with(portal_target.transform, delta)
		portal_mi.rotate_x(delta*10)
	
	if car_on:
		car_acceleration += delta * 0.0001
		car_speed += car_acceleration
		if car_speed > 0:
			$Ground/Building/Computer/Car.transform.origin = $Ground/Building/Computer/Car.transform.origin + (Vector3(-car_speed,0, 0))		
		if 	$Ground/Building/Computer/Car.global_transform.origin.x < $Ground/Building/Loading.global_transform.origin.x - 4:
			car_on = false
			emit_signal("load_fruit_world")
	

func camera_positioned():
	if not shop_open:
		shop_open = true
		order_time = OS.get_system_time_secs()
	else:
		computer_on = true
		
func order_arrived():
	$CashRegister.play()
	drink_order = random_order()
	shop_ui = shop_ui_scene.instance()	
	shop_ui.init(drink_order, fruit_data, scene_dictionary)
	add_child(shop_ui)
	
	shop_ui.connect("go_pressed", self, "_go_pressed")

func get_drink_order():
	return drink_order

func _go_pressed():
	if not portal_room:
		portal_camera()
		portal_room = true
		shop_ui.hide_go()
	else:
		turn_car_on()

func random_order():
	var order = []
	var total = randi() % 3 + 4
	for i in range(total):
		order.push_back(randi() % fruit_data.size())
	order.sort()
	return order
	
func shop_camera():
	lerp_target_camera = $ShopCamera
	lerping = true
	lerp_target_camera_reached = false

func portal_camera():
	lerp_target_camera = $PortalCamera
	lerping = true
	portal_room = true
	lerp_target_camera_reached = false

func portal_open():
	shop_ui.show_go()
	portal_open = true
	print("portal open")#

func turn_car_on():
	car_on = true
	lerp_target_camera = $Ground/Building/Computer/Car/CarCamera
	lerping = true
	shop_ui.hide_go()
