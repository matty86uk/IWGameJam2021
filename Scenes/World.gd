extends Spatial

var size_x
var size_z

func _ready():
	randomize()
	var points = generate(Vector3(0,0,0), 6, SimpleRoads.new(), 1)
	var m = SpatialMaterial.new()
	m.vertex_color_use_as_albedo = true
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_color(Color.green)
	for p in points:
		st.add_vertex(p)
	var mesh = st.commit()
	var mi = MeshInstance.new()
	mi.mesh = mesh
	mi.material_override = m
	add_child(mi)
	
func generate(start_position, iterations, rule, length):
#	length = -200
	var arrangement = rule.axiom
	for i in iterations:
#		length *= length_reduction
		var new_arrangement = ""
		for character in arrangement:
			new_arrangement += rule.get_character(character)
		arrangement = new_arrangement
	var lines = []
	var cache_queue = []
	var from = start_position
	var rot = 0 + ((randi() % 4) * rule.angle)
	for index in arrangement:
		match rule.get_action(index):
			"draw_forward":
				var to = from + Vector3(length, 0, 0).rotated(Vector3.UP, deg2rad(rot))
				lines.push_back(from)
				lines.push_back(to)
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
	return lines
		
func chance_ignore():
	if (randi() % 10 == 1):
		return true
	return false

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

