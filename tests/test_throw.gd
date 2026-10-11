extends SceneTree
var checks := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		assert(condition, message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var player := RumblePlayer.new()
	player.config = {"name":"Throw tester","slot":0,"kind":"keyboard","device":-1}
	root.add_child(player)
	player.active = true
	player.set_physics_process(false)
	var prop := RumbleProp.new()
	root.add_child(prop)
	prop.set_physics_process(false)
	prop.position = Vector3(0,0.8,-1)
	player.toggle_grab()
	player._update_hold()
	check(player.held_prop == prop and prop.carrier == player and prop.freeze,"Grab attaches the real rigid body")
	check(player.hold_hint.visible and player.hold_hint.text == "E THROW" and player.aim_arrow.visible,"Human sees contextual throw key and direction")
	var held_position := prop.position
	player.toggle_grab()
	check(player.throw_time == 0 and player.held_prop == prop,"Second grab starts windup without dropping object")
	player._physics_process(0.09)
	check(prop.freeze and prop.position.y > held_position.y and prop.position.z > held_position.z,"Windup physically lifts and draws object behind hands")
	check(player.arms[0].rotation.x > 1.5,"Arms visibly wind up with the lifted object")
	var pending_time := player.throw_time
	player.begin_throw()
	player.toggle_grab()
	check(player.throw_time == pending_time,"Repeated throw and grab cannot restart windup")
	player.input_override = {"move":Vector2.RIGHT}
	player._physics_process(0.091)
	check(player.held_prop == null and prop.carrier == null and not prop.freeze,"Windup releases real physical object")
	check(prop.linear_velocity.z < -13 and absf(prop.linear_velocity.x) < 0.01,"Throw follows locked initiation aim")
	check((prop.global_position - player.global_position).dot(player.throw_aim) > 1 and prop.angular_velocity.length() > 0,"Object releases in front of fighter and spins physically")
	check(player.followthrough > 0 and not player.hold_hint.visible and not player.aim_arrow.visible,"Release starts recovery and clears holding feedback")
	var released_velocity := prop.linear_velocity
	player._advance_throw(1)
	player.begin_throw()
	check(prop.linear_velocity == released_velocity,"Completed throw never releases twice")
	var launch_position := prop.global_position
	for frame in range(4): await physics_frame
	check((prop.global_position-launch_position).dot(player.throw_aim) > 0.1,"Released object flies forward under the real physics engine")
	# Immediate low-level release remains available to existing gameplay code.
	player.followthrough = 0
	player.input_override = {}
	player.position = Vector3.ZERO
	prop.position = Vector3(0,0.8,-1)
	player.grab_cooldown = 0
	player.toggle_grab()
	player.release_hold(true)
	check(not prop.freeze and prop.linear_velocity.length() > 10,"Low-level immediate throw remains compatible")
	var opponent := RumblePlayer.new()
	opponent.config = {"name":"Escape tester","kind":"cpu"}
	root.add_child(opponent)
	opponent.set_physics_process(false)
	opponent.position = Vector3(0,0,-1)
	prop.position = Vector3(10,0,10)
	player.grab_cooldown = 0
	player.toggle_grab()
	player.begin_throw()
	player._advance_throw(0.09)
	opponent.receive_hit(Vector3.ZERO,0.1)
	player._advance_throw(0.2)
	check(player.throw_time < 0 and opponent.grabbed_by == null and opponent.knockback == Vector3.ZERO,"Opponent escape cancels pending launch")
	opponent.free()
	var disappearing_prop := RumbleProp.new()
	root.add_child(disappearing_prop)
	player.held_prop = disappearing_prop
	disappearing_prop.take(player)
	player.begin_throw()
	disappearing_prop.free()
	player._advance_throw(0.2)
	check(player.throw_time < 0 and player.followthrough == 0,"Freed held target cancels rather than completing a ghost throw")
	for reason in ["hit","drop","inactive","eliminate"]:
		player.followthrough = 0
		player.stun = 0
		player.active = true
		prop.position = Vector3(0,0.8,-1)
		player.grab_cooldown = 0
		player.toggle_grab()
		player.begin_throw()
		player._advance_throw(0.09)
		match reason:
			"hit": player.receive_hit(Vector3.RIGHT,0.2)
			"drop": player.release_hold(false)
			"inactive": player.active = false
			"eliminate": player.eliminate()
		player._advance_throw(0.2)
		check(player.throw_time < 0 and prop.carrier == null and prop.linear_velocity == Vector3.ZERO,"Cancellation via " + reason + " drops without delayed launch")
	check(not player.hold_hint.visible and not player.aim_arrow.visible,"Elimination clears contextual feedback")
	prop.queue_free()
	player.queue_free()
	await process_frame
	print("PASS: ",checks," animated throw checks")
	quit()
