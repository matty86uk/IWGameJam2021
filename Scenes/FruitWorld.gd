extends Spatial

signal normal_music
signal getaway_music

var entities = load("res://Scenes/Entities.tscn").instance()
var player_scene = load("res://Entities/PlayerVehicle1.tscn")
var projectile_scene = load("res://Entities/Weapons/BallistaProjectile.tscn")

var size_x
var size_z
var player

var starting_color = Color.white
var target_color = Color.transparent

var blender_on = false


var navigation_points = {}
var navigation_astar = {}

#var building_sizes = {
#		"1":[7,7],
#		"2":[7,6],
#		"3":[7,5],
#		"4":[7,4],
#		"5":[6,6],
#		"6":[6,5],
#		"7":[6,4],
#		"8":[5,5],
#		"9":[5,4],
#		"10":[5,3],
#		"11":[4,3],
#		"12":[3,3]
#	}

var building_sizes = {
	"1":[3,3],
#	"2":[4,4],
#	"3":[3,3]
	}

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

var camera_path_index = 0
var camera_path = []

var mi_object = MeshInstance.new()

var world_size
var world_centre

var current_camera_pos
var player_spawn_point
var player_won = false

var four_corner_cam = false
var four_corners = []
var four_corner_index = 0

var fruit_data
var drink_order
var scene_dictionary

func _physics_process(delta):
	if current_camera_pos:
		if not four_corner_cam and not $Camera.global_transform.is_equal_approx(current_camera_pos.global_transform):
			$Camera.global_transform = $Camera.global_transform.interpolate_with(current_camera_pos.global_transform, delta* 3.0)
		if four_corner_cam:
			if not $Camera.global_transform.origin.distance_squared_to(four_corners[four_corner_index]) < 4:
				$Camera.global_transform.origin = $Camera.global_transform.origin.linear_interpolate(four_corners[four_corner_index], delta * 0.25)
				$Camera.look_at(world_centre, Vector3.UP)
			else:
				four_corner_index += 1
				if four_corner_index >= four_corners.size():
					four_corner_index = 0

func _process(delta):
	if player_won:
		if blender_on:
			$ObjectiveEnd/BlenderRect.texture = $Viewport.get_texture()
		else:
			if not $ObjectiveEnd.modulate.is_equal_approx(target_color):
				$ObjectiveEnd.modulate = $ObjectiveEnd.modulate.linear_interpolate(target_color, delta)
		
		
		if not $ObjectiveSuccess.modulate.is_equal_approx(target_color):
			$ObjectiveSuccess.modulate = $ObjectiveSuccess.modulate.linear_interpolate(target_color, delta * 0.25)
		
	

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
	world_centre = middle_of_building
	##Expand Buildings
	var buildings = expand_buildings_v2(map_dictionary, middle_of_building)
	#expand_buildings_v2(map_dictionary, middle_of_building)
	
	#Navigation
	var vehicle_astar = generate_astar_vehicle(map_dictionary)	
	var vehicle_points = vehicle_astar.get_points()
	var pedestrian_nav = generate_astar_pedestrian(map_dictionary)
	var pedestrian_astar = pedestrian_nav.get("astar")
	var pedestrian_points =  pedestrian_astar.get_points()
	
	var police_astar = generate_astar_police(map_dictionary)
	var police_points = police_astar.get_points()
	
	entities.add_entity_type_astar("vehicle", vehicle_astar, vehicle_points)
	entities.add_entity_type_astar("pedestrian", pedestrian_astar, pedestrian_points)
	entities.add_entity_type_astar_v2("police", police_astar, police_points, "vehicle")
	
	navigation_astar["vehicle"] = vehicle_astar
	navigation_points["vehicle"] = vehicle_points
	
	navigation_astar["pedestrian"] = pedestrian_astar
	navigation_points["pedestrian"] = pedestrian_points
	
	navigation_astar["police"] = police_astar
	navigation_points["police"] = police_points
		
	#World
	world_size = find_world_size(map_dictionary)
	
	#store four corners
	four_corners.push_back(Vector3(world_size["min_x"] + 30, 50, world_size["min_z"] + 30))
	four_corners.push_back(Vector3(world_size["min_x"]+ 30 , 50, world_size["max_z"] - 30))
	four_corners.push_back(Vector3(world_size["max_x"] - 30, 50, world_size["max_z"] - 30))
	four_corners.push_back(Vector3(world_size["max_x"] - 30, 50, world_size["min_z"] + 30))
	
	
	#floor
	create_floor_mesh(map_dictionary, world_size["min_x"], world_size["max_x"], world_size["min_z"], world_size["max_z"])
	
	#road and pavement
	create_road_and_pavement_mesh(map_dictionary, world_size["min_x"], world_size["max_x"], world_size["min_z"], world_size["max_z"])
	
	#buildings
	create_building_mesh(buildings)
	
func create_entity_types(type, sub_types, packed_scenes):
	entities.add_entity_type(type, sub_types, packed_scenes)

func create_entity(type, subtype):	
	entities.add_entity(type, subtype, random_spawn_point_for_entity(type) + Vector3.UP)

func random_spawn_point_for_entity(type):
	return navigation_astar[type].get_point_position(navigation_points[type][randi() % navigation_points[type].size()-1])

func spawn_player(fruit_data, scene_dictionary, drink_order):
	
	self.scene_dictionary = scene_dictionary
	self.fruit_data = fruit_data
	self.drink_order = drink_order
	
	emit_signal("normal_music")
	var max_x = world_size["max_x"]
	var max_z = world_size["max_z"]
	player_spawn_point = Vector3(max_x - 20, 0, max_z - 20)
	player = player_scene.instance()
	player.transform.origin = player_spawn_point
	player.init($Root, $Root/Rope, projectile_scene, $Camera, fruit_data, scene_dictionary, drink_order)
	player.set_spawn_point(player_spawn_point)
	player.connect("forward_camera", self, "_forward_camera")
	player.connect("reverse_camera", self, "_reverse_camera")
	player.connect("portal_on", self, "_portal_on")
	player.connect("player_won", self, "_player_won")
	player.connect("getaway", self, "_getaway")
	player.set_meta("type", "player")
	$Root.add_child(player)
	entities.init_player(player)
	entities.start_entity_loop()
	
func _portal_on():
	$Root/PortalExit.global_transform.origin = player_spawn_point
	$Root/PortalExit.show()
	$Root/PortalExit.play_noise()

func _player_won():
	print("Player won")
	if not player_won:
		transition_camera_world()
		player_won = true
		four_corner_cam = true
		$ObjectiveEnd.show()
		$ObjectiveEnd.modulate = starting_color
		blender_on = true
		$Viewport/Blender.connect("blender_finished", self, "_blender_finished")
		$Viewport/Blender.init(drink_order, fruit_data, scene_dictionary)
		$Viewport/Blender.start()
		emit_signal("normal_music")

func _blender_finished():
	blender_on = false
	$ObjectiveSuccess.show()	
	$ObjectiveSuccess.modulate = starting_color

func _getaway():
	emit_signal("getaway_music")

func _forward_camera():
	transition_camera("Final")

func _reverse_camera():
	transition_camera("FinalReverse")
	
func show_player_ui():
	player.show_player_ui()

func hide_player_ui():
	player.show_player_ui()
	
func move_camera(position):
	$Camera.global_transform = player.get_node(str("Camera", position)).global_transform	
	current_camera_pos =  player.get_node(str("Camera", position))
	
func transition_camera(position):
	current_camera_pos =  player.get_node(str("Camera", position))

func transition_camera_world():
	current_camera_pos = $Root/HighPoint

func set_current_camera():
	$Camera.current = true
	
func _ready():
	return
	
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

func expand_buildings_v2(map_dictionary, avg_building_point):

	var buildings = {}
	var used_building_points = {}
	var max_distance = 0 
	var min_distance = 1000
	for p in map_dictionary.keys():
		if map_dictionary.get(p) == "BUILDING":
			var distance = p.distance_squared_to(avg_building_point)
			if distance > max_distance:
				max_distance = distance
			if distance < min_distance:
				min_distance = distance
	
	for p in map_dictionary.keys():
		# and not used_building_points.has(p):
		if map_dictionary.get(p) == "BUILDING" and not used_building_points.has(p):
			var distance = p.distance_squared_to(avg_building_point)
			var normalised_height = remap_range(distance, min_distance, max_distance, 1, 10)
			var chance_removal = 0
			var building_height_factor = 1
			if normalised_height >= 5:
				building_height_factor = 2 + randi() % 2
				chance_removal = 0.35
			elif normalised_height >= 3 and normalised_height <5:
				building_height_factor = 5  + randi() % 3
				chance_removal = 0.25
			elif normalised_height >= 2.5 and normalised_height < 3:
				building_height_factor = 8 + randi() % 3
				chance_removal = 0.15
			elif normalised_height < 2.5:
				chance_removal = 0.05
				building_height_factor = 12 + randi() % 3
			
			var building_height = building_height_factor 

#			var min_building_size = int(floor(remap_range(distance, min_distance, max_distance, 1, 7)))
#		
#			var random_building_size_index = (randi() % min_building_size) + 5
#			if random_building_size_index > building_sizes.size():
#				random_building_size_index = building_sizes.size()
#			var random_building_size = building_sizes.get(str(random_building_size_index))
			var random_building_size_index = (randi() % building_sizes.size())
			var random_building_size = building_sizes.get(str(random_building_size_index + 1))
			
			var x_size = random_building_size[0]
			var z_size = random_building_size[1]
			
			var full_buildings = []
			var local_building_points_1 = []
			var local_building_points_2 = []
			var local_building_points_3 = []
			var local_building_points_4 = []
			var full_building = true
			
			for x in range(x_size):
				for z in range(z_size):
					var point = p + (x * Vector3.LEFT) + (z * Vector3.FORWARD)					
					if not map_dictionary.get(point) == "ROAD" and not map_dictionary.get(point) == "PAVEMENT" and not used_building_points.has(point):
						local_building_points_1.push_back(point)
					else:
						full_building = false
			if full_building and not local_building_points_1.empty():
				full_buildings.push_back(1)
			
			full_building = true
			for x in range(x_size):
				for z in range(z_size):
					var point = p + (x * Vector3.LEFT) + (z * Vector3.BACK)					
					if not map_dictionary.get(point) == "ROAD" and not map_dictionary.get(point) == "PAVEMENT" and not used_building_points.has(point):
						local_building_points_2.push_back(point)
					else:
						full_building = false
			if full_building and not local_building_points_2.empty():
				full_buildings.push_back(2)
			
			full_building = true
			for x in range(x_size):
				for z in range(z_size):
					var point = p + (x * Vector3.RIGHT) + (z * Vector3.FORWARD)					
					if not map_dictionary.get(point) == "ROAD" and not map_dictionary.get(point) == "PAVEMENT" and not used_building_points.has(point):
						local_building_points_3.push_back(point)
					else:		
						full_building = false
			if full_building and not local_building_points_3.empty():
				full_buildings.push_back(3)
						
			full_building = true
			for x in range(x_size):
				for z in range(z_size):
					var point = p + (x * Vector3.RIGHT) + (z * Vector3.BACK)
					if not map_dictionary.get(point) == "ROAD" and not map_dictionary.get(point) == "PAVEMENT" and not used_building_points.has(point):
						local_building_points_4.push_back(point)
					else:
						full_building = false
			if full_building and not local_building_points_4.empty():
				full_buildings.push_back(4)
			

			if not full_buildings.empty():
				var local_building_points = []
				var chosen_building_points = full_buildings[randi() % full_buildings.size()]
				if chosen_building_points == 1:
					local_building_points = local_building_points_1
				elif chosen_building_points == 2:
					local_building_points = local_building_points_2
				elif chosen_building_points == 3:
					local_building_points = local_building_points_3
				elif chosen_building_points == 4:
					local_building_points = local_building_points_4
				
				for point in local_building_points:
					used_building_points[point] = "USED"
				var building = {}
				if randf() < (0.9 - chance_removal):
					building["points"] = local_building_points
					building["height"] = building_height
					buildings[buildings.size()] = building
	
	return buildings
	
func remap_range(value, InputA, InputB, OutputA, OutputB):
	return(value - InputA) / (InputB - InputA) * (OutputB - OutputA) + OutputA

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

func generate_astar_police(map_dictionary):
	
	var police_points = {}
	for p in map_dictionary.keys():
		var type = map_dictionary.get(p)
		if type == "ROAD":
			var forward = p + Vector3.FORWARD
			var back = p + Vector3.BACK
			var left = p + Vector3.LEFT
			var right = p + Vector3.RIGHT
			
			var directions = []
			if map_dictionary.get(forward) == "ROAD":
				directions.push_back(Vector3.FORWARD)
			if map_dictionary.get(back) == "ROAD":
				directions.push_back(Vector3.BACK)
			if map_dictionary.get(left) == "ROAD":
				directions.push_back(Vector3.LEFT)
			if  map_dictionary.get(right) == "ROAD":
				directions.push_back(Vector3.RIGHT)
				
			police_points[p] = directions
	
	var id_list = {}
	var astar = AStar.new()
	
	for p in police_points:
		var id = generate_or_get_id_for_point(p, id_list)
		astar.add_point(id, p)

	var st = SurfaceTool.new()	
	st.begin(Mesh.PRIMITIVE_LINES)
	for p in police_points:
		var id = generate_or_get_id_for_point(p, id_list)
		var directions = police_points[p]
		for direction in directions:
			var target_id = generate_or_get_id_for_point(p + direction, id_list)
			astar.connect_points(id, target_id, true)
			st.add_color(Color.green)
			st.add_vertex(p + Vector3.UP)
			st.add_color(Color.white)
			st.add_vertex(p + direction + (Vector3.UP * 0.5))
	var mesh = st.commit()
	var mat = SpatialMaterial.new()
	mat.vertex_color_use_as_albedo = true
	mat.flags_unshaded = true
	var mi = MeshInstance.new()
	mi.mesh = mesh
	mi.material_override = mat
	#$Root.add_child(mi)
	return astar

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
	min_x -= 20
	max_x += 20
	min_z -= 20
	max_z += 20
	
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
			var random_y = randf()  * 0.1
			
			var y = 0
			var type = map_dictionary.get(Vector3(x, 0, z))
			if type == "PAVEMENT":
				y = 0.1
				random_y = 0
			elif type == "ROAD":
				y = 0.05
				random_y = 0
			vertices_terrain.push_back(Vector3(x, random_y , z))
			normals_terrain.push_back(Vector3.UP * random_y * 10)
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
	mat.albedo_color = Color.green.darkened(0.2)
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
	
func create_building_mesh(buildings_dictionary):
	var building_mesh = CubeMesh.new()
	building_mesh.size = Vector3(1,1,1)
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
	
	
	var collision_root = StaticBody.new()
	collision_root.name = "building_collision_root"
	$Root.add_child(collision_root)
	
	for building in buildings_dictionary:
		
		var building_points = buildings_dictionary.get(building)["points"]
		var building_height = buildings_dictionary.get(building)["height"]
		var random_building_color = Color(randf(), randf(), randf())
		
		
		
		if building_points.size() > 0:
			var lowest = lowest_vector(building_points)
			var highest = highest_vector(building_points)
			var centre_point = centre_vector(building_points)
			var x_size = highest.x - lowest.x
			var z_size = highest.z - lowest.z
			var shape = BoxShape.new()
			shape.extents = Vector3((x_size/2)+0.5, 1, (z_size/2)+0.5)
			var col_shape = CollisionShape.new()
			col_shape.transform = Transform(Basis(), centre_point)
			col_shape.shape =  shape
			collision_root.add_child(col_shape)
			
		
			for building_point in building_points:
				var t = Transform(Basis(), building_point).scaled(Vector3(1, building_height, 1))
				mm_buiding.set_instance_transform(building_instance_count, t)
				mm_buiding.set_instance_color(building_instance_count, random_building_color)
				building_instance_count += 1
	##			var collision_shape = CollisionShape.new()
	##			collision_shape.transform = t
	##			var shape = BoxShape.new()
	##			shape.extents = Vector3(1, building_height, 1)
	##			collision_shape.shape = shape
	##			collision_root.add_child(collision_shape)


		
		
		
		
	mm_buiding.visible_instance_count = building_instance_count
	$Root.add_child(mmi_buiding)

func lowest_vector(vectors):
	var lowest = vectors[0]
	for v in vectors:
		if v < lowest:
			lowest = v
	return lowest

func highest_vector(vectors):
	var highest = vectors[0]
	for v in vectors:
		if v > highest:
			highest = v
	return highest

func centre_vector(vectors):
	var total
	for v in vectors:
		if not total:
			total = v
		else:
			total += v
	return (total/vectors.size()).round()

func create_player(max_x, max_z):
	player = player_scene.instance()
	player.transform.origin = Vector3(max_x - 20, 0, max_z - 20)
	player.init($Root, $Root/Rope, projectile_scene)
	$Root.add_child(player)
	player.get_node("Camera").current = true
