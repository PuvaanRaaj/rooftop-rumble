extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	seed(8842)
	var game: RumbleGame = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var crew: Array = []
	for i in range(4):
		crew.append({"name":"CPU "+str(i+1),"color":Color.from_hsv(i/4.0,0.6,0.9),"kind":"cpu","slot":i,"device":-1})
	game.start_match(crew)
	var frames := 0
	while frames < 36000 and game.state != RumbleGame.State.WINNER:
		await physics_frame
		frames += 1
		if game.state == RumbleGame.State.RESULTS: game.next_round()
	if game.state != RumbleGame.State.WINNER:
		push_error("CPU match did not finish within 600 simulated seconds")
		quit(1)
		return
	print("PASS: four CPU fighters completed match in ",frames," physics frames; scores ",game.rounds.wins)
	game.queue_free()
	await process_frame
	quit()
