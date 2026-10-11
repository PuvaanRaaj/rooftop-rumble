extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game: RumbleGame = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_match([
		{"name":"Blue","color":Color("69b9f3"),"kind":"keyboard","slot":0,"device":-1},
		{"name":"Red","color":Color("f18b8f"),"kind":"keyboard","slot":1,"device":-1},
		{"name":"Yellow","color":Color("f5d46e"),"kind":"keyboard","slot":2,"device":-1},
		{"name":"Green","color":Color("89d1ac"),"kind":"keyboard","slot":3,"device":-1}])
	game.countdown = 1000
	for i in range(50): await physics_frame
	game.ui.show_countdown("")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/arena-preview.png")
	print("Rendered arena preview saved")
	game.queue_free()
	await process_frame
	quit()
