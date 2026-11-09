extends CanvasLayer

const PLAYER_STATE := preload("res://scripts/player_state.gd")
const RANGE := 1.65

@export var save_path := "user://orchard_progress.json"
@onready var player = $"../Player"
var state: PLAYER_STATE
var shop_house: Node3D
var panel: PanelContainer
var primary: Button
var prompt: Button
var status: Button
var title: Label
var description: Label
var feedback: Label
var mode := ""

func _ready() -> void:
	state = PLAYER_STATE.new(save_path)
	build_ui()
	refresh_status()

func register_house(house: Node3D) -> void:
	shop_house = house
	if state.shops.has(str(shop_house.get_meta("building_id"))):
		shop_house.open_shop()

func _process(_delta: float) -> void:
	var target := nearby_target()
	prompt.visible = state.health > 0 and not panel.visible and not target.is_empty()
	if prompt.visible:
		prompt.text = "按 F 交互 · 改造房屋" if target == "house" else "按 F 交互 · 商人"

func interact_nearby() -> void:
	var target := nearby_target()
	if not panel.visible and not target.is_empty():
		show_menu(target)

func toggle_inventory() -> void:
	if mode == "inventory":
		close_menu()
	elif not panel.visible:
		show_menu("inventory")

func nearby_target() -> String:
	if shop_house == null:
		return ""
	var marker: Node3D = shop_house.merchant if shop_house.merchant != null else shop_house.door_marker
	var offset: Vector3 = marker.global_position - player.global_position
	if Vector2(offset.x, offset.z).length() > RANGE:
		return ""
	return "merchant" if shop_house.merchant != null else "house"

func _input(event: InputEvent) -> void:
	if state.health == 0:
		return
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif panel.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		close_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		interact_nearby()
		if panel.visible:
			get_viewport().set_input_as_handled()

func show_menu(next_mode: String) -> void:
	if state.health == 0:
		return
	mode = next_mode
	feedback.text = "存档无法读取，本次不会覆盖它。" if state.load_error else ""
	match mode:
		"house":
			title.text = "建筑改造"
			description.text = "把这栋房屋改成药水商店。改造后商人会来到门口。"
			primary.text = "改造成商店 · 100 金币"
		"merchant":
			title.text = "药水商人"
			description.text = "欢迎！生命药水可在背包中使用，恢复 30 点生命。"
			primary.text = "购买生命药水 · 20 金币"
		"inventory":
			title.text = "背包"
			primary.text = "使用一瓶生命药水"
	refresh_status()
	player.movement_locked = true
	panel.show()
	prompt.hide()

func close_menu() -> void:
	panel.hide()
	mode = ""
	player.movement_locked = false

func transact() -> void:
	match mode:
		"house":
			if state.renovate(str(shop_house.get_meta("building_id"))):
				shop_house.open_shop()
				close_menu()
			else:
				feedback.text = "金币不足。" if state.coins < PLAYER_STATE.RENOVATION_PRICE else "无法写入存档。"
		"merchant":
			if state.buy_potion():
				feedback.text = "已购买一瓶生命药水。"
			else:
				feedback.text = "金币不足。" if state.coins < PLAYER_STATE.POTION_PRICE else "无法写入存档。"
		"inventory":
			if state.use_potion():
				feedback.text = "已恢复生命。"
			elif state.potions == 0:
				feedback.text = "背包里没有生命药水。"
			elif state.health >= PLAYER_STATE.MAX_HEALTH:
				feedback.text = "生命已满。"
			else:
				feedback.text = "无法写入存档。"
	refresh_status()

func refresh_status() -> void:
	status.text = "金币 %d   生命 %d / %d   药水 ×%d   [B] 背包" % [
		state.coins, state.health, PLAYER_STATE.MAX_HEALTH, state.potions]
	if mode == "inventory":
		description.text = "生命药水 ×%d。使用后恢复 30 点生命。" % state.potions

func build_ui() -> void:
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var theme := Theme.new()
	theme.default_font = preload("res://assets/fonts/NotoSansSC-VF.ttf")
	theme.default_font_size = 18
	canvas.theme = theme

	status = Button.new()
	status.focus_mode = Control.FOCUS_NONE
	status.pressed.connect(toggle_inventory)
	canvas.add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.offset_left = -375
	status.offset_right = -24
	status.offset_top = 24
	status.offset_bottom = 61

	prompt = Button.new()
	prompt.focus_mode = Control.FOCUS_NONE
	prompt.pressed.connect(interact_nearby)
	prompt.add_theme_color_override("font_color", Color("#fff3be"))
	prompt.hide()
	canvas.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -135
	prompt.offset_right = 135
	prompt.offset_top = -76
	prompt.offset_bottom = -32

	var overlay := CenterContainer.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.custom_minimum_size.x = 420
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#203b33")
	background.border_color = Color("#d3bc78")
	background.set_border_width_all(1)
	background.set_corner_radius_all(12)
	background.content_margin_left = 24
	background.content_margin_right = 24
	background.content_margin_top = 19
	background.content_margin_bottom = 19
	panel.add_theme_stylebox_override("panel", background)
	overlay.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	panel.add_child(rows)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 25)
	rows.add_child(title)
	description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(description)
	primary = Button.new()
	primary.custom_minimum_size.y = 40
	primary.pressed.connect(transact)
	rows.add_child(primary)
	feedback = Label.new()
	feedback.add_theme_color_override("font_color", Color("#ffd991"))
	rows.add_child(feedback)
	var close := Button.new()
	close.text = "关闭 · Esc"
	close.pressed.connect(close_menu)
	rows.add_child(close)
	panel.hide()
