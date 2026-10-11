class_name RumbleInput
extends RefCounted
## Poll physical keys so multiple players never share action-map bindings.

static var _previous: Dictionary = {}

static func reset() -> void:
	_previous.clear()

static func sample(slot: int, device: int = -1) -> Dictionary:
	var move := Vector2.ZERO
	var held := {"jump": false, "punch": false, "shove": false, "grab": false}
	if device >= 0:
		if device in Input.get_connected_joypads():
			move = Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
			if move.length() < 0.20:
				move = Vector2.ZERO
			else:
				move = move.normalized() * minf(1.0, (move.length() - 0.20) / 0.80)
			held.jump = Input.is_joy_button_pressed(device, JOY_BUTTON_A)
			held.punch = Input.is_joy_button_pressed(device, JOY_BUTTON_X)
			held.shove = Input.is_joy_button_pressed(device, JOY_BUTTON_B)
			held.grab = Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
	elif slot == 0:
		move = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
		held.jump = Input.is_physical_key_pressed(KEY_SPACE)
		held.punch = Input.is_physical_key_pressed(KEY_F)
		held.shove = Input.is_physical_key_pressed(KEY_G)
		held.grab = Input.is_physical_key_pressed(KEY_E)
	else:
		move = Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))).normalized()
		# Godot polls both physical Shift keys as KEY_SHIFT; right Shift works,
		# with left Shift also accepted for keyboards without a right Shift key.
		held.jump = Input.is_physical_key_pressed(KEY_SHIFT)
		held.punch = Input.is_physical_key_pressed(KEY_K)
		held.shove = Input.is_physical_key_pressed(KEY_L)
		held.grab = Input.is_physical_key_pressed(KEY_ENTER)
	var input_id := str(slot) + ":" + str(device)
	var old: Dictionary = _previous.get(input_id, {})
	var result := {"move": move}
	for action in held:
		result[action] = held[action] and not old.get(action, false)
	_previous[input_id] = held
	return result
