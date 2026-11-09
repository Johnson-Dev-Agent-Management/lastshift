extends Node2D
const Layout = preload("res://scripts/layout.gd")
const State = preload("res://scripts/repair_state.gd")
const Player = preload("res://scripts/player.gd")
const Feedback = preload("res://scripts/feedback.gd")
const HUD = preload("res://scripts/hud.gd")
const ICON = preload("res://assets/icon.svg")
const PROFILE = preload("res://m1_profile.tres")
var profile = PROFILE
var state = State.new()
var player = Player.new()
var feedback = Feedback.new()
var hud = HUD.new()
var gate_collision := CollisionShape2D.new()
var target := ""
var paused := false
var confirming := false
var map_open := false
var toggle_work := false
var work_latched := false
var work_active := false
var message := "Find Cargo via the shortcut or the lit permanent corridor."
var phase := 0.0
var frames := 0
var pause_panel: PanelContainer
var salvage_panel: PanelContainer
var cancel_button: Button
var resume_button: Button
var work_option: CheckButton
var wall_segments: Array[Rect2] = []
var ui_layer := CanvasLayer.new()

func _ready() -> void:
	build_collision()
	player.position = Layout.SPAWN
	player.speed = profile.walk_speed
	add_child(player)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -40)
	camera.zoom = Vector2(0.9, 0.9)
	player.add_child(camera)
	var listener := AudioListener2D.new()
	player.add_child(listener)
	listener.make_current()
	add_child(feedback)
	add_child(ui_layer)
	hud.ship = self
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud)
	build_menus()
	state.event_occurred.connect(on_event)
	state.changed.connect(sync_state)
	sync_state()

func build_collision() -> void:
	var floor_cells := Layout.cells()
	for cell: Vector2i in floor_cells:
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if floor_cells.has(cell + direction):
				continue
			var center := Vector2(cell) * Layout.TILE + Vector2.ONE * Layout.TILE / 2.0
			var extent := Vector2(8, 40) if direction.x else Vector2(40, 8)
			var area := Rect2(center + Vector2(direction) * 20 - extent / 2, extent)
			wall_segments.append(area)
			add_solid(area)
	var gate := StaticBody2D.new()
	gate.position = Layout.GATE.get_center()
	var shape := RectangleShape2D.new()
	shape.size = Layout.GATE.size
	gate_collision.shape = shape
	gate.add_child(gate_collision)
	add_child(gate)

func add_solid(area: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = area.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = area.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func build_menus() -> void:
	salvage_panel = panel(Vector2(600, 262))
	var box := menu_box(salvage_panel)
	menu_label(box, "SALVAGE CARGO MOTOR?", 25)
	menu_label(box, "Cost: the service shortcut closes and its work light goes out.\nThe permanent corridor stays lit and open.\nThe motor will restore the Engineering coolant pump.", 18)
	var confirm := Button.new()
	confirm.text = "Salvage motor — accept shortcut closure"
	confirm.pressed.connect(confirm_salvage)
	box.add_child(confirm)
	cancel_button = Button.new()
	cancel_button.text = "Keep shortcut open / cancel"
	cancel_button.pressed.connect(cancel_salvage)
	box.add_child(cancel_button)
	pause_panel = panel(Vector2(600, 300))
	box = menu_box(pause_panel)
	menu_label(box, "SHIFT PAUSED", 25)
	menu_label(box, "Progress is retained.  No survival clocks exist in M1.", 18)
	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.pressed.connect(toggle_pause)
	box.add_child(resume_button)
	work_option = CheckButton.new()
	work_option.text = "Toggle E to work (instead of holding E)"
	work_option.toggled.connect(func(enabled: bool): toggle_work = enabled; stop_work())
	box.add_child(work_option)
	menu_label(box, "Master volume", 16)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = 0.65
	AudioServer.set_bus_volume_linear(0, 0.65)
	volume.value_changed.connect(func(value: float): AudioServer.set_bus_volume_linear(0, value))
	box.add_child(volume)

func panel(dimensions: Vector2) -> PanelContainer:
	var result := PanelContainer.new()
	ui_layer.add_child(result)
	result.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result.offset_left = -dimensions.x / 2
	result.offset_right = dimensions.x / 2
	result.offset_top = -dimensions.y / 2
	result.offset_bottom = dimensions.y / 2
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182d39")
	style.border_color = Color("efbb70")
	style.set_border_width_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	result.add_theme_stylebox_override("panel", style)
	result.hide()
	return result

func menu_box(parent: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	parent.add_child(box)
	return box

func menu_label(parent: Control, value: String, font_size: int) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_reset") and OS.is_debug_build():
		reset_run()
		return
	if event.is_action_pressed("dev_log") and OS.is_debug_build():
		save_log()
		return
	if event.is_action_pressed("pause"):
		if confirming:
			cancel_salvage()
		else:
			toggle_pause()
		return
	if paused or confirming:
		return
	if event.is_action_pressed("map"):
		map_open = not map_open
	if event.is_action_pressed("work_mode"):
		toggle_work = not toggle_work
		stop_work()
	if event.is_action_pressed("drop"):
		drop_motor()
	if event.is_action_pressed("interact"):
		interact()

func interact() -> void:
	if paused or confirming:
		return
	target = select_target()
	match target:
		"donor":
			confirming = true
			stop_work()
			salvage_panel.show()
			cancel_button.grab_focus()
		"motor":
			state.pick_up()
		"pump":
			if state.motor == State.Motor.CARRIED and not state.repaired:
				work_latched = not work_latched if toggle_work else true

func confirm_salvage() -> void:
	# Recheck transaction preconditions even if a dialog callback is repeated.
	if confirming and player.position.distance_to(Layout.DONOR) <= profile.interaction_range:
		state.salvage()
	cancel_salvage()

func cancel_salvage() -> void:
	confirming = false
	salvage_panel.hide()
	get_viewport().gui_release_focus()

func drop_motor() -> void:
	stop_work()
	# Drop at the player's valid position, never in front of/through a wall.
	# Non-solid parts cannot obstruct a door. Unsafe edge positions simply reject.
	if not state.drop_at(player.position, Layout.safe_center(player.position, state.shortcut_closed())) and state.motor == State.Motor.CARRIED:
		message = "Move a little away from the wall to drop safely."

func toggle_pause() -> void:
	paused = not paused
	stop_work()
	pause_panel.visible = paused
	work_option.set_pressed_no_signal(toggle_work)
	feedback.pump.stream_paused = paused
	if paused:
		resume_button.grab_focus()
	else:
		get_viewport().gui_release_focus()

func stop_work() -> void:
	if work_active and not state.repaired:
		state.record("Work stopped at %d%%; progress retained." % progress_percent())
	work_latched = false
	work_active = false

func _physics_process(delta: float) -> void:
	player.frozen = paused or confirming
	target = select_target()
	var blocked := paused or confirming
	var requested: bool = work_latched if toggle_work else Input.is_action_pressed("interact")
	var can_work: bool = target == "pump" and state.motor == State.Motor.CARRIED and not state.repaired
	var working: bool = requested and can_work and not blocked
	if work_active and not working:
		stop_work()
	if not can_work:
		work_latched = false
	if working and not work_active:
		state.record("Pump work started at %d%%." % progress_percent())
		feedback.confirm()
	work_active = working
	state.advance(delta, working, can_work, blocked, profile.repair_seconds)
	player.working = working
	if not blocked:
		phase += delta
	player.carrying = state.motor == State.Motor.CARRIED
	queue_redraw()
	hud.queue_redraw()
	frames += 1
	if frames == 5 and "--smoke-test" in OS.get_cmdline_user_args():
		assert(ICON.get_width() == 128)
		assert(wall_segments.size() > 50 and player.is_inside_tree() and hud.is_inside_tree())
		assert(InputMap.has_action("interact") and Layout.ROOMS.size() == 5)
		print("LAST_SHIFT_STARTUP_PASS: imported texture, ship, collision, player, HUD and physics ticks")

func select_target() -> String:
	var candidates := {"pump": Layout.PUMP}
	if state.motor == State.Motor.DONOR:
		candidates["donor"] = Layout.DONOR
	if state.motor == State.Motor.DROPPED:
		candidates["motor"] = state.dropped_position
	var nearest := ""
	var distance: float = profile.interaction_range
	for key: String in candidates:
		var next_distance: float = player.position.distance_to(candidates[key])
		if next_distance < distance and has_line_of_sight(candidates[key]):
			distance = next_distance
			nearest = key
	return nearest

func has_line_of_sight(point: Vector2) -> bool:
	if player.position.is_equal_approx(point):
		return true
	var query := PhysicsRayQueryParameters2D.create(player.position, point)
	query.exclude = [player.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func progress_percent() -> int:
	return int(round(state.repair_elapsed / profile.repair_seconds * 100.0))

func prompt_title() -> String:
	match target:
		"donor": return "CARGO DONOR MOTOR   /   E to review salvage"
		"motor": return "MOTOR ON DECK   /   E to pick up"
		"pump":
			if state.repaired: return "COOLANT PUMP   /   READY — circulation restored"
			if state.motor == State.Motor.CARRIED: return "COOLANT PUMP   /   %s E to repair · %d%%" % ["Press" if toggle_work else "Hold", progress_percent()]
			return "COOLANT PUMP   /   BROKEN — motor required"
	return "PERMANENT ROUTE OPEN   /   Follow the floor lights"

func prompt_detail() -> String:
	match target:
		"donor": return "Cost: closes the service shortcut and turns off its work light. Main route stays open."
		"motor": return "One motor. Carry it to Engineering. Dropped parts never block the route."
		"pump":
			if state.repaired: return "This repair lasts. Power, heat and jump charging arrive in milestone M2."
			return "6 seconds total. Leaving, releasing or dropping keeps progress. Motor used at completion."
	return "Map: 1 Engineering · 2 Cargo · 3 Bridge · 4 Life Support · 5 Jump Chamber"

func sync_state() -> void:
	gate_collision.set_deferred("disabled", not state.shortcut_closed())
	queue_redraw()

func on_event(value: String) -> void:
	message = value
	if value.begins_with("PUMP REPAIRED"):
		feedback.confirm(true)
	elif value.begins_with("Motor"):
		feedback.confirm()

func reset_run() -> void:
	state = State.new()
	state.event_occurred.connect(on_event)
	state.changed.connect(sync_state)
	player.position = Layout.SPAWN
	player.velocity = Vector2.ZERO
	player.test_direction = Vector2.ZERO
	player.frozen = false
	player.working = false
	player.carrying = false
	paused = false
	confirming = false
	map_open = false
	work_latched = false
	work_active = false
	phase = 0
	pause_panel.hide()
	salvage_panel.hide()
	get_viewport().gui_release_focus()
	feedback.reset()
	feedback.pump.stream_paused = false
	message = "Developer reset. Motor, gate and repair restored to initial state."
	sync_state()

func save_log() -> void:
	var file := FileAccess.open("user://m1-events.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"milestone": "M1", "profile": "m1_profile.tres", "events": state.events, "active_seconds": state.active_seconds}, "\t"))
		message = "Local event log: " + ProjectSettings.globalize_path("user://m1-events.json")

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for area: Rect2 in Layout.floors():
		draw_rect(area, Color("1c303c"))
		for x in range(int(area.position.x) + 40, int(area.end.x), 80):
			draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), Color("243b47"), 1)
		for y in range(int(area.position.y) + 40, int(area.end.y), 80):
			draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color("243b47"), 1)
	for wall in wall_segments:
		draw_rect(wall, Color("677c83"))
	for x in range(160, 2050, 120):
		draw_rect(Rect2(x, 785, 38, 5), Color("efbb70"))
		draw_rect(Rect2(x, 890, 38, 5), Color("efbb70"))
	draw_string(font, Vector2(640, 853), "PERMANENT CORRIDOR  /  ALWAYS OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("c5d4d4"))
	for i in Layout.ROOMS.size():
		var corner: Vector2 = Layout.ROOMS[i].position + Vector2(24, 48)
		draw_string(font, corner, "%02d  /  %s" % [i + 1, Layout.NAMES[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("efbb70"))
	# Engineering: pump, pipes, status plate.
	draw_line(Vector2(140, 320), Vector2(700, 320), Color("386b6c"), 15)
	draw_rect(Rect2(262, 255, 156, 130), Color("314b56"))
	draw_circle(Layout.PUMP, 47, Color("0d202a"))
	var angle := phase * 3 if state.repaired else 0.0
	for blade in 4:
		var direction := Vector2.from_angle(angle + blade * PI / 2)
		draw_line(Layout.PUMP + direction * 12, Layout.PUMP + direction * 38, Color("7cdac0") if state.repaired else Color("b78e55"), 10)
	machine_label(Vector2(260, 420), "PUMP / " + ("READY" if state.repaired else "BROKEN"))
	machine_label(Vector2(550, 255), "POWER CONSOLE")
	draw_rect(Rect2(552, 275, 120, 70), Color("38505c"))
	machine_label(Vector2(550, 377), "OFFLINE IN M1")
	# Cargo: crate silhouettes and donor, all floor decals, never solid blockers.
	for x in [1450, 1560, 1930]:
		for y in [435, 515]:
			draw_rect(Rect2(x, y, 65, 55), Color("514c42"))
			draw_line(Vector2(x + 8, y + 8), Vector2(x + 57, y + 47), Color("8a7960"), 3)
	draw_rect(Rect2(1760, 255, 160, 130), Color("3c4d54"))
	if not state.shortcut_closed():
		draw_motor(Layout.DONOR)
	machine_label(Vector2(1740, 420), "DONOR / " + ("EMPTY" if state.shortcut_closed() else "MOTOR"))
	# Shortcut gate and its explicitly labeled work light.
	var light_color := Color("6a5b43") if state.shortcut_closed() else Color("efbb70")
	draw_rect(Rect2(835, 285, 210, 7), light_color)
	machine_label(Vector2(830, 445), "SERVICE: " + ("CLOSED / LIGHT OFF" if state.shortcut_closed() else "OPEN / LIGHT ON"))
	if state.shortcut_closed():
		draw_rect(Layout.GATE, Color("594e3f"))
		for y in range(285, 390, 24):
			draw_line(Vector2(1082, y), Vector2(1118, y + 24), Color("efbb70"), 6)
	else:
		draw_rect(Rect2(1080, 280, 40, 8), Color("7cdac0"))
	# Bridge viewport and helm.
	draw_rect(Rect2(180, 1170, 400, 80), Color("0a1c2b"))
	for i in 12:
		draw_circle(Vector2(197 + i * 31, 1185 + (i * 17) % 48), 2, Color("a8c6ce"))
	draw_arc(Vector2(380, 1330), 60, PI, TAU, 24, Color("7cdac0"), 12)
	machine_label(Vector2(270, 1410), "HELM / STANDBY")
	# Life-support cylinders.
	for x in [915, 1045, 1175]:
		draw_style_box(cylinder_style(), Rect2(x, 1200, 80, 160))
	machine_label(Vector2(930, 1430), "AIR RESERVE / STANDBY")
	# Circular jump assembly.
	var drive := Vector2(1820, 1300)
	draw_circle(drive, 90, Color("0f232e"))
	draw_arc(drive, 100, 0, TAU, 64, Color("526b7c"), 18)
	draw_arc(drive, 66, 0, TAU, 64, Color("7cdac0"), 3)
	machine_label(Vector2(1680, 1450), "JUMP DRIVE / STANDBY")
	if state.motor == State.Motor.DROPPED:
		draw_motor(state.dropped_position)
	if target != "":
		var point: Vector2 = Layout.PUMP if target == "pump" else (Layout.DONOR if target == "donor" else state.dropped_position)
		draw_arc(point, 62 if target != "motor" else 24, 0, TAU, 48, Color("efbb70"), 2)
		draw_string(font, point + Vector2(-7, -70 if target != "motor" else -32), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("efbb70"))

func machine_label(point: Vector2, value: String) -> void:
	draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("bfd1d3"))

func draw_motor(point: Vector2) -> void:
	draw_rect(Rect2(point - Vector2(18, 12), Vector2(36, 24)), Color("7cdac0"))
	draw_line(point - Vector2(25, 0), point + Vector2(25, 0), Color("e3eeeb"), 5)

func cylinder_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("45656b")
	style.set_corner_radius_all(20)
	return style
