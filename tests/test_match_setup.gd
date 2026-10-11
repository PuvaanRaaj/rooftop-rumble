extends SceneTree
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		quit(1)
		assert(value, message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game := RumbleGame.new()
	root.add_child(game)
	game.set_physics_process(false)
	var crew := [{"name":"Human", "kind":"touch", "color":Color.CORNFLOWER_BLUE}, {"name":"CPU", "kind":"cpu", "color":Color.SALMON}]
	var catalog := RooftopArena.map_catalog()
	for entry in catalog:
		game.start_match(crew, {"map_id":entry.id, "difficulty":"hard"})
		check(game.arena.map_id == entry.id, "Match loads selected map")
		check(game.players[1].config.difficulty == "hard", "CPU receives selected difficulty")
		check(game.camera.map_min_span == game.arena.camera_min_span, "Camera fits selected arena")
		check(game.touch_controls.player == game.players[0], "Each map retains touch ownership")
		game.state = RumbleGame.State.WINNER
		game.next_round()
		check(game.arena.map_id == entry.id and game.match_options.difficulty == "hard", "Replay retains map and difficulty")
		game.return_menu()
		await process_frame
	game.start_match(crew)
	check(game.arena.map_id == "skyline" and game.players[1].config.difficulty == "medium", "Existing callers keep default setup")
	game._audio_settings(false, false)
	game._audio_settings(true, true)
	game.queue_free()
	await process_frame
	print("PASS: ", checks, " match setup checks")
	quit()
