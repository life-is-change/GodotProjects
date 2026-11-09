extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.add_child(load("res://scenes/village.tscn").instantiate())
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var output := "res://logs/desktop.png"
	var result := frame.save_png(output)
	print("Captured rendered viewport ", frame.get_size(), " -> ", output, ", error=", result)
	quit(0 if result == OK else 1)
