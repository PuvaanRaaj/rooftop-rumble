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
	var arena := RooftopArena.new()
	root.add_child(arena)
	arena.build()
	var events := RumbleEvents.new()
	root.add_child(events)
	events.setup(arena)
	check(RooftopArena.map_catalog().size() == 5, "Five maps are selectable")
	var layouts := {}
	for entry in RooftopArena.map_catalog():
		arena.select_map(entry.id)
		await process_frame
		check(arena.map_id == entry.id, "Map switches to " + entry.id)
		check(arena.is_safe_position(Vector3.ZERO), "Center remains safe for CPU routing on " + entry.id)
		for point in arena.spawn_points:
			check(arena.is_safe_position(point), "Spawn is on the roof on " + entry.id)
		var props := arena.get_node("LooseProps")
		var count := props.get_child_count()
		check(count >= 8, "Each map supplies at least eight props")
		for prop in props.get_children():
			check(arena.is_safe_position(prop.position), "Prop spawns on a usable roof on " + entry.id)
		var floor_size: Vector3 = arena.get_child(0).get_child(0).mesh.size
		var signature := str(floor_size) + ":" + str(arena.collapsible.size()) + ":" + str(count)
		layouts[signature] = true
		var deck := arena.collapsible[0]
		var home: Vector3 = deck.get_meta("home_position")
		var material: Material = deck.get_meta("base_material")
		check(arena.is_safe_position(home), "Side deck starts safe")
		deck.visible = false
		deck.collision_layer = 0
		deck.position += Vector3(0, -5, 0)
		check(not arena.is_safe_position(home), "Collapsed deck is no longer safe")
		arena.reset()
		check(deck.visible and deck.collision_layer == 1 and deck.position == home, "Reset restores side deck")
		check(deck.get_child(0).material_override == material, "Reset retains map-specific palette")
		check(props.get_child_count() == count, "Reset replaces, rather than duplicates, props")
		# Hazard cleanup must restore the selected map's exact original material.
		events._target = deck
		deck.get_child(0).material_override = StandardMaterial3D.new()
		events.stop()
		check(deck.get_child(0).material_override == material, "Hazard cleanup retains map-specific palette")
		await physics_frame
		# Ray queries prove the generated collision surfaces exist below every spawn.
		for point in arena.spawn_points:
			var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2, point - Vector3.UP * 3, 1)
			var hit := arena.get_world_3d().direct_space_state.intersect_ray(ray)
			check(not hit.is_empty() and absf(hit.position.y) < 0.1, "Real floor collision supports spawn on " + entry.id)
		var children := arena.get_child_count()
		arena.select_map(entry.id)
		check(arena.get_child_count() == children, "Selecting current map does not duplicate scenery")
		await physics_frame
	check(layouts.size() == 5, "Maps have five distinct physical layouts and prop arrangements")
	arena.select_map("unknown")
	check(arena.map_id == "skyline", "Unknown map falls back safely")
	check(not arena.is_safe_position(Vector3(30, 0, 30)), "Outside map remains unsafe")
	check(not arena.is_safe_position(Vector3(0, -2, 0)), "Fallen fighter remains unsafe")
	events.queue_free()
	arena.queue_free()
	await process_frame
	if failures == 0: print("PASS: ", checks, " map checks")
	quit(1 if failures else 0)
