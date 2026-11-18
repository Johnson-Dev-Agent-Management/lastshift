extends Node
## Original ship sounds. One warning channel follows the same priority as the HUD.
const BUSES := ["Ambience", "Machinery", "Alerts", "Interface", "Music"]
enum Alert { NONE, STRAIN, LEAK, HEAT, CUTOFF, AIR, CRITICAL }
var ambience := AudioStreamPlayer.new()
var alarm := AudioStreamPlayer.new()
var last_alert := Alert.NONE
var repeat_in := 0.0
var ready_sound: AudioStreamWAV
var cue := AudioStreamPlayer.new()
var pump := AudioStreamPlayer2D.new()
var music := AudioStreamPlayer.new()

func _ready() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	ambience.bus = "Ambience"
	ambience.volume_db = -33
	ambience.stream = tone(55, 1.0, true)
	add_child(ambience)
	alarm.bus = "Alerts"
	alarm.volume_db = -9
	add_child(alarm)
	ready_sound = arrival_chime()
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

func arrival_chime() -> AudioStreamWAV:
	var sound := tone(440, 0.14)
	var data := sound.data
	data.append_array(tone(660, 0.28).data)
	sound.data = data
	return sound

func ready_chime() -> void:
	cue.stream = ready_sound
	cue.play()

func alert() -> void:
	alarm.stream = tone(300, 0.30)
	alarm.play()

func update_soundscape(priority: Alert, delta: float) -> void:
	if not ambience.playing: ambience.play()
	repeat_in -= delta
	if priority != last_alert:
		alarm.stop()
		last_alert = priority
		repeat_in = 0
	if priority != Alert.NONE and repeat_in <= 0:
		alarm.stream = tone(500 if priority == Alert.CRITICAL else 300, 0.25)
		alarm.play()
		repeat_in = 2.0 if priority == Alert.CRITICAL else 8.0

func finish(won: bool) -> void:
	if won: ready_chime()
	else: alert()

func set_paused(paused: bool) -> void:
	for player in [ambience, pump, alarm, music, cue]:
		player.stream_paused = paused

func set_final_push(active: bool) -> void:
	if active and not music.playing: music.play()
	elif not active and music.playing: music.stop()

func reset() -> void:
	ambience.stop()
	alarm.stop()
	last_alert = Alert.NONE
	repeat_in = 0
	cue.stop()
	pump.stop()
	music.stop()

func _exit_tree() -> void:
	reset()
