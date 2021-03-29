extends Spatial

var size_x
var size_z

var grass_colors = [
	Color8(138, 184, 99),
	Color8(179, 212, 142),
	Color8(112, 156, 63),
	Color8(55, 94, 42)
]

var building_colors = [
#	Color8(255, 154, 162),
#	Color8(255, 183, 178),
#	Color8(255, 218, 193),
#	Color8(226, 240, 203),
#	Color8(181, 234, 215),
#	Color8(199, 206, 234)
	Color.red.darkened(0.5),
	Color.blue.darkened(0.5),
	Color.yellow.darkened(0.5),
	Color.orange.darkened(0.5),
	Color.purple.darkened(0.5),
	Color.coral
]

var pedestrian_astar = AStar2D.new()
 
func _ready():
	#randomize()
	rand_seed(12345)
	var map_dictionary = {}
	var points = generate_roads(Vector3(0,0,0), 3, SimpleRoads.new(), 3)

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
	
	var building_points = generate_buildings(map_dictionary)
	var total_buiilding_points = Vector3(0,0,0)
	for p in building_points:
		map_dictionary[p] = "BUILDING"
		total_buiilding_points += p
	
	var avg_building_point = total_buiilding_points/building_points.size()

	var road_tarmac = SpatialMaterial.new()
	road_tarmac.albedo_color = Color8(95, 100, 117)
	road_tarmac.vertex_color_use_as_albedo = true
	
	var road_paint = SpatialMaterial.new()
	road_paint.albedo_color = Color.white
	road_paint.vertex_color_use_as_albedo = true
	
	var pavement = SpatialMaterial.new()
	pavement.albedo_color = Color8(224,224,237)
	pavement.vertex_color_use_as_albedo = true
		
	var road_mesh = CubeMesh.new()	
	road_mesh.size = Vector3(1, 0.1, 1)
	
	var pavement_mesh = CubeMesh.new()
	pavement_mesh.size = Vector3(1, 0.1, 1)
	
	var road_middle_mesh = CubeMesh.new()
	road_middle_mesh.size = Vector3(0.4,0.5,0.4)
	
	var max_x = 0
	var max_z = 0
	var min_x = 0
	var min_z = 0

	var buildings = {}
	var used_building_points = {}
	var building_count = 0
	for p in map_dictionary.keys():
		if map_dictionary.get(p) == "BUILDING" and !used_building_points.has(p):
			var distance_to_center = round((avg_building_point.distance_to(p)/10))	+ 1
			var building_size = (50/distance_to_center) + randi() % 5
			var building_height = 2 + randi() % 10
			var free_directions = find_building_direction(map_dictionary, p)
			var free_direction = Vector3(0,0,0)
			if free_directions.has("FORWARD"):
				free_direction += Vector3.FORWARD
			if free_directions.has("BACK"):
				free_direction += Vector3.BACK
			if free_directions.has("LEFT"):
				free_direction += Vector3.LEFT
			if free_directions.has("RIGHT"):
				free_direction += Vector3.RIGHT
			
			if (free_directions.size() == 1):
				var perp_direction = free_direction.rotated(Vector3.UP, deg2rad(90))
				var new_building_array = []
				for i in building_size:
					for j in building_size:
						var new_point = p + (free_direction * i) + (perp_direction * j)
						new_point = new_point.round()
						if ((map_dictionary.get(new_point) != "ROAD" and map_dictionary.get(new_point) != "PAVEMENT")):
							new_building_array.push_back(new_point)
							used_building_points[new_point] = "USED"
				buildings[buildings.size()] = new_building_array

	for p in map_dictionary.keys():
		if (p.x > max_x):
			max_x = p.x
		if (p.x < min_x):
			min_x = p.x
		if (p.z > max_z):
			max_z = p.z
		if (p.z < min_z):
			min_z = p.z
#
#	min_x -= 100
#	max_x += 100
#	min_z -= 100
#	max_z += 100

	print(max_x)
	print(min_x)
	print(max_z)
	print(min_z)

#	var x_size = max_x - min_x
#	var z_size = max_z - min_z

	var vert = 0

	
#	min_z = 0
#	min_x = 0
#	max_x = 1
#	max_z = 1
	
	var x_size = (max_x - min_x)
	var z_size = (max_z - min_z) 
	print(x_size)
	print(z_size)
	var z_pos = 0
	var x_pos = 0
	
	var vertices_terrain  : PoolVector3Array	
	var indexes_terrain : PoolIntArray
	var normals_terrain : PoolVector3Array
	
	for z in range(min_z, max_z + 1):
		for x in range(min_x, max_x + 1):
			vertices_terrain.push_back(Vector3(x, 0, z))
			normals_terrain.push_back(Vector3.UP)
			
			if x_pos < x_size and z_pos < z_size:
				indexes_terrain.push_back(vert + 0)
				indexes_terrain.push_back(vert + 1)
				indexes_terrain.push_back(vert + x_size + 1)
				indexes_terrain.push_back(vert + 1)
				indexes_terrain.push_back(vert + x_size + 2)
				indexes_terrain.push_back(vert + x_size + 1)
			vert += 1
			x_pos+=1
		x_pos=0
		z_pos+=1
		
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices_terrain
	arrays[ArrayMesh.ARRAY_INDEX] = indexes_terrain
	arrays[ArrayMesh.ARRAY_NORMAL] = normals_terrain
#	arrays[ArrayMesh.ARRAY_COLOR] = colors
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m = MeshInstance.new()
	var mat = SpatialMaterial.new()
	mat.vertex_color_is_srgb = true
	mat.albedo_color = Color.green
	mat.vertex_color_use_as_albedo = true
	mat.flags_use_point_size = true
	mat.params_point_size = 5
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	m.mesh = arr_mesh
	#m.material_override = mat
	m.set_surface_material(0, mat)	
	$Root.add_child(m)
	
	var mmi_roads = MultiMeshInstance.new()
	var mm_roads = MultiMesh.new()
	mm_roads.mesh = road_mesh
	mm_roads.mesh.surface_set_material(0, road_tarmac)
	mm_roads.transform_format = MultiMesh.TRANSFORM_3D
	mm_roads.color_format = MultiMesh.COLOR_FLOAT
	mm_roads.instance_count = 99999
	mm_roads.visible_instance_count = 0
	mmi_roads.multimesh = mm_roads
	
	var mmi_pavement = MultiMeshInstance.new()
	var mm_pavement = MultiMesh.new()
	mm_pavement.mesh = pavement_mesh
	mm_pavement.mesh.surface_set_material(0, pavement)
	mm_pavement.transform_format = MultiMesh.TRANSFORM_3D
	mm_pavement.color_format = MultiMesh.COLOR_FLOAT
	mm_pavement.instance_count = 99999
	mm_pavement.visible_instance_count = 0
	mmi_pavement.multimesh = mm_pavement
	
	var road_instance_count = 0
	var pavement_instance_count = 0
	for z in range(min_z, max_z):
		for x in range(min_x, max_x):
			var p = Vector3(x, 0, z)
			var type = map_dictionary.get(p)
			if type == "ROAD":
				mm_roads.set_instance_transform(road_instance_count, Transform(Basis(), p))
				road_instance_count+=1
			elif type == "PAVEMENT":
				mm_pavement.set_instance_transform(pavement_instance_count, Transform(Basis(), p + Vector3(0, 0.05, 0)))
				pavement_instance_count+=1
	
	mm_roads.visible_instance_count = road_instance_count
	mm_pavement.visible_instance_count = pavement_instance_count
	$Root.add_child(mmi_roads)
	$Root.add_child(mmi_pavement)
	
	var building_mesh = CubeMesh.new()
	building_mesh.size = Vector3(1,4,1)
	
	var building_mat = SpatialMaterial.new()
	building_mat.vertex_color_use_as_albedo = true
	building_mat.flags_unshaded = false
	
	var mmi_buiding = MultiMeshInstance.new()
	var mm_buiding = MultiMesh.new()
	mm_buiding.mesh = building_mesh
	mm_buiding.mesh.surface_set_material(0, building_mat)
	mm_buiding.transform_format = MultiMesh.TRANSFORM_3D
	mm_buiding.color_format = MultiMesh.COLOR_FLOAT
	mm_buiding.instance_count = 500000
	mm_buiding.visible_instance_count = 0
	mmi_buiding.multimesh = mm_buiding
	
	var building_instance_count = 0
	for b in buildings:
		var building_block_points = buildings.get(b)
		var random_building_color = Color(randf(), randf(), randf())
		var random_height =1 + randi() % 8 
		for building_block_point in building_block_points:
			mm_buiding.set_instance_transform(building_instance_count, Transform(Basis(), building_block_point).scaled(Vector3(1, random_height, 1)))
			mm_buiding.set_instance_color(building_instance_count, random_building_color)
			building_instance_count += 1
	mm_buiding.visible_instance_count = building_instance_count
	$Root.add_child(mmi_buiding)
	
	var road_side_dictionary = generate_astar_vehicle(map_dictionary)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_POINTS)

	for side in road_side_dictionary.keys():
		var prev_p = null
		for p in road_side_dictionary.get(side):
			if side == "LEFT":
				st.add_color(Color.red)
				st.add_vertex(p + Vector3(0,0.4,0))
			elif side == "RIGHT":
				st.add_color(Color.blue)	
				st.add_vertex(p + Vector3(0,0.4,0))
			elif side == "FORWARD":
				st.add_color(Color.green)	
				st.add_vertex(p + Vector3(0,0.4,0))
			elif side == "BACK":
				st.add_color(Color.yellow)	
				st.add_vertex(p + Vector3(0,0.4,0))	
	
	var debug_mat = SpatialMaterial.new()
	debug_mat.vertex_color_use_as_albedo = true
	debug_mat.flags_use_point_size = true
	debug_mat.params_point_size = 5
	debug_mat.flags_unshaded = true
	
	var debug_mesh = st.commit()
	var debug_mi = MeshInstance.new()
	debug_mi.material_override = debug_mat
	debug_mi.mesh = debug_mesh
	
	$Root.add_child(debug_mi)
	

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

func random_color(colors):
	return colors[randi() % colors.size()]

func generate_astar_pedestrian(map_dictionary):
	var astar = AStar2D.new()	
	pass

func generate_astar_vehicle(map_dictionary):
	var road_side_dictionary = {}
	var left = []
	var right = []
	var forward = []
	var back = []
	var astar = AStar2D.new()
	for p in map_dictionary.keys():
		var type = map_dictionary.get(p)
		if type == "ROAD":
#			find side of road
			var side = find_road_direction(map_dictionary, p)
			if side == "LEFT":
				left.push_back(p)
			elif side == "RIGHT":
				right.push_back(p)
			elif side == "FORWARD":
				forward.push_back(p)
			elif side == "BACK":
				back.push_back(p)
	road_side_dictionary["LEFT"] = left
	road_side_dictionary["RIGHT"] = right
	road_side_dictionary["FORWARD"] = forward
	road_side_dictionary["BACK"] = back
	return road_side_dictionary

func find_road_direction(map_dictionary, p):
	if map_dictionary.get(p + Vector3.LEFT)	== "PAVEMENT":
		return "FORWARD"
	elif map_dictionary.get(p + Vector3.RIGHT)	== "PAVEMENT":
		return "BACK"
	elif map_dictionary.get(p + Vector3.FORWARD) == "PAVEMENT":
		return "RIGHT"
	elif map_dictionary.get(p + Vector3.BACK) == "PAVEMENT":
		return "LEFT"
	return ""
func generate_pavement(road_dictionary):
	var pavement_points = []
	for p in road_dictionary.keys():
		var free_neighbours = find_free_area(road_dictionary, p, true)
		pavement_points += free_neighbours
	return pavement_points

func generate_buildings(map_dictionary):
	var building_points = []
	for p in map_dictionary.keys():
		var free_neighbours = find_free_area(map_dictionary, p)
		building_points += free_neighbours
	return building_points

func find_free_area(road_dictionary, position, corners=false):
	var free = []
	
	var forward = Vector3.FORWARD + position
	var back = Vector3.BACK + position
	var right = Vector3.RIGHT + position
	var left = Vector3.LEFT + position

	var forward_free = false
	var back_free = false
	var right_free = false 
	var left_free = false

	if (!road_dictionary.has(forward)):
		forward_free = true
		free.push_back(forward)
	if (!road_dictionary.has(back)):
		back_free = true
		free.push_back(back)
	if (!road_dictionary.has(right)):
		right_free = true
		free.push_back(right)
	if (!road_dictionary.has(left)):
		left_free = true
		free.push_back(left)
	if (corners):
		if (forward_free and left_free):
			free.push_back(Vector3.FORWARD + Vector3.LEFT + position)
		if (forward_free and right_free):
			free.push_back(Vector3.FORWARD + Vector3.RIGHT + position)
		if (back_free and left_free):
			free.push_back(Vector3.BACK + Vector3.LEFT + position)
		if (back_free and right_free):
			free.push_back(Vector3.BACK + Vector3.RIGHT + position)
	return free
	
func find_building_direction(map_dictionary, position):
	var free = []
	var forward = Vector3.FORWARD + position
	var back = Vector3.BACK + position
	var right = Vector3.RIGHT + position
	var left = Vector3.LEFT + position
		
	if (!map_dictionary.has(forward)):
		free.push_back("FORWARD")
	if (!map_dictionary.has(back)):
		free.push_back("BACK")
	if (!map_dictionary.has(right)):
		free.push_back("RIGHT")
	if (!map_dictionary.has(left)):
		free.push_back("LEFT")
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

