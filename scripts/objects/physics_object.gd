class_name RumbleProp
extends RigidBody3D
var carrier: CharacterBody3D
var thrower: CharacterBody3D
var dangerous_time := 0.0
var kind := 0
var tint := Color("d49a66")
func configure(type: int, color: Color) -> void:
	kind = type
	tint = color
func _ready() -> void:
	add_to_group("props")
	mass = 1.6
	contact_monitor = true
	max_contacts_reported = 6
	continuous_cd = true
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.4
	physics_material_override.friction = 0.7
	var mesh := MeshInstance3D.new()
	var shape := CollisionShape3D.new()
	if kind == 0:
		var box := BoxMesh.new()
		box.size = Vector3(0.75,0.75,0.75)
		mesh.mesh = box
		var hitbox := BoxShape3D.new()
		hitbox.size = box.size
		shape.shape = hitbox
	elif kind == 1:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.35
		cylinder.bottom_radius = 0.35
		cylinder.height = 0.85
		mesh.mesh = cylinder
		var hitbox := CylinderShape3D.new()
		hitbox.radius = 0.35
		hitbox.height = 0.85
		shape.shape = hitbox
	else:
		var sphere := SphereMesh.new()
		sphere.radius = 0.4
		sphere.height = 0.8
		mesh.mesh = sphere
		var hitbox := SphereShape3D.new()
		hitbox.radius = 0.4
		shape.shape = hitbox
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.8
	mesh.material_override = mat
	add_child(mesh)
	add_child(shape)
	body_entered.connect(_hit)
func _physics_process(delta: float) -> void:
	dangerous_time = maxf(0, dangerous_time - delta)
	if global_position.y < -25: queue_free()
func _hit(body: Node) -> void:
	if dangerous_time > 0 and body != thrower and body.has_method("receive_hit"):
		body.receive_hit(linear_velocity * 0.75 + Vector3.UP * 2, 0.6)
		dangerous_time = 0
func take(player: CharacterBody3D) -> void:
	carrier = player
	freeze = true
	collision_layer = 0
	collision_mask = 0
func release(impulse: Vector3) -> void:
	thrower = carrier
	carrier = null
	freeze = false
	collision_layer = 1
	collision_mask = 1
	linear_velocity = impulse
	dangerous_time = 1.5 if impulse.length() > 4 else 0.0
