extends RefCounted
## M1 authoritative state, independent of scenes, audio and input.
signal changed
signal event_occurred(message: String)
enum Motor { DONOR, CARRIED, DROPPED, INSTALLED }
var motor := Motor.DONOR
var dropped_position := Vector2.ZERO
var repair_elapsed := 0.0
var repaired := false
var active_seconds := 0.0
var events: Array[Dictionary] = []

func record(message: String) -> void:
	events.append({"seconds": snappedf(active_seconds, 0.01), "event": message})
	event_occurred.emit(message)
	changed.emit()

func shortcut_closed() -> bool:
	return motor != Motor.DONOR

func salvage() -> bool:
	if motor != Motor.DONOR:
		return false
	motor = Motor.CARRIED
	record("Motor salvaged. Shortcut CLOSED; work light OFF. Permanent corridor remains OPEN.")
	return true

func drop_at(point: Vector2, safe: bool) -> bool:
	if motor != Motor.CARRIED or not safe:
		return false
	motor = Motor.DROPPED
	dropped_position = point
	record("Motor dropped safely. Repair progress retained.")
	return true

func pick_up() -> bool:
	if motor != Motor.DROPPED:
		return false
	motor = Motor.CARRIED
	record("Motor picked up.")
	return true

func advance(delta: float, working: bool, in_range: bool, paused: bool, duration: float) -> void:
	if paused:
		return
	active_seconds += maxf(delta, 0.0)
	if not working or not in_range or repaired or motor != Motor.CARRIED:
		return
	repair_elapsed = minf(repair_elapsed + maxf(delta, 0.0), duration)
	if repair_elapsed >= duration:
		repaired = true
		motor = Motor.INSTALLED
		record("PUMP REPAIRED — circulation restored. Motor installed once; repair is permanent.")
	else:
		changed.emit()
