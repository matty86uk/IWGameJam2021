extends Node

var base_pedestrian = preload("res://Entities/BasePedestrian.tscn")

#var base_vehicle = preload("res://Entities/BaseVehicle.tscn")
var base_vehicle = preload("res://Entities/BaseVehicleRigid.tscn")
#var base_vehicle_gsai = preload("res://Entities/BaseVehicleGSAI.tscn")

var entity_types = {}
var entities = {}
var entity_mmi = {}
var entity_mm = {}

var vehicles = []
var pedestrians = []

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
	
	var mm_subtypes_dictionary = {}
	entity_mm[type] = mm_subtypes_dictionary
	
	var mmi_subtypes_dictionary = {}
	entity_mmi[type] = mmi_subtypes_dictionary
	
	var index=0
	for subtype in subtypes:
		##types dictionary
		var subtype_dictionary = {}
		subtype_dictionary["scene"] = scenes[index]
		subtype_dictionary["instance"] = scenes[index].instance()
		subtypes_dictionary[subtype] = subtype_dictionary
		
		##entities dictionary
		var entities_subtype_dictionary = []
		entities_subtypes_dictionary[subtype] = entities_subtype_dictionary
		
#		var mm_subtype = MultiMesh.new()
#		mm_subtypes_dictionary[subtype] = mm_subtype
#
#		var mmi_subtype = MultiMeshInstance.new()
#		mmi_subtypes_dictionary[subtype] = mmi_subtype
#
#		mmi_subtype.multimesh = mm_subtype
#		mm_subtype.instance_count = 1000
#		mm_subtype.transform_format = MultiMesh.TRANSFORM_3D
#		mm_subtype.color_format = MultiMesh.COLOR_8BIT
#		mm_subtype.visible_instance_count = 0
#
		
		#var a = subtype_dictionary["instance"].get_node("tmpParent").get_child(0).get_child(0).mesh
		
#		var current_node = subtype_dictionary["instance"].get_node("tmpParent").get_children()
#		var meshFound = false

#
#		mm_subtype.mesh = subtype_dictionary["instance"].get_node("tmpParent").get_child(0).get_child(0).mesh
#
		index+=1

func add_entity_type_astar(type, astar, astar_points):
	astar_dictionary[type] = astar
	astar_points_dictionary[type] = astar_points

func add_entity(type, subtype, position):
	if type == "vehicle":
		add_vehicle(type, subtype, position)
	elif type == "pedestrian":
		add_pedestrian(type, subtype, position)

func add_vehicle(type, subtype, position):
	var new_vehicle = base_vehicle.instance()
	new_vehicle.transform = Transform(Basis(), position)	
	var new_entity_scene = entity_types[type][subtype]["scene"].instance()
	for child in new_entity_scene.get_children():
		new_entity_scene.remove_child(child)
		new_vehicle.add_child(child)
	new_vehicle.state = new_vehicle.STATE_INSTANCED	
	add_child(new_vehicle)	
	vehicles.push_back(new_vehicle)

func add_pedestrian(type, subtype, position):
	var new_pedestrian = base_pedestrian.instance()
	new_pedestrian.transform = Transform(Basis(), position)
	var new_entity_scene = entity_types[type][subtype]["scene"].instance()
	for child in new_entity_scene.get_children():
		new_entity_scene.remove_child(child)
		new_pedestrian.add_child(child)
	new_pedestrian.state = new_pedestrian.STATE_INSTANCED
	add_child(new_pedestrian)
	pedestrians.push_back(new_pedestrian)	
	
func _process(delta):
	for vehicle in vehicles:
		var vehicle_state = vehicle.state
		var next_vehicle_state = null
		match vehicle_state:
			vehicle.STATE_INSTANCED:
				next_vehicle_state = vehicle.STATE_READY
			vehicle.STATE_READY:
				var path = generate_vehicle_path(vehicle.global_transform.origin)
				vehicle.path_index = 0
				if path.size() > 0:
					vehicle.set_path(path)
					next_vehicle_state = vehicle.STATE_HAS_ORDERS
				else:				
					print("No path")
					var new_path = []
					new_path.push_back(vehicle.transform.origin)
					new_path.push_back(vehicle.transform.origin + (Vector3.FORWARD))
					new_path.push_back(vehicle.transform.origin + (Vector3.FORWARD * 2))
					new_path.push_back(vehicle.transform.origin + (Vector3.FORWARD * 3))
					new_path.push_back(vehicle.transform.origin + (Vector3.FORWARD * 4))
					vehicle.set_path(new_path)
					next_vehicle_state = vehicle.STATE_HAS_ORDERS
			vehicle.STATE_HAS_ORDERS:
#				vehicle.path_index = 0
				#debug_show_path(vehicle)
				next_vehicle_state = vehicle.STATE_ENABLED
			vehicle.STATE_ENABLED:
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
			vehicle.forward()
	else:
		vehicle.state = vehicle.STATE_READY

