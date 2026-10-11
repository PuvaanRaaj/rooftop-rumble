extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func wait_frames(count: int) -> void:
	for i in range(count): await physics_frame

func combat_count(actions: Dictionary) -> int:
	var count := 0
	for key in ["punch", "shove", "grab"]:
		if actions.get(key, false): count += 1
	return count

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(8842)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(60, 1, 60)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	var human := RumblePlayer.new()
	human.config = {"kind":"keyboard"}
	human.position = Vector3(20, 0, -8)
	root.add_child(human)
	var cpu := RumblePlayer.new()
	cpu.config = {"kind":"cpu"}
	cpu.position = Vector3(-8, 0, -8)
	root.add_child(cpu)
	await wait_frames(30)
	human.active = true
	cpu.active = true
	human.input_override = {"move":Vector2.RIGHT}
	cpu.bot.intent = RumbleBot.Intent.APPROACH_FIGHTER
	cpu.bot.intent_time = 5.0
	cpu.bot.destination = human.global_position
	cpu.bot.target = human
	var human_start := human.position
	var cpu_start := cpu.position
	await wait_frames(30)
	var human_travel := human.position.x - human_start.x
	var cpu_travel := cpu.position.x - cpu_start.x
	check(absf(human_travel-cpu_travel) < 0.05, "CPU and human cover the same distance using real movement physics")
	check(is_equal_approx(cpu.velocity.x, 5.8) and is_equal_approx(human.velocity.x, 5.8), "CPU retains the human's full top speed")
	human.set_physics_process(false)
	cpu.set_physics_process(false)
	human.input_override = {}
	human.position = Vector3(1.3, 0, 0)
	cpu.position = Vector3.ZERO
	cpu.velocity = Vector3.ZERO
	var assessment := RumbleBot.new()
	var opening := assessment.sample(cpu, null, 0.01)
	check(combat_count(opening) == 0, "A nearby human is assessed rather than attacked on the first decision")

	# A committed attack can miss: it cannot swivel to a target that dodges.
	var committed := RumbleBot.new()
	committed.target = human
	committed.intent = RumbleBot.Intent.ATTACK_WINDUP
	committed.intent_time = 0.2
	committed.planned_action = "punch"
	committed.aim = Vector3.RIGHT
	cpu.facing = Vector3.RIGHT
	var early := committed.sample(cpu, null, 0.1)
	check(combat_count(early) == 0, "Attack preparation provides a visible reaction opportunity")
	human.position = Vector3(-1.3, 0, 0)
	var strike := committed.sample(cpu, null, 0.11)
	check(strike.get("punch", false) and combat_count(strike) == 1, "Prepared melee commits one action")
	check(cpu.facing.dot(Vector3.RIGHT) > 0.99, "Attack keeps its pre-dodge direction instead of tracking perfectly")
	if strike.get("punch", false): cpu.attack(false)
	check(human.stun == 0 and human.knockback == Vector3.ZERO, "Dodging behind a prepared punch avoids its real hit detection")
	var recover_safe := true
	for i in range(12):
		recover_safe = recover_safe and combat_count(committed.sample(cpu, null, 1.0/60)) == 0
	check(recover_safe, "A missed attack leaves recovery time without an immediate combo")

	# Exercise the complete pickup and animated release using the player's real loop.
	cpu.punch_cooldown = 0
	cpu.grab_cooldown = 0
	cpu.position = Vector3(-4, 0, 4)
	cpu.velocity = Vector3.ZERO
	human.position = Vector3(5, 0, 4)
	var prop := RumbleProp.new()
	prop.configure(1, Color.CORAL)
	prop.position = Vector3(-2, 0.6, 4)
	root.add_child(prop)
	await wait_frames(20)
	var prop_choices := 0
	var non_chase_choices := 0
	for decision in range(32):
		var natural := RumbleBot.new()
		natural.sample(cpu, null, 0.01)
		if natural.intent == RumbleBot.Intent.SEEK_PROP: prop_choices += 1
		if natural.intent in [RumbleBot.Intent.REPOSITION, RumbleBot.Intent.RECOVER]: non_chase_choices += 1
	check(prop_choices > 0, "Default decisions sometimes seek nearby props")
	check(non_chase_choices > 0, "Default decisions sometimes hesitate or reposition instead of always charging")
	cpu.bot = RumbleBot.new()
	cpu.bot.intent = RumbleBot.Intent.SEEK_PROP
	cpu.bot.intent_time = 3.0
	cpu.bot.prop_target = prop
	cpu.bot.planned_action = "grab"
	cpu.bot.destination = prop.global_position
	cpu.bot.target = human
	cpu.set_physics_process(true)
	var sought_prop := false
	var picked_up := false
	for i in range(150):
		await physics_frame
		if cpu.position.x > -3.8: sought_prop = true
		if cpu.held_prop == prop:
			picked_up = true
			break
	check(sought_prop and picked_up and prop.carrier == cpu and prop.freeze, "CPU approaches and grabs a real prop rather than only rushing the human")
	if picked_up:
		cpu.set_physics_process(false)
		cpu.bot.intent = RumbleBot.Intent.AIM_THROW
		cpu.bot.intent_time = 0.25
		cpu.bot.aim = Vector3.RIGHT
		cpu.facing = Vector3.RIGHT
		# Move the target sideways after the aim is committed.
		human.position.z = 10
		cpu.set_physics_process(true)
		var saw_windup := false
		var released := false
		var release_velocity := Vector3.ZERO
		for i in range(90):
			await physics_frame
			if cpu.throw_time >= 0 and prop.carrier == cpu: saw_windup = true
			if prop.carrier == null and not prop.freeze:
				released = true
				release_velocity = prop.linear_velocity
				break
		check(saw_windup and released, "CPU uses the same grab, wind-up and physical release sequence as the human")
		check(release_velocity.x > 10 and absf(release_velocity.z) < 0.1, "Committed throw travels along its old aim, allowing the human to dodge")
		var launch := prop.global_position
		await wait_frames(8)
		check(prop.global_position.x > launch.x + 0.5, "CPU projectile actually moves under rigid-body physics")
		check(human.stun == 0, "Dodged human is not magically hit by the thrown object")
	cpu.set_physics_process(false)

	var guarded := RumbleBot.new()
	guarded.intent = RumbleBot.Intent.ATTACK_WINDUP
	guarded.intent_time = 0
	guarded.planned_action = "shove"
	guarded.target = human
	guarded.aim = Vector3.RIGHT
	cpu.throw_time = 0.05
	cpu.facing = Vector3.FORWARD
	check(combat_count(guarded.sample(cpu, null, 0.1)) == 0 and cpu.facing == Vector3.FORWARD, "Pending throw prevents another action or aim mutation")
	cpu.throw_time = -1
	cpu.followthrough = 0.1
	check(combat_count(guarded.sample(cpu, null, 0.1)) == 0, "Throw follow-through cannot chain another attack")
	cpu.followthrough = 0
	cpu.stun = 0.5
	check(combat_count(guarded.sample(cpu, null, 0.1)) == 0, "Stunned CPU cannot execute its queued attack")
	cpu.stun = 0
	cpu.active = false
	check(combat_count(guarded.sample(cpu, null, 0.1)) == 0, "Inactive CPU cannot execute a queued attack")
	cpu.active = true

	var disposable := RumblePlayer.new()
	root.add_child(disposable)
	guarded.target = disposable
	guarded.intent = RumbleBot.Intent.ATTACK_WINDUP
	guarded.intent_time = 0
	disposable.free()
	check(combat_count(guarded.sample(cpu, null, 0.1)) == 0, "Freed target safely cancels a pending action")
	var lost_prop := RumbleProp.new()
	root.add_child(lost_prop)
	lost_prop.position = cpu.position + Vector3.RIGHT * 0.8 + Vector3.UP * 0.5
	guarded.intent = RumbleBot.Intent.SEEK_PROP
	guarded.intent_time = 1
	guarded.planned_action = "grab"
	guarded.target = human
	guarded.prop_target = lost_prop
	guarded.destination = lost_prop.position
	guarded.sample(cpu, null, 0.01)
	guarded.intent_time = 0
	lost_prop.take(human)
	check(combat_count(guarded.sample(cpu, null, 0.01)) == 0, "A prop taken by another fighter cancels the prepared pickup")
	lost_prop.release(Vector3.ZERO)
	guarded.planned_action = "grab"
	guarded.intent = RumbleBot.Intent.SEEK_PROP
	guarded.intent_time = 1
	guarded.prop_target = lost_prop
	guarded.destination = lost_prop.position
	guarded.sample(cpu, null, 0.01)
	guarded.intent_time = 0
	lost_prop.free()
	check(combat_count(guarded.sample(cpu, null, 0.01)) == 0, "A disappearing prop safely cancels the prepared pickup")
	var arena := RooftopArena.new()
	arena._safe_rects.append(Rect2(-7,-5,14,10))
	root.add_child(arena)
	# Round cleanup can detach nodes before queued deletion invalidates references.
	var detached_target := RumblePlayer.new()
	root.add_child(detached_target)
	detached_target.set_physics_process(false)
	guarded.target = detached_target
	guarded.intent = RumbleBot.Intent.ATTACK_WINDUP
	guarded.planned_action = "punch"
	guarded.pickup_plan = false
	guarded.intent_time = 0
	root.remove_child(detached_target)
	check(is_instance_valid(detached_target) and not guarded._valid_target(), "Live detached fighter is no longer a valid target during round cleanup")
	check(combat_count(guarded.sample(cpu, arena, 0.01)) == 0, "Detached fighter cancels queued combat without reading a missing world transform")
	detached_target.free()
	var detached_prop := RumbleProp.new()
	root.add_child(detached_prop)
	detached_prop.position = cpu.position + Vector3.RIGHT * 0.8
	guarded.target = human
	guarded.prop_target = detached_prop
	guarded.destination = detached_prop.position
	guarded.planned_action = "grab"
	guarded.intent = RumbleBot.Intent.SEEK_PROP
	guarded.intent_time = 1
	guarded.sample(cpu, arena, 0.01)
	guarded.intent_time = 0
	root.remove_child(detached_prop)
	check(is_instance_valid(detached_prop) and not guarded._available_prop(detached_prop, arena), "Live detached prop is unavailable before accessing its world position")
	check(combat_count(guarded.sample(cpu, arena, 0.01)) == 0, "Detached prop cancels queued pickup safely during round cleanup")
	detached_prop.free()
	cpu.position = Vector3(6.5,0,0)
	human.position = Vector3(12,0,0)
	var edge := RumbleBot.new()
	edge.intent = RumbleBot.Intent.APPROACH_FIGHTER
	edge.intent_time = 2
	edge.target = human
	edge.destination = human.position
	var edge_actions := edge.sample(cpu, arena, 0.01)
	check(edge_actions.move.x < 0 and combat_count(edge_actions) == 0, "Committed chase still redirects away from an unsafe rooftop edge")
	prop.queue_free()
	var exclusive := true
	var simulation := RumbleBot.new()
	human.position = Vector3(1.3, 0, 0)
	cpu.position = Vector3.ZERO
	for i in range(1800):
		exclusive = exclusive and combat_count(simulation.sample(cpu, null, 1.0/60)) <= 1
	check(exclusive, "Extended decisions never punch, shove and grab simultaneously")
	if failures == 0: print("PASS: ", checks, " natural CPU checks")
	for node in root.get_children(): node.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
