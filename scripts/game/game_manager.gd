class_name RumbleGame
extends Node3D
enum State { MENU, COUNTDOWN, PLAYING, RESULTS, WINNER }
var state := State.MENU
var arena: RooftopArena
var events: RumbleEvents
var ui: RumbleUI
var camera: RumbleCamera
var touch_controls: RumbleTouchControls
var _browser_window: JavaScriptObject
var _visibility_callback: JavaScriptObject
var effects: RumbleEffects
var rounds := RumbleRounds.new()
var configs: Array = []
var players: Array[RumblePlayer] = []
var countdown := 0.0
var settle := 0.0
var last_count := -1
var round_elapsed := 0.0
func _ready() -> void:
	_fit_touch_viewport()
	get_window().size_changed.connect(_fit_touch_viewport)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("a5d1de")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d4e9ff")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-30,0)
	light.light_color = Color("fff2d4")
	light.light_energy = 0.8
	light.shadow_enabled = true
	add_child(light)
	arena = RooftopArena.new()
	add_child(arena)
	arena.build()
	camera = RumbleCamera.new()
	add_child(camera)
	effects = RumbleEffects.new()
	add_child(effects)
	events = RumbleEvents.new()
	add_child(events)
	events.setup(arena)
	ui = RumbleUI.new()
	add_child(ui)
	ui.play_requested.connect(start_match)
	ui.next_requested.connect(next_round)
	ui.menu_requested.connect(return_menu)
	events.announcement.connect(ui.announce)
	touch_controls = RumbleTouchControls.new()
	add_child(touch_controls)
	touch_controls.menu_requested.connect(return_menu)
	if OS.has_feature("web"):
		_browser_window = JavaScriptBridge.get_interface("window")
		_visibility_callback = JavaScriptBridge.create_callback(_browser_visibility)
		_browser_window.addEventListener("message", _visibility_callback)
	ui.show_menu()
func start_match(crew: Array) -> void:
	configs = crew.duplicate(true)
	rounds.begin(configs.size())
	begin_round()
func begin_round() -> void:
	touch_controls.set_active(false)
	touch_controls.player = null
	events.stop()
	for player in players:
		player.release_hold(false)
		remove_child(player)
		player.queue_free()
	players.clear()
	arena.reset()
	RumbleInput.reset()
	rounds.round_number += 1
	for i in range(configs.size()):
		var player := RumblePlayer.new()
		player.config = configs[i]
		player.arena = arena
		player.position = arena.spawn_points[i]
		add_child(player)
		player.facing = (-player.position*Vector3(1,0,1)).normalized()
		player.knocked_out.connect(_eliminated)
		player.impact.connect(_impact)
		players.append(player)
		if configs[i].get("kind", "keyboard") == "touch": touch_controls.player = player
	state = State.COUNTDOWN
	countdown = 3.3
	settle = 0
	last_count = -1
	round_elapsed = 0
	ui.hide_panels()
	_refresh_hud()
func next_round() -> void:
	if state == State.WINNER: start_match(configs)
	elif state == State.RESULTS: begin_round()
func return_menu() -> void:
	touch_controls.set_active(false)
	touch_controls.player = null
	get_tree().paused = false
	events.stop()
	state = State.MENU
	for player in players:
		player.active = false
		player.release_hold(false)
		player.queue_free()
	players.clear()
	arena.reset()
	ui.show_menu()
func _physics_process(delta: float) -> void:
	if state == State.COUNTDOWN:
		countdown -= delta
		var number := ceili(countdown)
		if number != last_count:
			last_count = number
			ui.show_countdown(str(number) if number > 0 else "RUMBLE!")
			effects.tone(380 if number > 0 else 700,0.12)
		if countdown <= 0:
			state = State.PLAYING
			ui.show_countdown("")
			for player in players: player.active = true
			touch_controls.set_active(is_instance_valid(touch_controls.player))
			events.start()
	elif state == State.PLAYING:
		round_elapsed += delta
		for player in players:
			player.wind = events.wind
			player.slippery = events.slippery
		var survivors := living_indices()
		if survivors.size() <= 1:
			# Grace window lets same-tick / nearly simultaneous falls settle fairly.
			settle += delta
			if settle >= 0.6: finish_round(survivors)
		else: settle = 0
		# Long standoffs get persistent inward-to-outward chaos, no arbitrary winner.
		if round_elapsed > 120:
			for player in players:
				player.wind += player.global_position.normalized() * minf((round_elapsed-120)*0.7,20)
func living_indices() -> Array:
	var survivors: Array = []
	for i in range(players.size()):
		if players[i].alive: survivors.append(i)
	return survivors
func finish_round(survivors: Array) -> void:
	var winner := rounds.resolve(survivors)
	if winner == -2: return
	touch_controls.set_active(false)
	events.stop()
	for player in players:
		player.active = false
		player.wind = Vector3.ZERO
		player.release_hold(false)
	var champion := rounds.champion()
	state = State.WINNER if champion >= 0 else State.RESULTS
	_refresh_hud()
	var text := "DOUBLE KNOCKOUT! No point awarded." if winner == -1 else str(configs[winner].name)+" owns the rooftop!"
	ui.show_results(text,champion >= 0)
	if winner >= 0:
		for i in range(5):
			effects.burst(players[winner].global_position+Vector3.UP*2,configs[winner].color,1)
func _eliminated(_player: RumblePlayer) -> void:
	if _player == touch_controls.player: touch_controls.set_active(false)
	_refresh_hud()
	ui.announce(str(_player.config.name)+" took the scenic route!")
func _impact(where: Vector3, color: Color, strength: float) -> void:
	effects.burst(where,color,strength)
	camera.bump(strength * 0.25)
func _refresh_hud() -> void:
	var cards: Array = []
	for i in range(players.size()):
		cards.append({"name":configs[i].name,"color":configs[i].color,"wins":rounds.wins[i],"alive":players[i].alive})
	ui.update_hud(rounds.round_number,cards)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		return_menu()

func _fit_touch_viewport() -> void:
	if not RumbleInput.touch_available(): return
	var window := get_window()
	var target := Vector2i(960,540) if window.size.x >= window.size.y else Vector2i(540,960)
	if window.content_scale_size != target: window.content_scale_size = target
	if is_instance_valid(touch_controls): touch_controls.reset_input()

func _browser_visibility(arguments: Array) -> void:
	if arguments.is_empty() or not is_inside_tree(): return
	var event = arguments[0]
	if str(event.origin) != str(_browser_window.location.origin): return
	if event.data == null or str(event.data.type) != "rooftop-visibility": return
	touch_controls.reset_input()
	get_tree().paused = not bool(event.data.visible)

func _exit_tree() -> void:
	if _browser_window != null and _visibility_callback != null:
		_browser_window.removeEventListener("message", _visibility_callback)
