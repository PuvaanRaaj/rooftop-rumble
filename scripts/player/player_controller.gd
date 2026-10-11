class_name RumblePlayer
extends CharacterBody3D
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
var body_material: StandardMaterial3D
var attack_pose := 0.0
var flash := 0.0
var elapsed := 0.0
var bot: RumbleBot
var arena: RooftopArena
var input_override: Dictionary = {}
func _ready() -> void:
	add_to_group("fighters")
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
	body_material.roughness = 0.85
	_piece(Vector3(0,0.65,0), Vector3(0.7,0.75,0.5), body_material)
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
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color("fff0c9")
	trim.roughness = 0.8
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("ffffff")
	# Contrasting suit details stay readable when the fighter faces the camera.
	_piece(Vector3(0,0.36,0),Vector3(0.72,0.12,0.52),dark)
	_piece(Vector3(0,0.36,-0.275),Vector3(0.16,0.1,0.035),trim)
	_piece(Vector3(0,0.83,-0.265),Vector3(0.39,0.28,0.04),dark)
	_piece(Vector3(0,0.83,-0.292),Vector3(0.12,0.15,0.025),trim)
	_piece(Vector3(0,1.015,0),Vector3(0.5,0.07,0.4),trim)
	for x in [-0.17,0.17]:
		_piece(Vector3(x,1.3,-0.405),Vector3(0.15,0.18,0.06),white)
		_piece(Vector3(x,1.3,-0.444),Vector3(0.07,0.115,0.025),dark)
		_piece(Vector3(x,1.43,-0.385),Vector3(0.17,0.045,0.055),dark)
		_piece(Vector3(x,0.17,0),Vector3(0.24,0.3,0.36),dark)
		_piece(Vector3(x,0.07,-0.085),Vector3(0.26,0.12,0.43),dark)
		_piece(Vector3(x,0.025,-0.085),Vector3(0.265,0.045,0.435),trim)
		_piece(Vector3(x,0.285,0),Vector3(0.25,0.06,0.37),trim)
	_piece(Vector3(0,1.13,-0.432),Vector3(0.18,0.055,0.04),dark)
	_piece(Vector3(0,1.143,-0.457),Vector3(0.12,0.025,0.015),white)
	for side in [-1,1]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.46,0.9,0)
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
		glove.radius = 0.16
		glove.height = 0.29
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
	var label := Label3D.new()
	label.text = config.get("name", "Fighter")
	label.position.y = 2.0
	label.font_size = 32
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	if config.get("kind", "keyboard") == "cpu":
		bot = RumbleBot.new()
func _piece(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = pos
	visual.add_child(mesh)
func _physics_process(delta: float) -> void:
	if not alive: return
	elapsed += delta
	punch_cooldown = maxf(0,punch_cooldown-delta)
	shove_cooldown = maxf(0,shove_cooldown-delta)
	grab_cooldown = maxf(0,grab_cooldown-delta)
	stun = maxf(0,stun-delta)
	flash = maxf(0,flash-delta)
	attack_pose = maxf(0,attack_pose-delta)
	var actions: Dictionary = {"move":Vector2.ZERO}
	if active:
		if not input_override.is_empty(): actions = input_override
		elif bot != null: actions = bot.sample(self, arena, delta)
		else: actions = RumbleInput.sample(config.get("slot",0),config.get("device",-1))
	var direction := Vector3.ZERO
	var movement: Vector2 = actions.get("move",Vector2.ZERO)
	# Camera faces straight down Z, so keyboard directions match the screen.
	direction = Vector3(movement.x,0,movement.y).limit_length()
	if direction.length() > 0.1 and stun <= 0: facing = direction.normalized()
	var target := direction * speed if active and stun <= 0 else Vector3.ZERO
	if grabbed_target != null or held_prop != null: target *= 0.72
	var rate := acceleration if is_on_floor() else acceleration * 0.35
	if slippery: rate *= 0.13
	velocity.x = move_toward(velocity.x,target.x,rate * delta)
	velocity.z = move_toward(velocity.z,target.z,rate * delta)
	velocity.y -= 22 * delta
	if active and actions.get("jump",false) and is_on_floor() and stun <= 0:
		velocity.y = jump_speed
		visual.scale = Vector3(0.85,1.2,0.85)
	if active and stun <= 0:
		if actions.get("punch",false): attack(false)
		if actions.get("shove",false):
			if held_prop != null or grabbed_target != null: release_hold(true)
			else: attack(true)
		if actions.get("grab",false): toggle_grab()
	if grabbed_by != null:
		grab_time += delta
		var anchor := grabbed_by.global_position + grabbed_by.facing * 1.05
		var pull := (anchor-global_position) * 10.0
		velocity.x = lerpf(velocity.x,pull.x,0.3)
		velocity.z = lerpf(velocity.z,pull.z,0.3)
		if actions.get("jump",false) or actions.get("punch",false): grab_time += 0.45
		if grab_time > 2.2 or global_position.distance_to(anchor) > 3:
			grabbed_by.release_hold(false)
	knockback = knockback.move_toward(Vector3.ZERO,delta * 8.0)
	knockback += wind * delta
	var base_velocity := velocity
	velocity += knockback
	var was_floor := is_on_floor()
	move_and_slide()
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var prop := collision.get_collider() as RumbleProp
		if prop != null and prop.carrier == null:
			prop.apply_central_impulse(Vector3(base_velocity.x,0,base_velocity.z)*delta*8)
	# Momentum lives separately so walking cannot instantly cancel an impact.
	velocity.x = base_velocity.x
	velocity.z = base_velocity.z
	if is_on_floor() and not was_floor:
		visual.scale = Vector3(1.2,0.75,1.2)
		impact.emit(global_position,body_material.albedo_color,0.25)
	_update_hold()
	visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-facing.x,-facing.z),delta*14)
	visual.scale = visual.scale.lerp(Vector3.ONE,delta*9)
	visual.rotation.z = sin(elapsed*14) * minf(movement.length(),1) * 0.08
	for i in range(arms.size()):
		arms[i].rotation.x = -1.5 if attack_pose > 0 or held_prop != null or grabbed_target != null else sin(elapsed*12+i*PI)*movement.length()*0.35
	body_material.emission_enabled = flash > 0
	body_material.emission = Color.WHITE * 0.6
	if global_position.y < -8: eliminate()
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
	if held_prop != null or grabbed_target != null:
		release_hold(false)
		return
	if grab_cooldown > 0 or grabbed_by != null: return
	grab_cooldown = 0.3
	var best: Node3D
	var distance := 1.8
	var candidates := get_tree().get_nodes_in_group("fighters") + get_tree().get_nodes_in_group("props")
	for candidate in candidates:
		if candidate == self: continue
		if candidate is RumblePlayer and (not candidate.alive or candidate.grabbed_by != null): continue
		if candidate is RumbleProp and candidate.carrier != null: continue
		var offset: Vector3 = candidate.global_position - global_position
		if offset.length() < distance and facing.dot(offset.normalized()) > 0:
			best = candidate
			distance = offset.length()
	if best is RumblePlayer:
		grabbed_target = best
		best.grabbed_by = self
		best.grab_time = 0
	elif best is RumbleProp:
		held_prop = best
		best.take(self)
func _update_hold() -> void:
	if not is_instance_valid(held_prop): held_prop = null
	if held_prop != null:
		held_prop.global_position = global_position+Vector3.UP*1.3+facing*0.9
	if not is_instance_valid(grabbed_target): grabbed_target = null
func release_hold(throw_it: bool) -> void:
	if is_instance_valid(held_prop):
		held_prop.release(facing*14+Vector3.UP*5 if throw_it else Vector3.ZERO)
		held_prop = null
	if is_instance_valid(grabbed_target):
		var target := grabbed_target
		grabbed_target = null
		target.grabbed_by = null
		if throw_it: target.receive_hit(facing*11+Vector3.UP*5,0.5)
	grab_cooldown = 0.4
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
