extends RefCounted
## Local, opt-in exports. Periodic samples explain travel and idle time between events.
const SAMPLE_SECONDS := 5.0
const MAX_SAMPLES := 3600
var samples: Array[Dictionary] = []
var next_sample := 0.0
var last_stage := ""
var developer_setup := false
var samples_truncated := false
var filename := "run-%s-%d.json" % [Time.get_datetime_string_from_system(true).replace(":", "-"), Time.get_ticks_usec()]

func sample(state, position: Vector2, force := false) -> void:
	var clock: float = state.opening_seconds + state.active_seconds
	var stage: String = state.Stage.keys()[state.stage]
	if not force and clock < next_sample and stage == last_stage: return
	if samples.size() >= MAX_SAMPLES:
		samples_truncated = true
		return
	var entry: Dictionary = state.snapshot()
	entry["position"] = [position.x, position.y]
	entry["room"] = preload("res://scripts/layout.gd").room_at(position)
	samples.append(entry)
	next_sample = clock + SAMPLE_SECONDS
	last_stage = stage

func document(state, profile: Resource) -> Dictionary:
	var tuning := {}
	for property in profile.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
			tuning[property.name] = profile.get(property.name)
	var build := {"kind": "source/editor", "source_commit": "unrecorded"}
	if OS.has_feature("template"):
		build["kind"] = "packaged build; metadata unavailable"
		var path := OS.get_executable_path().get_base_dir().path_join("build-info.json")
		if FileAccess.file_exists(path):
			var metadata = JSON.parse_string(FileAccess.get_file_as_string(path))
			if metadata is Dictionary: build = metadata
	return {"schema": 1, "version": ProjectSettings.get_setting("application/config/version"), "build": build,
		"engine": Engine.get_version_info()["string"], "profile": profile.profile_id,
		"tuning": tuning, "developer_setup": developer_setup, "samples_truncated": samples_truncated,
		"sample_interval_seconds": SAMPLE_SECONDS, "events": state.events.duplicate(true),
		"samples": samples.duplicate(true), "snapshot": state.snapshot()}

func save(state, profile: Resource, directory := "user://playtests") -> String:
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return ""
	var path := directory.path_join(filename)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return ""
	file.store_string(JSON.stringify(document(state, profile), "\t"))
	file.flush()
	var succeeded := file.get_error() == OK
	file.close()
	return path if succeeded else ""
