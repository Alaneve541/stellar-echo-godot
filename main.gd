extends Node3D

func _ready():
	print("=== Main 场景启动 ===")

	var ground_tex = load("res://assets/ground_tile.png")
	if ground_tex:
		var ground_mat = StandardMaterial3D.new()
		ground_mat.albedo_texture = ground_tex
		ground_mat.uv1_scale = Vector3(8, 8, 1)
		var ground_mesh = get_node_or_null("Ground/MeshInstance3D")
		if ground_mesh:
			ground_mesh.material_override = ground_mat

	var building_tex = load("res://assets/building_tile.png")
	var buildings = get_node_or_null("Buildings")
	if buildings:
		for b in buildings.get_children():
			var mesh = b.get_node_or_null("MeshInstance3D")
			if mesh and building_tex:
				var mat = StandardMaterial3D.new()
				mat.albedo_texture = building_tex
				mat.uv1_scale = Vector3(2, 2, 1)
				mesh.material_override = mat

			var top = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(4.2, 0.1, 4.2)
			top.mesh = box
			var top_mat = StandardMaterial3D.new()
			top_mat.albedo_color = Color(0.4, 0.7, 1.0)
			top_mat.emission_enabled = true
			top_mat.emission = Color(0.4, 0.7, 1.0)
			top_mat.emission_energy_multiplier = 2.0
			top.material_override = top_mat
			top.position = Vector3(0, 4.1, 0)
			b.add_child(top)

	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.3, 0.3, 0.8)
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.3, 0.3, 0.8)
	line_mat.emission_energy_multiplier = 1.0

	for i in range(-30, 31, 5):
		var line1 = MeshInstance3D.new()
		var box1 = BoxMesh.new()
		box1.size = Vector3(0.05, 0.02, 60)
		line1.mesh = box1
		line1.material_override = line_mat
		line1.position = Vector3(i, 0.02, 0)
		add_child(line1)

		var line2 = MeshInstance3D.new()
		var box2 = BoxMesh.new()
		box2.size = Vector3(60, 0.02, 0.05)
		line2.mesh = box2
		line2.material_override = line_mat
		line2.position = Vector3(0, 0.02, i)
		add_child(line2)
