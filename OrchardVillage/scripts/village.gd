extends Node3D

var materials := {}

func _ready() -> void:
	var world_light := WorldEnvironment.new()
	world_light.environment = Environment.new()
	world_light.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_light.environment.ambient_light_color = Color("#d9ebdd")
	world_light.environment.ambient_light_energy = 0.62
	add_child(world_light)

	var grass := box(self, Vector3(0, -0.28, 0), Vector3(38, 0.56, 34), "#82965b")
	collider(grass, grass.mesh.size, Vector3.ZERO)
	box(self, Vector3(0, 0.012, 0), Vector3(30, 0.024, 3.15), "#d7b78b")
	box(self, Vector3(0, 0.014, 0), Vector3(3.1, 0.025, 26), "#d7b78b")
	box(self, Vector3(0, 0.017, 0), Vector3(5.7, 0.025, 5.7), "#dfc59c")

	for side in [-1, 1]:
		collider(self, Vector3(0.4, 3, 34), Vector3(side * 18.8, 1.4, 0))
		collider(self, Vector3(38, 3, 0.4), Vector3(0, 1.4, side * 16.8))

	house(Vector3(-5.1, 0, -6), 0.0, "#eac68d", "#a35542")
	house(Vector3(4.5, 0, -5.8), 0.0, "#f2deb0", "#a95942")
	house(Vector3(10.8, 0, -6.8), 0.0, "#dcb483", "#76654c")
	house(Vector3(-9.7, 0, 5.6), PI, "#ead4a2", "#687e75")
	house(Vector3(-4.4, 0, 7.5), PI, "#e9bc8a", "#9a584b")
	house(Vector3(6.2, 0, 6.8), PI, "#f0d5a5", "#81704d")

	var rng := RandomNumberGenerator.new()
	rng.seed = 312
	for x in [-15, -11, -6, -2, 3, 8, 13, 16]:
		for z in [-12, 12]:
			tree(Vector3(x + rng.randf_range(-0.7, 0.7), 0, z + rng.randf_range(-0.9, 0.9)),
				rng.randf_range(0.8, 1.22), "#5b8053" if rng.randf() > 0.5 else "#6b914f")
	for spot in [Vector3(-14, 0, -5), Vector3(14, 0, 4), Vector3(11, 0, 7), Vector3(-13, 0, 8)]:
		tree(spot, 1.12, "#50794d")

	for index in 125:
		var x := rng.randf_range(-18.0, 18.0)
		var z := rng.randf_range(-16.0, 16.0)
		if absf(x) < 2.9 or absf(z) < 2.9:
			continue
		box(self, Vector3(x, 0.031, z), Vector3(0.07, 0.063, 0.10),
			"#d4bc65" if index % 3 == 0 else "#6d8752")

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#213a31ee")
	panel.border_color = Color("#a9a879")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(10)
	$HUD/Card.add_theme_stylebox_override("panel", panel)

func material(hex: String) -> StandardMaterial3D:
	if not materials.has(hex):
		var paint := StandardMaterial3D.new()
		paint.albedo_color = Color(hex)
		paint.roughness = 1.0
		materials[hex] = paint
	return materials[hex]

func mesh_at(parent: Node3D, point: Vector3, mesh: Mesh, hex: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material(hex)
	instance.position = point
	parent.add_child(instance)
	return instance

func box(parent: Node3D, point: Vector3, dimensions: Vector3, hex: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return mesh_at(parent, point, mesh, hex)

func collider(parent: Node3D, dimensions: Vector3, point: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = point
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = dimensions
	shape.shape = bounds
	body.add_child(shape)
	parent.add_child(body)

func house(point: Vector3, yaw: float, walls: String, roof: String) -> void:
	var home := Node3D.new()
	home.position = point
	home.rotation.y = yaw
	$Buildings.add_child(home)
	box(home, Vector3(0, 0.14, 0), Vector3(3.5, 0.28, 3.55), "#948571")
	box(home, Vector3(0, 1.22, 0), Vector3(3.35, 2.3, 3.4), walls)
	collider(home, Vector3(3.5, 2.4, 3.55), Vector3(0, 1.2, 0))
	for side in [-1, 1]:
		var slope := box(home, Vector3(side * 0.96, 2.81, 0), Vector3(2.26, 0.17, 3.94), roof)
		slope.rotation.z = deg_to_rad(-side * 28.0)
		for front in [-1, 1]:
			var window := Vector3(side * 0.97, 1.41, front * 1.72)
			box(home, window, Vector3(0.67, 0.72, 0.10), "#eee0b4")
			box(home, window + Vector3(0, 0, front * 0.056), Vector3(0.48, 0.52, 0.035), "#496366")
			box(home, window + Vector3(0, 0, front * 0.080), Vector3(0.045, 0.53, 0.025), "#eee0b4")
	for front in [-1, 1]:
		var gable := PrismMesh.new()
		gable.size = Vector3(3.34, 0.89, 0.08)
		mesh_at(home, Vector3(0, 2.77, front * 1.66), gable, walls)
	box(home, Vector3(0, 0.70, 1.72), Vector3(0.69, 1.37, 0.11), "#79513b")
	box(home, Vector3(0, 0.07, 1.96), Vector3(1.0, 0.14, 0.44), "#a0957e")
	box(home, Vector3(-0.81, 3.03, -0.73), Vector3(0.42, 1.1, 0.44), "#956553")
	box(home, Vector3(-0.81, 3.60, -0.73), Vector3(0.52, 0.12, 0.54), "#765347")

func tree(point: Vector3, factor: float, green: String) -> void:
	box(self, point + Vector3.UP * 0.66 * factor, Vector3(0.32, 1.32, 0.34) * factor, "#795639")
	collider(self, Vector3(0.4, 1.6, 0.4) * factor, point + Vector3.UP * 0.8 * factor)
	for branch in [Vector3(0, 1.95, 0), Vector3(-0.5, 1.63, 0.11), Vector3(0.53, 1.74, -0.12)]:
		var leaves := SphereMesh.new()
		leaves.radius = 0.76 * factor
		leaves.height = 1.52 * factor
		leaves.radial_segments = 8
		leaves.rings = 4
		mesh_at(self, point + branch * factor, leaves, green)
