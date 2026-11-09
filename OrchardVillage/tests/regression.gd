extends SceneTree

var failures := 0

func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for index in count:
		await physics_frame

func wheel(button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)

func run() -> void:
	var scene := load("res://scenes/village.tscn") as PackedScene
	if scene == null:
		check(false, "Village scene exists")
		quit(1)
		return
	var village := scene.instantiate()
	root.add_child(village)
	await frames(8)
	var player := village.get_node("Player") as CharacterBody3D
	var orbit := village.get_node("Orbit") as Node3D
	var camera := orbit.get_node("Pitch/Camera3D") as Camera3D
	check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Orthographic")
	check(is_equal_approx(orbit.get_node("Pitch").rotation_degrees.x, -40.0), "40 degree pitch")
	check(village.get_node("Buildings").get_child_count() == 6, "Six houses")
	check(player.is_on_floor(), "Character rests on terrain")
	var start := player.position
	Input.action_press("move_forward")
	await frames(22)
	Input.action_release("move_forward")
	var forward := -camera.global_basis.z
	forward.y = 0.0
	check((player.position - start).normalized().dot(forward.normalized()) > 0.98, "W follows camera heading")
	check(orbit.position.distance_to(player.position + Vector3.UP * 0.7) < 0.29, "Camera tracks moving character")
	await frames(18)
	check(orbit.position.distance_to(player.position + Vector3.UP * 0.7) < 0.02, "Camera settles on stationary character")
	var initial_yaw := orbit.rotation.y
	var house_transform: Transform3D = village.get_node("Buildings").transform
	Input.action_press("orbit_right")
	await frames(2)
	Input.action_release("orbit_right")
	await frames(8)
	var partial := orbit.rotation.y - initial_yaw
	check(partial < -0.01 and partial > -PI / 2, "E rotation is gradual")
	await frames(17)
	check(is_equal_approx(orbit.rotation.y, initial_yaw - PI / 2), "90 degree turn completes within 0.43 seconds")
	await frames(25)
	check(is_equal_approx(orbit.rotation.y, initial_yaw - PI / 2), "E rotates 90 degrees")
	check(village.get_node("Buildings").transform == house_transform, "Village does not rotate")
	start = player.position
	Input.action_press("move_right")
	await frames(18)
	Input.action_release("move_right")
	check((player.position - start).normalized().dot(camera.global_basis.x) > 0.98, "D follows rotated camera")
	Input.action_press("orbit_left")
	await frames(2)
	Input.action_release("orbit_left")
	await frames(45)
	check(is_equal_approx(orbit.rotation.y, initial_yaw), "Q reverses E")
	for index in 22:
		wheel(MOUSE_BUTTON_WHEEL_UP)
	await frames(65)
	check(absf(camera.size - 9.0) < 0.02, "Zoom in clamps to 9")
	for index in 28:
		wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await frames(65)
	check(absf(camera.size - 27.0) < 0.02, "Zoom out clamps to 27")
	player.position = Vector3(4.5, 0.04, -2.5)
	await frames(8)
	var into_house := Vector3(0, 0, -1)
	var axes := Vector2(into_house.dot(camera.global_basis.x), into_house.dot(camera.global_basis.z.normalized()))
	Input.action_press("move_right", maxf(0.0, axes.x))
	Input.action_press("move_left", maxf(0.0, -axes.x))
	Input.action_press("move_back", maxf(0.0, axes.y))
	Input.action_press("move_forward", maxf(0.0, -axes.y))
	await frames(70)
	for action in ["move_right", "move_left", "move_back", "move_forward"]:
		Input.action_release(action)
	check(player.position.z < -2.8 and player.position.z > -4.1, "House stops character")
	print("RESULT failures=", failures)
	quit(1 if failures else 0)
