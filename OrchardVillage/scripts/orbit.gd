extends Node3D

const TURN_SECONDS := 0.34
const ZOOM_MIN := 9.0
const ZOOM_MAX := 27.0

@onready var player: Node3D = $"../Player"
@onready var camera: Camera3D = $Pitch/Camera3D
@onready var target_yaw := rotation.y
@onready var target_size := camera.size
var turn: Tween

func _ready() -> void:
	position = player.position + Vector3.UP * 0.7

func _process(delta: float) -> void:
	position = position.lerp(player.position + Vector3.UP * 0.7, 1.0 - exp(-22.0 * delta))
	camera.size = lerpf(camera.size, target_size, 1.0 - exp(-15.0 * delta))
	var step := int(Input.is_action_just_pressed("orbit_left")) - int(Input.is_action_just_pressed("orbit_right"))
	if step != 0:
		target_yaw += step * PI / 2.0
		if turn:
			turn.kill()
		turn = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		turn.tween_property(self, "rotation:y", target_yaw, TURN_SECONDS)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				target_size = maxf(ZOOM_MIN, target_size - 1.5)
			MOUSE_BUTTON_WHEEL_DOWN:
				target_size = minf(ZOOM_MAX, target_size + 1.5)
