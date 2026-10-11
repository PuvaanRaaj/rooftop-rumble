class_name RumbleCamera
extends Camera3D
var trauma := 0.0
var home := Vector3(0,19,23)
func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = 20
	position = home
	look_at(Vector3.ZERO)
	current = true
func bump(amount: float) -> void:
	trauma = minf(trauma + amount,0.5)
func _process(delta: float) -> void:
	trauma = maxf(0,trauma-delta*1.5)
	position = home+Vector3(randf_range(-1,1),randf_range(-1,1),0)*trauma*0.35
