class_name RumbleBot
extends RefCounted
const MOVE_STRENGTH := 0.5
const COMFORT_DISTANCE := 1.4
const RETREAT_DISTANCE := 0.9
var opening_time := 2.0
var decision_time := 1.4
var rest_time := 0.0
func sample(player: RumblePlayer, arena: RooftopArena, delta: float) -> Dictionary:
	opening_time = maxf(0, opening_time - delta)
	rest_time = maxf(0, rest_time - delta)
	var target: RumblePlayer
	var best := INF
	for other in player.get_tree().get_nodes_in_group("fighters"):
		if other != player and other.alive:
			var distance: float = player.global_position.distance_to(other.global_position)
			if distance < best:
				best = distance
				target = other
	var direction := Vector3.ZERO
	var resting := opening_time > 0 or rest_time > 0
	if target != null and not resting:
		if best > COMFORT_DISTANCE:
			direction = (target.global_position-player.global_position).normalized()
		elif best < RETREAT_DISTANCE:
			direction = (player.global_position-target.global_position).normalized()
	var safety_direction := direction
	if safety_direction == Vector3.ZERO:
		safety_direction = (player.global_position * Vector3(1,0,1)).normalized()
	if arena != null and not arena.is_safe_position(player.global_position+safety_direction*1.3):
		direction = (-player.global_position * Vector3(1,0,1)).normalized()
	if target != null and direction == Vector3.ZERO and player.throw_time < 0 and player.followthrough <= 0:
		player.facing = (target.global_position-player.global_position).normalized()
	var actions := {"move":Vector2(direction.x,direction.z) * MOVE_STRENGTH,"jump":false,"punch":false,"shove":false,"grab":false}
	# React only after reaching combat range; do not arrive with a queued instant hit.
	if not resting and best < 1.9:
		decision_time -= delta
	if not resting and decision_time <= 0 and best < 1.9:
		decision_time = randf_range(1.1,1.7)
		rest_time = 0.5
		actions["punch"] = true
		actions["shove"] = randf() < 0.12
		actions["grab"] = randf() < 0.05
		if player.grabbed_by != null: actions["jump"] = true
	return actions
