extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# 1. Verify archetypes and visual configuration
	var heroes := ["bolt", "atlas", "ember", "frost"]
	for h_id in heroes:
		var p := RumblePlayer.new()
		p.config = {"name": h_id.capitalize(), "hero": h_id, "kind": "keyboard", "slot": 0}
		root.add_child(p)
		p.set_physics_process(false)
		check(p.hero_id == h_id, "Player initializes with hero archetype " + h_id)
		check(p.legs.size() == 2, "Player has articulated two-leg hierarchy for " + h_id)
		check(p.eyes.size() == 2 and p.pupils.size() == 2, "Player has expressive two-eye structure for " + h_id)
		check(p.arms.size() == 2, "Player has articulated arms for " + h_id)
		p.queue_free()

	# 2. Test Bolt: Dash Strike
	var bolt := RumblePlayer.new()
	bolt.config = {"name": "Bolt", "hero": "bolt", "kind": "keyboard", "slot": 0}
	root.add_child(bolt)
	bolt.active = true
	bolt.facing = Vector3.FORWARD
	var cues: Array[String] = []
	bolt.action_sound.connect(func(k: String): cues.append(k))

	var target := RumblePlayer.new()
	target.config = {"name": "Target", "hero": "atlas", "kind": "keyboard", "slot": 1}
	target.position = Vector3(0, 0, -1.2)
	root.add_child(target)

	bolt.use_special_power()
	check(bolt.special_cooldown > 0, "Bolt dash triggers cooldown")
	check(bolt.dash_time > 0, "Bolt enters dash surge state")
	check(cues.has("dash"), "Bolt emits dash action sound")

	# Advance dash
	bolt._physics_process(0.05)
	check(target.stun > 0, "Bolt dash collides with and stuns target")

	# Rejection during cooldown
	var old_cd := bolt.special_cooldown
	bolt.use_special_power()
	check(bolt.special_cooldown == old_cd, "Special power cannot repeat during cooldown")

	bolt.queue_free()
	target.queue_free()

	# 3. Test Atlas: Ground Slam
	var atlas := RumblePlayer.new()
	atlas.config = {"name": "Atlas", "hero": "atlas", "kind": "keyboard", "slot": 0}
	root.add_child(atlas)
	atlas.active = true
	var atlas_cues: Array[String] = []
	atlas.action_sound.connect(func(k: String): atlas_cues.append(k))

	var dummy := RumblePlayer.new()
	dummy.config = {"name": "Dummy", "kind": "keyboard", "slot": 1}
	dummy.position = Vector3(1.5, 0, 0)
	root.add_child(dummy)

	atlas.use_special_power()
	check(atlas.special_cooldown > 0, "Atlas slam triggers cooldown")
	check(atlas_cues.has("slam"), "Atlas emits slam action sound")
	check(dummy.stun > 0 and dummy.knockback.x > 0, "Atlas slam imparts radial knockback and stun")

	atlas.queue_free()
	dummy.queue_free()

	# 4. Test Ember: Flame Burst
	var ember := RumblePlayer.new()
	ember.config = {"name": "Ember", "hero": "ember", "kind": "keyboard", "slot": 0}
	root.add_child(ember)
	ember.active = true
	ember.facing = Vector3.FORWARD
	var ember_cues: Array[String] = []
	ember.action_sound.connect(func(k: String): ember_cues.append(k))

	var opponent := RumblePlayer.new()
	opponent.config = {"name": "Opponent", "kind": "keyboard", "slot": 1}
	opponent.position = Vector3(0, 0, -2.0)
	root.add_child(opponent)

	ember.use_special_power()
	check(ember.special_cooldown > 0, "Ember flame burst triggers cooldown")
	check(ember_cues.has("flame"), "Ember emits flame action sound")
	check(opponent.stun > 0 and opponent.knockback.z < 0, "Ember flame burst blasts forward opponent backward")

	ember.queue_free()
	opponent.queue_free()

	# 5. Test Frost: Freeze Pulse
	var frost := RumblePlayer.new()
	frost.config = {"name": "Frost", "hero": "frost", "kind": "keyboard", "slot": 0}
	root.add_child(frost)
	frost.active = true
	var frost_cues: Array[String] = []
	frost.action_sound.connect(func(k: String): frost_cues.append(k))

	var victim := RumblePlayer.new()
	victim.config = {"name": "Victim", "kind": "keyboard", "slot": 1}
	victim.position = Vector3(0, 0, -1.5)
	root.add_child(victim)

	frost.use_special_power()
	check(frost.special_cooldown > 0, "Frost pulse triggers cooldown")
	check(frost_cues.has("freeze"), "Frost emits freeze action sound")
	check(victim.slow_duration > 0, "Frost pulse chills victim with slow duration")

	frost.queue_free()
	victim.queue_free()

	await process_frame
	if failures == 0:
		print("PASS: ", checks, " hero archetype and power checks")
	quit(1 if failures else 0)
