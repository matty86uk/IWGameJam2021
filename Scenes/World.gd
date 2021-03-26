extends Spatial

var size_x
var size_z

func _ready():
	#randomize()
	rand_seed(12345)
	var map_dictionary = {}
	var points = generate_roads(Vector3(0,0,0), 3, SimpleRoads.new(), 1)

	for p in points:
		var p1 = p*3+(Vector3(-1,0,1))
		var p2 = p*3+(Vector3(0,0,1))
		var p3 = p*3+(Vector3(1,0,1))
		var p4 = p*3+(Vector3(-1,0,0))
		var p5 = p*3+(Vector3(0,0,0))
		var p6 = p*3+(Vector3(1,0,0))
		var p7 = p*3+(Vector3(-1,0,-1))
		var p8 = p*3+(Vector3(0,0,-1))
		var p9 = p*3+(Vector3(1,0,-1))

		map_dictionary[p1.round()] = "ROAD"
		map_dictionary[p2.round()] = "ROAD"
		map_dictionary[p3.round()] = "ROAD"
		map_dictionary[p4.round()] = "ROAD"
		map_dictionary[p5.round()] = "ROAD"
		map_dictionary[p6.round()] = "ROAD"
		map_dictionary[p7.round()] = "ROAD"
		map_dictionary[p8.round()] = "ROAD"
		map_dictionary[p9.round()] = "ROAD"
		
	var pavement_points = generate_pavement(map_dictionary)		
	for p in pavement_points:
		map_dictionary[p.round()] = "PAVEMENT"
	
	
	var road_tarmac = SpatialMaterial.new()
	road_tarmac.albedo_color = Color8(32, 30, 25)
	road_tarmac.vertex_color_use_as_albedo = true
	
	var road_paint = SpatialMaterial.new()
	road_paint.albedo_color = Color.white
	road_paint.vertex_color_use_as_albedo = true
	
	var pavement = SpatialMaterial.new()
	pavement.albedo_color = Color.darkgray
	pavement.vertex_color_use_as_albedo = true
	
	
	var road_mesh = CubeMesh.new()	
	road_mesh.size = Vector3(1, 0.5, 1)
	
	var road_middle_mesh = CubeMesh.new()
	road_middle_mesh.size = Vector3(0.4,0.5,0.4)
	
	var max_x = 0
	var max_z = 0
	var min_x = 0
	var min_z = 0
	for p in map_dictionary.keys():
		if (p.x > max_x):
			max_x = p.x
		if (p.x < min_x):
			min_x = p.x
		if (p.z > max_z):
			max_z = p.z
		if (p.z < min_z):
			min_z = p.z
		
		if map_dictionary.get(p) == "ROAD":
			var mi = MeshInstance.new()
			mi.transform.origin = p
			mi.mesh = road_mesh
			mi.material_override = road_tarmac
#			if ((int(p.x) % 3) == 0 and (int(p.z) % 3) == 0):
#				mi.mesh = road_middle_mesh
#				mi.material_override = road_paint
			$Root.add_child(mi)
		
		if map_dictionary.get(p) == "PAVEMENT":
			var mi = MeshInstance.new()
			mi.mesh = road_mesh
			mi.transform.origin = p + Vector3(0, 0.05,0)
			mi.material_override = pavement
			$Root.add_child(mi)
	
	print(str("max_x:",max_x))
	print(str("min_x:",min_x))
	print(str("max_z:",max_z))
	print(str("min_z:",min_z))
	
	var p1 = Vector3(max_x, 0, max_z)
	var p2 = Vector3(max_x, 0, min_z)
	var p3 = Vector3(min_x, 0, min_z)
	var p4 = Vector3(min_x, 0, max_z)
	
	

func generate_roads(start_position, iterations, rule, length):
	var arrangement = rule.axiom
	for i in iterations:
		var new_arrangement = ""
		for character in arrangement:
			new_arrangement += rule.get_character(character)
		arrangement = new_arrangement
	var points = []
	var cache_queue = []
	var from = start_position
	var rot = 0 + ((randi() % 4) * rule.angle)
	for index in arrangement:
		var line_length = (length * randi() % 4)
		match rule.get_action(index):
			"draw_forward":
				for l in line_length*2:
					var to = from + Vector3(1, 0, 0).rotated(Vector3.UP, deg2rad(rot))
					points.push_back(from)
					points.push_back(to)
					from = to
					to = from + Vector3(1, 0, 0).rotated(Vector3.UP, deg2rad(rot))
					points.push_back(from)
					points.push_back(to)
					from = to
#					to = from + Vector3(1, 0, 0).rotated(Vector3.UP, deg2rad(rot))
#					points.push_back(from)
#					points.push_back(to)
#					from = to
			"rotate_right":
				if !chance_ignore():
					rot += rule.angle
			"rotate_left":
				if !chance_ignore():
					rot -= rule.angle
			"store":
				cache_queue.push_back([from, rot])
			"load":
				var cached_data = cache_queue.pop_back()
				from = cached_data[0]
				rot = cached_data[1]
	return points
		
func chance_ignore():
	if (randi() % 10 == 1):
		return true
	return false
	
func generate_pavement(road_dictionary):
	var building_points = []
	for p in road_dictionary.keys():
		var free_neighbours = find_free_area(road_dictionary, p)
		building_points += free_neighbours
	return building_points

func find_free_area(road_dictionary, position):
	var free = []	
	var up = Vector3(0,0,1) + position
	var down = Vector3(0,0,-1) + position
	var right = Vector3(1,0,0) + position
	var left = Vector3(-1,0,0) + position
	
	if (!road_dictionary.has(up)):
		free.push_back(up)
	if (!road_dictionary.has(down)):
		free.push_back(down)
	if (!road_dictionary.has(right)):
		free.push_back(right)
	if (!road_dictionary.has(left)):
		free.push_back(left)

	return free

class Rule:
	var axiom
	var angle
	var rules = {}
	var actions = {}
	func get_character(character):
		if rules.has(character):
			return rules.get(character)
		return character
	func get_action(character):
		return actions.get(character)

class SimpleRoads extends Rule:
	func _init():
		self.axiom = "F"
		self.angle = 90
		self.rules = {
			"F":"FF+[+F-F-F]-[-F+F+F]"
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
			"[" : "store",
			"]" : "load"
		}
		
#		var mi = MeshInstance.new()	
#		mi.transform.origin = Vector3(x_pos, 0.1, z_pos)
#		var mesh = CubeMesh.new()
#		mesh.size = Vector3(road_width, road_height, road_width)
#		mi.mesh = mesh
#		mi.material_override = mat
#		add_child(mi)

