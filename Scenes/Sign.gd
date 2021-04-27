extends MeshInstance


var material
func _ready():
	material = SpatialMaterial.new()
	material_override = material
	

func _process(delta):
	material.albedo_texture = $Viewport.get_texture()	
	
