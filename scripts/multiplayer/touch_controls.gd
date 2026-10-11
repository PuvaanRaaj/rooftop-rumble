class_name RumbleTouchControls
extends CanvasLayer
## Screen touches remain independent of keyboard and gamepad bindings.
signal menu_requested
var player: RumblePlayer
var active := false
var _pointers: Dictionary = {}
var _stick_origin := Vector2.ZERO
var _stick_offset := Vector2.ZERO
var _surface: TouchSurface

class TouchSurface extends Control:
	var controls: RumbleTouchControls
	func _draw() -> void:
		controls.draw_controls(self)

func _ready() -> void:
	layer = 20
	_surface = TouchSurface.new()
	_surface.controls = self
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	get_viewport().size_changed.connect(reset_input)
	set_active(active)

func set_active(value: bool) -> void:
	active = value
	visible = value
	reset_input()
	set_process(value)
	set_process_input(value)

func reset_input() -> void:
	_pointers.clear()
	_stick_offset = Vector2.ZERO
	_stick_origin = joystick_center()
	RumbleInput.clear_touch()
	if is_instance_valid(_surface): _surface.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		reset_input()

func _exit_tree() -> void:
	RumbleInput.clear_touch()

func _process(_delta: float) -> void:
	_surface.queue_redraw()

func _size() -> Vector2:
	return get_viewport().get_visible_rect().size

func joystick_center() -> Vector2:
	var size := _size()
	return Vector2(108, size.y - 108)

func control_center(action: String) -> Vector2:
	var size := _size()
	match action:
		"jump": return Vector2(size.x - 78, size.y - 192)
		"punch": return Vector2(size.x - 208, size.y - 94)
		"grab": return Vector2(size.x - 78, size.y - 72)
		"menu": return Vector2(size.x - 38, 38)
	return joystick_center()

func control_rect(action: String) -> Rect2:
	var radius := 26.0 if action == "menu" else 52.0
	return Rect2(control_center(action) - Vector2.ONE * radius, Vector2.ONE * radius * 2)

func _input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if not _pointers.has(event.index): return
			var action: String = _pointers[event.index]
			_pointers.erase(event.index)
			if action == "stick":
				RumbleInput.touch_move = Vector2.ZERO
				_stick_offset = Vector2.ZERO
				_stick_origin = joystick_center()
			else:
				RumbleInput.release_touch(action, event.canceled)
			get_viewport().set_input_as_handled()
			return
		if _pointers.has(event.index): return
		if control_rect("menu").has_point(event.position):
			reset_input()
			get_viewport().set_input_as_handled()
			menu_requested.emit()
			return
		for action in ["jump", "punch", "grab"]:
			if event.position.distance_to(control_center(action)) <= 52 and not action in _pointers.values():
				_pointers[event.index] = action
				RumbleInput.press_touch(action)
				get_viewport().set_input_as_handled()
				return
		var size := _size()
		if event.position.x < size.x * 0.45 and event.position.y > size.y * 0.45 and not "stick" in _pointers.values():
			_pointers[event.index] = "stick"
			_stick_origin = event.position.clamp(Vector2(76, size.y * 0.45), Vector2(size.x * 0.45 - 76, size.y - 76))
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _pointers.has(event.index):
		if _pointers[event.index] == "stick": _update_stick(event.position)
		get_viewport().set_input_as_handled()

func _update_stick(position: Vector2) -> void:
	_stick_offset = (position - _stick_origin).limit_length(58)
	var magnitude := _stick_offset.length() / 58.0
	RumbleInput.touch_move = Vector2.ZERO if magnitude <= 0.16 else _stick_offset.normalized() * ((magnitude - 0.16) / 0.84)

func draw_controls(surface: Control) -> void:
	var navy := Color(0.05, 0.10, 0.17, 0.70)
	var gold := Color(1.0, 0.77, 0.30, 0.9)
	var font := ThemeDB.fallback_font
	surface.draw_circle(_stick_origin, 74, navy)
	surface.draw_arc(_stick_origin, 74, 0, TAU, 64, Color(0.72, 0.86, 1.0, 0.65), 3, true)
	surface.draw_circle(_stick_origin + _stick_offset, 34, Color(0.68, 0.83, 0.96, 0.70))
	for action in ["jump", "punch", "grab", "menu"]:
		var center := control_center(action)
		var radius := 26.0 if action == "menu" else 52.0
		var pressed: bool = RumbleInput.touch_held.get(action, false)
		surface.draw_circle(center, radius, gold if pressed else navy)
		surface.draw_arc(center, radius, 0, TAU, 48, gold, 3, true)
		var label: String = "MENU" if action == "menu" else action.to_upper()
		if action == "grab" and is_instance_valid(player) and (is_instance_valid(player.held_prop) or is_instance_valid(player.grabbed_target)):
			label = "THROW"
		var font_size := 12 if action == "menu" else 19
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		surface.draw_string(font, center + Vector2(-text_size.x / 2, font_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.05, 0.1, 0.17) if pressed else Color.WHITE)
