class_name RumbleBot
extends RefCounted

# Plans remember positions, not the opponent's live input or velocity.
enum Intent { ASSESS, SEEK_PROP, APPROACH_FIGHTER, ATTACK_WINDUP, AIM_THROW, RECOVER, REPOSITION }
const MOVE_STRENGTH := 1.0
var intent := Intent.ASSESS
var intent_time := 0.0
var destination := Vector3.ZERO
var aim := Vector3.FORWARD
var planned_action := "punch"
var target: RumblePlayer
var prop_target: RumbleProp
var pickup_plan := false

func sample(player: RumblePlayer, arena: RooftopArena, delta: float) -> Dictionary:
	var actions := {"move": Vector2.ZERO, "jump": false, "punch": false, "shove": false, "grab": false}
	if not player.alive or not player.active: return actions
	# Interrupted plans cannot fight stun or the existing throw animation.
	if player.stun > 0 or player.throw_time >= 0 or player.followthrough > 0:
		intent = Intent.RECOVER
		intent_time = randf_range(0.3, 0.55)
		return actions
	intent_time -= delta
	if is_instance_valid(player.grabbed_by):
		if intent_time <= 0:
			actions["punch"] = true
			intent_time = randf_range(0.35, 0.65)
		intent = Intent.RECOVER
		return actions
	if intent == Intent.SEEK_PROP and not _available_prop(prop_target, arena):
		intent = Intent.ASSESS
	if intent == Intent.ATTACK_WINDUP and pickup_plan and not _available_prop(prop_target, arena):
		intent = Intent.ASSESS
	if intent in [Intent.APPROACH_FIGHTER, Intent.ATTACK_WINDUP, Intent.AIM_THROW] and not _valid_target():
		intent = Intent.ASSESS
	if intent == Intent.ASSESS or (intent_time <= 0 and intent in [Intent.RECOVER, Intent.REPOSITION]):
		_decide(player, arena)
	var direction := Vector3.ZERO
	if intent in [Intent.SEEK_PROP, Intent.APPROACH_FIGHTER, Intent.REPOSITION]:
		var offset := _flat(destination - player.global_position)
		var reach := 1.25 if intent == Intent.SEEK_PROP else 1.3
		if intent == Intent.REPOSITION: reach = 0.35
		if intent != Intent.REPOSITION and offset.length() <= reach:
			pickup_plan = intent == Intent.SEEK_PROP
			aim = offset.normalized() if offset.length() > 0.05 else player.facing
			intent = Intent.ATTACK_WINDUP
			intent_time = randf_range(0.22, 0.48)
		elif intent_time <= 0:
			# A chase burst ends with a short look around, even if it missed.
			intent = Intent.RECOVER
			intent_time = randf_range(0.16, 0.35)
		elif offset.length() > reach:
			direction = offset.normalized()
	elif intent in [Intent.ATTACK_WINDUP, Intent.AIM_THROW]:
		player.facing = aim
		if intent == Intent.ATTACK_WINDUP: player.attack_pose = maxf(player.attack_pose, 0.08)
		if intent_time <= 0:
			if intent == Intent.AIM_THROW:
				if _holding(player): actions["grab"] = true
			else:
				actions[planned_action] = true
			intent = Intent.RECOVER
			intent_time = randf_range(0.35, 0.7)
	# Edge awareness overrides locomotion, never creates instant attacks.
	if arena != null and direction != Vector3.ZERO and not arena.is_safe_position(player.global_position + direction * 1.2):
		direction = _flat(-player.global_position).normalized()
		intent = Intent.RECOVER
		intent_time = randf_range(0.25, 0.45)
	actions["move"] = Vector2(direction.x, direction.z) * MOVE_STRENGTH
	return actions

func _decide(player: RumblePlayer, arena: RooftopArena) -> void:
	pickup_plan = false
	target = null
	var best := INF
	for other in player.get_tree().get_nodes_in_group("fighters"):
		if other == player or not other.alive: continue
		var distance: float = player.global_position.distance_to(other.global_position)
		if distance < best:
			best = distance
			target = other
	if target == null:
		intent = Intent.RECOVER
		intent_time = 0.4
		return
	if _holding(player):
		# Aim once and spend time lining up; a sidestep can beat this throw.
		aim = _flat(target.global_position - player.global_position).normalized().rotated(Vector3.UP, randf_range(-0.2, 0.2))
		intent = Intent.AIM_THROW
		intent_time = randf_range(0.4, 0.75)
		return
	prop_target = null
	var prop_distance := 7.0
	for prop in player.get_tree().get_nodes_in_group("props"):
		if not _available_prop(prop, arena): continue
		var distance: float = player.global_position.distance_to(prop.global_position)
		if distance < prop_distance:
			prop_distance = distance
			prop_target = prop
	if prop_target != null and randf() < 0.55:
		pickup_plan = true
		destination = prop_target.global_position
		planned_action = "grab"
		intent = Intent.SEEK_PROP
		intent_time = randf_range(0.5, 0.8)
		return
	prop_target = null
	var choice := randf()
	if choice < 0.15:
		# Sometimes circle or hesitate instead of choosing the perfect attack.
		var sideways := _flat(target.global_position - player.global_position).normalized().cross(Vector3.UP)
		destination = player.global_position + sideways * (1.5 if randf() < 0.5 else -1.5)
		intent = Intent.REPOSITION
		intent_time = randf_range(0.4, 0.65)
	elif choice < 0.25:
		intent = Intent.RECOVER
		intent_time = randf_range(0.3, 0.55)
	else:
		destination = target.global_position + Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35))
		var attack_choice := randf()
		planned_action = "grab" if attack_choice < 0.3 else ("shove" if attack_choice < 0.6 else "punch")
		intent = Intent.APPROACH_FIGHTER
		intent_time = randf_range(0.4, 0.75)

func _valid_target() -> bool:
	return is_instance_valid(target) and target.alive

func _holding(player: RumblePlayer) -> bool:
	return is_instance_valid(player.held_prop) or is_instance_valid(player.grabbed_target)

func _available_prop(prop, arena: RooftopArena) -> bool:
	return is_instance_valid(prop) and not prop.broken and not prop._break_pending and prop.carrier == null and (arena == null or arena.is_safe_position(prop.global_position))

func _flat(value: Vector3) -> Vector3:
	return value * Vector3(1, 0, 1)
