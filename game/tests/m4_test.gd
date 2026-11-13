extends SceneTree
## Full physical emergency routes; policy choices are scripted, not human play.
const Run = preload("res://scripts/run_controller.gd")
const PROFILE = preload("res://balance_profile.tres")
var ship: Node2D
var failures := 0
var measurements := {}

func _initialize() -> void:
	run.call_deferred()

func expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func frames(count: int) -> void:
	for frame in count: await physics_frame

func wait_seconds(seconds: float) -> void:
	await frames(int(ceil(seconds * 60)))

func walk(points: Array) -> void:
	for point: Vector2 in points:
		var count := 0
		while ship.player.position.distance_to(point) > 4 and count < 1800 and not ship.state.terminal():
			ship.player.test_direction = (point - ship.player.position).normalized()
			await physics_frame
			count += 1
		ship.player.test_direction = Vector2.ZERO
		expect(count < 1800, "Physical route reaches %s" % point)
	await frames(2)

func work(seconds: float) -> void:
	ship.interact()
	await wait_seconds(seconds)
	ship.stop_work()
	await frames(2)

func power(consumer: String, enabled: bool) -> void:
	ship.systems_panel.open("power")
	expect(ship.can_operate("power"), "Power changes require a local console approach")
	if ship.state.get(consumer + "_powered") != enabled:
		ship.systems_panel.change_power(consumer)
	ship.systems_panel.close()
	expect(ship.state.get(consumer + "_powered") == enabled, "Requested power allocation succeeds: " + consumer)

func to_leak() -> void:
	await walk([Vector2(480, 390), Vector2(480, 840), Vector2(1720, 840), Vector2(1720, 530), Vector2(1910, 530)])

func to_power_from_cargo() -> void:
	await walk([Vector2(1720, 530), Vector2(1720, 840), Vector2(480, 840), Vector2(480, 390), Vector2(612, 390)])

func prepare(imperfect: bool, efficient := false) -> void:
	ship.reset_run()
	ship.toggle_work = true
	await frames(2)
	await walk([Vector2(480, 340), Vector2(1760, 340)])
	ship.interact()
	ship.confirm_salvage()
	if imperfect:
		# Wrong turn toward the closed service shutter, then recover by the corridor.
		await walk([Vector2(1160, 340), Vector2(1720, 340)])
	if efficient:
		# Player-reported route: arm while carrying the motor, before returning to repair.
		await walk([Vector2(1720, 840), Vector2(1800, 840), Vector2(1800, 1300), Vector2(1900, 1300)])
		ship.interact()
		await walk([Vector2(1800, 1300), Vector2(1800, 840), Vector2(1720, 840)])
	await walk([Vector2(1720, 840), Vector2(480, 840), Vector2(480, 400), Vector2(410, 370)])
	if imperfect:
		await work(3)
		var retained: float = ship.state.repair_elapsed
		await walk([Vector2(480, 550), Vector2(410, 370)])
		expect(ship.state.repair_elapsed == retained, "Wrong turn and interrupted pump work preserve progress")
	await work(PROFILE.repair_seconds + 0.1)
	expect(ship.state.repaired, "Physical motor trip repairs the pump")
	if efficient:
		await walk([Vector2(480, 390), Vector2(612, 390)])
		return
	if imperfect:
		await walk([Vector2(480, 390), Vector2(612, 390)])
		power("cooling", false)
	await walk([Vector2(480, 400), Vector2(480, 840), Vector2(1800, 840), Vector2(1800, 1300), Vector2(1900, 1300)])
	ship.interact()
	await walk([Vector2(1800, 1300), Vector2(1800, 840), Vector2(480, 840), Vector2(480, 390), Vector2(612, 390)])
	expect(ship.state.drive_armed, "Local drive arming precedes charging")

func policy(name: String) -> void:
	var imperfect := name == "imperfect"
	var efficient := name == "efficient"
	var aggressive := name in ["aggressive", "aggressive_reserve", "neglect", "efficient"]
	await prepare(imperfect, efficient)
	power("life_support" if aggressive else "cooling", false)
	power("drive", true)
	var cutoff_seen := false
	var patch_air_saved := 0.0
	while not ship.state.terminal() and ship.state.charge < 100 and ship.state.active_seconds < 1200:
		await frames(1)
		if efficient and ship.state.leak_active:
			await to_leak()
			await work(PROFILE.patch_seconds + 0.1)
			await walk([Vector2(1720, 530), Vector2(1720, 840), Vector2(360, 840), Vector2(360, 1260)])
		if name == "aggressive_reserve" and ship.state.air <= PROFILE.air_warning and not ship.state.reserve_used:
			await walk([Vector2(480, 390), Vector2(480, 840), Vector2(1080, 840), Vector2(1080, 1300)])
			ship.systems_panel.open("reserve")
			ship.systems_panel.use_reserve()
			ship.systems_panel.close()
			await walk([Vector2(1080, 840), Vector2(480, 840), Vector2(480, 390), Vector2(612, 390)])
		if aggressive: continue
		if imperfect and not cutoff_seen:
			if not ship.state.drive_cooling_down: continue
			cutoff_seen = true
			ship.state.record("M4 policy: late heat response after cutoff; charge retained.")
			power("cooling", true)
			# A late response still must wait for the heat-gated leak; never patch a future fault.
			await wait_seconds(5)
		elif ship.state.leak_active:
			power("drive", false)
			power("cooling", true)
			if imperfect:
				await walk([Vector2(480, 390), Vector2(480, 840), Vector2(1080, 840), Vector2(1080, 1300)])
				ship.systems_panel.open("reserve")
				ship.systems_panel.use_reserve()
				ship.systems_panel.close()
				await walk([Vector2(1080, 840), Vector2(1720, 840), Vector2(1720, 530), Vector2(1910, 530)])
				await work(3)
				var retained: float = ship.state.patch_elapsed
				await walk([Vector2(1720, 530)])
				await wait_seconds(6)
				await walk([Vector2(1910, 530)])
				expect(ship.state.patch_elapsed == retained, "Interrupted patch survives detour and delay")
			else:
				await to_leak()
			var rate_before: float = ship.state.air_rate()
			await work(PROFILE.patch_seconds + 0.1)
			patch_air_saved = ship.state.air_rate() - rate_before
			await to_power_from_cargo()
		elif ship.state.drive_powered and ship.state.heat >= PROFILE.heat_warning_enter - 4:
			power("drive", false)
			power("cooling", true)
		elif not ship.state.drive_powered and not ship.state.drive_cooling_down and ship.state.heat <= 38:
			power("cooling", false)
			power("drive", true)
	if name == "neglect": await wait_seconds(10)
	if not ship.state.terminal():
		if not efficient:
			power("life_support", true)
			power("cooling", true)
			await walk([Vector2(480, 390), Vector2(480, 840), Vector2(360, 840), Vector2(360, 1260)])
		ship.interact()
		await frames(2)
	if name == "neglect":
		expect(ship.state.failure == "AIR DEPLETED", "Ignoring leak/reserve and delaying escape spends the remaining air")
	else:
		expect(ship.state.escaped and ship.state.scenario.leak_fired, name + " physically reaches the bridge alive")
	if imperfect:
		expect(cutoff_seen and ship.state.reserve_used and ship.state.leak_patched, "Imperfect policy recovers from cutoff, uses reserve and completes interrupted repairs")
	elif not aggressive:
		expect(is_equal_approx(patch_air_saved, PROFILE.leak_drain), "Careful policy sees permanent relief from patching")
	if efficient: expect(ship.state.leak_patched and not ship.state.reserve_used, "Efficient route patches during charging without spending reserve")
	if name == "aggressive_reserve": expect(ship.state.reserve_used, "Aggressive reserve detour buys margin")
	measurements[name] = {"snapshot": ship.state.snapshot(), "events": ship.state.events.duplicate(true)}
	print("M4_PHYSICAL %s: %.2fs air %.2f heat %.2f" % [name, ship.state.active_seconds, ship.state.air, ship.state.heat])

func critical_recovery(grace: float, notice := 5.0) -> Dictionary:
	# Explicit threshold fixture; setup is excluded from full-run evidence above.
	ship.reset_run()
	ship.state.profile = PROFILE.duplicate()
	ship.state.profile.critical_grace_seconds = grace
	ship.state.salvage()
	ship.state.advance(PROFILE.repair_seconds, true, true, false, PROFILE.repair_seconds)
	ship.state.cooling_powered = false
	ship.state.heat = PROFILE.critical_enter
	ship.state.critical = true
	ship.state.drive_cooling_down = true
	ship.player.position = Vector2(1900, 1300)
	await frames(2)
	var started: float = ship.state.active_seconds
	await wait_seconds(notice)
	await walk([Vector2(1800, 1300), Vector2(1800, 840), Vector2(480, 840), Vector2(480, 390), Vector2(612, 390)])
	var travel: float = ship.state.active_seconds - started - notice
	power("cooling", true)
	while ship.state.critical and not ship.state.terminal(): await frames(1)
	return {"grace": grace, "travel_seconds": travel, "response_seconds": ship.state.active_seconds - started,
		"recovered": not ship.state.critical and not ship.state.terminal(), "snapshot": ship.state.snapshot()}

func check_reports() -> void:
	ship.reset_run()
	await frames(2)
	var report = ship.playtest_report
	await wait_seconds(6)
	expect(report.samples.size() >= 2, "Active play records periodic resource and location samples")
	ship.toggle_pause()
	var count: int = report.samples.size()
	await wait_seconds(6)
	expect(report.samples.size() == count, "Pause never manufactures active-time samples")
	var directory := "user://m4-report-test"
	var path: String = report.save(ship.state, ship.profile, directory)
	expect(not path.is_empty(), "Local report can be saved while paused")
	if not path.is_empty():
		var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
		expect(saved is Dictionary and saved["profile"] == PROFILE.profile_id and saved["tuning"]["critical_grace_seconds"] == PROFILE.critical_grace_seconds, "Report round trip preserves exact candidate tuning")
		expect(saved["events"].back()["event"] == "Paused." and not saved["developer_setup"] and saved["snapshot"]["stage"] == "EMERGENCY", "Report distinguishes ordinary play and retains actual state/events")
		DirAccess.remove_absolute(path)
	ship.reset_run()
	expect(ship.playtest_report.filename != report.filename and ship.playtest_report.samples.is_empty(), "Retry creates a separate report without stale samples")
	ship.playtest_report.developer_setup = true
	expect(ship.playtest_report.document(ship.state, ship.profile)["developer_setup"], "Developer-prepared runs identify themselves")
	ship.state.air = PROFILE.air_warning
	ship.state.leak_active = true
	ship.state.charge = 100
	expect(ship.hud.warning_text().contains("Bridge") and not ship.hud.warning_text().contains("patch"), "Low air with full charge points to escape instead of a Cargo detour")
	ship.state.charge = 99
	expect(ship.hud.warning_text().contains("patch"), "Before full charge the open leak remains an actionable air warning")
	ship.state.critical = true
	expect(ship.hud.warning_text().begins_with("CRITICAL HEAT"), "Critical countdown remains visible above low-air guidance")

func reported_route(config: Resource) -> Dictionary:
	# Rounded command times from the supplied 0.4.0 report, not a new human run.
	# This simulation replay has no movement claims; the efficient policy above walks the route.
	var state = Run.new(config, false)
	state.work_target = ""
	for command in [[15.50, "salvage"], [23.70, "arm"], [36.88, "pump_start"], [42.88, "pump_end"],
		[48.20, "air_off"], [48.78, "drive_on"], [98.18, "patch_start"], [106.18, "patch_end"], [169.22, "jump"]]:
		var working: bool = state.work_target in ["pump", "leak"]
		state.advance(command[0] - state.active_seconds, working, working, false, config.repair_seconds)
		match command[1]:
			"salvage": state.salvage()
			"arm": state.arm_drive()
			"pump_start": state.work_target = "pump"
			"pump_end": state.work_target = ""
			"air_off": state.set_power("life_support", false)
			"drive_on": state.set_power("drive", true)
			"patch_start": state.work_target = "leak"
			"patch_end": state.work_target = ""
			"jump": state.request_jump()
	state.advance(Run.STEP, false, false, false, config.repair_seconds)
	return {"snapshot": state.snapshot(), "events": state.events.duplicate(true)}

func check_reported_route() -> void:
	var baseline := PROFILE.duplicate()
	baseline.profile_id = "m4-candidate-01"
	baseline.powered_air_drain = 0.08
	baseline.unpowered_air_drain = 0.22
	baseline.charging_heat_rate = 0.35
	baseline.air_warning = 25
	baseline.heat_warning_enter = 68
	baseline.heat_warning_clear = 62
	var before := reported_route(baseline)
	var after := reported_route(PROFILE)
	measurements["reported_timing_baseline"] = before
	measurements["reported_timing_candidate"] = after
	expect(before.snapshot.escaped and absf(before.snapshot.air - 64.1362) < 0.1 and absf(before.snapshot.heat - 43.8605) < 0.1, "Rounded timing replay reproduces the supplied report's outcome")
	expect(after.snapshot.escaped and after.snapshot.leak_patched and not after.snapshot.reserve_used, "Efficient reported decisions still escape with permanent repairs")
	expect(after.snapshot.air < before.snapshot.air - 25 and after.snapshot.heat > before.snapshot.heat + 25, "Same reported decisions now spend substantially more air and heat margin")
	expect(PROFILE.air_warning / (PROFILE.unpowered_air_drain + PROFILE.leak_drain) >= 2 * (12.83 + PROFILE.patch_seconds), "Earlier air warning preserves the measured response allowance at the faster drain")
	expect((PROFILE.drive_cutoff - PROFILE.heat_warning_enter) / (PROFILE.idle_heat_rate + PROFILE.charging_heat_rate) >= 2 * (13.6334 + 1), "Earlier heat warning allows the distant return and a console action before cutoff")
	print("M4_REPORTED_TIMING baseline air %.2f heat %.2f; candidate air %.2f heat %.2f" % [before.snapshot.air, before.snapshot.heat, after.snapshot.air, after.snapshot.heat])

func run() -> void:
	ship = load("res://scenes/ship.tscn").instantiate()
	root.add_child(ship)
	await frames(2)
	for name in ["careful", "aggressive", "aggressive_reserve", "imperfect", "efficient", "neglect"]: await policy(name)
	measurements["critical_30"] = await critical_recovery(30)
	measurements["critical_candidate"] = await critical_recovery(PROFILE.critical_grace_seconds)
	measurements["critical_direct"] = await critical_recovery(PROFILE.critical_grace_seconds, 0)
	expect(not measurements["critical_30"]["recovered"] and measurements["critical_candidate"]["recovered"], "Candidate recovers after distant late response that the old grace window cannot cover")
	expect(PROFILE.critical_grace_seconds >= 2 * measurements["critical_direct"]["response_seconds"], "Critical grace covers twice the measured direct travel and cooling response")
	print("M4_CRITICAL ", JSON.stringify(measurements["critical_candidate"]))
	await check_reports()
	check_reported_route()
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../builds/m4-physical-runs.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": PROFILE.profile_id, "method": "Six physical policies use CharacterBody2D traversal at 60 Hz; critical tests use explicit fixtures; reported_timing entries replay commands without movement", "runs": measurements}, "\t"))
	file.close()
	ship.queue_free()
	await process_frame
	if failures == 0: print("LAST_SHIFT_M4_PASS: six physical policies, measured critical recovery, local reports and supplied timing replay")
	quit(1 if failures else 0)
