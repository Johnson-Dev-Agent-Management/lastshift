extends Node
## Original synthesized placeholders. No external audio assets or alarms.
var cue := AudioStreamPlayer.new()
var pump := AudioStreamPlayer2D.new()

func _ready() -> void:
	for bus in ["Machinery", "Interface"]:
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
	if recovered:
		pump.play()

func reset() -> void:
	cue.stop()
	pump.stop()
