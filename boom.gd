extends MeshInstance3D

var life := 0.0
const MAX_LIFE := 0.4
var mat: StandardMaterial3D

func _ready():
	mat = material_override as StandardMaterial3D
	scale = Vector3(0.3, 0.3, 0.3)

func _process(delta):
	if not is_inside_tree():
		return
	life += delta
	if life >= MAX_LIFE:
		queue_free()
		return
	var t = life / MAX_LIFE
	var s = 0.3 + t * 2.7
	scale = Vector3(s, s, s)
	if mat:
		var c = mat.albedo_color
		c.a = 0.8 * (1.0 - t)
		mat.albedo_color = c
