extends SceneTree
const Run = preload("res://scripts/run_controller.gd")
const Layout = preload("res://scripts/layout.gd")
const PROFILE = preload("res://balance_profile.tres")
var failures := 0
var ship: Node2D

func expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func tick(state, seconds: float, task := "", in_range := true) -> void:
	state.work_target = task
	state.advance(seconds, not task.is_empty(), in_range, false, PROFILE.repair_seconds)

func prepared():
	var state = Run.new(PROFILE, false)
	state.salvage()
	tick(state, PROFILE.repair_seconds, "pump")
	state.arm_drive()
	return state

func count_events(state, prefix: String) -> int:
	var count := 0
	for entry in state.events:
		if entry["event"].begins_with(prefix): count += 1
	return count

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	check_opening()
	check_incidents_and_patch()
	check_outcomes()
	check_cadence()
	await check_scene()
	var careful := scripted_run(true)
	var aggressive := scripted_run(false)
	expect(careful["leak_patched"] and not aggressive["leak_patched"], "Patch and endure policies both exercise the authored leak")
	var path := ProjectSettings.globalize_path("res://../builds/m3-scripted-runs.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"profile": PROFILE.profile_id, "careful": careful, "aggressive": aggressive, "method": "Emergency-start simulation with route allowances; not human balance evidence"}, "\t"))
	file.close()
	if failures == 0: print("LAST_SHIFT_M3_PASS: safe opening, ordered transition, one-shot gates, retained patch, deterministic outcomes, local controls, retry and two complete scripted runs")
	quit(1 if failures else 0)

func check_opening() -> void:
	var state = Run.new(PROFILE)
	tick(state, 600)
	expect(state.stage == Run.Stage.OPENING and state.air == 100 and state.heat == PROFILE.starting_heat and state.active_seconds == 0, "Slow checklist never starts lethal clocks or incidents")
	expect(state.repaired and state.cooling_active() and not state.salvage() and state.arm_drive() != "" and state.use_reserve() != "", "Functioning opening cannot consume emergency tools")
	expect(state.set_power("cooling", false) != "", "Power lesson waits for connector")
	tick(state, 2, "connector")
	var retained: float = state.connector_elapsed
	tick(state, 20, "connector", false)
	expect(state.connector_elapsed == retained, "Leaving connector preserves work")
	state.is_paused = true
	var frozen: Dictionary = state.snapshot()
	tick(state, 10, "connector")
	expect(state.snapshot() == frozen, "Pause freezes opening and work")
	state.is_paused = false
	tick(state, 2, "connector")
	expect(state.connector_ready and state.set_power("drive", true) != "", "Safe lesson cannot enable drive")
	state.set_power("cooling", false)
	expect(state.stage == Run.Stage.OPENING, "Power lesson requires restoring cooling")
	state.set_power("cooling", true)
	expect(state.stage == Run.Stage.TRANSITION, "Completed checklist starts jump failure")
	tick(state, 1)
	state.is_paused = true
	frozen = state.snapshot()
	tick(state, 100)
	expect(state.snapshot() == frozen, "Pause freezes announcement clock")
	state.is_paused = false
	tick(state, 7)
	var announcements: Array[String] = []
	for entry in state.events:
		if entry["event"] in Run.ANNOUNCEMENTS: announcements.append(entry["event"])
	expect(announcements == Array(Run.ANNOUNCEMENTS), "Evacuation, dead pod and one life sign appear in exact order once")
	expect(state.stage == Run.Stage.EMERGENCY and not state.repaired and state.air == 100 and state.active_seconds == 0, "Emergency starts after transition without consuming response time")
	state.begin_emergency()
	expect(count_events(state, "GET HOME") == 1, "Coolant fault fires once")

func check_incidents_and_patch() -> void:
	var state = prepared()
	state.charge = PROFILE.leak_charge_gate
	tick(state, PROFILE.recovery_seconds - 1)
	expect(not state.scenario.leak_warned, "Repair provides the full recovery interval")
	state.charge = PROFILE.leak_charge_gate - 1
	tick(state, 2)
	expect(not state.scenario.leak_warned, "Recovery time alone cannot bypass charge gate")
	state.charge = PROFILE.leak_charge_gate
	state.heat = PROFILE.heat_warning_enter
	state.set_power("cooling", false)
	tick(state, 1)
	expect(not state.scenario.leak_warned, "High heat delays leak eligibility")
	state.heat = PROFILE.heat_warning_clear - 1
	state.set_power("cooling", true)
	tick(state, Run.STEP)
	expect(state.scenario.leak_warned and not state.leak_active, "Eligible state first gives leak warning")
	state.is_paused = true
	var frozen: Dictionary = state.snapshot()
	tick(state, 30)
	expect(state.snapshot() == frozen, "Pause freezes incident lead-in")
	state.is_paused = false
	tick(state, PROFILE.leak_warning_seconds - 0.1)
	expect(not state.leak_active, "Warning precedes leak onset")
	state.heat = PROFILE.heat_warning_enter + 1
	state.set_power("cooling", false)
	tick(state, 2)
	expect(not state.leak_active, "Onset rechecks safe-heat prerequisite")
	state.heat = PROFILE.heat_warning_clear - 1
	state.set_power("cooling", true)
	tick(state, Run.STEP)
	expect(state.leak_active and is_equal_approx(state.air_rate(), -PROFILE.powered_air_drain - PROFILE.leak_drain), "One leak adds the documented drain")
	tick(state, 3, "leak")
	var progress: float = state.patch_elapsed
	tick(state, 1, "leak", false)
	expect(state.patch_elapsed == progress, "Interrupted patch retains progress")
	state.is_paused = true
	tick(state, 10, "leak")
	expect(state.patch_elapsed == progress, "Paused patch cannot advance")
	state.is_paused = false
	var air_before: float = state.air
	tick(state, PROFILE.patch_seconds - 3, "leak")
	expect(state.leak_patched and not state.leak_active and is_equal_approx(state.air_rate(), -PROFILE.powered_air_drain), "Patch permanently removes only additional drain")
	expect(state.air < air_before and state.motor == Run.Motor.INSTALLED and state.repaired, "Patch neither refills air nor consumes another component")
	state.begin_emergency()
	state.charge = PROFILE.final_push_charge
	tick(state, 80, "leak")
	expect(count_events(state, "HULL LEAK") == 1 and count_events(state, "HULL SEALED") == 1 and count_events(state, "FINAL PUSH") == 1, "Incidents, patch and final push cannot repeat")
	expect(state.repaired and state.leak_patched, "Completed repairs never regress")

func check_outcomes() -> void:
	for cause in ["AIR DEPLETED", "CRITICAL HEAT"]:
		var state = prepared()
		state.charge = 100
		if cause == "AIR DEPLETED": state.air = 0.00001
		else:
			state.heat = PROFILE.critical_enter
			state.critical = true
			state.critical_elapsed = PROFILE.critical_grace_seconds - Run.STEP / 2
			state.set_power("cooling", false)
		state.request_jump()
		tick(state, Run.STEP)
		expect(state.failure == cause and state.stage == Run.Stage.LOST and not state.escaped, "Terminal %s wins over same-tick bridge request" % cause)
		var stopped: Dictionary = state.snapshot()
		tick(state, 100)
		state.stop_simulation(cause)
		expect(state.snapshot() == stopped and count_events(state, "SHIFT ENDED") == 1, "Loss fires once and freezes all clocks")
	var state = prepared()
	expect(not state.request_jump().begins_with("Jump requested"), "Bridge rejects incomplete charge")
	state.charge = 100
	state.request_jump()
	state.is_paused = true
	tick(state, 10)
	expect(not state.escaped, "Queued jump cannot execute while paused")
	state.is_paused = false
	tick(state, Run.STEP)
	expect(state.escaped and state.stage == Run.Stage.WON and state.air_rate() == 0 and state.heat_rate() == 0, "Successful bridge jump stops survival simulation")
	var stopped: Dictionary = state.snapshot()
	tick(state, 100)
	expect(state.snapshot() == stopped and count_events(state, "SHIFT COMPLETE") == 1 and state.set_power("life_support", false) != "", "Victory cannot repeat or mutate resources")
	var lost = prepared()
	lost.leak_patched = true
	lost.reserve_used = true
	lost.stop_simulation("AIR DEPLETED")
	expect(not lost.recovery_advice().contains("unused") and not lost.recovery_advice().contains("still open"), "Loss advice never blames completed actions")

func check_cadence() -> void:
	var reference = prepared()
	reference.charge = 30
	tick(reference, 60)
	for fps in [30, 120, 144]:
		var state = prepared()
		state.charge = 30
		for frame in fps * 60: tick(state, 1.0 / fps)
		expect(state.snapshot() == reference.snapshot(), "Scenario and resource clocks agree at %d Hz" % fps)

func press(key: Key, down := true) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tap(key: Key) -> void:
	press(key)
	press(key, false)

func frames(count: int) -> void:
	for frame in count: await physics_frame

func walk_to(point: Vector2) -> int:
	var count := 0
	while ship.player.position.distance_to(point) > 4 and count < 1500:
		ship.player.test_direction = (point - ship.player.position).normalized()
		await physics_frame
		count += 1
	ship.player.test_direction = Vector2.ZERO
	expect(count < 1500, "Physical M3 route reaches %s" % point)
	return count

func check_scene() -> void:
	ship = load("res://scenes/ship.tscn").instantiate()
	root.add_child(ship)
	await frames(2)
	expect(ship.state.stage == Run.Stage.OPENING, "Player launch starts at the ordinary checklist")
	ship.player.position = Layout.CONNECTOR + Vector2(0, 70)
	await frames(2)
	press(KEY_E)
	await frames(120)
	press(KEY_E, false)
	await frames(2)
	expect(ship.state.connector_elapsed > 1.9 and ship.state.connector_elapsed < 2.1, "Connector uses held local work input")
	tap(KEY_T)
	tap(KEY_E)
	await frames(122)
	expect(ship.state.connector_ready, "Toggle mode resumes and completes connector")
	ship.player.position = Layout.POWER + Vector2(0, 80)
	await frames(2)
	tap(KEY_E)
	ship.systems_panel.change_power("cooling")
	ship.systems_panel.change_power("cooling")
	await frames(2)
	expect(ship.state.stage == Run.Stage.TRANSITION and ship.player.frozen and not ship.systems_panel.visible, "Checklist closes panel and gives ordered transition")
	tap(KEY_ESCAPE)
	var seconds: float = ship.state.transition_seconds
	await frames(60)
	expect(ship.state.transition_seconds == seconds, "Scene pause freezes transition")
	tap(KEY_ESCAPE)
	await frames(490)
	expect(ship.state.stage == Run.Stage.EMERGENCY and not ship.player.frozen, "Control returns to emergency without stale panel state")
	tap(KEY_F7)
	await frames(2)
	expect(ship.state.leak_active, "Developer leak beat uses scenario progression")
	ship.player.position = Layout.POWER + Vector2(0, 80)
	var route := 0
	for point in [Vector2(480, 390), Vector2(480, 840), Vector2(1720, 840), Vector2(1720, 530), Vector2(1910, 530)]:
		route += await walk_to(point)
	print("M3_MEASURE power-to-leak permanent route: %.2fs" % (route / 60.0))
	expect(ship.select_target() == "leak", "Leak is reachable after salvage closes shortcut")
	tap(KEY_E)
	await frames(120)
	tap(KEY_E)
	var retained: float = ship.state.patch_elapsed
	await frames(30)
	expect(retained > 1.9 and retained < 2.1 and ship.state.patch_elapsed == retained, "Local patch can stop with retained progress")
	tap(KEY_E)
	await frames(365)
	expect(ship.state.leak_patched and ship.state.repaired, "Built-in tool completes permanent patch")
	ship.state.charge = 100
	tap(KEY_E)
	expect(not ship.state.jump_requested, "Jump cannot be requested from Cargo")
	ship.player.position = Layout.BRIDGE
	await frames(2)
	tap(KEY_E)
	await frames(3)
	expect(ship.state.escaped and ship.results_panel.visible and ship.results_panel.heading.text == "SHIFT COMPLETE", "Local bridge jump opens victory results")
	expect(not ship.feedback.pump.playing and not ship.feedback.music.playing, "Ending stops looping audio")
	ship.results_panel.retry.pressed.emit()
	await frames(2)
	expect(ship.state.stage == Run.Stage.EMERGENCY and not ship.state.leak_active and not ship.state.scenario.leak_warned and not ship.state.repaired and ship.state.charge == 0 and not ship.state.reserve_used, "Default retry resets run and incidents at emergency")
	expect(not ship.results_panel.visible and not ship.player.frozen and ship.gate_collision.disabled, "Retry restores UI, controls and shortcut")
	for cause in ["AIR DEPLETED", "CRITICAL HEAT"]:
		if cause == "AIR DEPLETED": ship.state.air = 0
		else:
			ship.state.heat = 100
			ship.state.critical = true
			ship.state.critical_elapsed = PROFILE.critical_grace_seconds
		await frames(3)
		expect(ship.results_panel.visible and ship.results_panel.heading.text.contains(cause), "Results identify %s" % cause)
		ship.results_panel.retry.pressed.emit()
		await frames(2)
	ship.reset_run(true)
	await frames(2)
	expect(ship.state.stage == Run.Stage.OPENING and not ship.state.connector_ready and not ship.state.power_practiced and ship.state.repaired and not ship.results_panel.visible, "Replay opening resets checklist and functioning ship")
	ship.queue_free()
	await process_frame

func scripted_run(patch: bool) -> Dictionary:
	var state = Run.new(PROFILE, false)
	tick(state, 8.70 + 10)
	state.salvage()
	tick(state, 13.17)
	tick(state, PROFILE.repair_seconds, "pump")
	tick(state, 16)
	state.arm_drive()
	tick(state, 16)
	state.set_power("cooling" if patch else "life_support", false)
	state.set_power("drive", true)
	while state.charge < 100 and not state.terminal() and state.active_seconds < 1000:
		tick(state, Run.STEP)
		if patch and state.leak_active:
			state.set_power("drive", false)
			state.set_power("cooling", true)
			tick(state, 14)
			tick(state, PROFILE.patch_seconds, "leak")
			tick(state, 14)
			state.set_power("cooling", false)
			state.set_power("drive", true)
		elif patch:
			if state.drive_powered and state.heat >= PROFILE.heat_warning_enter - 4:
				state.set_power("drive", false)
				state.set_power("cooling", true)
			elif not state.drive_powered and state.heat <= 38:
				state.set_power("cooling", false)
				state.set_power("drive", true)
	state.set_power("life_support", true)
	state.set_power("cooling", true)
	tick(state, 12)
	state.request_jump()
	tick(state, Run.STEP)
	expect(state.escaped and state.scenario.leak_fired and state.scenario.final_push, "Complete %s policy escapes after authored events" % ("patch" if patch else "endure"))
	print("M3_RUN %s: %.2fs, air %.2f, heat %.2f, escaped %s" % ["patch" if patch else "endure", state.active_seconds, state.air, state.heat, str(state.escaped)])
	return state.snapshot()
