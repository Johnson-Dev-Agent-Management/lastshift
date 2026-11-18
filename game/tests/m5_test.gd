extends SceneTree
## Bridge input exercises the normal scene target selection and simulation clock.
const Run = preload("res://scripts/run_controller.gd")
const Layout = preload("res://scripts/layout.gd")
var ship
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func expect(condition: bool, what: String) -> void:
	if not condition:
		failures += 1
		push_error(what)

func prepare(charge: float) -> void:
	ship.reset_run()
	ship.player.position = Layout.BRIDGE
	var state = ship.state
	state.salvage()
	state.advance(ship.profile.repair_seconds, true, true, false, ship.profile.repair_seconds)
	state.arm_drive()
	state.set_power("life_support", false)
	state.set_power("drive", true)
	state.charge = charge
	state.scenario.final_push = charge >= ship.profile.final_push_charge
	ship.target = ship.select_target()

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.action_press(action)
	ship._unhandled_input(event)

func release(action: String) -> void:
	Input.action_release(action)
	var event := InputEventAction.new()
	event.action = action
	ship._unhandled_input(event)

func frames(count: int) -> void:
	for i in count: ship._physics_process(Run.STEP)

func run() -> void:
	ship = load("res://scenes/ship.tscn").instantiate()
	root.add_child(ship)
	await physics_frame
	ship.set_physics_process(false)
	prepare(60)
	press("interact")
	expect(not ship.state.helm_engaged, "Early charging cannot engage the final approach")
	release("interact")
	prepare(88.25)
	var normal = Run.new(ship.profile, false)
	normal.salvage()
	normal.advance(ship.profile.repair_seconds, true, true, false, ship.profile.repair_seconds)
	normal.arm_drive()
	normal.set_power("life_support", false)
	normal.set_power("drive", true)
	normal.charge = ship.state.charge
	normal.scenario.final_push = true
	# Keep an authored leak live during comparison to cover the additional drain.
	normal.leak_active = true
	ship.state.leak_active = true
	press("interact")
	frames(60)
	normal.advance(4, false, false, false, ship.profile.repair_seconds)
	for key in ["air", "heat", "charge", "active_seconds"]:
		expect(is_equal_approx(ship.state.get(key), normal.get(key)), "One held second matches four ordinary seconds of " + key)
	expect(is_equal_approx(ship.state.scenario.repair_age, normal.scenario.repair_age), "Scenario clock follows the same elapsed time")
	release("interact")
	var start: float = ship.state.active_seconds
	frames(60)
	expect(is_equal_approx(ship.state.active_seconds - start, 1.0), "Release resumes normal ship time")
	press("interact")
	ship.toggle_pause()
	start = ship.state.active_seconds
	frames(30)
	ship.toggle_pause()
	expect(not ship.state.helm_engaged and ship.state.active_seconds == start, "Pause cancels the hold and freezes ship time")
	release("interact")
	press("interact")
	ship.player.position = Layout.POWER
	frames(1)
	expect(not ship.state.helm_engaged, "Leaving helm range cancels acceleration")
	release("interact")
	ship.player.position = Layout.BRIDGE
	press("interact")
	press("map")
	expect(not ship.state.helm_engaged, "Opening the map releases the helm")
	release("map")
	release("interact")
	prepare(99.999)
	ship.state.heat = ship.profile.drive_cutoff - 0.001
	press("interact")
	start = ship.state.active_seconds
	frames(1)
	expect(ship.state.drive_cooling_down and not ship.state.escaped and not ship.state.helm_engaged, "Cutoff interrupts even on the completion tick")
	expect(is_equal_approx(ship.state.active_seconds - start, Run.STEP), "Cutoff consumes no extra accelerated ticks")
	release("interact")
	prepare(99.999)
	ship.state.air = 0.00001
	press("interact")
	frames(1)
	expect(ship.state.failure == "AIR DEPLETED" and not ship.state.escaped, "Terminal air loss wins the completion tick")
	release("interact")
	prepare(88.25)
	press("interact")
	var held_frames := 0
	while not ship.state.terminal() and held_frames < 300:
		frames(1)
		held_frames += 1
	expect(ship.state.escaped and held_frames == 212, "Held final 11.75 percent jumps in about 3.53 real seconds")
	expect(not ship.feedback.ambience.playing and not ship.feedback.alarm.playing, "Arrival silences ship and hazard loops")
	release("interact")
	prepare(100)
	press("interact")
	frames(1)
	expect(ship.state.escaped, "Single press at full charge still jumps")
	release("interact")
	prepare(80)
	ship.state.heat_warning = true
	ship.state.leak_active = true
	ship.state.air = 32
	frames(1)
	expect(ship.feedback.last_alert == ship.Feedback.Alert.AIR and ship.hud.warning_text().begins_with("LOW AIR"), "Simultaneous hazards share one highest warning")
	press("interact")
	ship.state_focus_lost()
	expect(not ship.state.helm_engaged, "Window focus loss drops the hold")
	release("interact")
	ship.toggle_pause()
	ship.open_settings()
	expect(ship.settings_panel.visible and ship.paused, "Options keep simulation paused")
	for option in ship.settings_panel.find_children("*", "CheckButton", true, false):
		option.button_pressed = true
	expect(ship.reduced_flashing and ship.reduced_shake and ship.toggle_work, "All three accessibility switches change play settings")
	var sliders = ship.settings_panel.find_children("*", "HSlider", true, false)
	expect(sliders.size() == 6, "Master and five mix channels are adjustable")
	for i in sliders.size():
		sliders[i].value = 0.25
		var bus = (["Master"] + ship.Feedback.BUSES)[i]
		expect(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus)), 0.25), "Slider changes " + bus)
	ship.close_settings()
	ship.toggle_pause()
	ship.reset_run(true)
	ship.on_event("JUMP FAILED")
	frames(4)
	expect(ship.camera.offset == Vector2.ZERO, "Reduced shake holds the camera still during the jump failure")
	expect(not ship.state.helm_engaged and not ship.settings_panel.visible, "Retry clears helm and menu state")
	if failures == 0: print("LAST_SHIFT_M5_PASS: helm hold, 4x clocks, cancellation, terminal priority, manual jump, warning priority and options")
	quit(0 if failures == 0 else 1)
