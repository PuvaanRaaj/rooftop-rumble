extends SceneTree
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + message)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var effects := RumbleEffects.new()
	root.add_child(effects)
	check(effects.has_method("start_music"), "Background music can start independently from sound effects")
	check(effects.has_method("play_action"), "Grab and throw have distinct action sounds")
	var player := RumblePlayer.new()
	player.config = {"name":"Audio tester","kind":"keyboard","slot":0}
	root.add_child(player)
	player.active = true
	player.set_physics_process(false)
	check(player.has_signal("action_sound"), "Real gameplay emits successful action audio cues")
	var cues: Array[String] = []
	player.action_sound.connect(func(kind: String): cues.append(kind))
	player.toggle_grab()
	check(cues.is_empty(), "Grabbing empty air is silent")
	var prop := RumbleProp.new()
	root.add_child(prop)
	prop.set_physics_process(false)
	prop.position = Vector3(0,0.8,-1)
	player.grab_cooldown = 0
	player.toggle_grab()
	check(cues == ["grab"], "Successful prop grab emits exactly one grab sound")
	player.begin_throw()
	check(cues == ["grab"], "Throw windup does not play release sound early")
	player.release_hold(false)
	check(cues == ["grab"], "Canceled throw does not emit a throw sound")
	player.grab_cooldown = 0
	player.toggle_grab()
	player.begin_throw()
	player._advance_throw(0.19)
	check(cues == ["grab", "grab", "throw"], "Physical release emits one throw sound")
	player.release_hold(true)
	check(cues.size() == 3, "An empty release does not emit a ghost sound")
	player.followthrough = 0
	player.grab_cooldown = 0
	prop.position = Vector3(10,0.8,10)
	var opponent := RumblePlayer.new()
	opponent.config = {"name":"Grabbed fighter","kind":"keyboard","slot":1}
	root.add_child(opponent)
	opponent.set_physics_process(false)
	opponent.position = Vector3(0,0,-1)
	player.toggle_grab()
	check(cues[-1] == "grab" and player.grabbed_target == opponent, "Fighter grabs use the same successful pickup cue")
	player.release_hold(true)
	check(cues[-1] == "throw" and opponent.grabbed_by == null, "Throwing a fighter emits its physical release cue")
	opponent.queue_free()
	for theme in ["skyline", "neon", "garden"]:
		effects.start_music(theme)
		var stream: AudioStreamWAV = effects.music.stream
		check(stream != null and stream.get_length() > 10, theme + " has a complete original music loop")
		effects.start_music(theme)
		check(effects.music.stream == stream, theme + " keeps the same music stream across rounds")
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end > 0, theme + " loops without replaying sound effects")
		var peak := 0
		var pcm := stream.data
		for offset in range(0,pcm.size(),2): peak = maxi(peak, absi(pcm.decode_s16(offset)))
		check(peak > 1000 and peak < 32767, theme + " PCM is audible without clipping")
	check(effects.action_sounds["grab"].data != effects.action_sounds["throw"].data, "Grab and throw use different original audio")
	effects.set_music_enabled(false)
	check(not effects.music.playing, "Music mute stops the background player")
	effects.set_sfx_enabled(false)
	effects.play_action("grab")
	for voice in effects.voices: check(not voice.playing, "SFX mute keeps every effect voice silent")
	effects.stop_music()
	check(not effects.music.playing, "Leaving a match stops music")
	prop.queue_free()
	player.queue_free()
	effects.queue_free()
	await process_frame
	print("PASS: ", checks, " audio checks")
	quit(1 if failures > 0 else 0)
