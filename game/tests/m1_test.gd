extends SceneTree
const State = preload("res://scripts/repair_state.gd")
const Layout = preload("res://scripts/layout.gd")
const PROFILE = preload("res://m1_profile.tres")
var failures := 0
var ship: Node2D

func expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for fps in [30, 60, 120]:
		var state := State.new()
		expect(state.salvage(), "First salvage succeeds")
		expect(not state.salvage(), "Duplicate salvage rejected")
		for tick in fps * 2:
			state.advance(1.0 / fps, true, true, false, 6.0)
		expect(is_equal_approx(state.repair_elapsed, 2.0), "Repair progress stable across frame rates")
		state.advance(10, false, true, false, 6.0)
		state.advance(10, true, false, false, 6.0)
		state.advance(10, true, true, true, 6.0)
		expect(is_equal_approx(state.repair_elapsed, 2.0), "Release, range exit and pause retain progress")
		var before_pause := state.active_seconds
		state.advance(10, false, false, true, 6.0)
		expect(state.active_seconds == before_pause, "Pause freezes active clock")
		expect(not state.drop_at(Vector2(-100, -100), false), "Unsafe drop rejected")
		expect(state.motor == State.Motor.CARRIED, "Unsafe drop retains motor")
		expect(state.drop_at(Layout.SPAWN, true), "Safe drop accepted")
		state.advance(10, true, true, false, 6.0)
		expect(not state.repaired and state.repair_elapsed < 3, "Cannot work without carried motor")
		expect(state.pick_up() and not state.pick_up(), "Dropped motor picked up once")
		state.advance(4.01, true, true, false, 6.0)
		expect(state.repaired and state.motor == State.Motor.INSTALLED, "Repair consumes once at completion")
		var event_count := state.events.size()
		state.advance(99, true, true, false, 6.0)
		expect(state.events.size() == event_count and state.repaired, "Completed repair permanent and idempotent")
		expect(not state.drop_at(Layout.SPAWN, true) and not state.salvage(), "Installed motor cannot duplicate")
	check_reachability(false)
	check_reachability(true)
	ship = load("res://scenes/ship.tscn").instantiate()
	root.add_child(ship)
	await process_frame
	await physics_frame
	# A canceled salvage leaves the motor, work light and gate untouched.
	ship.player.position = Layout.DONOR + Vector2(0, 80)
	ship.interact()
	expect(ship.confirming, "Donor opens cost confirmation")
	ship.cancel_salvage()
	expect(not ship.state.shortcut_closed(), "Cancel preserves donor and shortcut")
	# Exercise real CharacterBody2D collision, not just the logical gate flag.
	ship.player.position = Vector2(1040, 340)
	await move_for(Vector2.RIGHT, 45)
	expect(ship.player.position.x > 1150, "Open shortcut permits passage")
	ship.player.position = Layout.DONOR + Vector2(0, 80)
	ship.interact()
	ship.confirm_salvage()
	ship.confirm_salvage()
	await physics_frame
	await physics_frame
	expect(ship.state.motor == State.Motor.CARRIED, "Confirmed salvage carries exactly one motor")
	ship.player.position = Vector2(1040, 340)
	await move_for(Vector2.RIGHT, 45)
	expect(ship.player.position.x < 1070, "Closed shortcut physically blocks passage")
	# A wall-edge drop rejects without losing the component.
	ship.player.position = Vector2(137, 200)
	ship.drop_motor()
	expect(ship.state.motor == State.Motor.CARRIED, "Wall-edge drop keeps motor")
	ship.player.position = Vector2(1720, 840)
	ship.drop_motor()
	expect(ship.state.motor == State.Motor.DROPPED, "Corridor drop allowed")
	ship.interact()
	expect(ship.state.motor == State.Motor.CARRIED, "Corridor drop recoverable")
	# Walk the actual retained route after salvage and measure fixed-step ticks.
	ship.player.position = Layout.DONOR + Vector2(0, 80)
	var route_ticks := 0
	for point in [Vector2(1720, 400), Vector2(1720, 840), Vector2(480, 840), Vector2(480, 400), Vector2(340, 400)]:
		route_ticks += await walk_to(point)
	print("M1_MEASURE cargo-to-pump permanent route: %.2fs (%d physics ticks at 60Hz)" % [route_ticks / 60.0, route_ticks])
	expect(ship.select_target() == "pump", "Permanent route reaches pump interaction range")
	# Integrate toggle work, pause, range loss, drop/pickup, and completion through scene.
	ship.toggle_work = true
	ship.interact()
	await move_for(Vector2.ZERO, 120)
	var retained: float = ship.state.repair_elapsed
	expect(retained > 1.9 and retained < 2.1, "Scene toggle work advances two seconds")
	ship.toggle_pause()
	await move_for(Vector2.ZERO, 60)
	expect(ship.state.repair_elapsed == retained, "Scene pause retains repair")
	ship.toggle_pause()
	ship.interact()
	await walk_to(Vector2(480, 400))
	expect(not ship.work_latched, "Leaving range cancels toggled work")
	retained = ship.state.repair_elapsed
	ship.drop_motor()
	ship.interact()
	await walk_to(Vector2(340, 400))
	expect(ship.state.repair_elapsed == retained, "Drop, pickup and return retain repair")
	ship.interact()
	await move_for(Vector2.ZERO, 360)
	expect(ship.state.repaired and ship.feedback.pump.playing, "Repair restores pump and starts feedback")
	expect(ship.message.begins_with("PUMP REPAIRED"), "Recovery message survives subsequent idle frames")
	# Pause/restart state cannot leak into a new run.
	ship.toggle_pause()
	ship.reset_run()
	await physics_frame
	expect(not ship.paused and not ship.state.repaired and ship.state.repair_elapsed == 0, "Reset clears work and pause")
	expect(ship.state.motor == State.Motor.DONOR and not ship.feedback.pump.playing, "Reset restores motor and audio")
	expect(ship.gate_collision.disabled, "Reset reopens shortcut collider")
	ship.player.position = Vector2(340, 400)
	var shortcut_ticks := 0
	for point in [Vector2(700, 400), Vector2(700, 340), Vector2(1720, 340), Vector2(1840, 400)]:
		shortcut_ticks += await walk_to(point)
	print("M1_MEASURE pump-to-cargo open shortcut: %.2fs (%d physics ticks at 60Hz)" % [shortcut_ticks / 60.0, shortcut_ticks])
	if failures == 0:
		print("LAST_SHIFT_M1_PASS: state invariants, all-floor reachability, physical routes, safe drops, retained repair, feedback, reset")
	ship.queue_free()
	await process_frame
	quit(1 if failures else 0)

func move_for(direction: Vector2, ticks: int) -> void:
	ship.player.test_direction = direction
	for tick in ticks:
		await physics_frame
	ship.player.test_direction = Vector2.ZERO

func walk_to(point: Vector2) -> int:
	var ticks := 0
	while ship.player.position.distance_to(point) > 4 and ticks < 1500:
		ship.player.test_direction = (point - ship.player.position).normalized()
		await physics_frame
		ticks += 1
	ship.player.test_direction = Vector2.ZERO
	expect(ticks < 1500, "Physical route reached %s" % point)
	return ticks

func check_reachability(closed: bool) -> void:
	var cells := Layout.cells(closed)
	var queue: Array[Vector2i] = [Vector2i(Layout.SPAWN / Layout.TILE)]
	var seen := {queue[0]: true}
	var index := 0
	while index < queue.size():
		var current := queue[index]
		index += 1
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = current + direction
			if cells.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	expect(seen.size() == cells.size(), "All floor cells reachable with shortcut closed=%s" % closed)
	var safe_drops := 0
	for cell: Vector2i in cells:
		var point := Vector2(cell) * Layout.TILE + Vector2(20, 20)
		if Layout.safe_center(point, closed):
			safe_drops += 1
			expect(seen.has(cell), "Every safe drop is reachable")
	expect(safe_drops > 500, "Reachability covers the whole ship")
	for room: Rect2 in Layout.ROOMS:
		expect(seen.has(Vector2i(room.get_center() / Layout.TILE)), "Every room connects to permanent route")
