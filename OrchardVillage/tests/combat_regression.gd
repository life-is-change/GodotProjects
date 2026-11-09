extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func frames(count: int) -> void:
	for frame in count:
		await physics_frame

func attack() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.keycode = KEY_SPACE
	Input.parse_input_event(event)

func run() -> void:
	create_timer(20).timeout.connect(func(): quit(1))
	var village := (load("res://scenes/village.tscn") as PackedScene).instantiate()
	var combat := village.get_node_or_null("Combat")
	check(combat != null and combat.has_method("try_attack"), "Main scene integrates combat")
	if combat == null or not combat.has_method("try_attack"):
		village.free()
		quit(1)
		return
	var shop := village.get_node("ShopLoop")
	shop.save_path = "user://combat-test-%d.json" % OS.get_process_id()
	root.add_child(village)
	await frames(5)
	var player: CharacterBody3D = village.get_node("Player")
	check(shop.state.health == 100 and combat.enemies.get_child_count() == 3, "Full health and three slimes")
	var slime: CharacterBody3D = combat.enemies.get_child(0)
	var start := slime.global_position
	await frames(24)
	check(slime.global_position.distance_to(start) > 0.15, "Slime patrols")
	player.position = slime.position + Vector3(3, 0, 0)
	start = slime.position
	await frames(30)
	check(slime.position.x > start.x + 0.35, "Slime chases nearby player")
	await frames(75)
	var hp: int = shop.state.health
	check(hp < 100 and hp > 0, "Slime contact attacks")
	await frames(8)
	check(shop.state.health == hp, "Enemy attack has a cooldown")
	check(shop.state.buy_potion(), "Potion purchased using shop state")
	shop.show_menu("inventory")
	await attack()
	check(not combat.slash.visible, "Inventory blocks melee")
	shop.primary.pressed.emit()
	check(shop.state.potions == 0 and shop.state.health == mini(100, hp + 30), "Potion works during combat")
	shop.close_menu()

	player.position = Vector3(0, 0.03, 0)
	slime.position = Vector3(0, 0.03, -3.2)
	player.facing = Vector3.FORWARD
	await attack()
	check(slime.health == 30 and combat.slash.visible, "Swing is visible and out of range misses")
	await frames(28)
	slime.position = Vector3(0, 0.03, 1.2)
	await attack()
	check(slime.health == 30, "Enemy behind player is missed")
	await frames(28)
	slime.position = Vector3(0, 0.03, -1.3)
	await attack()
	check(slime.health == 20, "Forward swing deals 10 damage")
	await attack()
	check(slime.health == 20, "Attack cooldown prevents spam")
	for hit in 2:
		await frames(28)
		slime.position = Vector3(0, 0.03, -1.3)
		await attack()
	await process_frame
	check(combat.enemies.get_child_count() == 2 and shop.state.coins == 155, "Third hit kills and grants 25 coins")
	check(shop.state.buy_potion() and shop.state.coins == 135, "Combat reward spends in shop")

	slime = combat.enemies.get_child(0)
	player.position = Vector3(4.5, 0.03, -3.2)
	slime.position = Vector3(4.5, 0.03, -8.2)
	var entered_house := false
	for frame in 270:
		await physics_frame
		if absf(slime.position.x - 4.5) < 1.7 and absf(slime.position.z + 5.8) < 1.7:
			entered_house = true
	check(not entered_house and slime.position.z > -4.1, "Slime detours around collidable house")
	combat.take_hit(100)
	check(shop.state.health == 0 and combat.death_panel.visible and player.movement_locked, "Death overlay locks player")
	shop.toggle_inventory()
	check(not shop.panel.visible, "Dead player cannot reopen inventory")
	combat.restart_button.pressed.emit()
	await process_frame
	check(shop.state.health == 100 and not player.movement_locked and not combat.death_panel.visible, "Restart restores health and control")
	check(combat.enemies.get_child_count() == 3 and shop.state.coins == 135 and shop.state.potions == 1, "Restart respawns slimes and preserves progress")
	DirAccess.remove_absolute(shop.save_path)
	print("RESULT failures=", failures)
	quit(1 if failures else 0)
