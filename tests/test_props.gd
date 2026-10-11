extends SceneTree

class Target extends CharacterBody3D:
	var hits := 0
	func receive_hit(_impulse: Vector3, _stun: float) -> void:
		hits += 1

var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + message)
		failures += 1

func wait_frames(count: int) -> void:
	for i in range(count): await physics_frame

func prop(type: int, location: Vector3) -> RumbleProp:
	var result := RumbleProp.new()
	result.configure(type, Color.CORAL)
	result.position = location
	root.add_child(result)
	return result

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	collision.shape = box
	floor_body.position.y = -0.5
	floor_body.add_child(collision)
	root.add_child(floor_body)
	var thrower := Target.new()
	var victim := Target.new()
	root.add_child(thrower)
	root.add_child(victim)
	var crate := prop(0, Vector3(0, 2, 0))
	var barrel := prop(1, Vector3(5, 2, 0))
	var ball := prop(2, Vector3(-5, 2, 0))
	check(barrel.mass > crate.mass and crate.mass > ball.mass, "Prop weights differ")
	check(ball.physics_material_override.bounce > barrel.physics_material_override.bounce, "Beach ball is bouncier")
	check(barrel.physics_material_override.friction < crate.physics_material_override.friction, "Barrel rolls with less friction")
	crate.linear_velocity = Vector3.ONE * 3
	crate.angular_velocity = Vector3.ONE * 3
	crate.take(thrower)
	check(crate.freeze and crate.linear_velocity == Vector3.ZERO and crate.angular_velocity == Vector3.ZERO, "Pickup clears motion")
	crate.release(Vector3(8, 4, 0))
	crate._hit(thrower)
	check(thrower.hits == 0 and crate.dangerous_time > 0, "Throw excludes thrower")
	var start := crate.position
	await wait_frames(12)
	check(crate.position.x > start.x + 0.5 and crate.position.y > start.y, "Thrown object follows a physical rising trajectory")
	check(crate.angular_velocity.length() > 1, "Released prop spins")
	crate._hit(victim)
	crate._hit(victim)
	check(victim.hits == 1, "One throw damages only once")
	await process_frame
	check(crate.broken and crate.collision_layer == 0 and not crate.is_in_group("props"), "Crate breaks safely after fighter hit")
	await create_timer(0.8).timeout
	check(not is_instance_valid(crate), "Broken crate and all shards expire")
	var floor_crate := prop(0, Vector3(0, 1.5, 4))
	floor_crate.take(thrower)
	floor_crate.release(Vector3(0, -8, 0))
	await wait_frames(25)
	check(is_instance_valid(floor_crate) and floor_crate.broken, "Real floor collision breaks thrown crate")
	var resting_crate := prop(0, Vector3(0, 1.5, -4))
	await wait_frames(45)
	check(not resting_crate.broken, "Ordinary settling leaves crate intact")
	# Detect a real ball bounce by finding upward velocity after contact.
	ball.position = Vector3(-5, 2, 0)
	ball.release(Vector3(0, -6, 0))
	var bounced := false
	for i in range(40):
		await physics_frame
		if ball.linear_velocity.y > 2: bounced = true
	check(bounced and not ball.broken, "Beach ball physically bounces and survives")
	barrel.take(thrower)
	barrel.release(Vector3(8, 3, 0))
	barrel._hit(victim)
	check(not barrel.broken and victim.hits == 2, "Barrel survives its damaging hit")
	var roll_start := barrel.position
	await wait_frames(40)
	check(barrel.position.x > roll_start.x + 0.5 and absf(barrel.global_basis.y.dot(Vector3.UP)) < 0.9, "Thrown barrel travels and tumbles on the ground")
	var fighter := RumblePlayer.new()
	fighter.position = Vector3(0, 0, 10)
	root.add_child(fighter)
	fighter.set_physics_process(false)
	var carried := prop(0, Vector3(0, 1.4, 9))
	carried.take(fighter)
	fighter.held_prop = carried
	var projectile := prop(1, Vector3(-3, 0.9, 10))
	projectile.take(thrower)
	projectile.release(Vector3(14, 0, 0))
	await wait_frames(20)
	check(fighter.held_prop == null and not carried.freeze and carried.collision_layer == 1, "Real collision safely releases a fighter's carried prop")
	check(fighter.stun > 0 and fighter.knockback.x > 0, "Real collision damages the carrying fighter")
	if failures == 0: print("PASS: ", checks, " prop checks")
	for node in root.get_children(): node.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
