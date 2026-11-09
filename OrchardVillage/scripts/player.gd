extends CharacterBody3D

const SPEED := 4.8
var stride := 0.0
var movement_locked := false

func _physics_process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var axes := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if movement_locked:
		axes = Vector2.ZERO
	var right := camera.global_basis.x
	var back := camera.global_basis.z
	back.y = 0.0
	var direction := right * axes.x + back.normalized() * axes.y
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	velocity.y -= 18.0 * delta
	move_and_slide()

	if get_real_velocity().slide(Vector3.UP).length_squared() > 0.1:
		stride += delta * 15.0
		$Figure.rotation.y = atan2(-direction.x, -direction.z)
		$Figure/LeftBoot.position.z = sin(stride) * 0.11
		$Figure/RightBoot.position.z = -sin(stride) * 0.11
	else:
		$Figure/LeftBoot.position.z = -0.03
		$Figure/RightBoot.position.z = -0.03
