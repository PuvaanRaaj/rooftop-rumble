class_name RooftopArena
extends Node3D

var spawn_points: Array[Vector3] = [Vector3(-3.8, 1, -2.5), Vector3(3.8, 1, 2.5), Vector3(-3.8, 1, 2.5), Vector3(3.8, 1, -2.5)]
var collapsible: Array[StaticBody3D] = []
var _props: Node3D
var _built := false
var map_id := "skyline"
var camera_min_span := 12.0
var camera_width := 24.0
var _safe_rects: Array[Rect2] = []

static func map_catalog() -> Array:
	return [
		{"id": "skyline", "name": "Skyline Terrace", "description": "Classic rooftop with jumpable side roofs."},
		{"id": "neon", "name": "Neon Junction", "description": "A neon square with narrow side decks."},
		{"id": "garden", "name": "Sky Garden", "description": "Wide terraces, trees, and chunky planters."},
		{"id": "cargo", "name": "Cargo Deck", "description": "Shipping containers and plenty of throwable crates."},
		{"id": "foundry", "name": "Foundry Heights", "description": "A large square surrounded by machinery."}
	]

func select_map(id: String) -> void:
	var selected := "skyline"
	for entry in map_catalog():
		if entry.id == id:
			selected = id
			break
	if _built and selected == map_id:
		return
	# Manager calls between matches, after stopping hazards and removing fighters.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	collapsible.clear()
	_safe_rects.clear()
	_props = null
	_built = false
	map_id = selected
	build()

func build() -> void:
	if _built:
		return
	_built = true
	camera_min_span = 12.0
	camera_width = 24.0
	if map_id == "skyline":
		_build_skyline()
	else:
		_build_variant()
	_city()
	_props = Node3D.new()
	_props.name = "LooseProps"
	add_child(_props)
	_spawn_props()

func _build_skyline() -> void:
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

func reset() -> void:
	for platform in collapsible:
		platform.visible = true
		platform.collision_layer = 1
		platform.position = platform.get_meta("home_position")
		var surface := platform.get_child(0) as MeshInstance3D
		surface.material_override = platform.get_meta("base_material")
	if is_instance_valid(_props):
		for prop in _props.get_children():
			_props.remove_child(prop)
			prop.queue_free()
		_spawn_props()

func is_safe_position(pos: Vector3) -> bool:
	if pos.y < -1.5 or _safe_rects.is_empty():
		return false
	for rect in _safe_rects:
		if rect.has_point(Vector2(pos.x, pos.z)):
			return true
	for platform in collapsible:
		if platform.collision_layer != 0:
			var size: Vector3 = platform.get_meta("platform_size")
			var center: Vector3 = platform.get_meta("home_position")
			if absf(pos.x - center.x) <= size.x / 2 and absf(pos.z - center.z) <= size.z / 2:
				return true
	return false

func _spawn_props() -> void:
	var locations := [Vector3(-2.7, 0.75, -0.9), Vector3(2.5, 0.75, 1.2), Vector3(-4.8, 0.75, 0.7), Vector3(4.8, 0.75, -1.1), Vector3(-1.2, 0.75, 3.2), Vector3(1.5, 0.75, -3.1), Vector3(-5.1, 0.75, 2.6), Vector3(5.1, 0.75, -2.6)]
	if map_id == "cargo":
		locations.append_array([Vector3(-6, 0.75, 0), Vector3(6, 0.75, 0), Vector3(0, 0.75, 4.2), Vector3(0, 0.75, -4.2)])
	elif map_id == "garden":
		locations.append_array([Vector3(-6.5, 0.75, -1.2), Vector3(6.5, 0.75, 1.2)])
	elif map_id == "foundry":
		locations.append_array([Vector3(-2.5, 0.75, -5.5), Vector3(2.5, 0.75, 5.5)])
	var colors := [Color("ff9c5d"), Color("ef6584"), Color("53cbbc")]
	var prop_script := load("res://scripts/objects/physics_object.gd")
	for i in locations.size():
		var prop = prop_script.new()
		var kind := 0 if map_id == "cargo" and i >= 8 else i % 3
		prop.configure(kind, colors[i % 3])
		prop.position = locations[i]
		prop.rotation.y = i * 0.8
		_props.add_child(prop)

func _floor(center: Vector3, size: Vector3, color: Color, can_collapse: bool) -> void:
	var body := StaticBody3D.new()
	body.position = center
	body.collision_layer = 1
	add_child(body)
	var surface := _box(body, Vector3(0, -size.y / 2, 0), size, color)
	body.set_meta("base_material", surface.material_override)
	if not can_collapse:
		_safe_rects.append(Rect2(center.x - size.x / 2, center.z - size.z / 2, size.x, size.z))
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

func _build_variant() -> void:
	var size := Vector3(12, 0.7, 12)
	var surface := Color("34334f")
	var accent := Color("fa68da")
	match map_id:
		"garden":
			size = Vector3(16, 0.7, 12)
			camera_min_span = 13.0
			surface = Color("497f70")
			accent = Color("b9ee83")
		"cargo":
			size = Vector3(16, 0.7, 12)
			surface = Color("75575a")
			accent = Color("ffd274")
		"foundry":
			size = Vector3(16, 0.7, 16)
			surface = Color("4f515b")
			accent = Color("ff9852")
			camera_min_span = 16.0
	_floor(Vector3.ZERO, size, surface, false)
	_box(self, Vector3(0, -8.4, 0), Vector3(size.x - 0.2, 16, size.z - 0.2), surface.darkened(0.55))
	# Flat edge markings retain the ability to shove fighters off every arena.
	for x in [-size.x / 2 + 0.22, size.x / 2 - 0.22]:
		_box(self, Vector3(x, 0.02, 0), Vector3(0.09, 0.025, size.z - 0.45), accent, true)
	for z in [-size.z / 2 + 0.22, size.z / 2 - 0.22]:
		_box(self, Vector3(0, 0.02, z), Vector3(size.x - 0.45, 0.025, 0.09), accent, true)
	for point in spawn_points:
		_ring(Vector3(point.x, 0.025, point.z), accent)
	_ring(Vector3(0, 0.025, 0), accent, 1.6)
	match map_id:
		"neon":
			# Narrow lateral decks add a second route while keeping the center open.
			_floor(Vector3(-8.1, 0, 0), Vector3(3, 0.7, 5.5), Color("514b75"), true)
			_floor(Vector3(8.1, 0, 0), Vector3(3, 0.7, 5.5), Color("514b75"), true)
			for x in [-4.8, 4.8]:
				for z in [-4.8, 4.8]:
					_solid_box(Vector3(x, 0.65, z), Vector3(0.8, 1.3, 0.8), Color("24253b"))
					_box(self, Vector3(x, 1.34, z), Vector3(0.9, 0.09, 0.9), accent, true)
			for x in [-2.0, 2.0]:
				_box(self, Vector3(x, 0.015, 0), Vector3(0.055, 0.02, 10), Color("6eeae0"), true)
			_sign("NEON JUNCTION", Vector3(0, 2.3, -5.8), accent)
		"garden":
			_floor(Vector3(0, -0.12, -8.4), Vector3(5.5, 0.7, 3), Color("63957a"), true)
			for x in [-6.5, 6.5]:
				for z in [-4.5, 4.5]:
					_planter(Vector3(x, 0, z))
			# Cross paths are paint, not invisible walls.
			_box(self, Vector3(0, 0.012, 0), Vector3(15.5, 0.02, 1.4), Color("bfc494"))
			_box(self, Vector3(0, 0.013, 0), Vector3(1.4, 0.02, 11.5), Color("bfc494"))
			_sign("SKY GARDEN", Vector3(4.8, 2.3, -5.8), accent)
		"cargo":
			_floor(Vector3(-10, -0.12, 0), Vector3(3, 0.7, 4.5), Color("a37364"), true)
			_floor(Vector3(10, -0.12, 0), Vector3(3, 0.7, 4.5), Color("a37364"), true)
			camera_width = 25.0
			_container(Vector3(-5, 0, -4.8), Color("489da3"))
			_container(Vector3(5, 0, 4.8), Color("b45572"))
			for x in [-6.7, 6.7]:
				for z in [-3.0, 0.0, 3.0]:
					_box(self, Vector3(x, 0.02, z), Vector3(0.7, 0.025, 0.11), accent, true)
			_sign("CARGO DECK", Vector3(0, 2.3, -5.8), accent)
		"foundry":
			_floor(Vector3(0, -0.12, -10), Vector3(5, 0.7, 3), Color("787079"), true)
			for x in [-6.6, 6.6]:
				for z in [-5.3, 5.3]:
					_solid_box(Vector3(x, 0.65, z), Vector3(1.6, 1.3, 1.6), Color("343943"))
					_box(self, Vector3(x, 0.75, z + 0.81), Vector3(1.2, 0.45, 0.02), Color("fba050"), true)
					_cylinder(Vector3(x, 2.1, z), 0.38, 1.6, Color("788490"))
			for z in [-6.9, 6.9]:
				_box(self, Vector3(0, 0.02, z), Vector3(10, 0.025, 0.14), accent, true)
			for x in [-4.8, 0.0, 4.8]:
				_box(self, Vector3(x, 0.01, 0), Vector3(0.045, 0.015, 14), Color("30343d"))
			_sign("FOUNDRY HEIGHTS", Vector3(4.5, 2.3, -7.8), accent)
	# Facade windows are batched on all maps to keep mobile draw calls modest.
	var windows: Array[Transform3D] = []
	for y in [-2.5, -5.0, -7.5, -10.0, -12.5]:
		for x in range(-int(size.x / 2) + 1, int(size.x / 2), 2):
			windows.append(Transform3D(Basis.IDENTITY, Vector3(x, y, size.z / 2 - 0.08)))
	_batched_boxes(windows, Vector3(1.0, 1.0, 0.025), accent.darkened(0.35))

func _sign(text: String, center: Vector3, accent: Color) -> void:
	_box(self, center, Vector3(5, 1.2, 0.16), Color("18243a"))
	for y in [-0.65, 0.65]:
		_box(self, center + Vector3(0, y, 0), Vector3(5.15, 0.1, 0.22), accent, true)
	for x in [-2.2, 2.2]:
		_box(self, Vector3(center.x + x, 0.8, center.z), Vector3(0.11, 1.6, 0.11), Color("617584"))
	var label := Label3D.new()
	label.text = text
	label.font_size = 62
	label.pixel_size = 0.0055
	label.modulate = accent
	label.position = center + Vector3(0, 0, 0.1)
	add_child(label)

func _container(center: Vector3, color: Color) -> void:
	_solid_box(center + Vector3(0, 0.85, 0), Vector3(4, 1.7, 1.6), color)
	for x in range(-3, 4):
		_box(self, center + Vector3(x * 0.5, 0.85, 0.82), Vector3(0.08, 1.55, 0.06), color.lightened(0.22))
	_box(self, center + Vector3(0, 1.73, 0), Vector3(4.05, 0.08, 1.65), color.darkened(0.2))

func _planter(center: Vector3) -> void:
	_solid_box(center + Vector3(0, 0.3, 0), Vector3(1.7, 0.6, 1.7), Color("dba278"))
	_box(self, center + Vector3(0, 0.63, 0), Vector3(1.4, 0.05, 1.4), Color("4b5541"))
	_cylinder(center + Vector3(0, 1.05, 0), 0.15, 0.9, Color("93644c"))
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.85
	sphere.height = 1.6
	sphere.radial_segments = 12
	sphere.rings = 6
	crown.mesh = sphere
	crown.material_override = _material(Color("79b953"))
	crown.position = center + Vector3(0, 1.85, 0)
	add_child(crown)

func _cylinder(center: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 12
	mesh.mesh = cylinder
	mesh.material_override = _material(color)
	mesh.position = center
	add_child(mesh)
