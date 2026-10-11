class_name RumbleEvents
extends Node

signal announcement(text: String)

var wind := Vector3.ZERO
var slippery := false
var _arena: RooftopArena
var _running := false
var _elapsed := 0.0
var _remaining := 0.0
var _warning := 0.0
var _event := -1
var _target: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _wind_direction := Vector3.RIGHT
var _wind_arrow := ">>>"
var _prop_friction: Dictionary = {}

func setup(arena: RooftopArena) -> void:
	_arena = arena
	_rng.randomize()

func start() -> void:
	stop()
	_elapsed = 0.0
	_running = true

func stop() -> void:
	_running = false
	_elapsed = 0.0
	_clear_event()

func _physics_process(delta: float) -> void:
	if not _running or not is_instance_valid(_arena):
		return
	_elapsed += delta
	if _event >= 0:
		if _warning > 0:
			_warning -= delta
			if _event == 2 and is_instance_valid(_target):
				var home: Vector3 = _target.get_meta("home_position")
				_target.position = home + Vector3(sin(_elapsed * 42) * 0.04, 0, cos(_elapsed * 37) * 0.04)
			if _warning <= 0:
				_activate()
		else:
			_remaining -= delta
			if _remaining <= 0:
				_clear_event()
				announcement.emit("ROOFTOP CLEAR — KEEP RUMBLING!")
	if _elapsed >= 20.0 and _event == -1:
		_elapsed = 0.0
		_begin_event()

func _begin_event() -> void:
	_event = _rng.randi_range(0, 2)
	_warning = 2.5
	_remaining = 5.5
	match _event:
		0:
			_choose_wind()
			announcement.emit("WIND %s INCOMING — WATCH YOUR FOOTING!" % _wind_arrow)
		1:
			announcement.emit("RAIN INCOMING — ROOF WILL GET SLIPPERY!")
		2:
			if _arena.collapsible.is_empty():
				_event = 0
				_choose_wind()
				announcement.emit("WIND %s INCOMING — WATCH YOUR FOOTING!" % _wind_arrow)
				return
			_target = _arena.collapsible[_rng.randi_range(0, _arena.collapsible.size() - 1)]
			var surface := _target.get_child(0) as MeshInstance3D
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("ef5264")
			material.emission_enabled = true
			material.emission = Color("b63a44")
			surface.material_override = material
			announcement.emit("UNSTABLE SIDE ROOF — GET OFF THE RED PLATFORM!")

func _activate() -> void:
	match _event:
		0:
			wind = _wind_direction * 9.0
			announcement.emit("WIND %s! STAY AWAY FROM THE EDGE!" % _wind_arrow)
		1:
			slippery = true
			_set_prop_friction()
			announcement.emit("SLIPPERY ROOF! EASY ON THE TURNS!")
		2:
			if is_instance_valid(_target):
				_target.visible = false
				_target.collision_layer = 0
			announcement.emit("SIDE ROOF COLLAPSED! JUMP THE GAP!")

func _clear_event() -> void:
	wind = Vector3.ZERO
	slippery = false
	_restore_prop_friction()
	_warning = 0.0
	_remaining = 0.0
	_event = -1
	if is_instance_valid(_target):
		_target.visible = true
		_target.collision_layer = 1
		_target.position = _target.get_meta("home_position")
		var surface := _target.get_child(0) as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("395c70")
		material.roughness = 0.82
		surface.material_override = material
	_target = null

func _choose_wind() -> void:
	var direction := _rng.randf_range(0, TAU)
	_wind_direction = Vector3(cos(direction), 0, sin(direction))
	if absf(_wind_direction.x) >= absf(_wind_direction.z):
		_wind_arrow = ">>>" if _wind_direction.x >= 0 else "<<<"
	else:
		_wind_arrow = "v" if _wind_direction.z >= 0 else "^"

func _set_prop_friction() -> void:
	if not is_instance_valid(_arena):
		return
	var props := _arena.get_node_or_null("LooseProps")
	if props == null:
		return
	for prop in props.get_children():
		if prop is RigidBody3D:
			var body := prop as RigidBody3D
			if _prop_friction.has(body):
				continue
			_prop_friction[body] = body.physics_material_override
			var material := PhysicsMaterial.new()
			if body.physics_material_override != null:
				material = body.physics_material_override.duplicate() as PhysicsMaterial
			material.friction = 0.04
			body.physics_material_override = material

func _restore_prop_friction() -> void:
	for body in _prop_friction:
		if is_instance_valid(body):
			body.physics_material_override = _prop_friction[body]
	_prop_friction.clear()
