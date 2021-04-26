extends Spatial

var material = SpatialMaterial.new()

func _ready():
	material.flags_transparent = true
	material.flags_unshaded = true
	material.params_billboard_mode = SpatialMaterial.BILLBOARD_ENABLED
	$MeshInstance2.material_override = material

func play_noise():
	$SpawnNoise.play()

func _process(delta):
	material.albedo_texture = $Viewport.get_texture()	
	$MeshInstance/MeshInstance.rotate_y(delta)
