class_name RooftopArena
extends Node3D

var spawn_points: Array[Vector3] = [Vector3(-3.8, 1, -2.5), Vector3(3.8, 1, 2.5), Vector3(-3.8, 1, 2.5), Vector3(3.8, 1, -2.5)]
var collapsible: Array[StaticBody3D] = []
var _props: Node3D
var _built := false
var _safe_rects: Array[Rect2] = []

func build() -> void:
	if _built:
		return
	_built = true
	_safe_rects.append(Rect2(-7, -5, 14, 10))
	_floor(Vector3.ZERO, Vector3(14, 0.7, 10), Color("344e68"), false)
	# Satellite roofs leave real gaps; players must commit to a jump.
	_floor(Vector3(-9.4, -0.12, -2.7), Vector3(3.2, 0.7, 3.7), Color("395c70"), true)
	_floor(Vector3(9.4, -0.12, 2.7), Vector3(3.2, 0.7, 3.7), Color("395c70"), true)
	_floor(Vector3(0, -0.12, -7.4), Vector3(4.4, 0.7, 3.2), Color("395c70"), true)
	_box(self, Vector3(0, -8.4, 0), Vector3(13.8, 16, 9.8), Color("1b273c"))
	_roof_details()
	# Painted rooftop markings frame the action without blocking falls.
	for x in [-6.72, 6.72]:
		_box(self, Vector3(x, 0.014, 0), Vector3(0.10, 0.025, 9.45), Color("fbcd55"), true)
	for z in [-4.72, 4.72]:
		_box(self, Vector3(0, 0.014, z), Vector3(13.45, 0.025, 0.10), Color("fbcd55"), true)
	for x in range(-6, 7, 2):
		for z in [-4.45, 4.45]:
			var stripe := _box(self, Vector3(x, 0.035, z), Vector3(0.7, 0.026, 0.11), Color("fbcd55"), true)
			stripe.rotation.y = -0.55
	for x in [-3.8, 3.8]:
		for z in [-2.5, 2.5]:
			_ring(Vector3(x, 0.025, z), Color("68dfd1"))
	_ring(Vector3(0, 0.028, 0), Color("ed786c"), 1.6)
	for pos in [Vector3(-5.4, 0, -3.5), Vector3(5.4, 0, 3.5)]:
		_solid_box(pos + Vector3(0, 0.55, 0), Vector3(1.2, 1.1, 0.85), Color("4d6b7b"))
		_box(self, pos + Vector3(0, 0.10, 0), Vector3(1.32, 0.18, 0.97), Color("283e52"))
		_box(self, pos + Vector3(0, 1.12, 0), Vector3(1.32, 0.10, 0.97), Color("a1c7cd"))
		_box(self, pos + Vector3(0, 0.58, 0.432), Vector3(0.94, 0.52, 0.02), Color("243d50"))
		for offset in [-0.30, -0.10, 0.10, 0.30]:
			_box(self, pos + Vector3(offset, 1.11, 0), Vector3(0.08, 0.025, 0.65), Color("233647"))
	# Neon rooftop billboard faces the overview camera.
	_box(self, Vector3(0, 2.35, -4.65), Vector3(4.8, 1.45, 0.16), Color("101d31"))
	_box(self, Vector3(0, 3.12, -4.65), Vector3(5.0, 0.10, 0.23), Color("6de6d2"), true)
	_box(self, Vector3(0, 1.58, -4.65), Vector3(5.0, 0.10, 0.23), Color("e1a64e"))
	for x in [-2.45, 2.45]:
		_box(self, Vector3(x, 2.35, -4.65), Vector3(0.10, 1.55, 0.23), Color("79a8b7"))
	for x in [-2.2, 2.2]:
		_box(self, Vector3(x, 1.25, -4.65), Vector3(0.1, 2.5, 0.1), Color("547589"))
	var title := Label3D.new()
	title.text = "ROOFTOP RUMBLE"
	title.font_size = 66
	title.pixel_size = 0.0055
	title.modulate = Color("70f8d8")
	title.outline_modulate = Color("143943")
	title.outline_size = 10
	title.position = Vector3(0, 2.37, -4.54)
	add_child(title)
	_city()
	_props = Node3D.new()
	_props.name = "LooseProps"
	add_child(_props)
	_spawn_props()

func reset() -> void:
	for platform in collapsible:
		platform.visible = true
		platform.collision_layer = 1
		platform.position = platform.get_meta("home_position")
		var surface := platform.get_child(0) as MeshInstance3D
		surface.material_override = _material(Color("395c70"))
	if is_instance_valid(_props):
		for prop in _props.get_children():
			_props.remove_child(prop)
			prop.queue_free()
		_spawn_props()

func is_safe_position(pos: Vector3) -> bool:
	if pos.y < -1.5 or _safe_rects.is_empty():
		return false
	if _safe_rects[0].has_point(Vector2(pos.x, pos.z)):
		return true
	for platform in collapsible:
		if platform.collision_layer != 0:
			var size: Vector3 = platform.get_meta("platform_size")
			var center: Vector3 = platform.get_meta("home_position")
			if absf(pos.x - center.x) <= size.x / 2 and absf(pos.z - center.z) <= size.z / 2:
				return true
	return false

func _spawn_props() -> void:
	var locations := [Vector3(-2.7, 0.75, -0.9), Vector3(2.5, 0.75, 1.2), Vector3(-4.8, 0.75, 0.7), Vector3(4.8, 0.75, -1.1), Vector3(-1.2, 0.75, 3.2), Vector3(1.5, 0.75, -3.1)]
	var colors := [Color("ff9c5d"), Color("ef6584"), Color("53cbbc")]
	var prop_script := load("res://scripts/objects/physics_object.gd")
	for i in locations.size():
		var prop = prop_script.new()
		prop.configure(i % 3, colors[i % 3])
		prop.position = locations[i]
		prop.rotation.y = i * 0.8
		_props.add_child(prop)

func _floor(center: Vector3, size: Vector3, color: Color, can_collapse: bool) -> void:
	var body := StaticBody3D.new()
	body.position = center
	body.collision_layer = 1
	add_child(body)
	_box(body, Vector3(0, -size.y / 2, 0), size, color)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = -size.y / 2
	body.add_child(collision)
	if can_collapse:
		body.set_meta("home_position", center)
		body.set_meta("platform_size", size)
		collapsible.append(body)
		_box(body, Vector3(0, 0.016, 0), Vector3(size.x - 0.16, 0.025, 0.09), Color("ff966d"), true)

func _solid_box(center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = center
	add_child(body)
	_box(body, Vector3.ZERO, size, color)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _box(parent: Node3D, center: Vector3, size: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = _material(color, glow)
	mesh.position = center
	parent.add_child(mesh)
	return mesh

func _material(color: Color, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.5
	return material

func _ring(center: Vector3, color: Color, radius := 0.7) -> void:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.025
	torus.outer_radius = radius
	torus.rings = 24
	torus.ring_segments = 6
	mesh.mesh = torus
	mesh.material_override = _material(color, true)
	mesh.position = center
	mesh.scale.y = 0.2
	add_child(mesh)

func _roof_details() -> void:
	# Flat painted panels preserve the collision geometry and readable play area.
	for x in [-4.6, -2.3, 0.0, 2.3, 4.6]:
		_box(self, Vector3(x, 0.005, 0), Vector3(0.035, 0.006, 9.4), Color("263e55"))
	for z in [-3.2, 0.0, 3.2]:
		_box(self, Vector3(0, 0.005, z), Vector3(13.4, 0.006, 0.035), Color("263e55"))
	# Architectural cornices sit below the surface so fighters can still fall freely.
	for y in [-0.43, -1.1]:
		_box(self, Vector3(0, y, 4.96), Vector3(14.0, 0.18, 0.18), Color("62829b"))
		_box(self, Vector3(0, y, -4.96), Vector3(14.0, 0.18, 0.18), Color("62829b"))
		for x in [-6.96, 6.96]:
			_box(self, Vector3(x, y, 0), Vector3(0.18, 0.18, 10.0), Color("62829b"))
	var windows: Array[Transform3D] = []
	for y in [-2.0, -4.1, -6.2, -8.3, -10.4, -12.5, -14.6]:
		for x in [-5.5, -3.3, -1.1, 1.1, 3.3, 5.5]:
			windows.append(Transform3D(Basis.IDENTITY, Vector3(x, y, 4.915)))
		for z in [-3.4, -1.1, 1.1, 3.4]:
			windows.append(Transform3D(Basis(Vector3.UP, PI / 2), Vector3(6.915, y, z)))
	_batched_boxes(windows, Vector3(1.25, 1.1, 0.025), Color("456b87"))

func _batched_boxes(transforms: Array[Transform3D], size: Vector3, color: Color) -> void:
	if transforms.is_empty():
		return
	var boxes := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var shape := BoxMesh.new()
	shape.size = size
	batch.mesh = shape
	batch.instance_count = transforms.size()
	for i in transforms.size():
		batch.set_instance_transform(i, transforms[i])
	boxes.multimesh = batch
	boxes.material_override = _material(color)
	add_child(boxes)

func _city() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8842
	var palette := [Color("648b9b"), Color("859ba8"), Color("7287a4"), Color("9dacae"), Color("7696ab")]
	var windows: Array[Transform3D] = []
	for i in 38:
		var angle := float(i) / 38.0 * TAU
		var distance := rng.randf_range(25, 48)
		var height := rng.randf_range(8, 25)
		var center := Vector3(cos(angle) * distance, -17 + height / 2, sin(angle) * distance)
		var width := rng.randf_range(3.5, 6.5)
		var building_color: Color = palette[i % palette.size()]
		_box(self, center, Vector3(width, height, width), building_color.lerp(Color("adc3ca"), rng.randf_range(0.0, 0.15)))
		_box(self, center + Vector3(0, height / 2, 0), Vector3(width + 0.12, 0.20, width + 0.12), Color("a2b7c3"))
		for row in range(2, int(height), 3):
			for col in [-0.28, 0.0, 0.28]:
				if rng.randf() > 0.35:
					windows.append(Transform3D(Basis.IDENTITY, Vector3(center.x + width * col, -17 + row, center.z + width / 2 + 0.02)))
		if i % 4 == 0:
			_box(self, center + Vector3(0, height / 2 + 1.2, 0), Vector3(0.12, 2.4, 0.12), Color("56657c"))
			_box(self, center + Vector3(0, height / 2 + 2.45, 0), Vector3(0.22, 0.22, 0.22), Color("ee697c"), true)
	_batched_boxes(windows, Vector3(0.45, 0.7, 0.03), Color("b6c7cc"))
