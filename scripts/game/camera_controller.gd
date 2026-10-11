class_name RumbleCamera
extends Camera3D
var trauma := 0.0
var home := Vector3(0,19,23)
func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	_fit_arena()
	get_viewport().size_changed.connect(_fit_arena)
	position = home
	look_at(Vector3.ZERO)
	current = true
func _fit_arena() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0: return
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	# Zoom closer while keeping every satellite roof inside narrower views.
	var minimum_span := 12.0 if RumbleInput.touch_available() else 15.0
	size = maxf(minimum_span, 24.0 / aspect)
func bump(amount: float) -> void:
	trauma = minf(trauma + amount,0.5)
func _process(delta: float) -> void:
	trauma = maxf(0,trauma-delta*1.5)
	position = home+Vector3(randf_range(-1,1),randf_range(-1,1),0)*trauma*0.35
