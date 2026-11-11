extends Node
## Original synthesized placeholders. No external audio assets or alarms.
var cue := AudioStreamPlayer.new()
var pump := AudioStreamPlayer2D.new()
var music := AudioStreamPlayer.new()

func _ready() -> void:
	for bus in ["Machinery", "Interface", "Music"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	cue.bus = "Interface"
	add_child(cue)
	pump.bus = "Machinery"
	pump.volume_db = -24
	pump.max_distance = 900
	pump.position = preload("res://scripts/layout.gd").PUMP
	pump.stream = tone(90, 1.0, true)
	add_child(pump)
	music.bus = "Music"
	music.volume_db = -30
	music.stream = tone(220, 1.0, true)
	add_child(music)

func tone(frequency: float, seconds: float, loop := false) -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var samples := int(sound.mix_rate * seconds)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var envelope := 1.0 if loop else sin(PI * i / samples)
		var value := int(sin(TAU * frequency * i / sound.mix_rate) * envelope * 5000)
		data.encode_s16(i * 2, value)
	sound.data = data
	if loop:
		sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sound.loop_end = samples
	return sound

func confirm(recovered := false) -> void:
	cue.stream = tone(660 if recovered else 400, 0.35 if recovered else 0.12)
	cue.play()

func set_pump_running(running: bool) -> void:
	if running and not pump.playing:
		pump.play()
	elif not running and pump.playing:
		pump.stop()

func switch_pull() -> void:
	# A brief low clunk distinguishes the latched lever from UI button tones.
	cue.stream = tone(160, 0.16)
	cue.play()

func alert() -> void:
	cue.stream = tone(300, 0.3)
	cue.play()

func set_final_push(active: bool) -> void:
	if active and not music.playing: music.play()
	elif not active and music.playing: music.stop()

func reset() -> void:
	cue.stop()
	pump.stop()
	music.stop()

func _exit_tree() -> void:
	reset()
