extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		failures += 1

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	create_timer(8).timeout.connect(func():
		printerr("FAIL Shop test timed out")
		quit(1)
	)
	var packed := load("res://scenes/village.tscn") as PackedScene
	if packed == null:
		check(false, "Village scene loads")
		quit(1)
		return
	var village := packed.instantiate()
	var shop := village.get_node_or_null("ShopLoop")
	check(shop != null, "Village integrates shop loop")
	if shop == null:
		village.free()
		quit(1)
		return

	var save_path := "user://shop-regression-%s.json" % OS.get_process_id()
	shop.save_path = save_path
	root.add_child(village)
	await process_frame
	var player: CharacterBody3D = village.get_node("Player")
	var buildings: Node = village.get_node("Buildings")
	var ids := {}
	for building in buildings.get_children():
		ids[building.get_meta("building_id", "")] = true
	check(ids.size() == 6 and not ids.has(""), "All six buildings have unique IDs")
	check(shop.state.coins == 150 and shop.state.health == 60, "New player defaults")
	check(shop.shop_house.get_node_or_null("Merchant") == null, "Merchant absent before renovation")
	await key(KEY_F)
	check(not shop.panel.visible, "F from plaza does not open interaction")
	player.position = shop.shop_house.door_marker.global_position
	await process_frame
	await key(KEY_F)
	check(shop.panel.visible and shop.primary.text.contains("100"), "F at house opens renovation")
	var start := player.position
	Input.action_press("move_forward")
	for i in 12:
		await physics_frame
	Input.action_release("move_forward")
	check(player.position.distance_to(start) < 0.02, "Menu blocks walking")
	await key(KEY_ESCAPE)
	check(not shop.panel.visible, "Escape closes menu")
	await key(KEY_F)
	shop.primary.pressed.emit()
	check(shop.state.coins == 50 and shop.shop_house.get_node_or_null("ShopDecor") != null, "Renovation charges 100 and changes appearance")
	check(shop.shop_house.get_node_or_null("Merchant") != null, "Renovation spawns merchant")
	player.position = shop.shop_house.merchant.global_position
	await process_frame
	await key(KEY_F)
	check(shop.panel.visible and shop.primary.text.contains("20"), "F near merchant opens shop")
	shop.primary.pressed.emit()
	check(shop.state.coins == 30 and shop.state.potions == 1, "Purchase debits coins and adds potion")
	shop.primary.pressed.emit()
	shop.primary.pressed.emit()
	check(shop.state.coins == 10 and shop.state.potions == 2, "Insufficient funds reject another purchase")
	village.queue_free()
	await process_frame
	village = packed.instantiate()
	shop = village.get_node("ShopLoop")
	shop.save_path = save_path
	root.add_child(village)
	await process_frame
	check(shop.state.coins == 10 and shop.state.health == 60 and shop.state.potions == 2, "Non-empty inventory restored")
	await key(KEY_B)
	check(shop.panel.visible, "B opens inventory")
	shop.primary.pressed.emit()
	check(shop.state.health == 90 and shop.state.potions == 1, "Use consumes potion and heals 30")
	shop.primary.pressed.emit()
	check(shop.state.health == 100 and shop.state.potions == 0, "Healing caps at 100")
	shop.primary.pressed.emit()
	check(shop.state.health == 100 and shop.state.potions == 0, "Empty bag cannot consume")
	village.queue_free()
	await process_frame
	village = packed.instantiate()
	shop = village.get_node("ShopLoop")
	shop.save_path = save_path
	root.add_child(village)
	await process_frame
	check(shop.state.coins == 10 and shop.state.health == 100 and shop.state.potions == 0, "Player data restored")
	check(shop.shop_house.get_node_or_null("ShopDecor") != null and shop.shop_house.get_node_or_null("Merchant") != null, "Shop and merchant restored")
	DirAccess.remove_absolute(save_path)
	print("RESULT failures=", failures)
	quit(1 if failures else 0)
