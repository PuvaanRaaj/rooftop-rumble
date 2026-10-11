extends SceneTree
func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _initialize() -> void:
	RumbleInput.reset()
	key(KEY_D,true)
	key(KEY_LEFT,true)
	key(KEY_F,true)
	key(KEY_K,true)
	var a := RumbleInput.sample(0)
	var b := RumbleInput.sample(1)
	assert(a.move == Vector2.RIGHT and b.move == Vector2.LEFT,"Layouts move independently with simultaneous keys")
	assert(a.punch and b.punch,"Both punches independently edge-trigger")
	assert(not RumbleInput.sample(0).punch,"Held punch cannot repeat")
	for code in [KEY_D,KEY_LEFT,KEY_F,KEY_K]: key(code,false)
	key(KEY_F,true)
	RumbleInput.sample(0) # release was not sampled, so must still be held edge state
	key(KEY_F,false)
	RumbleInput.sample(0)
	key(KEY_F,true)
	assert(RumbleInput.sample(0).punch,"New press after release triggers again")
	key(KEY_F,false)
	print("PASS: simultaneous keyboard routing and action edges (synthetic input)")
	quit()
