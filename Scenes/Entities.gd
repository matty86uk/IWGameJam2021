extends Node

var base_pedestrian = preload("res://Entities/BasePedestrian.tscn")
var base_vehicle = preload("res://Entities/BaseVehicleRigid.tscn")
var base_police = preload("res://Entities/BasePolice.tscn")
var police_entity_scene = preload("res://Entities/Vehicles/police.tscn")

var entity_types = {}
var entities = {}
var entity_mmi = {}
var entity_mm = {}

var vehicles = []
var pedestrians = []
var polices = []

var astar_dictionary = {}
var astar_points_dictionary = {}
var astar_secondary_type = {}

var mi_debug = MeshInstance.new()
var mat_debug = SpatialMaterial.new()

var entity_tick = 0

var player

var police_update_timer

var police_evade_time_max = 30
var police_evade_time = 0
var police_evade_time_interval = 1
var police_alert = false
var police_alert_perm = false


var entity_timers_desc = {
	"do_pedestrian": 1.0,
	"do_vehicle": 1.0,
	"do_police": 1.0,
}
var entity_timers = []

func init_player(player):
	player.connect("weapon_used", self, "_weapon_used")
	player.connect("police_alerted", self, "_police_alerted")
	player.connect("police_alerted_perm", self, "_police_alerted_perm")
	self.player = player

func _weapon_used():
	police_alert = true
	player.show_warning()

func _police_alerted():
	player.show_warning()
	police_evade_time = 0

func _police_alerted_perm():
	police_alert_perm = true
	player.show_warning()

func _ready():
	mat_debug.vertex_color_use_as_albedo = true	
	mat_debug.flags_unshaded = true
	add_child(mi_debug)
	police_update_timer = Timer.new()
	add_child(police_update_timer)
	
	police_update_timer.connect("timeout", self, "_police_logic")
	police_update_timer.set_wait_time(police_evade_time_interval)
	police_update_timer.set_one_shot(false) # Make sure it loops
	police_update_timer.start()
	
	for entity_timer in entity_timers_desc.keys():
		var timeout = entity_timers_desc[entity_timer]
		var new_timer = Timer.new()
		new_timer.name = entity_timer
		add_child(new_timer)
		new_timer.connect("timeout", self, entity_timer)
		new_timer.set_wait_time(timeout)
		new_timer.set_one_shot(false)
		new_timer.start()
		
func start_entity_loop():
	pass

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
		entities_subtypes_dictionary[subtype] = entities_subtype_dictionary#
		index+=1

func add_entity_type_astar_v2(type, astar, astar_points, secondary_type):
	astar_dictionary[type] = astar
	astar_points_dictionary[type] = astar_points
	astar_secondary_type[type] = secondary_type

func add_entity_type_astar(type, astar, astar_points):
	astar_dictionary[type] = astar
	astar_points_dictionary[type] = astar_points

func add_entity(type, subtype, position):
	if type == "vehicle":
		add_vehicle(type, subtype, position)
	elif type == "pedestrian":
		add_pedestrian(type, subtype, position)
	elif type == "police":
		add_police(type, subtype, position)

func add_vehicle(type, subtype, position):
	var new_vehicle = base_vehicle.instance()
	new_vehicle.transform = Transform(Basis(), position)	
	var new_entity_scene = entity_types[type][subtype]["scene"].instance()
	for child in new_entity_scene.get_children():
		new_entity_scene.remove_child(child)
		new_vehicle.add_child(child)
	new_vehicle.state = new_vehicle.STATE_INSTANCED
	new_vehicle.set_meta("type", type)
	new_vehicle.set_meta("subtype", subtype)
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
	new_pedestrian.set_meta("type", type)
	new_pedestrian.set_meta("subtype", subtype)
	add_child(new_pedestrian)
	pedestrians.push_back(new_pedestrian)

func add_police(type, subtype, position):
	var new_police = base_police.instance()
	new_police.transform = Transform(Basis(), position)
	var new_entity_scene = police_entity_scene.instance()
	for child in new_entity_scene.get_children():
		new_entity_scene.remove_child(child)
		new_police.add_child(child)
	new_police.state = new_police.STATE_INSTANCED
	new_police.set_meta("type", type)
	new_police.set_meta("subtype", subtype)
	add_child(new_police)
	polices.push_back(new_police)


func _process(delta):
	#entity_loop()
	pass
	
func entity_loop():	
		do_police()
		do_vehicle()
		do_pedestrian()
		

func do_pedestrian():
	#print("do_pedestrian")
	for pedestrian in pedestrians:
			var pedestrian_state = pedestrian.state
			var next_pedestrian_state = null
			match pedestrian_state:
				pedestrian.STATE_INSTANCED:
					next_pedestrian_state = pedestrian.STATE_READY
				pedestrian.STATE_READY:
					var path = generate_pedestrian_path(pedestrian.global_transform.origin)
					pedestrian.path_index = 0
					if path.size() > 0:
						pedestrian.set_path(path)
						next_pedestrian_state = pedestrian.STATE_HAS_ORDERS
					else:
						#print("No path")
						var new_path = []
						new_path.push_back(pedestrian.transform.origin)
						new_path.push_back(pedestrian.transform.origin + (Vector3.FORWARD))
						new_path.push_back(pedestrian.transform.origin + (Vector3.FORWARD * 2))
						new_path.push_back(pedestrian.transform.origin + (Vector3.FORWARD * 3))
						new_path.push_back(pedestrian.transform.origin + (Vector3.FORWARD * 4))
						pedestrian.set_path(new_path)
						next_pedestrian_state = pedestrian.STATE_HAS_ORDERS
				pedestrian.STATE_HAS_ORDERS:
	#				vehicle.path_index = 0
					#debug_show_path(vehicle)
					next_pedestrian_state = pedestrian.STATE_ENABLED
				pedestrian.STATE_ENABLED:
					check_pedestrian_point(pedestrian)
			if next_pedestrian_state:
				pedestrian.state = next_pedestrian_state

func do_vehicle():
	#print("do_vehicle")
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
						#print("No path")
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
					check_vehicle_point(vehicle)
			if next_vehicle_state:
				vehicle.state = next_vehicle_state

func do_police():
	#print("do_police")
	for police in polices:
		var police_state =police.state
		var next_police_state = null
		match police_state:
			police.STATE_INSTANCED:
				police.mode = police.MODE_PATROL
				next_police_state = police.STATE_READY
			police.STATE_READY:
				var path = [police.global_transform.origin]
				if police.mode == police.MODE_PATROL:
					path = generate_vehicle_path(police.global_transform.origin)
				police.set_path(path)
				police.set_path_index(0)
				next_police_state = police.STATE_HAS_ORDERS
			police.STATE_HAS_ORDERS:
				next_police_state = police.STATE_ENABLED
			police.STATE_ENABLED:
				check_police_point(police)
				if police.mode == police.MODE_CHASE:
					if player:
						var player_pos = player.global_transform.origin
						if police.can_see_player(player) and police.global_transform.origin.distance_to(player_pos) < 10:
							police.chase_direct = true
							police.chase_point = player_pos
							police_alert = true
							#police_evade_time = 0
						else: #goto player position
							police.chase_direct = false
				elif police.mode == police.MODE_PATROL:
					if police.can_see_player(player) and police_alert:
						police.alert()
			police.STATE_MODE_CHANGED:
				police.state = police.STATE_READY
		if next_police_state:
			police.state = next_police_state
			
func _police_logic():
	if police_alert_perm:
		police_alert = true
		police_evade_time = 0
	var player_seen = false
	for police in polices:
		var police_state = police.state
		if police.state == police.STATE_ENABLED and not police.chase_direct:
			if police.mode == police.MODE_CHASE:
				var player_pos = player.global_transform.origin
				var path = [police.global_transform.origin]
				var last_chase_path_point = player_pos
				if police.chase_path.size() > 0:
					last_chase_path_point = police.chase_path[police.chase_path.size()-1]
				if police.chase_path.size() == 0 or player_pos.distance_to(last_chase_path_point) > 3:
					path = generate_police_path(police.global_transform.origin, player.global_transform.origin)
					police.set_path(path)
		if police.can_see_player(player) and police_alert:
			player_seen = true
			#print("Spotted")
			player.show_spotted()
			police_evade_time = 0
		else:
			pass
	
	if player_seen:
		player.hide_hiding()
		

	if not player_seen:
		#print("Hiding")
		if police_alert:
			player.show_hiding()
		police_evade_time += police_evade_time_interval
		if police_evade_time > police_evade_time_max:
			police_alert = false
			player.hide_warning()
			police_evade_time =  police_evade_time_max + 1
			#print("Escaped")
			var was_chased = false
			for police in polices:
				if police.mode == police.MODE_CHASE:
					was_chased = true
				police.unalert()
			if was_chased:
				player.show_escaped()
	else:
		police_alert = true
	
func generate_vehicle_path(from):
	var astar = astar_dictionary["vehicle"]
	var from_point = astar.get_closest_point(from)
	var to_point = astar_points_dictionary["vehicle"][randi() % astar_points_dictionary["vehicle"].size()-1]
	return astar.get_point_path(from_point, to_point)
	
func generate_pedestrian_path(from):
	var astar = astar_dictionary["pedestrian"]
	var from_point = astar.get_closest_point(from)
	var to_point = astar_points_dictionary["pedestrian"][randi() % astar_points_dictionary["pedestrian"].size()-1]
	return astar.get_point_path(from_point, to_point)

func generate_police_path(from, to):
	var astar = astar_dictionary["police"]
	var from_point = astar.get_closest_point(from)
	var to_point = astar_points_dictionary["police"][randi() % astar_points_dictionary["police"].size()-1]
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
	
func check_vehicle_point(vehicle):	
	if vehicle.path.size() > 0 and  vehicle.path_index < vehicle.path.size():
		var target = vehicle.path[vehicle.path_index]
		var from = vehicle.get_global_transform().origin
		var distance =  from.distance_squared_to(target)
		if distance < 3:
			vehicle.path_index += 1
#		elif distance > 6:
#			vehicle.state = vehicle.STATE_READY		
	else:
		#print("new orders")
		vehicle.state = vehicle.STATE_READY

func check_pedestrian_point(pedestrian):
	if pedestrian.path.size() > 0 and  pedestrian.path_index < pedestrian.path.size():
		var target = pedestrian.path[pedestrian.path_index]
		var from = pedestrian.get_global_transform().origin
		var distance =  from.distance_squared_to(target)
		if distance < 1:
			pedestrian.path_index += 1
#		elif distance > 6:
#			pedestrian.state = pedestrian.STATE_READY		
	else:
		#print("new orders")
		pedestrian.state = pedestrian.STATE_READY
	pass
	
func check_police_point(police):
	
	var path = []
	var path_index = 0
	
	if police.mode == police.MODE_PATROL:
		path = police.patrol_path
		path_index = police.patrol_path_index
	elif police.mode == police.MODE_CHASE:
		path = police.chase_path
		path_index = police.chase_path_index
	
	if path.size() > 0 and  path_index < path.size():
		var target = path[path_index]
		var from = police.get_global_transform().origin
		var distance =  from.distance_squared_to(target)
		if distance < 3:
			if police.mode == police.MODE_PATROL:
				police.patrol_path_index += 1
			elif police.mode == police.MODE_CHASE:
				police.chase_path_index += 1
#		elif distance > 6:
#			vehicle.state = vehicle.STATE_READY		
	else:
		#print("police new orders")
		police.state = police.STATE_READY
	pass

