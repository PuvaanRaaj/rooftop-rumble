class_name RumbleProp
extends RigidBody3D

var carrier: CharacterBody3D
var thrower: CharacterBody3D
var dangerous_time := 0.0
var kind := 0
var tint := Color("d49a66")
var broken := false
var _visuals: Node3D
var _break_pending := false
var _flight_velocity := Vector3.ZERO

func configure(type: int, color: Color) -> void:
	kind = type
	tint = color

func _ready() -> void:
	add_to_group("props")
	contact_monitor = true
	max_contacts_reported = 6
	continuous_cd = true
	physics_material_override = PhysicsMaterial.new()
	_visuals = Node3D.new()
	add_child(_visuals)
	var shape := CollisionShape3D.new()
	if kind == 0:
		mass = 1.6
		physics_material_override.bounce = 0.2
		physics_material_override.friction = 0.75
		var hitbox := BoxShape3D.new()
		hitbox.size = Vector3.ONE * 0.75
		shape.shape = hitbox
		_box(Vector3.ZERO, hitbox.size, Color("bb793e"))
		# Raised wooden framing and diagonal braces on both broad faces.
		for side in [-1, 1]:
			for offset in [-0.27, 0.27]:
				_box(Vector3(offset, 0, side * 0.39), Vector3(0.1, 0.75, 0.06), Color("efbb78"))
				_box(Vector3(0, offset, side * 0.39), Vector3(0.75, 0.1, 0.06), Color("efbb78"))
			var brace := _box(Vector3(0, 0, side * 0.4), Vector3(0.08, 0.72, 0.06), Color("e3a668"))
			brace.rotation.z = -PI / 4
		for offset in [-0.15, 0.15]:
			_box(Vector3(0, offset, 0.378), Vector3(0.55, 0.018, 0.018), Color("80502e"))
	elif kind == 1:
		mass = 2.6
		physics_material_override.bounce = 0.25
		physics_material_override.friction = 0.25
		angular_damp = 0.15
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.35
		cylinder.bottom_radius = 0.35
		cylinder.height = 0.85
		_mesh(cylinder, Vector3.ZERO, tint, 0.4)
		for height in [-0.38, 0.0, 0.38]:
			var rim := CylinderMesh.new()
			rim.top_radius = 0.365
			rim.bottom_radius = 0.365
			rim.height = 0.055
			_mesh(rim, Vector3(0, height, 0), Color("57697a"), 0.7)
		var cap := CylinderMesh.new()
		cap.top_radius = 0.075
		cap.bottom_radius = 0.075
		cap.height = 0.025
		_mesh(cap, Vector3(0.17, 0.435, 0), Color("c4d0d6"), 0.7)
		var hitbox := CylinderShape3D.new()
		hitbox.radius = 0.35
		hitbox.height = 0.85
		shape.shape = hitbox
	else:
		mass = 0.55
		physics_material_override.bounce = 0.82
		physics_material_override.friction = 0.18
		angular_damp = 0.08
		# Alternating curved panels remain readable while the ball spins.
		var colors := [Color("ff625c"), Color("fff4ca"), Color("46bdf4"), Color("fff4ca"), Color("ffd54b"), Color("fff4ca")]
		var vertices := PackedVector3Array()
		for panel in range(6):
			vertices.clear()
			for latitude in range(12):
				for longitude in range(4):
					var a := _sphere_point(latitude, panel * 4 + longitude)
					var b := _sphere_point(latitude + 1, panel * 4 + longitude)
					var c := _sphere_point(latitude + 1, panel * 4 + longitude + 1)
					var d := _sphere_point(latitude, panel * 4 + longitude + 1)
					vertices.append_array(PackedVector3Array([a, b, c, a, c, d]))
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for vertex in vertices:
				surface.set_normal(vertex.normalized())
				surface.add_vertex(vertex)
			_mesh(surface.commit(), Vector3.ZERO, colors[panel])
		var hitbox := SphereShape3D.new()
		hitbox.radius = 0.4
		shape.shape = hitbox
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _sphere_point(latitude: int, longitude: int) -> Vector3:
	var phi := PI * latitude / 12.0
	var theta := TAU * longitude / 24.0
	return Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)) * 0.4

func _mesh(resource: Mesh, offset: Vector3, color: Color, metallic: float = 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = resource
	instance.position = offset
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = metallic
	instance.material_override = mat
	_visuals.add_child(instance)
	return instance

func _box(offset: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, offset, color)

func _physics_process(delta: float) -> void:
	dangerous_time = maxf(0, dangerous_time - delta)
	if dangerous_time > 0: _flight_velocity = linear_velocity
	if global_position.y < -25: queue_free()

func _on_body_entered(body: Node) -> void:
	# A fighter hit can drop another carried rigid body; defer the entire
	# damage callback, not only crate destruction, beyond physics flushing.
	call_deferred("_hit", body, _flight_velocity)

func _hit(body: Node, impact_velocity: Vector3 = Vector3.INF) -> void:
	if not is_instance_valid(body): return
	if impact_velocity == Vector3.INF: impact_velocity = linear_velocity
	if broken or _break_pending or dangerous_time <= 0 or body == thrower:
		return
	if body.has_method("receive_hit"):
		body.receive_hit(impact_velocity * 0.75 + Vector3.UP * 2, 0.6)
		dangerous_time = 0
		if kind == 0: _schedule_break()
	elif kind == 0 and body is StaticBody3D:
		dangerous_time = 0
		_schedule_break()

func _schedule_break() -> void:
	_break_pending = true
	# Physics collision callbacks cannot safely change body collision state.
	call_deferred("_break_apart")

func _break_apart() -> void:
	if broken: return
	broken = true
	carrier = null
	dangerous_time = 0
	freeze = true
	collision_layer = 0
	collision_mask = 0
	remove_from_group("props")
	_visuals.hide()
	# Shards are visual children, so resetting the arena removes them too.
	for i in range(8):
		var shard := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.14, 0.26, 0.08)
		shard.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("e3a668")
		shard.material_override = material
		add_child(shard)
		var direction := Vector3(cos(i * TAU / 8), 0, sin(i * TAU / 8))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(shard, "position", direction * 1.1 + Vector3.UP * 0.25, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", direction * 5, 0.65)
		tween.tween_property(shard, "scale", Vector3.ZERO, 0.3).set_delay(0.35)
	var cleanup := create_tween()
	cleanup.tween_interval(0.7)
	cleanup.tween_callback(queue_free)

func take(player: CharacterBody3D) -> void:
	if broken or _break_pending: return
	carrier = player
	thrower = null
	dangerous_time = 0
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0

func release(impulse: Vector3) -> void:
	if broken or _break_pending: return
	thrower = carrier
	carrier = null
	freeze = false
	sleeping = false
	collision_layer = 1
	collision_mask = 1
	linear_velocity = impulse
	_flight_velocity = impulse
	dangerous_time = 1.5 if impulse.length() > 4 else 0.0
	angular_velocity = Vector3(impulse.z, 1.5, -impulse.x).normalized() * (9.0 if kind == 1 else 6.0) if dangerous_time > 0 else Vector3.ZERO
