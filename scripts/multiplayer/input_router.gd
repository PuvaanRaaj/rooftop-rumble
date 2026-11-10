class_name RumbleInput
extends RefCounted
## Poll physical keys so multiple players never share action-map bindings.

static var _previous: Dictionary = {}
static var touch_move := Vector2.ZERO
static var touch_held: Dictionary = {"jump": false, "punch": false, "shove": false, "grab": false, "special": false}
static var _touch_pending: Dictionary = {}
static var dual_keyboard := false

static func touch_available() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0", true))
	return false

static func clear_touch() -> void:
	touch_move = Vector2.ZERO
	for action in touch_held:
		touch_held[action] = false
	_touch_pending.clear()

static func press_touch(action: String) -> void:
	if not touch_held.get(action, false):
		_touch_pending[action] = int(_touch_pending.get(action, 0)) + 1
	touch_held[action] = true

static func release_touch(action: String, canceled: bool = false) -> void:
	touch_held[action] = false
	if canceled: _touch_pending.erase(action)

static var _previous_held: Dictionary = {}

static func sample_touch() -> Dictionary:
	var result := {
		"move": touch_move,
		"jump": false,
		"punch": false,
		"shove": false,
		"grab": false,
		"special": false
	}
	for action in touch_held:
		var pending: int = _touch_pending.get(action, 0)
		result[action] = pending > 0
		if pending > 0: _touch_pending[action] = pending - 1
	return result

static func reset() -> void:
	_previous_held.clear()
	clear_touch()

static func sample(slot: int, device: int = -1) -> Dictionary:
	var move := Vector2.ZERO
	var jump := false
	var punch := false
	var shove := false
	var grab := false
	var special := false
	if device >= 0:
		if device in Input.get_connected_joypads():
			move = Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
			if move.length() < 0.20:
				move = Vector2.ZERO
			else:
				move = move.normalized() * minf(1.0, (move.length() - 0.20) / 0.80)
			jump = Input.is_joy_button_pressed(device, JOY_BUTTON_A)
			punch = Input.is_joy_button_pressed(device, JOY_BUTTON_X)
			shove = Input.is_joy_button_pressed(device, JOY_BUTTON_B)
			grab = Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
			special = Input.is_joy_button_pressed(device, JOY_BUTTON_RIGHT_SHOULDER) or Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER)
	elif slot == 0:
		var wasd_x := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		var wasd_y := float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		if wasd_x != 0.0 or wasd_y != 0.0 or dual_keyboard:
			move = Vector2(wasd_x, wasd_y).normalized()
		else:
			var arrow_x := float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
			var arrow_y := float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
			move = Vector2(arrow_x, arrow_y).normalized()
		jump = Input.is_physical_key_pressed(KEY_SPACE) or (not dual_keyboard and Input.is_physical_key_pressed(KEY_SHIFT))
		punch = Input.is_physical_key_pressed(KEY_F) or (not dual_keyboard and Input.is_physical_key_pressed(KEY_K))
		shove = Input.is_physical_key_pressed(KEY_H) or (not dual_keyboard and Input.is_physical_key_pressed(KEY_L))
		grab = Input.is_physical_key_pressed(KEY_G) or Input.is_physical_key_pressed(KEY_E) or (not dual_keyboard and Input.is_physical_key_pressed(KEY_ENTER))
		special = Input.is_physical_key_pressed(KEY_Q) or Input.is_physical_key_pressed(KEY_R) or (not dual_keyboard and Input.is_physical_key_pressed(KEY_O))
	else:
		move = Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))).normalized()
		jump = Input.is_physical_key_pressed(KEY_SHIFT)
		punch = Input.is_physical_key_pressed(KEY_K)
		shove = Input.is_physical_key_pressed(KEY_L)
		grab = Input.is_physical_key_pressed(KEY_ENTER)
		special = Input.is_physical_key_pressed(KEY_O) or Input.is_physical_key_pressed(KEY_P) or Input.is_physical_key_pressed(KEY_SEMICOLON)

	var input_key: int = (slot & 0xFF) | ((device + 2) << 8)
	var current_bits: int = (1 if jump else 0) | (2 if punch else 0) | (4 if shove else 0) | (8 if grab else 0) | (16 if special else 0)
	var old_bits: int = _previous_held.get(input_key, 0)
	var rising: int = current_bits & (~old_bits)
	_previous_held[input_key] = current_bits

	return {
		"move": move,
		"jump": (rising & 1) != 0,
		"punch": (rising & 2) != 0,
		"shove": (rising & 4) != 0,
		"grab": (rising & 8) != 0,
		"special": (rising & 16) != 0
	}
