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

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	seed(8842)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(50, 1, 50)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	var human := RumblePlayer.new()
	human.config = {"kind":"keyboard"}
	human.position = Vector3(12, 0, -4)
	root.add_child(human)
	var cpu := RumblePlayer.new()
	cpu.config = {"kind":"cpu"}
	cpu.position = Vector3(-5, 0, -4)
	root.add_child(cpu)
	await wait_frames(30)
	human.active = true
	cpu.active = true
	human.input_override = {"move":Vector2.RIGHT}
	cpu.bot.opening_time = 0
	var human_start := human.position
	var cpu_start := cpu.position
	await wait_frames(30)
	var human_travel := human.position.x - human_start.x
	var cpu_travel := cpu.position.x - cpu_start.x
	check(cpu_travel > 1 and human_travel > cpu_travel * 1.7, "Real CPU movement is about half human movement speed")
	check(is_equal_approx(cpu.velocity.x, 2.9) and is_equal_approx(human.velocity.x, 5.8), "Human top speed stays unchanged")
	human.set_physics_process(false)
	cpu.set_physics_process(false)
	human.position = Vector3(1.3, 0, 0)
	cpu.position = Vector3.ZERO
	var opening := RumbleBot.new()
	var opening_clear := true
	for i in range(119):
		var actions := opening.sample(cpu, null, 1.0 / 60)
		opening_clear = opening_clear and actions.move == Vector2.ZERO and not actions.punch and not actions.shove and not actions.grab
	check(opening_clear, "Opening grace gives space even inside attack range")
	var pacing := RumbleBot.new()
	pacing.opening_time = 0
	check(pacing.sample(cpu, null, 0.01).move == Vector2.ZERO, "CPU holds comfortable combat spacing")
	check(cpu.facing.dot(Vector3.RIGHT) > 0.99, "Stationary CPU keeps facing its opponent")
	cpu.throw_time = 0.05
	cpu.facing = Vector3.FORWARD
	pacing.sample(cpu, null, 0.01)
	check(cpu.facing == Vector3.FORWARD, "Stationary aiming preserves a throw's locked direction")
	cpu.throw_time = -1
	human.position.x = 0.8
	check(pacing.sample(cpu, null, 0.01).move.x < 0, "CPU retreats instead of crowding overlapping opponents")
	human.position.x = 1.3
	var first_hit := -1
	for i in range(120):
		if pacing.sample(cpu, null, 1.0 / 60).punch:
			first_hit = i
			break
	check(first_hit >= 60 and first_hit < 110, "First attack has a deliberate reaction delay")
	var paused := true
	for i in range(29):
		var actions := pacing.sample(cpu, null, 1.0 / 60)
		paused = paused and actions.move == Vector2.ZERO and not actions.punch and not actions.shove and not actions.grab
	check(paused, "Attack is followed by half a second of breathing room")
	var arena := RooftopArena.new()
	arena._safe_rects.append(Rect2(-7,-5,14,10))
	root.add_child(arena)
	cpu.position = Vector3(6.5,0,0)
	human.position = Vector3(5.2,0,0)
	pacing.rest_time = 0.5
	check(pacing.sample(cpu, arena, 0.01).move.x < 0, "Edge avoidance remains active during post-attack rest")
	var grace_edge := RumbleBot.new()
	check(grace_edge.sample(cpu, arena, 0.01).move.x < 0, "Edge avoidance remains active during opening grace")
	cpu.position = Vector3(-3,0,0)
	human.position = Vector3.ZERO
	cpu.velocity = Vector3.ZERO
	cpu.bot = RumbleBot.new()
	cpu.bot.opening_time = 0
	cpu.bot.decision_time = 100
	cpu.set_physics_process(true)
	await wait_frames(90)
	check(cpu.position.distance_to(human.position) > 1.2 and cpu.position.distance_to(human.position) < 1.5, "Real pursuit stops before colliding with a stationary human")
	if failures == 0: print("PASS: ", checks, " CPU pacing checks")
	for node in root.get_children(): node.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
