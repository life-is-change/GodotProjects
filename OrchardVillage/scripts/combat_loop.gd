extends Node3D

const NAVIGATION := preload("res://scripts/combat_navigation.gd")
const SLIME := preload("res://scripts/slime.gd")
const ATTACK_DAMAGE := 10
const ATTACK_REACH := 1.9
const ATTACK_COOLDOWN := 0.42
const SWING_HALF_ANGLE := PI / 3.0
const REWARD := 25
const SPAWNS := [Vector3(-8, 0.04, 0), Vector3(9, 0.04, 1), Vector3(1.7, 0.04, 10)]

@onready var player: CharacterBody3D = $"../Player"
@onready var shop = $"../ShopLoop"
@onready var spawn_point := player.position
var navigation := NAVIGATION.new()
var enemies := Node3D.new()
var slash := MeshInstance3D.new()
var death_panel := PanelContainer.new()
var restart_button := Button.new()
var swing_time := 0.0
var hurt_time := 0.0
var cooldown := 0.0
var pending_attack := false
var initialized := false
var hurt_paint := StandardMaterial3D.new()

func _ready() -> void:
	enemies.name = "Slimes"
	add_child(enemies)
	hurt_paint.albedo_color = Color("#ff775f")
	hurt_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	build_slash()
	build_death_panel()
	if not is_alive():
		show_death()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and is_alive() and not player.movement_locked:
		pending_attack = true
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not initialized:
		navigation.bake(get_world_3d(), player)
		spawn_slimes()
		initialized = true
	cooldown = maxf(0, cooldown - delta)
	swing_time = maxf(0, swing_time - delta)
	slash.visible = swing_time > 0 and is_alive()
	if hurt_time > 0:
		hurt_time = maxf(0, hurt_time - delta)
		if hurt_time <= 0:
			tint_player(false)
	if pending_attack:
		pending_attack = false
		try_attack()

func is_alive() -> bool:
	return shop.state.health > 0

func try_attack() -> void:
	if cooldown > 0 or not is_alive() or player.movement_locked:
		return
	cooldown = ATTACK_COOLDOWN
	swing_time = 0.15
	var facing: Vector3 = player.facing
	if facing.is_zero_approx():
		facing = -get_viewport().get_camera_3d().global_basis.z
		facing.y = 0
		facing = facing.normalized()
	slash.rotation.y = atan2(-facing.x, -facing.z)
	slash.show()
	for slime in enemies.get_children():
		var offset: Vector3 = slime.global_position - player.global_position
		offset.y = 0
		if offset.length() > ATTACK_REACH or facing.dot(offset.normalized()) < cos(SWING_HALF_ANGLE):
			continue
		if navigation.clear_line(get_world_3d(), player.global_position, slime.global_position, player):
			slime.take_damage(ATTACK_DAMAGE)

func take_hit(amount: int) -> void:
	if not is_alive():
		return
	shop.state.take_damage(amount)
	shop.refresh_status()
	hurt_time = 0.22
	tint_player(true)
	if not is_alive():
		show_death()

func tint_player(active: bool) -> void:
	for part in player.get_node("Figure").get_children():
		if part is MeshInstance3D:
			part.material_overlay = hurt_paint if active else null

func show_death() -> void:
	shop.close_menu()
	player.movement_locked = true
	death_panel.show()

func restart() -> void:
	shop.state.restore_health()
	shop.refresh_status()
	player.position = spawn_point
	player.velocity = Vector3.ZERO
	player.facing = Vector3.ZERO
	player.movement_locked = false
	pending_attack = false
	cooldown = 0
	swing_time = 0
	hurt_time = 0
	tint_player(false)
	death_panel.hide()
	for slime in enemies.get_children():
		enemies.remove_child(slime)
		slime.queue_free()
	spawn_slimes()

func spawn_slimes() -> void:
	for point in SPAWNS:
		var slime := SLIME.new()
		slime.combat = self
		slime.home = point
		slime.position = point
		slime.defeated.connect(reward_player)
		enemies.add_child(slime)

func reward_player() -> void:
	shop.state.add_coins(REWARD)
	shop.refresh_status()

func build_slash() -> void:
	var arc := ImmediateMesh.new()
	var light := StandardMaterial3D.new()
	light.albedo_color = Color(1, 0.82, 0.24, 0.74)
	light.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	light.cull_mode = BaseMaterial3D.CULL_DISABLED
	light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, light)
	for step in 15:
		var angle := lerpf(-SWING_HALF_ANGLE, SWING_HALF_ANGLE, step / 14.0)
		var ray := Vector3(sin(angle), 0, -cos(angle))
		arc.surface_add_vertex(ray * 0.9)
		arc.surface_add_vertex(ray * ATTACK_REACH)
	arc.surface_end()
	slash.mesh = arc
	slash.position.y = 0.35
	slash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player.add_child.call_deferred(slash)
	slash.hide()

func build_death_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme := Theme.new()
	theme.default_font = preload("res://assets/fonts/NotoSansSC-VF.ttf")
	theme.default_font_size = 20
	death_panel.theme = theme
	death_panel.custom_minimum_size = Vector2(370, 160)
	center.add_child(death_panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 12)
	death_panel.add_child(stack)
	var title := Label.new()
	title.text = "你倒下了"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	restart_button.text = "重新开始"
	restart_button.pressed.connect(restart)
	stack.add_child(restart_button)
	death_panel.hide()
