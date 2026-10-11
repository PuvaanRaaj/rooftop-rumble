extends SceneTree
var game: RumbleGame
var checks := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		assert(condition, message)
func wait_frames(count: int) -> void:
	for i in range(count): await physics_frame
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var configs := [
		{"name":"Blue","color":Color.CORNFLOWER_BLUE,"kind":"keyboard","slot":0,"device":-1},
		{"name":"Red","color":Color.SALMON,"kind":"keyboard","slot":1,"device":-1}]
	game.start_match(configs)
	await wait_frames(220)
	check(game.state == RumbleGame.State.PLAYING,"Countdown enters playable round")
	var a := game.players[0]
	var b := game.players[1]
	check(a.is_on_floor() and b.is_on_floor(),"Fighters settle on rooftop")
	var old_a := a.position
	var old_b := b.position
	a.input_override = {"move":Vector2(1,0)}
	b.input_override = {"move":Vector2(-1,0)}
	await wait_frames(15)
	check(a.position.x > old_a.x and b.position.x < old_b.x,"Two independent simultaneous moves")
	a.input_override = {"move":Vector2.ZERO}
	b.input_override = {"move":Vector2.ZERO}
	a.position = Vector3(0,0,0)
	b.position = Vector3(0,0,-1.2)
	a.facing = Vector3.FORWARD
	a.velocity = Vector3.ZERO
	b.velocity = Vector3.ZERO
	a.attack(false)
	check(b.stun > 0 and b.knockback.z < 0,"Punch knocks back and stuns")
	var before := b.knockback
	a.attack(false)
	check(b.knockback == before,"Punch cooldown rejects immediate repeat")
	b.position = Vector3(0,0,-1.2)
	a.attack(true)
	check(b.knockback.length() > before.length(),"Shove gives stronger knockback")
	b.knockback = Vector3.ZERO
	b.velocity = Vector3.ZERO
	a.stun = 0
	b.position = Vector3(0,0,-1)
	a.grab_cooldown = 0
	a.toggle_grab()
	check(a.grabbed_target == b and b.grabbed_by == a,"Grab attaches opponent")
	b.receive_hit(Vector3.RIGHT*5,0.2)
	check(a.grabbed_target == null and b.grabbed_by == null,"Impact interrupts grab")
	b.position = Vector3(0,0,-1)
	a.grab_cooldown = 0
	a.toggle_grab()
	b.grab_time = 3
	await wait_frames(2)
	check(b.grabbed_by == null,"Grab expires with escape")
	b.position = Vector3(4,0,4)
	a.position = Vector3.ZERO
	a.facing = Vector3.FORWARD
	a.grab_cooldown = 0
	var prop: RumbleProp = get_nodes_in_group("props")[0]
	prop.position = Vector3(0,0.8,-1)
	a.toggle_grab()
	check(a.held_prop == prop and prop.freeze,"Prop pickup freezes body")
	a.release_hold(true)
	check(not prop.freeze and prop.linear_velocity.length() > 10,"Throw restores physical velocity")
	prop.dangerous_time = 1
	prop.linear_velocity = Vector3(12,0,0)
	prop._hit(b)
	check(b.knockback.x > 0,"Thrown prop applies damage impulse")
	for hazard in range(3):
		game.events.stop()
		game.events._event = hazard
		if hazard == 2: game.events._target = game.arena.collapsible[0]
		game.events._activate()
		if hazard == 0: check(game.events.wind.length() > 0,"Wind activates")
		if hazard == 1: check(game.events.slippery,"Slippery activates")
		if hazard == 2: check(game.arena.collapsible[0].collision_layer == 0,"Collapse removes collision")
		game.events.stop()
		check(game.events.wind == Vector3.ZERO and not game.events.slippery and game.arena.collapsible[0].collision_layer == 1,"Hazard reset restores arena")
	a.position = Vector3(20,-9,0)
	b.position = Vector3(-20,-9,0)
	await wait_frames(50)
	check(game.state == RumbleGame.State.RESULTS and game.rounds.wins == [0,0],"Simultaneous elimination yields draw")
	for round_index in range(3):
		game.next_round()
		await wait_frames(220)
		check(game.players[0].alive and game.players[1].alive,"Restart restores players")
		game.players[1].position = Vector3(20,-9,0)
		await wait_frames(50)
	check(game.state == RumbleGame.State.WINNER,"Complete first-to-three match reaches winner")
	game.next_round()
	check(game.rounds.wins == [0,0] and game.state == RumbleGame.State.COUNTDOWN,"Play again resets score")
	game.return_menu()
	check(game.state == RumbleGame.State.MENU and game.players.is_empty(),"Return to menu clears fighters")
	print("PASS: ",checks," integrated gameplay checks")
	game.queue_free()
	await process_frame
	quit()
