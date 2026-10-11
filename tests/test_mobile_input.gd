extends SceneTree
var checks := 0
var controls: RumbleTouchControls
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		assert(condition, message)
func _initialize() -> void:
	call_deferred("run")
func touch(index: int, position: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event, true)
func drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	root.push_input(event, true)
func run() -> void:
	controls = RumbleTouchControls.new()
	root.add_child(controls)
	controls.set_active(true)
	var origin := controls.joystick_center()
	touch(10, origin, true)
	drag(10, origin + Vector2(200, 0))
	touch(22, controls.control_center("jump"), true)
	touch(37, controls.control_center("grab"), true)
	var sample := RumbleInput.sample_touch()
	check(sample.move == Vector2.RIGHT and sample.jump and sample.grab, "Three independent touches move, jump and grab simultaneously")
	check(not RumbleInput.sample_touch().jump, "Holding jump produces only one press edge")
	touch(22, controls.control_center("jump"), false)
	check(RumbleInput.sample_touch().move == Vector2.RIGHT and RumbleInput.touch_held.grab, "Releasing one finger preserves other controls")
	touch(50, origin, false)
	check(RumbleInput.touch_move == Vector2.RIGHT, "Unowned touch release cannot release joystick")
	drag(10, origin + Vector2(2, 0))
	check(RumbleInput.touch_move == Vector2.ZERO, "Joystick deadzone prevents drift")
	drag(10, origin + Vector2(500, 500))
	check(is_equal_approx(RumbleInput.touch_move.length(), 1), "Joystick movement stays bounded")
	touch(10, origin, false, true)
	check(RumbleInput.touch_move == Vector2.ZERO and RumbleInput.touch_held.grab, "Canceled joystick clears only its own state")
	controls.set_active(false)
	check(not RumbleInput.touch_held.grab and RumbleInput.touch_move == Vector2.ZERO, "Closing controls clears all held state")
	controls.set_active(true)
	touch(8, controls.control_center("punch"), true)
	check(RumbleInput.sample_touch().punch, "Punch action has independent rising edge")
	controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not RumbleInput.touch_held.punch, "App focus loss clears touch state")
	var requested := [false]
	controls.menu_requested.connect(func(): requested[0] = true)
	touch(9, origin, true)
	drag(9, origin + Vector2.RIGHT * 58)
	touch(12, controls.control_center("menu"), true)
	check(requested[0] and RumbleInput.touch_move == Vector2.ZERO, "Menu emits its request and clears movement")
	touch(14, controls.control_center("grab"), true)
	RumbleInput.reset()
	check(not RumbleInput.touch_held.grab, "Global round reset clears touch actions")
	controls.reset_input()
	check(controls.control_rect("grab").size.x == 104, "Action targets are large enough for landscape touch")
	controls.reset_input()
	touch(60, controls.control_center("jump"), true)
	touch(60, controls.control_center("jump"), false)
	check(RumbleInput.sample_touch().jump, "A complete tap between physics samples is retained")
	check(not RumbleInput.sample_touch().jump, "A short tap produces exactly one pulse")
	touch(61, controls.control_center("grab"), true)
	check(RumbleInput.sample_touch().grab, "First held grab press produces a pulse")
	touch(61, controls.control_center("grab"), false)
	touch(62, controls.control_center("grab"), true)
	check(RumbleInput.sample_touch().grab, "Release and repress between samples produces a new pulse")
	check(not RumbleInput.sample_touch().grab, "Holding a repress does not autorepeat")
	touch(62, controls.control_center("grab"), false)
	for index in [63, 64]:
		touch(index, controls.control_center("punch"), true)
		touch(index, controls.control_center("punch"), false)
	check(RumbleInput.sample_touch().punch and RumbleInput.sample_touch().punch and not RumbleInput.sample_touch().punch, "Multiple fast taps queue separate pulses without autorepeat")
	touch(65, controls.control_center("jump"), true)
	touch(65, controls.control_center("jump"), false, true)
	check(not RumbleInput.sample_touch().jump, "Canceled owned touch discards its pending action")
	touch(66, controls.control_center("grab"), true)
	touch(66, controls.control_center("grab"), false)
	controls.reset_input()
	check(not RumbleInput.sample_touch().grab, "Reset clears even pending short taps")
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	var player := RumblePlayer.new()
	player.config = {"name": "Touch tester", "kind": "touch", "slot": 0, "device": -1}
	root.add_child(player)
	player.active = true
	controls.player = player
	for frame in range(8): await physics_frame
	check(player.is_on_floor(), "Touch player rests on an actual physics floor")
	var start_position := player.position
	touch(20, origin, true)
	drag(20, origin + Vector2.RIGHT * 58)
	touch(21, controls.control_center("jump"), true)
	for frame in range(12): await physics_frame
	check(player.position.x > start_position.x + 0.15 and player.position.y > start_position.y + 0.3, "Real touch player moves and jumps together under physics")
	touch(21, controls.control_center("jump"), false)
	touch(20, origin, false)
	for frame in range(70): await physics_frame
	check(player.is_on_floor() and absf(player.velocity.x) < 0.01, "Releasing joystick stops the fighter and jump lands")
	player.facing = Vector3.FORWARD
	var prop := RumbleProp.new()
	root.add_child(prop)
	prop.position = player.position + Vector3(0, 0.8, -1)
	prop.freeze = true
	touch(22, controls.control_center("grab"), true)
	for frame in range(2): await physics_frame
	check(player.held_prop == prop and prop.carrier == player, "Touch grab attaches a real prop to the fighter")
	touch(22, controls.control_center("grab"), false)
	for frame in range(2): await physics_frame
	touch(23, controls.control_center("grab"), true)
	for frame in range(2): await physics_frame
	check(player.throw_time >= 0 and prop.freeze, "Second touch starts animated windup before release")
	touch(23, controls.control_center("grab"), false)
	for frame in range(14): await physics_frame
	check(player.held_prop == null and not prop.freeze and prop.linear_velocity.z < -8, "Touch throw releases the real flying body")
	player.queue_free()
	prop.queue_free()
	floor_body.queue_free()
	controls.queue_free()
	await process_frame
	var game := RumbleGame.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_match([{"name": "Touch", "kind": "touch", "slot": 0, "device": -1, "color": Color.CORNFLOWER_BLUE}, {"name": "CPU", "kind": "cpu", "color": Color.SALMON}])
	check(not game.touch_controls.active and game.touch_controls.player != null, "Real countdown assigns touch fighter while withholding controls")
	game._physics_process(4)
	check(game.state == RumbleGame.State.PLAYING and game.touch_controls.active, "Real countdown enables controls only when play begins")
	controls = game.touch_controls
	origin = controls.joystick_center()
	touch(24, origin, true)
	drag(24, origin + Vector2.RIGHT * 58)
	touch(25, controls.control_center("menu"), true)
	check(game.state == RumbleGame.State.MENU and not controls.active and RumbleInput.touch_move == Vector2.ZERO, "Real menu clears held gameplay touches and returns to menu")
	game.start_match([{"name": "Touch", "kind": "touch", "slot": 0, "device": -1, "color": Color.CORNFLOWER_BLUE}, {"name": "CPU", "kind": "cpu", "color": Color.SALMON}])
	check(not controls.active and RumbleInput.touch_move == Vector2.ZERO and not RumbleInput.touch_held.grab, "Starting another round never carries old touches")
	game._physics_process(4)
	touch(26, controls.control_center("jump"), true)
	game.players[0].eliminate()
	check(not controls.active and not RumbleInput.touch_held.jump, "Eliminating the actual touch fighter removes controls and clears held buttons")
	game.begin_round()
	check(not controls.active and controls.player == game.players[0], "Next countdown replaces the eliminated fighter without stale control ownership")
	game.queue_free()
	await process_frame
	print("PASS: ", checks, " mobile input checks")
	quit()
