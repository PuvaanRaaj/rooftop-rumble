class_name RumbleUI
extends CanvasLayer
## Native, resolution-independent menu and match presentation.

signal play_requested(configs: Array)
signal next_requested()
signal menu_requested()

const INK := Color("182638")
const CREAM := Color("fff4dc")
const MUTED := Color("b9c7d3")
const ACCENT := Color("f9cf76")
const COLORS := [Color("69b9f3"), Color("f18b8f"), Color("f5d46e"), Color("89d1ac")]
var _root: Control
var _panel: PanelContainer
var _content: VBoxContainer
var _hud: HBoxContainer
var _countdown: Label
var _announcement: Label
var _count: OptionButton
var _selectors: Array[OptionButton] = []
var _error: Label
var _announcement_remaining := 0.0

func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var theme := Theme.new()
	theme.default_font_size = 20
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, _box(Color("30465c"), 12))
		theme.set_stylebox("hover", type, _box(ACCENT, 12))
		theme.set_stylebox("pressed", type, _box(Color("e6b95b"), 12))
		theme.set_stylebox("focus", type, _box(Color(0, 0, 0, 0), 12, ACCENT))
	_root.theme = theme
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(630, 0)
	_panel.add_theme_stylebox_override("panel", _box(Color(0.075, 0.12, 0.19, 0.96), 24, Color("547087")))
	center.add_child(_panel)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	_panel.add_child(_content)
	_hud = HBoxContainer.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hud.offset_left = 24
	_hud.offset_right = -24
	_hud.offset_top = 20
	_hud.add_theme_constant_override("separation", 12)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hud)
	_countdown = _label("", 88)
	_countdown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_countdown)
	_announcement = _label("", 28)
	_announcement.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_announcement.offset_top = -76
	_announcement.offset_bottom = -24
	_announcement.add_theme_color_override("font_color", ACCENT)
	_announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_announcement)

func _box(color: Color, radius: int, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(2 if border.a > 0 else 0)
	box.border_color = border
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func _label(text: String, size := 20, color := CREAM) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _clear() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_panel.show()
	_countdown.text = ""
	_announcement.text = ""

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 52
	button.pressed.connect(callback)
	_content.add_child(button)
	return button

func _controls() -> void:
	_content.add_child(_label("KEYBOARD 1   WASD · Space · F / G / E", 16, MUTED))
	_content.add_child(_label("KEYBOARD 2   Arrows · Shift · K / L / Enter", 16, MUTED))
	_content.add_child(_label("GAMEPAD   Left stick · A jump · X punch · B shove · Y grab/throw", 15, MUTED))
	_content.add_child(_label("Tap E / Enter / Y to grab. Tap again to THROW!", 15, ACCENT))

func show_menu() -> void:
	_clear()
	_hud.hide()
	_content.add_child(_label("ROOFTOP", 58))
	_content.add_child(_label("R U M B L E", 48, ACCENT))
	_content.add_child(_label("Tiny fighters. Big falls.", 22, MUTED))
	_content.add_child(_label("2–4 players  ·  First to three wins", 18))
	_button("LET'S RUMBLE", show_setup).grab_focus()
	_controls()
	if not OS.has_feature("web"):
		_button("Quit game", func() -> void: get_tree().quit())

func show_setup() -> void:
	_clear()
	_hud.hide()
	_selectors.clear()
	_content.add_child(_label("ASSEMBLE YOUR CREW", 34, ACCENT))
	var count_row := HBoxContainer.new()
	count_row.add_theme_constant_override("separation", 18)
	count_row.add_child(_label("Fighters", 20))
	_count = OptionButton.new()
	for amount in [2, 3, 4]:
		_count.add_item(str(amount) + " players", amount)
	count_row.add_child(_count)
	_content.add_child(count_row)
	for index in 4:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		var name_label := _label("PLAYER " + str(index + 1), 20, COLORS[index])
		name_label.custom_minimum_size.x = 140
		row.add_child(name_label)
		var select := OptionButton.new()
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.add_item("Keyboard 1 · WASD", 0)
		select.add_item("Keyboard 2 · Arrows", 1)
		select.add_item("CPU · rooftop troublemaker", 2)
		for device in Input.get_connected_joypads():
			select.add_item("Gamepad " + str(device + 1) + " · " + Input.get_joy_name(device).left(22), 100 + device)
		select.select(0 if index == 0 else 2)
		row.add_child(select)
		_content.add_child(row)
		_selectors.append(select)
		row.visible = index < 2
	_count.item_selected.connect(func(selection: int) -> void:
		for index in 4:
			_selectors[index].get_parent().visible = index < selection + 2
	)
	var gamepad_hint := "Press a gamepad button, then reopen setup to detect it." if OS.has_feature("web") else "Connect gamepads before opening this screen."
	_error = _label(gamepad_hint, 15, MUTED)
	_content.add_child(_error)
	_button("START MATCH", _start_match)
	_controls()
	_button("Back", show_menu)

func _start_match() -> void:
	var configs: Array = []
	var used: Array[int] = []
	for index in _count.get_selected_id():
		var choice := _selectors[index].get_selected_id()
		if choice != 2 and choice in used:
			_error.text = "Each keyboard layout and gamepad can join once."
			_error.add_theme_color_override("font_color", COLORS[1])
			return
		used.append(choice)
		if choice >= 100 and not choice - 100 in Input.get_connected_joypads():
			_error.text = "Gamepad disconnected. Reopen setup to refresh devices."
			return
		configs.append({"name": "Player " + str(index + 1), "color": COLORS[index], "kind": "cpu" if choice == 2 else ("controller" if choice >= 100 else "keyboard"), "slot": choice if choice < 2 else index, "device": choice - 100 if choice >= 100 else -1})
	hide_panels()
	play_requested.emit(configs)

func hide_panels() -> void:
	_panel.hide()
	_hud.show()
	_countdown.text = ""

func show_countdown(text: String) -> void:
	_panel.hide()
	_countdown.text = text

func update_hud(round_number: int, players: Array) -> void:
	for child in _hud.get_children():
		_hud.remove_child(child)
		child.queue_free()
	var round_label := _label("ROUND " + str(round_number) + "\nFIRST TO 3", 19, ACCENT)
	_hud.add_child(round_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud.add_child(spacer)
	for player in players:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _box(Color(0.075, 0.12, 0.19, 0.84), 12))
		var player_color: Color = player.get("color", CREAM)
		if not player.get("alive", true):
			player_color = MUTED
		card.add_child(_label(str(player.get("name", "Player")) + "  " + str(player.get("wins", 0)) + "/3" + ("  OUT" if not player.get("alive", true) else ""), 18, player_color))
		_hud.add_child(card)

func announce(text: String) -> void:
	_announcement.text = text
	_announcement_remaining = 4.0

func _process(delta: float) -> void:
	if _announcement_remaining > 0:
		_announcement_remaining -= delta
		if _announcement_remaining <= 0:
			_announcement.text = ""

func show_results(text: String, match_over: bool) -> void:
	_clear()
	_content.add_child(_label("CHAMPION!" if match_over else "ROUND OVER", 40, ACCENT))
	_content.add_child(_label(text, 28))
	_content.add_child(_label("The roof remembers every tumble.", 18, MUTED))
	_button("PLAY AGAIN" if match_over else "NEXT ROUND", func() -> void: next_requested.emit()).grab_focus()
	_button("MAIN MENU", func() -> void: menu_requested.emit())
