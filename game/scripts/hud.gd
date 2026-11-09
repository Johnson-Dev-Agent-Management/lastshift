extends Control
const Layout = preload("res://scripts/layout.gd")
const State = preload("res://scripts/repair_state.gd")
const INK := Color("e3eeeb")
const MUTED := Color("9bafba")
const AMBER := Color("efbb70")
const MINT := Color("7cdac0")
var ship: Node2D
var font := ThemeDB.fallback_font

func text_at(point: Vector2, value: String, size_px := 18, color := INK) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func _draw() -> void:
	if not is_instance_valid(ship):
		return
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(1280, 720))
	draw_rect(Rect2(0, 0, 1280, 104), Color("101e29"))
	draw_line(Vector2(28, 103), Vector2(1252, 103), Color("364d59"), 1)
	text_at(Vector2(28, 34), "LAST SHIFT", 25, AMBER)
	text_at(Vector2(207, 33), "M1 / WALKABLE SHIP", 14, MUTED)
	text_at(Vector2(28, 65), "GET HOME.  " + objective(), 22)
	text_at(Vector2(28, 89), "Crew evacuated. Pod dead. Your way home is the ship itself.", 15, MUTED)
	text_at(Vector2(960, 31), Layout.room_at(ship.player.position), 15, AMBER)
	text_at(Vector2(960, 56), "No survival timer in this milestone", 15, MUTED)
	text_at(Vector2(960, 81), "M  ship map     Esc  pause", 16)
	draw_rect(Rect2(0, 580, 1280, 140), Color("101e29"))
	draw_line(Vector2(28, 581), Vector2(1252, 581), Color("364d59"), 1)
	text_at(Vector2(28, 610), ship.prompt_title(), 21, AMBER)
	text_at(Vector2(28, 636), ship.prompt_detail(), 17)
	text_at(Vector2(28, 662), ship.message, 15, MINT if ship.state.repaired else MUTED)
	text_at(Vector2(28, 700), "WASD / arrows  move    E  interact    Q  drop    T  " + ("toggle work" if not ship.toggle_work else "hold work"), 16, MUTED)
	var carried: String = "MOTOR: " + ["IN CARGO", "CARRYING 1 / 1", "ON DECK", "INSTALLED"][ship.state.motor]
	text_at(Vector2(910, 609), carried, 18, MINT)
	text_at(Vector2(910, 635), "PUMP  %d%%  /  %s" % [ship.progress_percent(), "READY" if ship.state.repaired else "BROKEN"], 17)
	draw_rect(Rect2(910, 649, 334, 8), Color("31434e"))
	draw_rect(Rect2(910, 649, 334 * ship.state.repair_elapsed / ship.profile.repair_seconds, 8), MINT)
	text_at(Vector2(910, 681), "Work mode: " + ("TOGGLE E" if ship.toggle_work else "HOLD E"), 15, MUTED)
	if OS.is_debug_build():
		text_at(Vector2(910, 704), "DEV  F5 reset · F10 local log", 14, MUTED)
	if ship.map_open:
		draw_rect(Rect2(210, 126, 860, 426), Color("101e29"))
		text_at(Vector2(238, 156), "SHIP PLAN   /   M to close", 21, AMBER)
		draw_map(Vector2(380, 164), 0.23)
		text_at(Vector2(238, 527), "Solid route stays OPEN.  Service shortcut: " + ("CLOSED / motor removed" if ship.state.shortcut_closed() else "OPEN"), 17)
	else:
		draw_rect(Rect2(981, 119, 278, 203), Color(0.06, 0.10, 0.14, 0.94))
		draw_map(Vector2(987, 123), 0.125)

func objective() -> String:
	if ship.state.repaired:
		return "Cooling restored. Explore the ship; M1 complete."
	if ship.state.motor == State.Motor.DONOR:
		return "Restore cooling — find the donor motor in Cargo."
	if ship.state.motor == State.Motor.DROPPED:
		return "Recover the motor marked on your map."
	return "Carry the motor to the coolant pump in Engineering."

func draw_map(origin: Vector2, scale_factor: float) -> void:
	for floor_area: Rect2 in Layout.floors():
		draw_rect(Rect2(origin + floor_area.position * scale_factor, floor_area.size * scale_factor), Color("304854"))
	for i in Layout.ROOMS.size():
		var area: Rect2 = Layout.ROOMS[i]
		var center: Vector2 = origin + area.get_center() * scale_factor
		draw_circle(center, 8 if scale_factor < 0.2 else 13, Color("152b37"))
		text_at(center + Vector2(-4, 5), str(i + 1), 13, AMBER)
		if scale_factor > 0.2:
			text_at(origin + (area.position + Vector2(20, 55)) * scale_factor, Layout.NAMES[i], 13, INK)
	if ship.state.shortcut_closed():
		var gate_pos := origin + Layout.GATE.get_center() * scale_factor
		draw_line(gate_pos - Vector2(6, 6), gate_pos + Vector2(6, 6), AMBER, 3)
		draw_line(gate_pos + Vector2(-6, 6), gate_pos + Vector2(6, -6), AMBER, 3)
	if ship.state.motor == State.Motor.DROPPED:
		draw_circle(origin + ship.state.dropped_position * scale_factor, 5, MINT)
	draw_circle(origin + ship.player.position * scale_factor, 5, Color.WHITE)
