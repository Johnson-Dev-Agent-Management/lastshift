extends RefCounted
## Shared geometry for rendering, collision generation and reachability checks.
const TILE := 40
const ROOMS := [
	Rect2(120, 120, 680, 480), Rect2(1400, 120, 680, 480),
	Rect2(120, 1080, 520, 400), Rect2(840, 1080, 520, 400), Rect2(1560, 1080, 520, 400)
]
const NAMES := ["ENGINEERING", "CARGO", "BRIDGE", "LIFE SUPPORT", "JUMP CHAMBER"]
const CORRIDOR := Rect2(120, 760, 1960, 160)
const SHORTCUT := Rect2(800, 280, 600, 120)
const CONNECTIONS := [
	Rect2(400, 600, 160, 160), Rect2(1640, 600, 160, 160),
	Rect2(280, 920, 160, 160), Rect2(1000, 920, 160, 160), Rect2(1720, 920, 160, 160)
]
const GATE := Rect2(1080, 280, 40, 120)
const PUMP := Vector2(340, 320)
const DONOR := Vector2(1840, 320)
const SPAWN := Vector2(480, 460)

static func floors() -> Array:
	return ROOMS + CONNECTIONS + [CORRIDOR, SHORTCUT]

static func is_floor(point: Vector2, closed := false) -> bool:
	if closed and GATE.has_point(point):
		return false
	for area: Rect2 in floors():
		if area.has_point(point):
			return true
	return false

static func safe_center(point: Vector2, closed := false) -> bool:
	# Same clearance as the player's capsule, including wall thickness.
	for offset in [Vector2.ZERO, Vector2(-20, -20), Vector2(20, -20), Vector2(-20, 20), Vector2(20, 20)]:
		if not is_floor(point + offset, closed):
			return false
	return true

static func cells(closed := false) -> Dictionary:
	var result := {}
	for y in range(3, 37):
		for x in range(3, 52):
			var cell := Vector2i(x, y)
			if is_floor(Vector2(cell) * TILE + Vector2.ONE * TILE / 2.0, closed):
				result[cell] = true
	return result

static func room_at(point: Vector2) -> String:
	for i in ROOMS.size():
		if ROOMS[i].has_point(point):
			return NAMES[i]
	if SHORTCUT.has_point(point):
		return "CARGO SERVICE SHORTCUT"
	return "PERMANENT CORRIDOR"
