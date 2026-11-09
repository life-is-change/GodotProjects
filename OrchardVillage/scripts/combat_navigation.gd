extends RefCounted

const GRID := Rect2i(-18, -16, 37, 33)
var grid := AStarGrid2D.new()

func bake(world: World3D, player: CharacterBody3D) -> void:
	grid.region = GRID
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var shape := CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 0.45
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	for x in range(GRID.position.x, GRID.end.x):
		for z in range(GRID.position.y, GRID.end.y):
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.65, z))
			if not world.direct_space_state.intersect_shape(query, 1).is_empty():
				grid.set_point_solid(Vector2i(x, z))

func clear_line(world: World3D, from: Vector3, to: Vector3, player: CharacterBody3D) -> bool:
	var offset := Vector3.UP * 0.65
	var query := PhysicsRayQueryParameters3D.create(from + offset, to + offset, 1, [player.get_rid()])
	return world.direct_space_state.intersect_ray(query).is_empty()

func route(from: Vector3, to: Vector3) -> Array[Vector2i]:
	return grid.get_id_path(nearest_cell(from), nearest_cell(to))

func nearest_cell(point: Vector3) -> Vector2i:
	var center := Vector2i(roundi(point.x), roundi(point.z))
	var best := center
	var distance := INF
	for x in range(center.x - 1, center.x + 2):
		for z in range(center.y - 1, center.y + 2):
			var candidate := Vector2i(x, z)
			if not GRID.has_point(candidate) or grid.is_point_solid(candidate):
				continue
			var score := Vector2(x - point.x, z - point.z).length_squared()
			if score < distance:
				distance = score
				best = candidate
	return best
