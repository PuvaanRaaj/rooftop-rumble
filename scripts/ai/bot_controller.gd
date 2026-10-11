class_name RumbleBot
extends RefCounted
var decision_time := 0.0
func sample(player: RumblePlayer, arena: RooftopArena, delta: float) -> Dictionary:
	decision_time -= delta
	var target: RumblePlayer
	var best := INF
	for other in player.get_tree().get_nodes_in_group("fighters"):
		if other != player and other.alive:
			var distance: float = player.global_position.distance_to(other.global_position)
			if distance < best:
				best = distance
				target = other
	var direction := Vector3.ZERO
	if target != null: direction = (target.global_position-player.global_position).normalized()
	if arena != null and not arena.is_safe_position(player.global_position+direction*1.3):
		direction = (-player.global_position * Vector3(1,0,1)).normalized()
	var actions := {"move":Vector2(direction.x,direction.z),"jump":false,"punch":false,"shove":false,"grab":false}
	if decision_time <= 0 and best < 1.9:
		decision_time = randf_range(0.35,0.9)
		actions["punch"] = true
		actions["shove"] = randf() < 0.35
		actions["grab"] = randf() < 0.15
		if player.grabbed_by != null: actions["jump"] = true
	return actions
