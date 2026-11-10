class_name RumblePlayer
extends CharacterBody3D
signal action_sound(kind: String)
signal knocked_out(player: RumblePlayer)
signal impact(where: Vector3, color: Color, strength: float)
@export var speed := 5.8
@export var acceleration := 24.0
@export var jump_speed := 8.5
var config: Dictionary
var alive := true
var active := false
var facing := Vector3.FORWARD
var knockback := Vector3.ZERO
var stun := 0.0
var slippery := false
var wind := Vector3.ZERO
var grabbed_by: RumblePlayer
var grabbed_target: RumblePlayer
var held_prop: RumbleProp
var grab_time := 0.0
var punch_cooldown := 0.0
var shove_cooldown := 0.0
var grab_cooldown := 0.0
var visual: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var eyes: Array[MeshInstance3D] = []
var pupils: Array[MeshInstance3D] = []
var body_material: StandardMaterial3D
var attack_pose := 0.0
var flash := 0.0
var elapsed := 0.0
var bot: RumbleBot
const THROW_WINDUP := 0.18
const THROW_FOLLOWTHROUGH := 0.2
var throw_time := -1.0
var throw_aim := Vector3.FORWARD
var followthrough := 0.0
var aim_arrow: Node3D
var hold_hint: Label3D
var arena: RooftopArena
var input_override: Dictionary = {}
var hero_id: String = ""
var special_cooldown := 0.0
var dash_time := 0.0
var slow_duration := 0.0
var blink_timer := 3.0

func _ready() -> void:
	add_to_group("fighters")
	hero_id = str(config.get("hero", ""))
	if hero_id.is_empty():
		match int(config.get("slot", 0)) % 4:
			0: hero_id = "bolt"
			1: hero_id = "ember"
			2: hero_id = "atlas"
			3: hero_id = "frost"

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.45
	collision.shape = capsule
	collision.position.y = 0.75
	add_child(collision)

	visual = Node3D.new()
	add_child(visual)

	body_material = StandardMaterial3D.new()
	body_material.albedo_color = config.get("color", Color.CORNFLOWER_BLUE)
	body_material.roughness = 0.82

	# Torso
	_piece_on(visual, Vector3(0, 0.65, 0), Vector3(0.7, 0.75, 0.5), body_material)

	# Head
	var head := SphereMesh.new()
	head.radius = 0.46
	head.height = 0.88
	head.radial_segments = 24
	head.rings = 12
	var mesh := MeshInstance3D.new()
	mesh.mesh = head
	mesh.material_override = body_material
	mesh.position.y = 1.25
	visual.add_child(mesh)

	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("18243c")
	dark.roughness = 0.78

	var trim_color: Color = Color("fff0c9")
	match hero_id:
		"bolt": trim_color = Color("68e5ff")
		"atlas": trim_color = Color("fcd269")
		"ember": trim_color = Color("ff725c")
		"frost": trim_color = Color("82f2db")

	var trim := StandardMaterial3D.new()
	trim.albedo_color = trim_color
	trim.roughness = 0.8

	var white := StandardMaterial3D.new()
	white.albedo_color = Color("ffffff")

	# Suit details
	_piece_on(visual, Vector3(0, 0.36, 0), Vector3(0.72, 0.12, 0.52), dark)
	_piece_on(visual, Vector3(0, 0.36, -0.275), Vector3(0.16, 0.1, 0.035), trim)
	_piece_on(visual, Vector3(0, 0.83, -0.265), Vector3(0.39, 0.28, 0.04), dark)
	_piece_on(visual, Vector3(0, 0.83, -0.292), Vector3(0.12, 0.15, 0.025), trim)
	_piece_on(visual, Vector3(0, 1.015, 0), Vector3(0.5, 0.07, 0.4), trim)
	_piece_on(visual, Vector3(0, 1.13, -0.432), Vector3(0.18, 0.055, 0.04), dark)
	_piece_on(visual, Vector3(0, 1.143, -0.457), Vector3(0.12, 0.025, 0.015), white)

	# Expressive animated eyes & brow
	for x in [-0.17, 0.17]:
		var eye := _piece_on(visual, Vector3(x, 1.30, -0.405), Vector3(0.15, 0.18, 0.06), white)
		eyes.append(eye)
		var pupil := _piece_on(eye, Vector3(0, 0, -0.035), Vector3(0.07, 0.115, 0.025), dark)
		pupils.append(pupil)
		_piece_on(visual, Vector3(x, 1.43, -0.385), Vector3(0.17, 0.045, 0.055), dark)

	# Hero-specific accessories and headgear
	match hero_id:
		"bolt":
			# Sleek glowing aerodynamic visor
			_piece_on(visual, Vector3(0, 1.31, -0.42), Vector3(0.52, 0.11, 0.06), _glow_mat(Color("54f2ff")))
			# Swept lightning crest fin
			_piece_on(visual, Vector3(0, 1.68, -0.06), Vector3(0.07, 0.28, 0.48), _glow_mat(Color("54f2ff")))
			_piece_on(visual, Vector3(0, 1.76, 0.06), Vector3(0.07, 0.18, 0.30), trim)
		"atlas":
			# Heavy titanium faceplate & reinforced brow
			_piece_on(visual, Vector3(0, 1.15, -0.44), Vector3(0.38, 0.16, 0.06), dark)
			_piece_on(visual, Vector3(0, 1.45, -0.39), Vector3(0.56, 0.08, 0.08), trim)
			# Heavy chest plate
			_piece_on(visual, Vector3(0, 0.72, -0.28), Vector3(0.54, 0.36, 0.08), dark)
			_piece_on(visual, Vector3(0, 0.72, -0.32), Vector3(0.24, 0.20, 0.04), trim)
		"ember":
			# Swept dual flame horns
			for side in [-1, 1]:
				var horn := _piece_on(visual, Vector3(side * 0.24, 1.66, -0.05), Vector3(0.08, 0.28, 0.22), _glow_mat(Color("ff4838")))
				horn.rotation.z = side * -0.35
				horn.rotation.x = -0.25
			# Flame chest emblem
			_piece_on(visual, Vector3(0, 0.88, -0.28), Vector3(0.26, 0.26, 0.06), _glow_mat(Color("ffa834")))
		"frost":
			# Crystalline ice crown
			_piece_on(visual, Vector3(0, 1.68, -0.10), Vector3(0.12, 0.32, 0.12), _glow_mat(Color("47e5bc")))
			for side in [-1, 1]:
				var shard := _piece_on(visual, Vector3(side * 0.22, 1.62, -0.06), Vector3(0.08, 0.24, 0.08), _glow_mat(Color("82f2db")))
				shard.rotation.z = side * -0.45
			# Frost chest gem
			_piece_on(visual, Vector3(0, 0.85, -0.28), Vector3(0.22, 0.22, 0.06), _glow_mat(Color("82f2db")))

	# Articulated legs and boots
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.18, 0.35, 0)
		visual.add_child(leg)
		legs.append(leg)
		# Upper thigh
		_piece_on(leg, Vector3(0, -0.08, 0), Vector3(0.22, 0.20, 0.26), dark)
		_piece_on(leg, Vector3(0, -0.02, 0), Vector3(0.24, 0.05, 0.28), trim)
		# Foot and boot
		var boot_size := Vector3(0.28, 0.16, 0.44) if hero_id == "atlas" else Vector3(0.24, 0.14, 0.40)
		_piece_on(leg, Vector3(0, -0.22, -0.05), boot_size, dark)
		_piece_on(leg, Vector3(0, -0.30, -0.05), Vector3(boot_size.x + 0.02, 0.05, boot_size.z + 0.02), trim)

	# Articulated arms with sleeves, cuffs, and fists
	for side in [-1, 1]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.46, 0.9, 0)
		visual.add_child(arm)
		arms.append(arm)
		var sleeve := MeshInstance3D.new()
		var sleeve_mesh := CapsuleMesh.new()
		sleeve_mesh.radius = 0.125
		sleeve_mesh.height = 0.36
		sleeve_mesh.radial_segments = 12
		sleeve_mesh.rings = 4
		sleeve.mesh = sleeve_mesh
		sleeve.material_override = body_material
		sleeve.position.y = -0.115
		arm.add_child(sleeve)
		var fist := MeshInstance3D.new()
		var glove := SphereMesh.new()
		glove.radius = 0.19 if hero_id == "atlas" else 0.16
		glove.height = 0.34 if hero_id == "atlas" else 0.29
		glove.radial_segments = 12
		glove.rings = 6
		fist.mesh = glove
		fist.material_override = dark
		fist.position.y = -0.3
		arm.add_child(fist)
		var cuff := MeshInstance3D.new()
		var cuff_mesh := CylinderMesh.new()
		cuff_mesh.top_radius = 0.13
		cuff_mesh.bottom_radius = 0.13
		cuff_mesh.height = 0.065
		cuff_mesh.radial_segments = 12
		cuff.mesh = cuff_mesh
		cuff.material_override = trim
		cuff.position.y = -0.235
		arm.add_child(cuff)
		# Hero-specific shoulder pauldrons
		match hero_id:
			"bolt":
				_piece_on(arm, Vector3(0, 0.10, 0), Vector3(0.28, 0.12, 0.26), trim)
			"atlas":
				_piece_on(arm, Vector3(0, 0.12, 0), Vector3(0.38, 0.18, 0.36), dark)
				_piece_on(arm, Vector3(0, 0.18, 0), Vector3(0.40, 0.06, 0.38), trim)
			"ember":
				_piece_on(arm, Vector3(0, 0.12, 0), Vector3(0.32, 0.16, 0.30), _glow_mat(Color("ff4838")))
			"frost":
				_piece_on(arm, Vector3(0, 0.12, 0), Vector3(0.30, 0.16, 0.30), _glow_mat(Color("47e5bc")))

	var label := Label3D.new()
	var fighter_name: String = config.get("name", "Fighter")
	var hero_tag := hero_id.capitalize()
	label.text = fighter_name if fighter_name.to_lower().contains(hero_id) else fighter_name + "\n[" + hero_tag + "]"
	label.position.y = 2.05
	label.font_size = 28
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	_create_hold_feedback()
	if config.get("kind", "keyboard") == "cpu":
		bot = RumbleBot.new()

func _piece(pos: Vector3, size: Vector3, mat: Material) -> void:
	_piece_on(visual, pos, size, mat)

func _piece_on(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

func _glow_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	return mat
func _physics_process(delta: float) -> void:
	if not alive: return
	elapsed += delta
	punch_cooldown = maxf(0, punch_cooldown - delta)
	shove_cooldown = maxf(0, shove_cooldown - delta)
	grab_cooldown = maxf(0, grab_cooldown - delta)
	special_cooldown = maxf(0, special_cooldown - delta)
	slow_duration = maxf(0, slow_duration - delta)
	stun = maxf(0, stun - delta)
	flash = maxf(0, flash - delta)
	attack_pose = maxf(0, attack_pose - delta)
	followthrough = maxf(0, followthrough - delta)
	_advance_throw(delta)

	var actions: Dictionary = {"move": Vector2.ZERO}
	if active:
		if not input_override.is_empty(): actions = input_override
		elif bot != null: actions = bot.sample(self, arena, delta)
		elif config.get("kind", "keyboard") == "touch": actions = RumbleInput.sample_touch()
		else: actions = RumbleInput.sample(config.get("slot", 0), config.get("device", -1))

	var direction := Vector3.ZERO
	var movement: Vector2 = actions.get("move", Vector2.ZERO)
	# Camera faces straight down Z, so keyboard directions match the screen.
	direction = Vector3(movement.x, 0, movement.y).limit_length()
	if direction.length() > 0.1 and stun <= 0 and throw_time < 0 and followthrough <= 0: facing = direction.normalized()
	var target := direction * speed if active and stun <= 0 else Vector3.ZERO
	if slow_duration > 0: target *= 0.55
	if grabbed_target != null or held_prop != null: target *= 0.72
	var rate := acceleration if is_on_floor() else acceleration * 0.35
	if slippery: rate *= 0.13
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)
	velocity.y -= 22 * delta

	# Dash burst processing
	if dash_time > 0:
		dash_time -= delta
		velocity.x = facing.x * 17.0
		velocity.z = facing.z * 17.0
		for other in get_tree().get_nodes_in_group("fighters"):
			if other == self or not other.alive: continue
			var dash_offset: Vector3 = other.global_position - global_position
			if dash_offset.length() < 1.7 and facing.dot(dash_offset.normalized()) > 0.1:
				other.receive_hit(facing * 12.0 + Vector3.UP * 3.5, 0.55)
				impact.emit(other.global_position + Vector3.UP, body_material.albedo_color, 1.1)

	if active and actions.get("jump", false) and is_on_floor() and stun <= 0:
		velocity.y = jump_speed
		visual.scale = Vector3(0.85, 1.2, 0.85)

	if active and stun <= 0:
		if actions.get("special", false): use_special_power()
		elif actions.get("punch", false): attack(false)
		elif actions.get("shove", false):
			if held_prop != null or grabbed_target != null: begin_throw()
			else: attack(true)
		elif actions.get("grab", false): toggle_grab()

	if grabbed_by != null:
		grab_time += delta
		var anchor := grabbed_by.global_position + grabbed_by.facing * 1.05
		var pull := (anchor - global_position) * 10.0
		velocity.x = lerpf(velocity.x, pull.x, 0.3)
		velocity.z = lerpf(velocity.z, pull.z, 0.3)
		if actions.get("jump", false) or actions.get("punch", false): grab_time += 0.45
		if grab_time > 2.2 or global_position.distance_to(anchor) > 3:
			grabbed_by.release_hold(false)

	knockback = knockback.move_toward(Vector3.ZERO, delta * 8.0)
	knockback += wind * delta
	var base_velocity := velocity
	velocity += knockback
	var was_floor := is_on_floor()
	move_and_slide()

	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var prop := collision.get_collider() as RumbleProp
		if prop != null and prop.carrier == null:
			prop.apply_central_impulse(Vector3(base_velocity.x, 0, base_velocity.z) * delta * 8)

	# Momentum lives separately so walking cannot instantly cancel an impact.
	velocity.x = base_velocity.x
	velocity.z = base_velocity.z

	if is_on_floor() and not was_floor:
		visual.scale = Vector3(1.2, 0.75, 1.2)
		impact.emit(global_position, body_material.albedo_color, 0.25)

	_update_hold()
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), delta * 14)
	visual.scale = visual.scale.lerp(Vector3.ONE, delta * 9)
	visual.rotation.z = sin(elapsed * 14) * minf(movement.length(), 1) * 0.08

	# Articulated leg animation and idle breathing
	var move_length := movement.length()
	if is_on_floor():
		if move_length > 0.08 and active and stun <= 0 and throw_time < 0 and followthrough <= 0:
			var stride_phase := elapsed * 14.0
			if legs.size() >= 2:
				legs[0].rotation.x = sin(stride_phase) * minf(move_length, 1.0) * 0.65
				legs[1].rotation.x = -legs[0].rotation.x
			visual.position.y = absf(sin(stride_phase)) * 0.04
		else:
			if legs.size() >= 2:
				legs[0].rotation.x = lerp_angle(legs[0].rotation.x, 0.0, delta * 12.0)
				legs[1].rotation.x = lerp_angle(legs[1].rotation.x, 0.0, delta * 12.0)
			visual.position.y = sin(elapsed * 3.5) * 0.02
	else:
		if legs.size() >= 2:
			legs[0].rotation.x = lerpf(legs[0].rotation.x, -0.45, delta * 10.0)
			legs[1].rotation.x = lerpf(legs[1].rotation.x, -0.35, delta * 10.0)

	# Expressive blinking and hit reaction
	blink_timer -= delta
	var is_blinking: bool = (blink_timer < 0.12 and blink_timer > 0.0)
	if blink_timer <= 0.0:
		blink_timer = randf_range(2.5, 4.5)
	var squinting: bool = (stun > 0.0 or flash > 0.0)
	for i in range(eyes.size()):
		var eye := eyes[i]
		if squinting:
			eye.scale.y = 0.2
			eye.rotation.z = (1 if i == 0 else -1) * 0.25
		elif is_blinking:
			eye.scale.y = 0.08
			eye.rotation.z = 0.0
		else:
			eye.scale.y = 1.0
			eye.rotation.z = 0.0

	for i in range(arms.size()):
		if throw_time >= 0:
			arms[i].rotation.x = lerpf(1.5, 3.4, throw_time / THROW_WINDUP)
		elif followthrough > 0:
			arms[i].rotation.x = lerpf(0, 1.3, followthrough / THROW_FOLLOWTHROUGH)
		else:
			arms[i].rotation.x = 1.5 if attack_pose > 0 or held_prop != null or grabbed_target != null else sin(elapsed * 12 + i * PI) * movement.length() * 0.35

	body_material.emission_enabled = flash > 0
	body_material.emission = Color.WHITE * 0.6
	if global_position.y < -8: eliminate()

func use_special_power() -> void:
	if special_cooldown > 0 or not active or stun > 0 or not alive: return
	if throw_time >= 0 or followthrough > 0: return
	match hero_id:
		"bolt":
			special_cooldown = 6.0
			dash_time = 0.22
			action_sound.emit("dash")
			impact.emit(global_position + Vector3.UP * 0.8, Color("54f2ff"), 0.8)
			visual.scale = Vector3(0.75, 1.25, 1.25)
		"atlas":
			special_cooldown = 7.5
			velocity.y = 4.2
			attack_pose = 0.28
			action_sound.emit("slam")
			impact.emit(global_position, Color("fcd269"), 1.8)
			visual.scale = Vector3(1.3, 0.7, 1.3)
			for other in get_tree().get_nodes_in_group("fighters"):
				if other == self or not other.alive: continue
				var offset: Vector3 = other.global_position - global_position
				if offset.length() < 3.2:
					var push_dir: Vector3 = offset.normalized() if offset.length() > 0.1 else facing
					other.receive_hit(push_dir * 12.0 + Vector3.UP * 4.5, 0.7)
					impact.emit(other.global_position + Vector3.UP, Color("fcd269"), 1.0)
			for prop in get_tree().get_nodes_in_group("props"):
				if prop.carrier == null and prop.global_position.distance_to(global_position) < 3.2:
					var p_offset: Vector3 = prop.global_position - global_position
					prop.apply_central_impulse(p_offset.normalized() * 10.0 + Vector3.UP * 4.0)
		"ember":
			special_cooldown = 6.5
			attack_pose = 0.24
			action_sound.emit("flame")
			impact.emit(global_position + facing * 1.5 + Vector3.UP * 0.8, Color("ff4838"), 1.4)
			for other in get_tree().get_nodes_in_group("fighters"):
				if other == self or not other.alive: continue
				var offset: Vector3 = other.global_position - global_position
				if offset.length() < 3.6 and facing.dot(offset.normalized()) > 0.25:
					other.receive_hit(facing * 14.0 + Vector3.UP * 3.5, 0.65)
					impact.emit(other.global_position + Vector3.UP, Color("ff4838"), 1.1)
			for prop in get_tree().get_nodes_in_group("props"):
				if prop.carrier == null and prop.global_position.distance_to(global_position + facing) < 2.0:
					prop.apply_central_impulse(facing * 12.0 + Vector3.UP * 4.0)
		"frost":
			special_cooldown = 7.0
			attack_pose = 0.24
			action_sound.emit("freeze")
			impact.emit(global_position + Vector3.UP * 0.5, Color("47e5bc"), 1.3)
			for other in get_tree().get_nodes_in_group("fighters"):
				if other == self or not other.alive: continue
				var offset: Vector3 = other.global_position - global_position
				if offset.length() < 3.0:
					var push_dir: Vector3 = offset.normalized() if offset.length() > 0.1 else facing
					other.receive_hit(push_dir * 6.5 + Vector3.UP * 2.0, 0.4)
					other.slow_duration = 2.0
					other.flash = 0.3
					impact.emit(other.global_position + Vector3.UP, Color("82f2db"), 0.9)
func attack(shove: bool) -> void:
	if shove and shove_cooldown > 0 or not shove and punch_cooldown > 0: return
	if shove: shove_cooldown = 1.15
	else: punch_cooldown = 0.38
	attack_pose = 0.22
	if grabbed_by != null: grabbed_by.release_hold(false)
	for other in get_tree().get_nodes_in_group("fighters"):
		if other == self or not other.alive: continue
		var offset: Vector3 = other.global_position-global_position
		if offset.length() < (2.0 if shove else 1.65) and facing.dot(offset.normalized()) > 0.25:
			other.receive_hit(facing * (12 if shove else 6.5) + Vector3.UP * (4 if shove else 2),0.65 if shove else 0.3)
			impact.emit(other.global_position + Vector3.UP,body_material.albedo_color,1.0 if shove else 0.5)
	for prop in get_tree().get_nodes_in_group("props"):
		if prop.carrier == null and prop.global_position.distance_to(global_position+facing) < 1.3:
			prop.apply_central_impulse(facing*8+Vector3.UP*3)
func receive_hit(force: Vector3, duration: float) -> void:
	if not alive: return
	release_hold(false)
	if grabbed_by != null: grabbed_by.release_hold(false)
	knockback += Vector3(force.x,0,force.z)
	velocity.y = maxf(velocity.y,force.y)
	stun = duration
	flash = 0.15
	visual.scale = Vector3(1.25,0.7,1.25)
func toggle_grab() -> void:
	if throw_time >= 0 or followthrough > 0: return
	if held_prop != null or grabbed_target != null:
		begin_throw()
		return
	if grab_cooldown > 0 or grabbed_by != null: return
	grab_cooldown = 0.3
	var best: Node3D
	var distance := 1.8
	for candidate in get_tree().get_nodes_in_group("fighters"):
		if candidate == self or not candidate.alive or candidate.grabbed_by != null: continue
		var offset: Vector3 = candidate.global_position - global_position
		if offset.length() < distance and facing.dot(offset.normalized()) > 0:
			best = candidate
			distance = offset.length()
	for candidate in get_tree().get_nodes_in_group("props"):
		if candidate.carrier != null: continue
		var offset: Vector3 = candidate.global_position - global_position
		if offset.length() < distance and facing.dot(offset.normalized()) > 0:
			best = candidate
			distance = offset.length()
	if best is RumblePlayer:
		grabbed_target = best
		best.grabbed_by = self
		best.grab_time = 0
		action_sound.emit("grab")
	elif best is RumbleProp:
		held_prop = best
		best.take(self)
		action_sound.emit("grab")
func _update_hold() -> void:
	if not is_instance_valid(held_prop): held_prop = null
	if held_prop != null:
		var progress := clampf(throw_time / THROW_WINDUP,0,1)
		held_prop.global_position = global_position+Vector3.UP*(1.3+progress*0.65)+facing*(0.9-progress*1.2)
	if not is_instance_valid(grabbed_target): grabbed_target = null
	_update_hold_feedback()
func release_hold(throw_it: bool) -> void:
	var has_target := is_instance_valid(held_prop) or is_instance_valid(grabbed_target)
	throw_time = -1
	followthrough = 0
	if is_instance_valid(held_prop):
		held_prop.release(facing*14+Vector3.UP*5 if throw_it else Vector3.ZERO)
		held_prop = null
	if is_instance_valid(grabbed_target):
		var target := grabbed_target
		grabbed_target = null
		target.grabbed_by = null
		if throw_it: target.receive_hit(facing*11+Vector3.UP*5,0.5)
	if throw_it and has_target: action_sound.emit("throw")
	grab_cooldown = 0.4
	_update_hold_feedback()
func eliminate() -> void:
	if not alive: return
	release_hold(false)
	if grabbed_by != null: grabbed_by.release_hold(false)
	alive = false
	active = false
	collision_layer = 0
	collision_mask = 0
	visible = false
	impact.emit(global_position,config.get("color",Color.WHITE),1.2)
	knocked_out.emit(self)

func begin_throw() -> void:
	if not alive or not active or stun > 0 or grabbed_by != null: return
	if throw_time >= 0 or followthrough > 0: return
	if not is_instance_valid(held_prop) and not is_instance_valid(grabbed_target): return
	throw_aim = facing
	throw_time = 0

func _advance_throw(delta: float) -> void:
	if throw_time < 0: return
	if not alive or not active or stun > 0 or grabbed_by != null or (not is_instance_valid(held_prop) and not is_instance_valid(grabbed_target)):
		release_hold(false)
		return
	facing = throw_aim
	throw_time += delta
	if throw_time >= THROW_WINDUP:
		if is_instance_valid(held_prop):
			held_prop.global_position = global_position + facing * 1.05 + Vector3.UP * 1.45
		release_hold(true)
		followthrough = THROW_FOLLOWTHROUGH

func _create_hold_feedback() -> void:
	aim_arrow = Node3D.new()
	add_child(aim_arrow)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fff0a0")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var arrow := MeshInstance3D.new()
	var shape := ImmediateMesh.new()
	shape.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [Vector3(-0.24,0,-1.45),Vector3(0,0,-2.05),Vector3(0.24,0,-1.45)]:
		shape.surface_add_vertex(point)
	shape.surface_end()
	arrow.mesh = shape
	arrow.material_override = mat
	aim_arrow.add_child(arrow)
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08,0.025,0.65)
	shaft.mesh = box
	shaft.position.z = -1.2
	shaft.material_override = mat
	aim_arrow.add_child(shaft)
	hold_hint = Label3D.new()
	var key := "Y" if config.get("device",-1) >= 0 else ("G" if config.get("slot",0) == 0 else "Enter")
	hold_hint.text = "TAP THROW" if config.get("kind", "keyboard") == "touch" else key + " THROW"
	hold_hint.position.y = 2.45
	hold_hint.font_size = 30
	hold_hint.pixel_size = 0.009
	hold_hint.modulate = Color("fff0a0")
	hold_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hold_hint.no_depth_test = true
	add_child(hold_hint)
	_update_hold_feedback()

func _update_hold_feedback() -> void:
	if aim_arrow == null or hold_hint == null: return
	var holding := alive and active and (is_instance_valid(held_prop) or is_instance_valid(grabbed_target))
	aim_arrow.visible = holding
	aim_arrow.position.y = 0.06
	aim_arrow.rotation.y = atan2(-facing.x,-facing.z)
	hold_hint.visible = holding and bot == null and throw_time < 0
