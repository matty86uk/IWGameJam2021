extends Spatial


var entity_types = {}
var entities = {}

class Entity:
	
	const STATE_INSTANCED = 0
	const STATE_READY = 1
	
	var id
	var state
	var colors
	var path
	var path_index
	var body
	var position
	var type
	
	func _init(id, state, colors, path, path_index, body, position):
		self.id = id
		self.state = state
		self.colors = colors
		self.path = path
		self.path_index = path_index
		self.body = body
		self.position = position

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

func add_entity(type, subtype, position):
	var new_entity = entity_types[type][subtype]["scene"].instance()
	new_entity.transform = Transform(Basis(), position)
	#new_entity.transform = new_entity.transform.scaled(Vector3(0.5,0.5,0.5))
	
	#new_entity.sleeping = true
	#new_entity.steering = -0.1
	new_entity.engine_force = 400
	add_child(new_entity)
	
func _physics_process(delta):
	#get_children()[0].engine_force = 100
	pass
	
