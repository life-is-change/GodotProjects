extends Node3D

func _ready() -> void:
	var coat := CapsuleMesh.new()
	coat.radius = 0.29
	coat.height = 0.94
	figure_part(coat, 0.50, Color("#723a84"))
	var head := SphereMesh.new()
	head.radius = 0.22
	head.height = 0.44
	figure_part(head, 1.01, Color("#e4ad79"))
	var hat := CylinderMesh.new()
	hat.top_radius = 0.18
	hat.bottom_radius = 0.35
	hat.height = 0.22
	figure_part(hat, 1.20, Color("#46304d"))
	var tag := Label3D.new()
	tag.text = "MERCHANT"
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("#ffe1a4")
	tag.pixel_size = 0.004
	tag.position.y = 1.64
	add_child(tag)

func figure_part(mesh: PrimitiveMesh, height: float, color: Color) -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.material_override = paint
	model.position.y = height
	add_child(model)
