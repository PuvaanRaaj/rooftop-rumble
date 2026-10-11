class_name RumbleEffects
extends Node3D
var sound: AudioStreamPlayer
var tones: Dictionary = {}
func _ready() -> void:
	sound = AudioStreamPlayer.new()
	add_child(sound)
func burst(where: Vector3, tint: Color, strength: float) -> void:
	for i in range(8):
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.13
		mesh.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = material
		add_child(mesh)
		mesh.global_position = where
		var direction := Vector3(randf_range(-1,1),randf_range(0.3,1.5),randf_range(-1,1))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(mesh,"position",mesh.position+direction*(0.8+strength),0.5)
		tween.tween_property(mesh,"scale",Vector3.ZERO,0.5)
		tween.chain().tween_callback(mesh.queue_free)
	if strength > 0.3: tone(100+strength*180,0.09)
func tone(frequency: float, duration: float) -> void:
	if DisplayServer.get_name() == "headless": return
	var key := str(frequency)+":"+str(duration)
	if tones.has(key):
		sound.stop()
		sound.stream = tones[key]
		sound.play()
		return
	# Original procedural PCM audio; no external assets or licensing dependencies.
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	var frames := int(duration*22050)
	data.resize(frames*2)
	for i in range(frames):
		var sample_value := int(sin(TAU*frequency*i/22050.0)*10000*(1.0-float(i)/frames))
		data.encode_s16(i*2,sample_value)
	wav.data = data
	tones[key] = wav
	sound.stop()
	sound.stream = wav
	sound.play()

func _exit_tree() -> void:
	if is_instance_valid(sound):
		sound.stop()
		sound.stream = null
	tones.clear()
