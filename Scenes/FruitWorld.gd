extends Spatial

signal loading(what)

var entities = load("res://Scenes/Entities.tscn").instance()
var player_scene = load("res://Entities/PlayerVehicle1.tscn")
var projectile_scene = load("res://Entities/Weapons/BallistaProjectile.tscn")

var size_x
var size_z
var player

var navigation_points = {}
var navigation_astar = {}

var grass_colors = [
	Color8(138, 184, 99),
	Color8(179, 212, 142),
	Color8(112, 156, 63),
	Color8(55, 94, 42)
]

var building_colors = [
	Color.red.darkened(0.5),
	Color.blue.darkened(0.5),
	Color.yellow.darkened(0.5),
	Color.orange.darkened(0.5),
	Color.purple.darkened(0.5),
	Color.coral
]




#var vehicle_astar = AStar.new()
#var vehicle_points = []
#
#var pedestrian_astar = AStar.new()
#var pedestrian_points = []

var camera_path_index = 0
var camera_path = []

var mi_object = MeshInstance.new()

func _process(delta):
	pass
	

func generate_world(world_seed : int):
	rand_seed(world_seed)

	#Road
	var map_dictionary = {}
	var road_points = generate_roads(Vector3(0,0,0), 2, SimpleRoads.new(), 3)
	expand_and_assign_roads(map_dictionary, road_points)
	
	#Pavements
	var pavement_points = generate_pavement(map_dictionary)
	assign_pavements(map_dictionary, pavement_points)
	
	#Buildings
	var building_points = generate_buildings(map_dictionary)
	var middle_of_building = assign_buildings_and_calculate_middle(map_dictionary, building_points)
	
	##Expand Buildings
	var buildings = expand_buildings(map_dictionary, middle_of_building)
	
	#Navigation
	var vehicle_astar = generate_astar_vehicle(map_dictionary)	
	var vehicle_points = vehicle_astar.get_points()
	var pedestrian_nav = generate_astar_pedestrian(map_dictionary)
	var pedestrian_astar = pedestrian_nav.get("astar")
	var pedestrian_points =  pedestrian_astar.get_points()
	entities.add_entity_type_astar("vehicle", vehicle_astar, vehicle_points)
	entities.add_entity_type_astar("pedestrian", pedestrian_astar, pedestrian_points)
	
	navigation_astar["vehicle"] = vehicle_astar
	navigation_points["vehicle"] = vehicle_points
	
	navigation_astar["pedestrian"] = pedestrian_astar
	navigation_points["pedestrian"] = pedestrian_points
	
	
	#World
	var world_size = find_world_size(map_dictionary)
	
	#floor
	create_floor_mesh(map_dictionary, world_size["min_x"], world_size["max_x"], world_size["min_z"], world_size["max_z"])
	
	#road and pavement
	create_road_and_pavement_mesh(map_dictionary, world_size["min_x"], world_size["max_x"], world_size["min_z"], world_size["max_z"])
	
	#buildings
	create_building_mesh(buildings)
	
func create_entity_types(type, sub_types, packed_scenes):
	entities.add_entity_type(type, sub_types, packed_scenes)

func create_entity(type, subtype):
	entities.add_entity(type, subtype, random_spawn_point_for_entity(type))

func random_spawn_point_for_entity(type):
	return navigation_astar[type].get_point_position(navigation_points[type][randi() % navigation_points[type].size()-1])		

func spawn_player():
	pass
	
func _ready():
	return
	#entities.add_entity_type("vehicle", ["sedan", "suv"], [load("res://Entities/Vehicles/sedan.tscn"), load("res://Models/Vehicles/suv.tscn")])	
	#entities.add_entity_type("vehicle", ["sedan"], [load("res://Entities/Vehicles/sedan.tscn")])	
	#entities.add_entity_type("pedestrian", ["pineapple"], [load("res://Entities/Pedestrians/pineapple.tscn")])
#	for i in range(10):
#		entities.add_entity("vehicle","sedan", Vector3(-54 - (i * 2),10,0))
	
	#randomize()
	rand_seed(12345)
	var map_dictionary = {}
	var points = generate_roads(Vector3(0,0,0), 2, SimpleRoads.new(), 3)

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
	print(str("Total Roads:", map_dictionary.size()))
	var pavement_points = generate_pavement(map_dictionary)
	for p in pavement_points:
		map_dictionary[p.round()] = "PAVEMENT"

	var vehicle_astar = generate_astar_vehicle(map_dictionary)	
	var vehicle_points = vehicle_astar.get_points()
	
	var pedestrian_nav = generate_astar_pedestrian(map_dictionary)
	var pedestrian_astar = pedestrian_nav.get("astar")
	var pedestrian_points =  pedestrian_astar.get_points()
	entities.add_entity_type_astar("vehicle", vehicle_astar, vehicle_points)
	entities.add_entity_type_astar("pedestrian", pedestrian_astar, pedestrian_points)
	
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
	min_x -= 100
	max_x += 100
	min_z -= 100
	max_z += 100

	print(max_x)
	print(min_x)
	print(max_z)
	print(min_z)

	var vert = 0	
	var x_size = (max_x - min_x)
	var z_size = (max_z - min_z) 
	var z_pos = 0
	var x_pos = 0
	
	
	var vertices_terrain  : PoolVector3Array
	var verticies_terrain_collision : PoolVector3Array
	var indexes_terrain : PoolIntArray
	var normals_terrain : PoolVector3Array
	
	for z in range(min_z, max_z + 1):
		for x in range(min_x, max_x + 1):
			vertices_terrain.push_back(Vector3(x, 0, z))
			normals_terrain.push_back(Vector3.UP)
			var y = 0
			var type = map_dictionary.get(Vector3(x, 0, z))
			if type == "PAVEMENT":
				y = 0.1
			elif type == "ROAD":
				y = 0.05
			verticies_terrain_collision.push_back(Vector3(x, y, z))
			
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

	var arr_mesh_collision = ArrayMesh.new()
	var arrays_collision = []
	arrays_collision.resize(ArrayMesh.ARRAY_MAX)
	arrays_collision[ArrayMesh.ARRAY_VERTEX] = verticies_terrain_collision
	arrays_collision[ArrayMesh.ARRAY_INDEX] = indexes_terrain
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr_mesh_collision.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_collision)
	
	var m = MeshInstance.new()
	var mat = SpatialMaterial.new()
	mat.vertex_color_is_srgb = true
	mat.albedo_color = Color.green
	mat.vertex_color_use_as_albedo = true
	mat.flags_use_point_size = true
	mat.params_point_size = 5
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	m.mesh = arr_mesh	
	m.name="floor"
	m.set_surface_material(0, mat)
	m.add_child(entities)
	$Root.add_child(m)
	
	
	var m_collision = MeshInstance.new()
	m_collision.mesh = arr_mesh_collision
	m_collision.create_trimesh_collision()
	m_collision.name = "floor_collision"
	m_collision.visible = false
	$Root.add_child(m_collision)
	
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
#
#	for i in range(200):
#		entities.add_entity("vehicle","sedan", vehicle_astar.get_point_position(vehicle_points[randi() % vehicle_points.size()-1]))
#
#	for i in range(1000):
#		entities.add_entity("pedestrian", "pineapple", pedestrian_astar.get_point_position(pedestrian_points[randi() % pedestrian_points.size()]))

	var building_mesh = CubeMesh.new()
	building_mesh.size = Vector3(1,4,1)
#
	var building_mat = SpatialMaterial.new()
	building_mat.vertex_color_use_as_albedo = true
	building_mat.flags_unshaded = false
#
	var mmi_buiding = MultiMeshInstance.new()
	var mm_buiding = MultiMesh.new()
	mm_buiding.mesh = building_mesh
	mm_buiding.mesh.surface_set_material(0, building_mat)
	mm_buiding.transform_format = MultiMesh.TRANSFORM_3D
	mm_buiding.color_format = MultiMesh.COLOR_FLOAT
	mm_buiding.instance_count = 500000
	mm_buiding.visible_instance_count = 0
	mmi_buiding.multimesh = mm_buiding
#
	var building_instance_count = 0
	for b in buildings:
		var building_block_points = buildings.get(b)
		var random_building_color = Color(randf(), randf(), randf())
		var random_height =1 + randi() % 3 
		for building_block_point in building_block_points:
			mm_buiding.set_instance_transform(building_instance_count, Transform(Basis(), building_block_point).scaled(Vector3(1, random_height, 1)))
			mm_buiding.set_instance_color(building_instance_count, random_building_color)
			building_instance_count += 1
	mm_buiding.visible_instance_count = building_instance_count
	$Root.add_child(mmi_buiding)
	
	player = player_scene.instance()
	player.transform.origin = Vector3(max_x - 20, 0, max_z - 20)
	player.init($Root, $Root/Rope, projectile_scene)
	$Root.add_child(player)
	player.get_node("Camera").current = true
	
# -----------------------

func expand_and_assign_roads(map_dictionary, points):
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

func assign_pavements(map_dictionary, points):
	for p in points:
		map_dictionary[p.round()] = "PAVEMENT"

func assign_buildings_and_calculate_middle(map_dictionary, points):
	var total_building_points = Vector3(0,0,0)
	for p in points:
		map_dictionary[p] = "BUILDING"
		total_building_points += p
	return total_building_points/points.size()
	
func expand_buildings(map_dictionary, avg_building_point):
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
	return buildings

func render_path():
	var existing = $Root.find_node("Path")
	if existing != null:
		$Root.remove_child(existing)
	var debug_mat = SpatialMaterial.new()
	debug_mat.vertex_color_use_as_albedo = true
	debug_mat.flags_use_point_size = true
	debug_mat.flags_unshaded = true
	var st_lines = SurfaceTool.new()
	st_lines.begin(Mesh.PRIMITIVE_LINES)
	st_lines.add_color(Color.green)
	var prev_p = camera_path[0]	
	for p in camera_path:
		st_lines.add_vertex(p + Vector3(0, 0.3, 0))
		st_lines.add_vertex(prev_p + Vector3(0, 0.3, 0))
		prev_p = p
	var debug_mesh_path = st_lines.commit()
	var debug_mi_path = MeshInstance.new()
	debug_mi_path.name="Path"
	debug_mi_path.material_override = debug_mat
	debug_mi_path.mesh = debug_mesh_path
	$Root.add_child(debug_mi_path)

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

func generate_astar_vehicle(map_dictionary):
	var road_side_dictionary = {}
	var astar = AStar.new()
	for p in map_dictionary.keys():
		var type = map_dictionary.get(p)
		if type == "ROAD":
#			find side of road
			var directions = find_road_direction(map_dictionary, p)
			
			if !is_dictionary_empty(directions):
				for point_direction in directions.keys():
					if !road_side_dictionary.has(point_direction):
						road_side_dictionary[point_direction] = []
					road_side_dictionary[point_direction] += directions.get(point_direction)

	print("road direction dictionary:", road_side_dictionary.size())
	var id_list = {}
	#create all points (that have directions)
	for point in road_side_dictionary.keys():		
		var id = generate_or_get_id_for_point(point, id_list)
		astar.add_point(id, point)
	#create connections
	for point in road_side_dictionary.keys():
		var id = generate_or_get_id_for_point(point, id_list)
		for direction in road_side_dictionary.get(point):
			var target_id = generate_or_get_id_for_point(point + direction, id_list)
			astar.connect_points(id, target_id, false)
	print("total id's in id_list:", id_list.size())
	return astar

func generate_astar_pedestrian(map_dictionary):
	var direction_length = 4
	var pavement_dictionary = {}
	var pavement_array = []
	var crossing_array = []
	for p in map_dictionary.keys():
		var type = map_dictionary.get(p)
		if type == "PAVEMENT":
			pavement_array.push_back(p)
			
			for i in range(3):
				var p1 = p + (Vector3.FORWARD/direction_length * i)
				var p2 = p + (Vector3.BACK/direction_length * i)
				var p3 = p + (Vector3.LEFT/direction_length * i)
				var p4 = p + (Vector3.RIGHT/direction_length * i)
				pavement_array.push_back(p1)
				pavement_array.push_back(p2)
				pavement_array.push_back(p3)
				pavement_array.push_back(p4)
				
			for x in range(3):
				for z in range(3):
					var p5 = p + (Vector3.FORWARD/direction_length * z) + (Vector3.LEFT/direction_length * x)
					var p6 = p + (Vector3.FORWARD/direction_length * z) + (Vector3.RIGHT/direction_length * x)
					var p7 = p + (Vector3.BACK/direction_length * z) + (Vector3.LEFT/direction_length * x)
					var p8 = p + (Vector3.BACK/direction_length * z) + (Vector3.RIGHT/direction_length * x)
					pavement_array.push_back(p5)
					pavement_array.push_back(p6)
					pavement_array.push_back(p7)
					pavement_array.push_back(p8)

			var forward = p + Vector3.FORWARD
			var left = p + Vector3.LEFT
			var right = p + Vector3.RIGHT
			var back = p + Vector3.BACK
			
			if map_dictionary.get(forward) == "PAVEMENT" and map_dictionary.get(left) == "PAVEMENT" and map_dictionary.get(back) == "ROAD" and map_dictionary.get(right) == "ROAD":				
				for i in range(16):
					crossing_array.push_back(p + (Vector3.RIGHT/direction_length * i))
					crossing_array.push_back(p + (Vector3.RIGHT/direction_length * i + Vector3.FORWARD/direction_length))
					crossing_array.push_back(p + (Vector3.RIGHT/direction_length * i + Vector3.BACK/direction_length))
					
					crossing_array.push_back(p + (Vector3.BACK/direction_length * i))	
					crossing_array.push_back(p + (Vector3.BACK/direction_length * i + Vector3.LEFT/direction_length))
					crossing_array.push_back(p + (Vector3.BACK/direction_length * i+ Vector3.RIGHT/direction_length))
			if map_dictionary.get(back) == "PAVEMENT" and map_dictionary.get(right) == "PAVEMENT" and map_dictionary.get(left) == "ROAD" and map_dictionary.get(forward) == "ROAD":				
				for i in range(16):
					crossing_array.push_back(p + (Vector3.LEFT/direction_length * i))
					crossing_array.push_back(p + (Vector3.LEFT/direction_length * i + Vector3.FORWARD/direction_length))
					crossing_array.push_back(p + (Vector3.LEFT/direction_length * i + Vector3.BACK/direction_length))
					
					crossing_array.push_back(p + (Vector3.FORWARD/direction_length * i))
					crossing_array.push_back(p + (Vector3.FORWARD/direction_length * i + Vector3.LEFT/direction_length))
					crossing_array.push_back(p + (Vector3.FORWARD/direction_length * i + Vector3.RIGHT/direction_length))
	
	
	var combined_dictionary = {}
	for p in pavement_array:
		combined_dictionary[p] = "PAVEMENT"
	for p in crossing_array:
		combined_dictionary[p] = "CROSSING"
		
	var id_list = {}
	var astar = AStar.new()
	var pedestrian_nav = {}
	for point in combined_dictionary:
		var id = generate_or_get_id_for_point(point, id_list)
		astar.add_point(id, point)
	
	for point in combined_dictionary:
		var id = generate_or_get_id_for_point(point, id_list)
		var directions = get_pavement_directions(combined_dictionary, point)
		for direction in directions:
			var target_id = generate_or_get_id_for_point(point + direction, id_list)
			astar.connect_points(id, target_id, false)
	pedestrian_nav["astar"] = astar
	return pedestrian_nav

func get_pavement_directions(pavement_points, point):
	var forward = point + Vector3.FORWARD/4
	var back = point + Vector3.BACK/4
	var left = point + Vector3.LEFT/4
	var right = point + Vector3.RIGHT/4
	
	var directions = []
	
	if pavement_points.get(forward) == "PAVEMENT" or pavement_points.get(forward) == "CROSSING":
		directions.push_back(Vector3.FORWARD/4)
	if pavement_points.get(back) == "PAVEMENT" or pavement_points.get(back) == "CROSSING":
		directions.push_back(Vector3.BACK/4)
	if pavement_points.get(left) == "PAVEMENT" or pavement_points.get(left) == "CROSSING":
		directions.push_back(Vector3.LEFT/4)
	if pavement_points.get(right) == "PAVEMENT" or pavement_points.get(right) == "CROSSING":
		directions.push_back(Vector3.RIGHT/4)
	return directions

func generate_or_get_id_for_point(point, id_list):
	if !id_list.has(point):
		id_list[point] = id_list.size() + 1
	return id_list[point]

func is_dictionary_empty(dictionary):
	var size = 0
	for key in dictionary.keys():
		var array = dictionary.get(key)
		size += array.size()
	return size == 0

func find_road_direction(map_dictionary, p):
	var directions = {}
	directions[p] = []
	
	var left = map_dictionary.get(p + Vector3.LEFT)
	var right = map_dictionary.get(p + Vector3.RIGHT)
	var forward = map_dictionary.get(p + Vector3.FORWARD)
	var back = map_dictionary.get(p + Vector3.BACK)
	
	var left_back = map_dictionary.get(p + Vector3.LEFT + Vector3.BACK)
	var right_back = map_dictionary.get(p + Vector3.RIGHT + Vector3.BACK)
	var right_forward = map_dictionary.get(p + Vector3.RIGHT + Vector3.FORWARD)
	var left_forward = map_dictionary.get(p + Vector3.LEFT + Vector3.FORWARD)
	
	var left_left =  map_dictionary.get(p + Vector3.LEFT + Vector3.LEFT)
	var right_right =  map_dictionary.get(p + Vector3.RIGHT + Vector3.RIGHT)
	var forward_forward =  map_dictionary.get(p + Vector3.FORWARD + Vector3.FORWARD)
	var back_back =  map_dictionary.get(p + Vector3.BACK + Vector3.BACK)
	var left_left_forward_forward =  map_dictionary.get(p + Vector3.LEFT + Vector3.LEFT + Vector3.FORWARD + Vector3.FORWARD)
	var right_right_forward_forward =  map_dictionary.get(p + Vector3.RIGHT + Vector3.RIGHT + Vector3.FORWARD + Vector3.FORWARD)
	var left_left_back_back =  map_dictionary.get(p + Vector3.LEFT + Vector3.LEFT + Vector3.BACK + Vector3.BACK)
	var right_right_back_back =  map_dictionary.get(p + Vector3.RIGHT + Vector3.RIGHT + Vector3.BACK + Vector3.BACK)
	
	var forward_forward_left = map_dictionary.get(p + Vector3.FORWARD + Vector3.FORWARD + Vector3.LEFT)
	var back_back_left = map_dictionary.get(p + Vector3.BACK + Vector3.BACK + Vector3.LEFT)
	var left_left_forward = map_dictionary.get(p + Vector3.LEFT + Vector3.LEFT + Vector3.FORWARD)
	
	if left	== "PAVEMENT" and forward == "ROAD":
		directions.get(p).push_back(Vector3.FORWARD)
	elif right	== "PAVEMENT" and back == "ROAD":
		directions.get(p).push_back(Vector3.BACK)
	elif forward == "PAVEMENT" and right == "ROAD":
		directions.get(p).push_back(Vector3.RIGHT)
	elif back == "PAVEMENT" and left == "ROAD":
		directions.get(p).push_back(Vector3.LEFT)
	
	## Directions relative to camera with no y-rotation. Forward - Back on Z-Axis. Left - Right on X-Axis
	
		## Forward -> Left
	if left == "ROAD" and back == "ROAD" and left_back == "PAVEMENT":
		directions.get(p).push_back(Vector3.LEFT)
		## Back -> Right
	elif right == "ROAD" and forward == "ROAD" and right_forward == "PAVEMENT":
		directions.get(p).push_back(Vector3.RIGHT)
		## Right -> Forward
	elif forward == "ROAD" and left == "ROAD" and left_forward == "PAVEMENT":
		directions.get(p).push_back(Vector3.FORWARD)
		## Left -> Back
	elif back == "ROAD" and right == "ROAD" and right_back == "PAVEMENT":
		directions.get(p).push_back(Vector3.BACK)	

	## centre of cross road
	if left_left == "ROAD" and right_right == "ROAD" and forward_forward == "ROAD" and back_back == "ROAD" \
	and left_left_forward_forward == "PAVEMENT" and right_right_forward_forward == "PAVEMENT" \
	and left_left_back_back == "PAVEMENT" and right_right_back_back == "PAVEMENT":
		directions[p + Vector3.BACK + Vector3.LEFT] = create_array_with_direction(Vector3.FORWARD)
		directions[p + Vector3.LEFT] = create_array_with_direction(Vector3.FORWARD)
		directions[p + Vector3.LEFT] += create_array_with_direction(Vector3.FORWARD + Vector3.RIGHT)
		directions[p + Vector3.FORWARD] = create_array_with_direction(Vector3.RIGHT)
		
		directions[p + Vector3.FORWARD + Vector3.RIGHT] = create_array_with_direction(Vector3.BACK)
		directions[p + Vector3.RIGHT] = create_array_with_direction(Vector3.BACK)
		directions[p + Vector3.RIGHT] += create_array_with_direction(Vector3.BACK + Vector3.LEFT)
		directions[p + Vector3.BACK] = create_array_with_direction(Vector3.LEFT)
		
		directions[p + Vector3.FORWARD + Vector3.LEFT] = create_array_with_direction(Vector3.RIGHT)
		directions[p + Vector3.FORWARD] += create_array_with_direction(Vector3.BACK + Vector3.RIGHT)
		
		directions[p + Vector3.BACK + Vector3.RIGHT] = create_array_with_direction(Vector3.LEFT)
		directions[p + Vector3.BACK] += create_array_with_direction(Vector3.FORWARD + Vector3.LEFT)
		
	## t-junction pointing Forward	
	if left_left == "ROAD" and right_right == "ROAD" and forward_forward == "PAVEMENT" and back_back == "ROAD" \
	 and left_left_back_back == "PAVEMENT" and right_right_back_back == "PAVEMENT":
		directions[p + Vector3.BACK + Vector3.LEFT] = create_array_with_direction(Vector3.FORWARD)
		directions[p + Vector3.LEFT] = create_array_with_direction(Vector3.FORWARD + Vector3.RIGHT)
		directions[p + Vector3.BACK + Vector3.RIGHT] = create_array_with_direction(Vector3.LEFT)
		directions[p + Vector3.BACK] = create_array_with_direction(Vector3.LEFT)

	## t-junction pointing back
	if left_left == "ROAD" and right_right == "ROAD" and back_back == "PAVEMENT" and forward_forward == "ROAD" \
	 and left_left_forward_forward == "PAVEMENT" and right_right_forward_forward == "PAVEMENT":
		directions[p + Vector3.FORWARD + Vector3.RIGHT] = create_array_with_direction(Vector3.BACK)
		directions[p + Vector3.RIGHT] = create_array_with_direction(Vector3.BACK + Vector3.LEFT)
		directions[p + Vector3.FORWARD + Vector3.LEFT] = create_array_with_direction(Vector3.RIGHT)
		directions[p + Vector3.FORWARD] = create_array_with_direction(Vector3.RIGHT)
	
# t-junction pointing left
	if back_back == "ROAD" and right_right == "ROAD" and left_left == "PAVEMENT" and forward_forward == "ROAD" \
	 and right_right_forward_forward == "PAVEMENT" and right_right_back_back == "PAVEMENT":
		directions[p + Vector3.BACK + Vector3.RIGHT] = create_array_with_direction(Vector3.LEFT)
		directions[p + Vector3.BACK] = create_array_with_direction(Vector3.FORWARD + Vector3.LEFT)
		directions[p + Vector3.FORWARD + Vector3.RIGHT] = create_array_with_direction(Vector3.BACK)
		directions[p + Vector3.RIGHT] = create_array_with_direction(Vector3.BACK)
		
# t-junction pointing right
	if back_back == "ROAD" and left_left == "ROAD" and right_right == "PAVEMENT" and forward_forward == "ROAD" \
	 and left_left_forward_forward == "PAVEMENT" and left_left_back_back == "PAVEMENT":
		directions[p + Vector3.FORWARD + Vector3.LEFT] = create_array_with_direction(Vector3.RIGHT)
		directions[p + Vector3.FORWARD] = create_array_with_direction(Vector3.BACK + Vector3.RIGHT)
		directions[p + Vector3.BACK + Vector3.LEFT] = create_array_with_direction(Vector3.FORWARD)
		directions[p + Vector3.LEFT] = create_array_with_direction(Vector3.FORWARD)
	
	return directions

func create_array_with_direction(direction):
	var array = []
	array.push_back(direction)
	return array
	
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
			"F":"FF+[+F-F-F+F+F]-[-F+F+F-F-F]-[+FF]"
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
			"[" : "store",
			"]" : "load"
		}

func find_world_size(map_dictionary):
	
	var min_x = 0
	var max_x = 0
	var min_z = 0
	var max_z = 0
	
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
	min_x -= 100
	max_x += 100
	min_z -= 100
	max_z += 100
	
	var dictionary = {}
	dictionary["min_x"] = min_x
	dictionary["max_x"] = max_x
	dictionary["min_z"] = min_z
	dictionary["max_z"] = max_z
	return dictionary

## Rendering
func create_floor_mesh(map_dictionary, min_x, max_x, min_z, max_z):
	var vert = 0	
	var x_size = (max_x - min_x)
	var z_size = (max_z - min_z) 
	var z_pos = 0
	var x_pos = 0
	var vertices_terrain  : PoolVector3Array
	var verticies_terrain_collision : PoolVector3Array
	var indexes_terrain : PoolIntArray
	var normals_terrain : PoolVector3Array
	
	for z in range(min_z, max_z + 1):
		for x in range(min_x, max_x + 1):
			vertices_terrain.push_back(Vector3(x, 0, z))
			normals_terrain.push_back(Vector3.UP)
			var y = 0
			var type = map_dictionary.get(Vector3(x, 0, z))
			if type == "PAVEMENT":
				y = 0.1
			elif type == "ROAD":
				y = 0.05
			verticies_terrain_collision.push_back(Vector3(x, y, z))
			
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

	var arr_mesh_collision = ArrayMesh.new()
	var arrays_collision = []
	arrays_collision.resize(ArrayMesh.ARRAY_MAX)
	arrays_collision[ArrayMesh.ARRAY_VERTEX] = verticies_terrain_collision
	arrays_collision[ArrayMesh.ARRAY_INDEX] = indexes_terrain
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr_mesh_collision.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_collision)
	
	var m = MeshInstance.new()
	var mat = SpatialMaterial.new()
	mat.vertex_color_is_srgb = true
	mat.albedo_color = Color.green
	mat.vertex_color_use_as_albedo = true
	mat.flags_use_point_size = true
	mat.params_point_size = 5
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	m.mesh = arr_mesh	
	m.name="floor"
	m.set_surface_material(0, mat)
	m.add_child(entities)
	$Root.add_child(m)
	
	
	var m_collision = MeshInstance.new()
	m_collision.mesh = arr_mesh_collision
	m_collision.create_trimesh_collision()
	m_collision.name = "floor_collision"
	m_collision.visible = false
	$Root.add_child(m_collision)
	
func create_road_and_pavement_mesh(map_dictionary, min_x, max_x, min_z, max_z):
	
	var road_mesh = CubeMesh.new()	
	road_mesh.size = Vector3(1, 0.1, 1)
	
	var road_tarmac = SpatialMaterial.new()
	road_tarmac.albedo_color = Color8(95, 100, 117)
	road_tarmac.vertex_color_use_as_albedo = true
	
	var pavement_mesh = CubeMesh.new()
	pavement_mesh.size = Vector3(1, 0.1, 1)
	
	var pavement = SpatialMaterial.new()
	pavement.albedo_color = Color8(224,224,237)
	pavement.vertex_color_use_as_albedo = true
	
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
	
func create_building_mesh(buildings):
	var building_mesh = CubeMesh.new()
	building_mesh.size = Vector3(1,4,1)
#
	var building_mat = SpatialMaterial.new()
	building_mat.vertex_color_use_as_albedo = true
	building_mat.flags_unshaded = false
#
	var mmi_buiding = MultiMeshInstance.new()
	var mm_buiding = MultiMesh.new()
	mm_buiding.mesh = building_mesh
	mm_buiding.mesh.surface_set_material(0, building_mat)
	mm_buiding.transform_format = MultiMesh.TRANSFORM_3D
	mm_buiding.color_format = MultiMesh.COLOR_FLOAT
	mm_buiding.instance_count = 500000
	mm_buiding.visible_instance_count = 0
	mmi_buiding.multimesh = mm_buiding
#
	var building_instance_count = 0
	for b in buildings:
		var building_block_points = buildings.get(b)
		var random_building_color = Color(randf(), randf(), randf())
		var random_height =1 + randi() % 3 
		for building_block_point in building_block_points:
			mm_buiding.set_instance_transform(building_instance_count, Transform(Basis(), building_block_point).scaled(Vector3(1, random_height, 1)))
			mm_buiding.set_instance_color(building_instance_count, random_building_color)
			building_instance_count += 1
	mm_buiding.visible_instance_count = building_instance_count
	$Root.add_child(mmi_buiding)
	
func create_player(max_x, max_z):
	player = player_scene.instance()
	player.transform.origin = Vector3(max_x - 20, 0, max_z - 20)
	player.init($Root, $Root/Rope, projectile_scene)
	$Root.add_child(player)
	player.get_node("Camera").current = true
