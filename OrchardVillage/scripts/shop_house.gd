extends Node3D

const MERCHANT := preload("res://scripts/merchant.gd")
var door_marker: Marker3D
var renovation_marker: Label3D
var merchant: Node3D

func _ready() -> void:
	door_marker = Marker3D.new()
	door_marker.position = Vector3(0, 0, 2.85)
	add_child(door_marker)
	renovation_marker = Label3D.new()
	renovation_marker.text = "RENOVATION"
	renovation_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	renovation_marker.modulate = Color("#ffe1a4")
	renovation_marker.pixel_size = 0.005
	renovation_marker.position = Vector3(0, 2.65, 2.02)
	add_child(renovation_marker)

func open_shop() -> void:
	if is_instance_valid(merchant):
		return
	renovation_marker.hide()
	var decor := Node3D.new()
	decor.name = "ShopDecor"
	add_child(decor)
	block(decor, Vector3(0, 1.86, 1.93), Vector3(2.85, 0.12, 0.72), Color("#247c6b"))
	for stripe in 4:
		block(decor, Vector3(-1.06 + stripe * 0.7, 1.93, 1.94),
			Vector3(0.31, 0.03, 0.72), Color("#fff0b4"))
	block(decor, Vector3(0, 2.18, 1.78), Vector3(1.55, 0.36, 0.13), Color("#244742"))
	var sign := Label3D.new()
	sign.text = "APOTHECARY"
	sign.font_size = 42
	sign.pixel_size = 0.0044
	sign.outline_size = 0
	sign.modulate = Color("#ffebaa")
	sign.position = Vector3(0, 2.18, 1.86)
	decor.add_child(sign)

	merchant = MERCHANT.new()
	merchant.name = "Merchant"
	merchant.position = Vector3(-1.22, 0.025, 3.03)
	add_child(merchant)

func block(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	var model := MeshInstance3D.new()
	model.mesh = mesh
	model.material_override = paint
	model.position = at
	parent.add_child(model)
