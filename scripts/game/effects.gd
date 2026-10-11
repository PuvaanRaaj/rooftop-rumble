class_name RumbleEffects
extends Node3D
# All score and action samples are original offline-generated PCM assets.
const MUSIC_TRACKS := {
	"skyline": preload("res://assets/audio/skyline.wav"),
	"neon": preload("res://assets/audio/neon.wav"),
	"garden": preload("res://assets/audio/garden.wav")
}
var action_sounds := {
	"grab": preload("res://assets/audio/grab.wav"),
	"throw": preload("res://assets/audio/throw.wav")
}
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var music_enabled := true
var sfx_enabled := true
var _music_requested := false
var _voice_cursor := 0
var tones: Dictionary = {}
func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.volume_db = -8
	add_child(music)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -4
		add_child(voice)
		voices.append(voice)

func start_music(theme: String = "skyline") -> void:
	var track := "skyline"
	if theme.contains("neon") or theme.contains("foundry"): track = "neon"
	elif theme.contains("garden"): track = "garden"
	var selected: AudioStreamWAV = MUSIC_TRACKS[track]
	# Do not restart the song between rounds on the same map.
	if music.stream == null or music.stream.resource_name != track:
		music.stop()
		var loop: AudioStreamWAV = selected.duplicate()
		loop.resource_name = track
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop.loop_begin = 0
		loop.loop_end = int(round(loop.get_length() * loop.mix_rate))
		music.stream = loop
	_music_requested = true
	if music_enabled and not music.playing and DisplayServer.get_name() != "headless": music.play()

func stop_music() -> void:
	_music_requested = false
	music.stop()

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled: music.stop()
	elif _music_requested and music.stream != null and not music.playing and DisplayServer.get_name() != "headless": music.play()

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if not enabled:
		for voice in voices: voice.stop()

func play_action(kind: String) -> void:
	if action_sounds.has(kind): _play_sfx(action_sounds[kind])

func _play_sfx(stream: AudioStream) -> void:
	if not sfx_enabled or DisplayServer.get_name() == "headless": return
	var voice := voices[_voice_cursor]
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	_voice_cursor = (_voice_cursor + 1) % voices.size()
	voice.stop()
	voice.stream = stream
	voice.play()
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
	if not sfx_enabled or DisplayServer.get_name() == "headless": return
	var key := str(frequency)+":"+str(duration)
	if tones.has(key):
		_play_sfx(tones[key])
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
	_play_sfx(wav)

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	tones.clear()
