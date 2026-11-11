extends SceneTree
const Simulation = preload("res://scripts/ship_simulation.gd")
const Run = preload("res://scripts/run_controller.gd")
const Layout = preload("res://scripts/layout.gd")
const PROFILE = preload("res://balance_profile.tres")
var failures := 0
var ship: Node2D

func expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func tick(state, seconds: float, work := false) -> void:
	if work and state is Run: state.work_target = "pump"
	state.advance(seconds, work, work, false, state.profile.repair_seconds)

func prepared():
	var state = Simulation.new(PROFILE)
	state.salvage()
	tick(state, PROFILE.repair_seconds, true)
	expect(state.repaired, "Six accumulated seconds completes repair at fixed step")
	state.arm_drive()
	return state

func charging_state():
	var state = prepared()
	state.set_power("life_support", false)
	state.set_power("drive", true)
	return state

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	check_power_and_progress()
	check_cadence()
	check_reserve()
	check_heat_and_terminal_order()
	await check_scene_controls()
	var careful := scripted_run(false)
	var aggressive := scripted_run(true)
	expect(aggressive["seconds"] < careful["seconds"], "Aggressive uninterrupted charging is faster in this candidate")
	expect(aggressive["air"] < careful["air"], "Faster candidate spends more air margin")
	var results := {"profile": PROFILE.profile_id, "careful": careful, "aggressive": aggressive,
		"method": "Fixed-step simulation with measured route allowances; not human balance evidence"}
	var path := ProjectSettings.globalize_path("res://../builds/m2-scripted-runs.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	if failures == 0:
		print("LAST_SHIFT_M2_PASS: accounting, cadence, retained charge/repair, reserve, thresholds, terminal ordering, local controls, pause/reset and scripted approaches")
	quit(1 if failures else 0)

func check_power_and_progress() -> void:
	var state = Simulation.new(PROFILE)
	expect(state.used_power() == 4, "Opening allocates life support and broken cooling only")
	state.arm_drive()
	expect(not state.set_power("drive", true).is_empty(), "Repair interlock rejects charging")
	expect(state.used_power() == 4 and not state.drive_powered, "Rejected interlock preserves allocation")
	state.salvage()
	tick(state, 2, true)
	state.drop_at(Layout.SPAWN, true)
	tick(state, 1, true)
	expect(is_equal_approx(state.repair_elapsed, 2.0), "M2 cannot work without motor")
	state.pick_up()
	tick(state, 4, true)
	expect(state.repaired and state.cooling_active(), "Repair restores powered cooling permanently")
	var allocation := state.used_power()
	expect(not state.set_power("drive", true).is_empty(), "Capacity rejects eight-unit allocation")
	expect(state.used_power() == allocation and state.life_support_powered and state.cooling_powered, "Rejection never silently changes other consumers")
	expect(state.set_power("unknown", true) != "", "Unknown consumer rejected")
	state.set_power("life_support", false)
	expect(state.set_power("drive", true).is_empty() and state.used_power() == 6, "Explicit tradeoff enables drive")
	tick(state, 20)
	expect(state.charge > 0 and state.heat_rate() > 0, "Charging adds heat even with cooling")
	var retained: float = state.charge
	state.set_power("drive", false)
	state.set_power("life_support", true)
	var heat_before: float = state.heat
	var air_before: float = state.air
	tick(state, 20)
	expect(state.charge == retained and state.heat < heat_before and state.air < air_before, "Paused charging retains progress; repaired cooling gives real relief; air stays finite")
	state.set_power("cooling", false)
	expect(state.repaired and not state.cooling_active() and state.pump_status() == "OFF / REPAIRED", "Power-off does not undo repair")
	# Pause preserves the sub-step remainder as well as every clock/resource.
	tick(state, Simulation.STEP / 2)
	state.is_paused = true
	var before: Dictionary = state.snapshot()
	var remainder: float = state.accumulator
	tick(state, 100, true)
	expect(state.set_power("cooling", true) != "" and state.arm_drive() != "" and state.use_reserve() != "", "Paused equipment commands rejected")
	expect(not state.salvage() and not state.drop_at(Layout.SPAWN, true), "Pause rejects motor commands")
	expect(state.snapshot() == before and state.accumulator == remainder, "Pause freezes all simulation clocks and values")
	state.is_paused = false
	tick(state, Simulation.STEP / 2)
	expect(state.active_seconds > before["seconds"], "Resume consumes retained fractional time")
	var full = charging_state()
	full.charge = 99.999
	tick(full, Simulation.STEP)
	expect(full.charge == 100 and not full.drive_powered and full.used_power() == 2, "Full charge releases only drive demand")
	var full_air: float = full.air
	tick(full, 5)
	expect(full.charge == 100 and full.air < full_air and full.escape_ready(), "Full charge stays while survival pressure continues")
	expect(full.set_power("drive", true) != "", "Full drive cannot consume power again")

func check_cadence() -> void:
	var reference = charging_state()
	tick(reference, 60)
	for fps in [30, 60, 120, 144]:
		var state = charging_state()
		for frame in fps * 60:
			tick(state, 1.0 / fps)
		for field in ["air", "heat", "charge", "active_seconds"]:
			expect(is_equal_approx(state.get(field), reference.get(field)), "%s agrees at %d Hz" % [field, fps])
	var irregular = charging_state()
	for frame in 200:
		for delta in [0.007, 0.023, 0.27]: tick(irregular, delta)
	for field in ["air", "heat", "charge", "active_seconds"]:
		expect(is_equal_approx(irregular.get(field), reference.get(field)), "Irregular cadence preserves %s" % field)
	var snapshot: Dictionary = irregular.snapshot()
	for delta in [-1.0, 0.0, INF, NAN]: tick(irregular, delta)
	expect(irregular.snapshot() == snapshot, "Invalid deltas do not corrupt state")

func check_reserve() -> void:
	var state = Simulation.new(PROFILE)
	expect(state.reserve_gain() == 0 and state.use_reserve() != "" and not state.reserve_used, "Full air does not waste reserve")
	state.air = 98
	var gain: float = state.reserve_gain()
	expect(gain == 2 and state.use_reserve().is_empty() and state.air == 100, "Reserve preview equals capped actual gain")
	expect(state.reserve_used and state.reserve_gain() == 0 and state.use_reserve() != "", "Reserve consumed once")
	tick(state, 100)
	expect(state.air < 100 and state.reserve_gain() == 0, "Reserve does not refill after use")

func check_heat_and_terminal_order() -> void:
	var state = charging_state()
	state.heat = PROFILE.heat_warning_enter
	tick(state, Simulation.STEP)
	expect(state.heat_warning, "Warning enters at configured threshold")
	state.set_power("drive", false)
	state.heat = PROFILE.heat_warning_clear + 1
	tick(state, Simulation.STEP)
	expect(state.heat_warning, "Warning hysteresis prevents flicker")
	state.heat = PROFILE.heat_warning_clear
	tick(state, Simulation.STEP)
	expect(not state.heat_warning, "Warning clears after visible recovery")
	state.set_power("drive", true)
	state.heat = PROFILE.drive_cutoff
	var retained: float = state.charge
	tick(state, Simulation.STEP)
	expect(state.drive_cooling_down and not state.drive_powered and state.cooling_powered, "Cutoff releases drive only")
	expect(state.charge >= retained and state.repaired, "Cutoff never resets charge or repair")
	retained = state.charge
	state.heat = PROFILE.drive_restart + 0.02
	tick(state, Simulation.STEP)
	expect(state.drive_cooling_down and state.set_power("drive", true) != "", "Cooldown blocks premature reassignment")
	state.heat = PROFILE.drive_restart - 0.02
	tick(state, Simulation.STEP)
	expect(not state.drive_cooling_down and not state.drive_powered and state.charge == retained, "Restart threshold restores availability without automatic power draw")
	expect(state.set_power("drive", true).is_empty(), "Explicit reassignment resumes drive")
	var hot = prepared()
	hot.set_power("cooling", false)
	hot.heat = PROFILE.critical_enter
	tick(hot, 10)
	expect(hot.critical and hot.critical_elapsed > 9, "Critical heat starts visible grace")
	hot.is_paused = true
	var grace: float = hot.critical_elapsed
	tick(hot, 100)
	expect(hot.critical_elapsed == grace and hot.failure.is_empty(), "Pause freezes critical grace")
	hot.is_paused = false
	hot.heat = PROFILE.critical_clear - 0.1
	tick(hot, Simulation.STEP)
	expect(not hot.critical and hot.critical_elapsed == 0, "Critical recovery resets grace")
	hot.heat = PROFILE.critical_enter
	tick(hot, PROFILE.critical_grace_seconds)
	expect(hot.failure == "CRITICAL HEAT", "Sustained critical heat stops simulation")
	var event_count: int = hot.events.size()
	var stopped: Dictionary = hot.snapshot()
	tick(hot, 100)
	expect(hot.snapshot() == stopped and hot.events.size() == event_count, "Failure freezes clocks and fires once")
	expect(hot.use_reserve() != "" and hot.arm_drive() != "", "Terminal state rejects resource commands")
	var depleted = charging_state()
	depleted.air = 0.0001
	depleted.charge = 99.999
	tick(depleted, Simulation.STEP)
	expect(depleted.air == 0 and depleted.failure == "AIR DEPLETED" and depleted.charge < 100 and not depleted.escape_ready(), "Air failure wins over charge completion in the same tick")

func send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func press(key: Key) -> void:
	send_key(key, true)
	send_key(key, false)

func frames(count: int) -> void:
	for frame in count: await physics_frame

func walk_to(point: Vector2) -> int:
	var count := 0
	while ship.player.position.distance_to(point) > 4 and count < 1500:
		ship.player.test_direction = (point - ship.player.position).normalized()
		await physics_frame
		count += 1
	ship.player.test_direction = Vector2.ZERO
	expect(count < 1500, "M2 physical route reached %s" % point)
	return count

func check_scene_controls() -> void:
	ship = load("res://scenes/ship.tscn").instantiate()
	root.add_child(ship)
	ship.reset_run()
	await frames(2)
	ship.state.salvage()
	tick(ship.state, PROFILE.repair_seconds, true)
	ship.player.position = Layout.POWER + Vector2(0, 80)
	await frames(2)
	press(KEY_E)
	await frames(2)
	expect(ship.systems_panel.visible and ship.player.frozen, "E opens local console and freezes movement")
	ship.systems_panel.use_reserve()
	expect(not ship.state.reserve_used, "Power console cannot remotely consume the reserve")
	ship.player.position = Layout.SPAWN
	ship.systems_panel.change_power("life_support")
	expect(ship.state.life_support_powered, "Out-of-range console callback cannot change power")
	ship.player.position = Layout.POWER + Vector2(0, 80)
	ship.systems_panel.change_power("cooling")
	await frames(2)
	expect(ship.state.repaired and not ship.feedback.pump.playing, "Unpowered repaired pump stops its machinery hum")
	ship.systems_panel.change_power("cooling")
	await frames(2)
	expect(ship.feedback.pump.playing, "Restored cooling power restarts machinery hum")
	ship.systems_panel.change_power("drive")
	expect(not ship.state.drive_powered and ship.systems_panel.response.text.contains("Arm"), "Console displays local-arm rejection")
	press(KEY_ESCAPE)
	await frames(2)
	var route_ticks := 0
	for point in [Vector2(480, 390), Vector2(480, 840), Vector2(1800, 840), Vector2(1800, 1300), Vector2(1900, 1300)]:
		route_ticks += await walk_to(point)
	print("M2_MEASURE power-to-drive: %.2fs" % [route_ticks / 60.0])
	expect(ship.select_target() == "drive", "Permanent route reaches local drive panel")
	press(KEY_E)
	expect(ship.state.drive_armed and not ship.state.drive_powered, "Local panel arms without silently allocating power")
	var arm_events: int = ship.state.events.size()
	press(KEY_E)
	expect(ship.state.drive_armed and ship.state.events.size() == arm_events, "Repeated interaction keeps the switch armed without another activation event")
	route_ticks = 0
	for point in [Vector2(1800, 1300), Vector2(1800, 840), Vector2(480, 840), Vector2(480, 390), Vector2(612, 390)]:
		route_ticks += await walk_to(point)
	print("M2_MEASURE drive-to-power: %.2fs" % [route_ticks / 60.0])
	press(KEY_E)
	ship.systems_panel.change_power("drive")
	expect(ship.systems_panel.response.text.contains("Capacity") and ship.state.used_power() == 4, "Console clearly rejects over-capacity request")
	ship.systems_panel.change_power("life_support")
	ship.systems_panel.change_power("drive")
	var before: float = ship.state.charge
	await frames(60)
	expect(ship.state.charge > before and ship.systems_panel.summary.text.contains("CHARGE"), "Console stays live while simulation runs")
	press(KEY_ESCAPE)
	press(KEY_ESCAPE)
	await frames(2)
	var paused: Dictionary = ship.state.snapshot()
	await frames(60)
	expect(ship.paused and ship.player.frozen and ship.state.snapshot() == paused, "Escape pause freezes resources, clock and player")
	press(KEY_ESCAPE)
	ship.player.position = Layout.RESERVE
	await frames(2)
	press(KEY_E)
	expect(ship.systems_panel.visible and ship.systems_panel.mode == "reserve", "Reserve opens only at local station")
	ship.systems_panel.use_reserve()
	expect(ship.state.reserve_used and ship.systems_panel.reserve_button.disabled, "Reserve feedback and button reflect single use")
	ship.reset_run()
	await frames(2)
	expect(ship.state.charge == 0 and not ship.state.drive_armed and not ship.state.reserve_used and not ship.state.repaired, "Restart clears all M2 progress")
	expect(ship.state.used_power() == 4 and not ship.systems_panel.visible and not ship.paused and not ship.feedback.pump.playing, "Restart restores allocation, menus, controls and machinery")
	ship.state.stop_simulation("AIR DEPLETED")
	await frames(2)
	press(KEY_ESCAPE)
	expect(ship.results_panel.visible, "Terminal simulation presents the retry screen")
	ship.reset_run()
	await frames(2)
	expect(ship.state.failure.is_empty() and not ship.player.frozen, "Restart recovers from terminal stop")
	ship.queue_free()
	await process_frame

func scripted_run(aggressive: bool) -> Dictionary:
	var state = Simulation.new(PROFILE)
	# Measured M1 travel plus a deliberate ten-second reading/decision allowance.
	tick(state, 8.70 + 10.0)
	state.salvage()
	tick(state, 13.17)
	tick(state, PROFILE.repair_seconds, true)
	# Conservative round-up of the measured panel journeys including positioning.
	tick(state, 16.0)
	state.arm_drive()
	tick(state, 16.0)
	if aggressive:
		state.set_power("life_support", false)
		state.set_power("drive", true)
	else:
		state.set_power("cooling", false)
		state.set_power("drive", true)
	var recovery_intervals := 0
	while state.charge < 100 and state.failure.is_empty() and state.active_seconds < 1200:
		tick(state, Simulation.STEP)
		if not aggressive:
			if state.drive_powered and state.heat >= PROFILE.heat_warning_enter - 4:
				state.set_power("drive", false)
				state.set_power("cooling", true)
				recovery_intervals += 1
			elif not state.drive_powered and state.heat <= 38:
				state.set_power("cooling", false)
				state.set_power("drive", true)
	# Full charge releases demand; restore both survival consumers for bridge travel.
	state.set_power("life_support", true)
	state.set_power("cooling", true)
	tick(state, 12.0)
	expect(state.escape_ready() and state.failure.is_empty(), "Scripted %s approach remains alive and full at bridge" % ("aggressive" if aggressive else "careful"))
	var result: Dictionary = state.snapshot()
	result["recovery_intervals"] = recovery_intervals
	result["route_allowances_seconds"] = 8.70 + 10.0 + 13.17 + 16.0 + 16.0 + 12.0
	print("M2_RUN %s: %.2fs, air %.2f, heat %.2f, charge %.2f, recoveries %d" % ["aggressive" if aggressive else "careful", state.active_seconds, state.air, state.heat, state.charge, recovery_intervals])
	return result
