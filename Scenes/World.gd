extends Spatial

var size_x
var size_z

func _ready():
	randomize()
	#rand_seed(12345)
	var points = generate_roads(Vector3(0,0,0), 3, SimpleRoads.new(), 3)
	
	var road_dictionary = {}	
	
	var m2 = SpatialMaterial.new()
	m2.vertex_color_use_as_albedo = true
	m2.params_point_size = 4
	m2.flags_use_point_size = true
	m2.flags_unshaded = true
	
	var m1 = SpatialMaterial.new()
	m1.vertex_color_use_as_albedo = true
	m1.params_point_size = 4
	m1.flags_use_point_size = true
	m1.flags_unshaded = true
	
	var m = SpatialMaterial.new()
	m.vertex_color_use_as_albedo = true	
	m.flags_unshaded = true
	
	var st1 = SurfaceTool.new()
	st1.begin(Mesh.PRIMITIVE_POINTS)
	st1.add_color(Color.yellow)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_color(Color.white)
	var max_x = 0
	var max_z = 0
	var min_x = 0
	var min_z = 0
	for p in points:
		if (p.x > max_x):
			max_x = p.x
		if (p.x < min_x):
			min_x = p.x
		if (p.z > max_z):
			max_z = p.z
		if (p.z < min_z):
			min_z = p.z
		road_dictionary[p.round()] = "ROAD"
		st.add_vertex(p)
		st1.add_vertex(p)
	var mesh = st.commit()
	var mi = MeshInstance.new()
	mi.mesh = mesh
	mi.material_override = m
	$Root.add_child(mi)
	
	var mesh1 = st1.commit()
	var mi1 = MeshInstance.new()
	mi1.mesh = mesh1
	mi1.material_override = m1
	$Root.add_child(mi1)
	
	print(str("max_x:",max_x))
	print(str("min_x:",min_x))
	print(str("max_z:",max_z))
	print(str("min_z:",min_z))
	
	var building_points = generate_buildings(road_dictionary)
	
	var st2 = SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_POINTS)
	for p in building_points:
		if !road_dictionary.has(p):
			st2.add_color(Color.blue)
		else:
			st2.add_color(Color.red)
		st2.add_vertex(p)
		
	var mesh2 = st2.commit()
	var mi2 = MeshInstance.new()
	mi2.mesh = mesh2
	mi2.material_override = m2
	$Root.add_child(mi2)
	
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
					to = from + Vector3(1, 0, 0).rotated(Vector3.UP, deg2rad(rot))
					points.push_back(from)
					points.push_back(to)
					from = to
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
	
func generate_buildings(road_dictionary):
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

