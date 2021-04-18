extends Spatial


var base_pedestrian = preload("res://Entities/BasePedestrian.tscn")

var fruits = []
var fruit_data = {}
var started = false
var fruit_delay = 1
var fruit_time = 2

var stop_blade = false
var blade_speed = 1
var blade_speed_max = 4

var drink_height_max = 0.19
var drink_rate = 0.01
onready var drink_height = $bowl/drink.transform.origin.y
var drink = false



func init(fruits, fruit_data):
	self.fruits = fruits
	self.fruit_data = fruit_data
	
	var blended_color = color_from_fruit(fruits[0])
	for i in range(fruits.size()):
		blended_color = blended_color.linear_interpolate(color_from_fruit(fruits[i]), 0.5)
		
	var mat = SpatialMaterial.new()
	mat.albedo_color = blended_color
	mat.flags_unshaded = true
	$bowl/drink/tmpParent/bowl.material_override = mat
	
func start():
	started = true
	pass

func _process(delta):	
	if started:
		if fruits.size() > 0:
			if fruit_time > fruit_delay:
				var next_fruit = fruits.pop_front()
				add_fruit(next_fruit)
				fruit_time = 0
		else:
			if stop_blade:
				pass
			else:
				$bowl/Blades.rotate_y(delta * blade_speed)
			if blade_speed < blade_speed_max:
				blade_speed += delta
			else:
				drink = true
				$bowl/drink.show()
		fruit_time+=delta
		
	if drink:
		if drink_height < drink_height_max:		
			var pos = $bowl/drink.transform.origin
			pos += Vector3(0, drink_rate * delta, 0)
			drink_height += drink_rate * delta
			$bowl/drink.transform.origin = pos
		if drink_height > drink_height_max * 0.8:
			stop_blade = true
		

func add_fruit(fruit):
	var new_fruit = base_pedestrian.instance()
	new_fruit.transform.origin = $Pipe/Spatial.global_transform.origin
	new_fruit.scale = Vector3(2,2,2)	
	new_fruit.rotation = Vector3(randf(), randf(), randf())
	var new_entity_scene = fruit_data[fruit].instance()
	for child in new_entity_scene.get_children():
		new_entity_scene.remove_child(child)
		new_fruit.add_child(child)
	add_child(new_fruit)
	new_fruit.apply_central_impulse(Vector3.RIGHT * ((randi() % 2)))
	
func color_from_fruit(fruit):
	
	match fruit:
		"apple":
			return Color.darkred
		"banana":
			return Color.lightyellow
		"coconut":
			return Color.white
		"grapes":
			return Color.purple
		"lemon":
			return Color.yellow
		"orange":
			return Color.orange
		"pear":
			return Color.green
		"pineapple":
			return Color.darkorange
		"strawberry":
			return Color.red
		_: 
			return Color.transparent
	
