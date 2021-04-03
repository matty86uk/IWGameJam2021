extends Spatial

var base_vehicle = preload("res://Models/Vehicles/BaseVehicle.tscn")
var base_vehicle_rigid = preload("res://Models/Vehicles/BaseVehicleRigid.tscn")
var base_vehicle_gsai = preload("res://Models/Vehicles/BaseVehicleGSAI.tscn")

var entity_types = {}
var entities = {}

var vehicles = []

var astar_dictionary = {}
var astar_points_dictionary = {}

var mi_debug = MeshInstance.new()
var mat_debug = SpatialMaterial.new()

func _ready():
	mat_debug.vertex_color_use_as_albedo = true	
	mat_debug.flags_unshaded = true
	add_child(mi_debug)

func add_entity_type(type, subtypes, scenes):
	var subtypes_dictionary = {}
	entity_types[type] = subtypes_dictionary
	
	var entities_subtypes_dictionary = {}
	entities[type] = entities_subtypes_dictionary
	
	var index=0
	for subtype in subtypes:
		##types dictionary
		var subtype_dictionary = {}
		subtype_dictionary["scene"] = scenes[index]
		subtypes_dictionary[subtype] = subtype_dictionary
		
		##entities dictionary
		var entities_subtype_dictionary = []
		entities_subtypes_dictionary[subtype] = entities_subtype_dictionary
		index+=1

func add_entity_type_astar(type, astar, astar_points):
	astar_dictionary[type] = astar
	astar_points_dictionary[type] = astar_points

func add_entity(type, subtype, position):
	var new_vehicle = base_vehicle.instance()
	new_vehicle.transform = Transform(Basis(), position)
	var new_entity_scene = entity_types[type][subtype]["scene"].instance()
	for child in new_entity_scene.get_children():
		new_entity_scene.remove_child(child)
		new_vehicle.add_child(child)
	new_vehicle.state = new_vehicle.STATE_INSTANCED	
	add_child(new_vehicle)	
	vehicles.push_back(new_vehicle)
	
	
	
func _process(delta):
	for vehicle in vehicles:
		var vehicle_state = vehicle.state
		var next_vehicle_state = null
		match vehicle_state:
			vehicle.STATE_INSTANCED:
				next_vehicle_state = vehicle.STATE_READY
			vehicle.STATE_READY:
				var path = generate_vehicle_path(vehicle.transform.origin)
				vehicle.path_index = 0
				if path.size() > 0:
					vehicle.set_path(path)
					next_vehicle_state = vehicle.STATE_HAS_ORDERS
				else:
					pass
			vehicle.STATE_HAS_ORDERS:
#				vehicle.path_index = 0
				#debug_show_path(vehicle)
				next_vehicle_state = vehicle.STATE_MOVING
			vehicle.STATE_MOVING:
				#pass
				move_vehicle(vehicle)
		if next_vehicle_state:
			vehicle.state = next_vehicle_state
#
#func _process(delta):
#	pass
	
func generate_vehicle_path(from):
	var astar = astar_dictionary["vehicle"]
	var from_point = astar.get_closest_point(from)
	var to_point = astar_points_dictionary["vehicle"][randi() % astar_points_dictionary["vehicle"].size()-1]
#	var path = []
#	path.push_back(Vector3(0,0,-20))
#	path.push_back(Vector3(0,0,-19))
#	return path
	return astar.get_point_path(from_point, to_point)

func debug_show_path(vehicle):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_color(Color.yellow)
	for point in vehicle.path:
		st.add_vertex(point + Vector3(0, 0.5, 0))
	
	var mi = MeshInstance.new()
	mi.mesh = st.commit()
	
	var mat = SpatialMaterial.new()
	mat.vertex_color_use_as_albedo = true
	mat.flags_unshaded = true
	
	mi.material_override = mat
	add_child(mi)
	
func move_vehicle(vehicle):
	pass
	if vehicle.path.size() > 0 and  vehicle.path_index < vehicle.path.size():

		var target = vehicle.path[vehicle.path_index]
		var from = vehicle.get_global_transform().origin

		if from.distance_squared_to(target) < 1:
			vehicle.path_index += 1
		else:
			vehicle.power()
	else:
		vehicle.state = vehicle.STATE_READY

