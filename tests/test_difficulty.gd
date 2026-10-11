extends SceneTree

var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cpu := RumblePlayer.new()
	cpu.config = {"kind": "cpu"}
	root.add_child(cpu)
	var human := RumblePlayer.new()
	human.config = {"kind": "keyboard"}
	human.position = Vector3(4, 1, 0)
	root.add_child(human)
	cpu.set_physics_process(false)
	human.set_physics_process(false)
	cpu.active = true
	var prop := RumbleProp.new()
	root.add_child(prop)
	cpu.held_prop = prop
	var metrics := {}
	for level in ["easy", "medium", "hard"]:
		cpu.config.difficulty = level
		seed(9218)
		var duration := 0.0
		var error := 0.0
		for i in range(80):
			var bot := RumbleBot.new()
			bot.sample(cpu, null, 0.001)
			duration += bot.intent_time
			error += absf(bot.aim.angle_to(Vector3.RIGHT))
		metrics[level] = Vector2(duration / 80, error / 80)
	check(metrics.easy.x > metrics.medium.x and metrics.medium.x > metrics.hard.x, "Difficulty changes actual throw preparation time")
	check(metrics.easy.y > metrics.medium.y and metrics.medium.y > metrics.hard.y, "Difficulty changes actual throw aim accuracy")
	check(metrics.hard.y > 0.01 and metrics.hard.x >= 0.25, "Hard still makes aim errors and gives a reaction opportunity")
	cpu.held_prop = null
	for level in ["easy", "medium", "hard"]:
		cpu.config.difficulty = level
		var bot := RumbleBot.new()
		bot.target = human
		bot.intent = RumbleBot.Intent.APPROACH_FIGHTER
		bot.intent_time = 1
		bot.destination = Vector3(4, 0, 0)
		check(is_equal_approx(bot.sample(cpu, null, 0.01).move.length(), 1), level + " keeps full movement strength")
		bot.intent = RumbleBot.Intent.ATTACK_WINDUP
		bot.intent_time = 0.1
		bot.aim = Vector3.RIGHT
		human.position = Vector3(-4, 1, 0)
		var action := bot.sample(cpu, null, 0.11)
		check(action.punch and cpu.facing.dot(Vector3.RIGHT) > 0.99, level + " commits its old aim after a dodge")
		human.position = Vector3(4, 1, 0)
	var ui := RumbleUI.new()
	root.add_child(ui)
	ui.show_setup()
	await process_frame
	var map_choice: OptionButton = ui._content.get_child(1).get_child(1)
	var difficulty_choice: OptionButton = ui._content.get_child(2).get_child(1)
	check(map_choice.item_count == RooftopArena.map_catalog().size(), "Map picker lists every available arena")
	check(difficulty_choice.get_item_text(1) == "Medium", "Setup starts on Medium difficulty")
	map_choice.select(1)
	map_choice.item_selected.emit(1)
	difficulty_choice.select(0)
	difficulty_choice.item_selected.emit(0)
	var selected := {}
	ui.play_requested.connect(func(configs: Array, options: Dictionary) -> void:
		selected.configs = configs
		selected.options = options
	)
	ui._start_match()
	check(selected.get("options", {}).get("map_id") == "neon" and selected.options.difficulty == "easy", "Start match emits selected arena and CPU difficulty")
	check(selected.configs.size() == 2 and selected.configs[1].kind == "cpu", "Setup retains fighter input selection")
	ui.show_setup()
	await process_frame
	# Deferred removal keeps button callbacks safe; identify the current visible audio row.
	var audio_row: HBoxContainer
	for child in ui._content.get_children():
		if child.visible and child is HBoxContainer and child.get_child_count() == 2 and child.get_child(0) is CheckButton:
			audio_row = child
	var audio_changes := {}
	ui.audio_settings_changed.connect(func(music: bool, sfx: bool) -> void:
		audio_changes.music = music
		audio_changes.sfx = sfx
	)
	audio_row.get_child(0).button_pressed = false
	check(audio_changes.get("music") == false and audio_changes.get("sfx") == true, "Music toggle preserves sound effects")
	audio_row.get_child(1).button_pressed = false
	check(audio_changes.get("music") == false and audio_changes.get("sfx") == false, "Sound toggle independently disables effects")
	check(ui.selected_map == "neon" and ui.selected_difficulty == "easy", "Reopening setup preserves map and difficulty")
	# Exercise the native menu layout at the mobile logical viewport.
	ui._panel.remove_child(ui._content)
	ui._scroll = ScrollContainer.new()
	ui._scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui._panel.add_child(ui._scroll)
	ui._content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui._scroll.add_child(ui._content)
	ui._mobile = true
	root.size = Vector2i(960, 540)
	ui.show_setup()
	for i in range(4): await process_frame
	var start_button: Button
	var details_button: Button
	for child in ui._content.get_children():
		if child.visible and child is Button:
			if child.text == "START MATCH": start_button = child
			if child.text.begins_with("Fighters & audio"): details_button = child
	var scroll_rect := ui._scroll.get_global_rect()
	check(start_button != null and scroll_rect.encloses(start_button.get_global_rect()), "Phone Start Match is visible without scrolling")
	check(not ui._selectors[0].get_parent().visible and ui._selectors[0].get_selected_id() == 3, "Phone defaults to touch input with optional settings collapsed")
	details_button.pressed.emit()
	check(ui._selectors[0].get_parent().visible and ui._count.get_parent().visible, "Phone can expand fighter and audio settings")
	details_button.pressed.emit()
	check(not ui._selectors[0].get_parent().visible, "Phone can collapse optional settings again")
	if failures == 0: print("PASS: ", checks, " difficulty and setup checks")
	for node in root.get_children(): node.queue_free()
	await process_frame
	quit(1 if failures else 0)
