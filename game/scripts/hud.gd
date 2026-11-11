extends Control
const Layout = preload("res://scripts/layout.gd")
const State = preload("res://scripts/repair_state.gd")
const INK := Color("e3eeeb")
const MUTED := Color("9bafba")
const AMBER := Color("efbb70")
const MINT := Color("7cdac0")
const DANGER := Color("ffad97")
var ship: Node2D
var font := ThemeDB.fallback_font

func text_at(point: Vector2, value: String, size_px := 18, color := INK, max_width := 860.0) -> void:
	if font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > max_width:
		while value.length() > 0 and font.get_string_size(value + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > max_width:
			value = value.left(-1)
		value += "…"
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func _draw() -> void:
	if not is_instance_valid(ship): return
	var state = ship.state
	var profile = ship.profile
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(1280, 720))
	draw_rect(Rect2(0, 0, 1280, 142), Color("101e29"))
	text_at(Vector2(28, 30), "LAST SHIFT", 25, AMBER)
	text_at(Vector2(207, 29), "M3 / " + ship.State.Stage.keys()[state.stage], 14, MUTED)
	text_at(Vector2(28, 61), objective(), 21)
	text_at(Vector2(960, 29), Layout.room_at(ship.player.position), 15, AMBER, 292)
	text_at(Vector2(960, 55), "M ship map · Esc pause", 16, INK, 292)
	text_at(Vector2(28, 88), "AIR RESERVE", 14, MUTED)
	text_at(Vector2(28, 119), "%.1f" % state.air, 26, AMBER if state.air <= profile.air_warning else INK)
	text_at(Vector2(116, 117), "%+.2f /s" % state.air_rate(), 17, MUTED)
	text_at(Vector2(326, 88), "HEAT", 14, MUTED)
	text_at(Vector2(326, 119), "%.1f" % state.heat, 26, DANGER if state.critical else (AMBER if state.heat_warning else INK))
	text_at(Vector2(410, 117), "%+.2f /s" % state.heat_rate(), 17, MINT if state.heat_rate() < 0 else AMBER)
	text_at(Vector2(628, 88), "JUMP CHARGE", 14, MUTED)
	text_at(Vector2(628, 119), "%.1f%%" % state.charge, 26, MINT)
	text_at(Vector2(737, 117), "CHARGING" if state.charging() else ("READY" if state.escape_ready() else "RETAINED"), 15, MUTED)
	text_at(Vector2(960, 88), "REACTOR ALLOCATION", 14, MUTED)
	text_at(Vector2(960, 119), "%d / %d" % [state.used_power(), profile.capacity], 26)
	text_at(Vector2(1058, 117), "AIR %s  COOL %s" % ["ON" if state.life_support_powered else "OFF", "ON" if state.cooling_powered else "OFF"], 14, MUTED, 200)
	var warning := warning_text()
	if not warning.is_empty():
		draw_rect(Rect2(20, 152, 938, 36), Color("28303a"))
		text_at(Vector2(32, 177), warning, 18, DANGER if state.critical or not state.failure.is_empty() else AMBER, 908)
	draw_rect(Rect2(0, 580, 1280, 140), Color("101e29"))
	draw_line(Vector2(28, 581), Vector2(1252, 581), Color("364d59"), 1)
	text_at(Vector2(28, 610), ship.prompt_title(), 20, AMBER)
	text_at(Vector2(28, 636), ship.prompt_detail(), 17)
	text_at(Vector2(28, 662), ship.message, 15, MINT if state.repaired else MUTED)
	text_at(Vector2(28, 700), "WASD / arrows move · E interact · Q drop · T " + ("toggle work" if not ship.toggle_work else "hold work"), 16, MUTED)
	var progress: float = state.repair_elapsed / profile.repair_seconds
	if state.stage == ship.State.Stage.OPENING:
		text_at(Vector2(910, 609), "CHECKLIST / SAFE TO PRACTICE", 18, MINT, 334)
		progress = ship.task_progress("connector")
		text_at(Vector2(910, 635), "CONNECTOR %d%% / %s" % [int(round(progress * 100)), "SEATED" if state.connector_ready else "RESEAT"], 16, INK, 334)
	else:
		text_at(Vector2(910, 609), "MOTOR: " + ["IN CARGO", "CARRYING 1 / 1", "ON DECK", "INSTALLED"][state.motor], 18, MINT, 334)
		if state.scenario.leak_fired:
			progress = ship.task_progress("leak")
			text_at(Vector2(910, 635), "HULL %d%% / %s" % [int(round(progress * 100)), "SEALED" if state.leak_patched else "LEAKING"], 16, INK, 334)
		else:
			text_at(Vector2(910, 635), "PUMP %d%% / %s" % [ship.progress_percent(), state.pump_status()], 16, INK, 334)
	draw_rect(Rect2(910, 649, 334, 8), Color("31434e"))
	draw_rect(Rect2(910, 649, 334 * progress, 8), MINT)
	text_at(Vector2(910, 680), "RESERVE: " + ("EMPTY" if state.reserve_used else "AVAILABLE IN LIFE SUPPORT"), 14, MUTED, 334)
	if OS.is_debug_build(): text_at(Vector2(910, 704), "DEV F5 retry · F6 repair · F7 leak · F8/F10", 13, MUTED, 334)
	if ship.map_open:
		draw_rect(Rect2(210, 190, 860, 376), Color("101e29"))
		text_at(Vector2(238, 218), "SHIP PLAN / M to close · TIME RUNNING", 19, AMBER)
		draw_map(Vector2(380, 218), 0.20)
		text_at(Vector2(238, 548), "Permanent route OPEN · Shortcut " + ("CLOSED" if state.shortcut_closed() else "OPEN"), 17)
	else:
		draw_rect(Rect2(981, 152, 278, 203), Color(0.06, 0.10, 0.14, 0.94))
		draw_map(Vector2(987, 156), 0.125)
	if ship.dev_overlay and OS.is_debug_build():
		draw_rect(Rect2(28, 207, 650, 158), Color("101e29"))
		text_at(Vector2(42, 231), "DEV / " + profile.profile_id + " / active %.2fs" % state.active_seconds, 16, MINT)
		text_at(Vector2(42, 257), "Air %+.2f/s · heat %+.2f/s · charge %+.2f/s" % [state.air_rate(), state.heat_rate(), profile.charge_rate if state.charging() else 0.0], 16)
		text_at(Vector2(42, 283), "Drive " + state.drive_status(), 16)
		text_at(Vector2(42, 309), "Warning %.0f/%.0f · cutoff %.0f · restart below %.0f" % [profile.heat_warning_enter, profile.heat_warning_clear, profile.drive_cutoff, profile.drive_restart], 16)
		text_at(Vector2(42, 335), "Critical %.2f/%.0fs · remainder %.6fs" % [state.critical_elapsed, profile.critical_grace_seconds, state.accumulator], 16)
	if state.stage == ship.State.Stage.TRANSITION:
		var pre_jump: bool = state.announcement_index == 0
		draw_rect(Rect2(0, 142, 1280, 438), Color(0.03, 0.09, 0.12, 0.72) if pre_jump else Color(0.12, 0.08, 0.05, 0.72))
		draw_rect(Rect2(210, 200, 860, 350), Color("101e29"))
		text_at(Vector2(240, 239), "SHIP STATUS / " + ("SCHEDULED JUMP" if pre_jump else "EMERGENCY REPORT"), 22, MINT if pre_jump else AMBER)
		text_at(Vector2(982, 239), "%d / %d" % [state.announcement_index + 1, state.ANNOUNCEMENTS.size()], 17, MUTED, 70)
		var lines: PackedStringArray = state.ANNOUNCEMENTS[state.announcement_index].split("\n")
		text_at(Vector2(240, 314), lines[0], 27, INK, 800)
		for i in range(1, lines.size()):
			text_at(Vector2(240, 340 + i * 36), lines[i], 22, INK, 800)
		text_at(Vector2(240, 507), "Take your time. Resources stay held until you begin." if state.awaiting_report_dismissal() else "Resources held until control returns. Esc pauses this report.", 17, MUTED)
		for i in state.ANNOUNCEMENTS.size():
			draw_rect(Rect2(240 + i * 202, 527, 188, 4), (MINT if pre_jump else AMBER) if i <= state.announcement_index else Color("31434e"))
	if state.terminal(): draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.5))

func warning_text() -> String:
	var state = ship.state
	if state.terminal(): return ""
	if state.stage == ship.State.Stage.OPENING: return "PRE-JUMP CHECKLIST · no resource danger · take your time"
	if state.critical:
		var action := "keep cooling powered" if state.cooling_active() else "turn on cooling"
		if state.drive_powered: action += ", stop drive"
		return "CRITICAL HEAT · %.1fs remaining · %s" % [maxf(0, ship.profile.critical_grace_seconds - state.critical_elapsed), action]
	if state.air <= ship.profile.air_warning:
		if state.leak_active: return "LOW AIR · patch the Cargo leak to stop extra loss"
		if not state.life_support_powered: return "LOW AIR · power life support to slow the loss"
		if not state.reserve_used: return "LOW AIR · emergency reserve available in Life Support"
		return "LOW AIR · life support on, reserve spent · finish charging and reach the bridge"
	if state.drive_cooling_down: return "DRIVE COOLING DOWN · charge retained · cool below %.0f, then reassign power" % ship.profile.drive_restart
	if state.heat_warning: return "HIGH HEAT · enable cooling or stop charging before cutoff at %.0f" % ship.profile.drive_cutoff
	if state.leak_active: return "CARGO HULL LEAK · extra −%.2f air/s · patch with your built-in tool" % ship.profile.leak_drain
	if state.scenario.leak_warned and not state.scenario.leak_fired: return "CARGO SEAL STRAIN · your built-in repair tool can patch a leak"
	return ""

func objective() -> String:
	var state = ship.state
	if state.escaped: return "SHIFT COMPLETE — YOU BROUGHT THE SHIP HOME"
	if not state.failure.is_empty(): return "SHIFT ENDED — " + state.failure
	if state.stage == ship.State.Stage.OPENING:
		if not state.connector_ready: return "Pre-jump checklist: reseat the SERVICE connector in Cargo."
		return "Pre-jump check: Engineering power — cycle cooling OFF, then ON."
	if state.stage == ship.State.Stage.TRANSITION:
		return "Checklist complete. Stand by for the scheduled jump." if state.announcement_index == 0 else "Jump failure. Read the ship status report."
	if state.escape_ready(): return "RETURN TO BRIDGE — JUMP READY"
	if state.motor == State.Motor.DONOR: return "Get home. Restore cooling — salvage Cargo's door-pump motor."
	if state.motor == State.Motor.DROPPED: return "Get home. Recover the motor marked on your map."
	if not state.repaired: return "Get home. Carry the motor to Engineering and repair the pump."
	if not state.drive_armed: return "Cooling repaired. Arm the drive in the Jump Chamber."
	if state.leak_active: return "Get home. Patch the Cargo leak or spend air to keep charging."
	if state.drive_cooling_down: return "Cool the drive. Charge is retained; power must be reassigned."
	if not state.drive_powered: return "Drive armed. Allocate power at the Engineering console."
	return "Final push. Keep charging, then return to the bridge." if state.scenario.final_push else "Charge the drive. Watch air and heat; repaired cooling is permanent."

func draw_map(origin: Vector2, scale_factor: float) -> void:
	for floor_area: Rect2 in Layout.floors():
		draw_rect(Rect2(origin + floor_area.position * scale_factor, floor_area.size * scale_factor), Color("304854"))
	for i in Layout.ROOMS.size():
		var area: Rect2 = Layout.ROOMS[i]
		var center: Vector2 = origin + area.get_center() * scale_factor
		draw_circle(center, 8 if scale_factor < 0.2 else 13, Color("152b37"))
		text_at(center + Vector2(-4, 5), str(i + 1), 13, AMBER)
		if scale_factor >= 0.2:
			text_at(origin + (area.position + Vector2(20, 55)) * scale_factor, Layout.NAMES[i], 13, INK)
	if ship.state.shortcut_closed():
		var gate_pos := origin + Layout.GATE.get_center() * scale_factor
		draw_line(gate_pos - Vector2(6, 6), gate_pos + Vector2(6, 6), AMBER, 3)
		draw_line(gate_pos + Vector2(-6, 6), gate_pos + Vector2(6, -6), AMBER, 3)
	if ship.state.motor == State.Motor.DROPPED:
		draw_circle(origin + ship.state.dropped_position * scale_factor, 5, MINT)
	if ship.state.leak_active:
		var leak_point := origin + Layout.LEAK * scale_factor
		draw_circle(leak_point, 6, AMBER)
		text_at(leak_point + Vector2(-3, 4), "!", 12, Color("101e29"))
	draw_circle(origin + ship.player.position * scale_factor, 5, Color.WHITE)
