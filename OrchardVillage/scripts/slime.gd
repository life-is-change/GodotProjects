extends CharacterBody3D

signal defeated

const MAX_HEALTH := 30
const DAMAGE := 12
const ATTACK_INTERVAL := 1.1
const REACH := 1.0
const AGGRO := 6.5
const CHASE_SPEED := 2.65
const PATROL_SPEED := 1.05

var health := MAX_HEALTH
var home: Vector3
var combat: Node3D
var cooldown := 0.0
var patrol_clock := 0.0
var repath := 0.0
var path: Array[Vector2i] = []
var figure: MeshInstance3D
var label: Label3D
var paint := StandardMaterial3D.new()
var flash := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = 0.15
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.37
	capsule.height = 0.78
	collision.shape = capsule
	collision.position.y = 0.39
	add_child(collision)

	figure = MeshInstance3D.new()
	var body := SphereMesh.new()
	body.radius = 0.49
	body.height = 0.72
	figure.mesh = body
	figure.position.y = 0.35
	figure.material_override = paint
	add_child(figure)
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = 0.065
		dot.height = 0.13
		eye.mesh = dot
		var ink := StandardMaterial3D.new()
		ink.albedo_color = Color("#253942")
		eye.material_override = ink
		eye.position = Vector3(side * 0.145, 0.12, -0.43)
		figure.add_child(eye)
	label = Label3D.new()
	label.text = "30 / 30"
	label.font_size = 28
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.02
	add_child(label)

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	cooldown = maxf(0, cooldown - delta)
	flash = maxf(0, flash - delta)
	patrol_clock += delta
	paint.albedo_color = Color("#fff2b4") if flash > 0 else Color("#63c697")
	figure.scale.y = 1.0 + sin(patrol_clock * 8.0) * 0.14
	var offset: Vector3 = combat.player.global_position - global_position
	offset.y = 0
	var direction := Vector3.ZERO
	var speed := PATROL_SPEED
	if combat.is_alive() and offset.length() <= AGGRO:
		speed = CHASE_SPEED
		direction = chase(offset, delta)
	else:
		path.clear()
		repath = 0.0
		var patrol := home + Vector3(sin(patrol_clock * 0.85), 0, cos(patrol_clock * 0.85)) * 1.05
		direction = planar_direction(patrol)
	if direction.length_squared() > 0.01:
		figure.rotation.y = atan2(-direction.x, -direction.z)
	velocity = Vector3(direction.x * speed, velocity.y - 18.0 * delta, direction.z * speed)
	move_and_slide()

func chase(offset: Vector3, delta: float) -> Vector3:
	var target: Vector3 = combat.player.global_position
	var clear: bool = combat.navigation.clear_line(get_world_3d(), global_position, target, combat.player)
	if clear and offset.length() <= REACH:
		if cooldown <= 0:
			cooldown = ATTACK_INTERVAL
			flash = 0.13
			combat.take_hit(DAMAGE)
		return Vector3.ZERO
	# A center ray can graze a corner. Sweep the actual body before taking the direct route.
	if clear and not test_move(global_transform, offset.normalized() * 0.48):
		repath = 0.0
		return offset.normalized()
	repath -= delta
	if repath <= 0:
		repath = 0.35
		path = combat.navigation.route(global_position, target)
	while not path.is_empty():
		var cell := path.front() as Vector2i
		var waypoint := Vector3(cell.x, global_position.y, cell.y)
		if global_position.distance_to(waypoint) > 0.23:
			return planar_direction(waypoint)
		path.pop_front()
	return Vector3.ZERO

func planar_direction(target: Vector3) -> Vector3:
	var offset := target - global_position
	offset.y = 0
	return offset.normalized()

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	label.text = "%d / %d" % [health, MAX_HEALTH]
	flash = 0.16
	if health == 0:
		defeated.emit()
		queue_free()
