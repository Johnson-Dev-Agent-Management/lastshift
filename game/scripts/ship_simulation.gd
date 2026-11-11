extends "res://scripts/repair_state.gd"
## One authoritative state: inherited motor/repair plus M2 resources and clocks.
## No scene references. Integrates at 60 Hz regardless of caller frame cadence.
const DEFAULT_PROFILE = preload("res://balance_profile.tres")
const STEP := 1.0 / 60.0
var profile: Resource
var air: float
var heat: float
var charge := 0.0
var life_support_powered := true
var cooling_powered := true
var drive_powered := false
var drive_armed := false
var drive_cooling_down := false
var reserve_used := false
var heat_warning := false
var critical := false
var critical_elapsed := 0.0
var is_paused := false
var failure := ""
var accumulator := 0.0

func _init(config: Resource = DEFAULT_PROFILE) -> void:
	profile = config
	air = profile.starting_air
	heat = profile.starting_heat

func used_power() -> int:
	return (profile.life_support_demand if life_support_powered else 0) + (profile.cooling_demand if cooling_powered else 0) + (profile.drive_demand if drive_powered else 0)

func cooling_active() -> bool:
	return repaired and cooling_powered and failure.is_empty()

func charging() -> bool:
	return drive_powered and drive_armed and repaired and not drive_cooling_down and charge < 100 and failure.is_empty()

func air_rate() -> float:
	return -(profile.powered_air_drain if life_support_powered else profile.unpowered_air_drain) if failure.is_empty() else 0.0

func heat_rate() -> float:
	if not failure.is_empty():
		return 0.0
	return profile.idle_heat_rate + (profile.charging_heat_rate if charging() else 0.0) - (profile.cooling_rate if cooling_active() else 0.0)

func drive_status() -> String:
	if not failure.is_empty(): return "STOPPED"
	if charge >= 100: return "READY"
	if not repaired: return "INTERLOCK: REPAIR PUMP"
	if drive_cooling_down: return "COOLING DOWN"
	if not drive_armed: return "NOT ARMED"
	return "CHARGING" if drive_powered else "OFF / CHARGE RETAINED"

func pump_status() -> String:
	if not repaired: return "BROKEN"
	if not failure.is_empty(): return "STOPPED / REPAIRED"
	return "COOLING" if cooling_powered else "OFF / REPAIRED"

func command_blocked() -> String:
	if is_paused: return "Paused — resume before operating equipment."
	if not failure.is_empty(): return "Simulation stopped — restart from the pause menu."
	return ""

func salvage() -> bool:
	return super.salvage() if command_blocked().is_empty() else false

func drop_at(point: Vector2, safe: bool) -> bool:
	return super.drop_at(point, safe) if command_blocked().is_empty() else false

func pick_up() -> bool:
	return super.pick_up() if command_blocked().is_empty() else false

func set_power(consumer: String, enabled: bool) -> String:
	var blocked := command_blocked()
	if not blocked.is_empty(): return blocked
	var demand := 0
	var current := false
	match consumer:
		"life_support": demand = profile.life_support_demand; current = life_support_powered
		"cooling": demand = profile.cooling_demand; current = cooling_powered
		"drive": demand = profile.drive_demand; current = drive_powered
		_: return "Unknown consumer."
	if current == enabled: return ""
	if enabled:
		if consumer == "drive":
			if not repaired: return "Charging interlock: repair the coolant pump first."
			if not drive_armed: return "Arm the drive at its panel in the Jump Chamber first."
			if charge >= 100: return "Charge is full. Drive power has been released."
			if drive_cooling_down: return "Drive cooling down: cool below %.0f, then reassign power." % profile.drive_restart
		if used_power() + demand > profile.capacity:
			return "Capacity exceeded: %d + %d > %d. Switch off a consumer first." % [used_power(), demand, profile.capacity]
	match consumer:
		"life_support": life_support_powered = enabled
		"cooling": cooling_powered = enabled
		"drive": drive_powered = enabled
	record("Power: %s %s (%d/%d)." % [consumer, "ON" if enabled else "OFF", used_power(), profile.capacity])
	return ""

func arm_drive() -> String:
	var blocked := command_blocked()
	if not blocked.is_empty(): return blocked
	if not drive_armed:
		drive_armed = true
		record("Drive ARMED. Allocate drive power at Engineering when the pump is repaired.")
	return ""

func reserve_gain() -> float:
	return 0.0 if reserve_used else minf(profile.reserve_amount, 100.0 - air)

func use_reserve() -> String:
	var blocked := command_blocked()
	if not blocked.is_empty(): return blocked
	if reserve_used: return "Emergency air reserve already used."
	var gain := reserve_gain()
	if gain <= 0.0: return "Air is full. Reserve kept for later."
	air += gain
	reserve_used = true
	record("Air reserve used: +%.2f air. Reserve EMPTY." % gain)
	return ""

func escape_ready() -> bool:
	return charge >= 100 and failure.is_empty()

func advance(delta: float, working: bool, in_range: bool, paused: bool, _duration: float) -> void:
	if paused or is_paused or not failure.is_empty() or not is_finite(delta) or delta <= 0:
		return
	accumulator += delta
	while accumulator + 0.000000001 >= STEP:
		accumulator = maxf(0.0, accumulator - STEP)
		step(working, in_range)
		if not failure.is_empty():
			accumulator = 0.0
			break
	changed.emit()

func step(working: bool, in_range: bool) -> void:
	# Repair completion makes cooling effective in this tick and never regresses.
	super.advance(STEP, working, in_range, false, profile.repair_seconds)
	var was_charging := charging()
	air = clampf(air + air_rate() * STEP, 0.0, 100.0)
	heat = clampf(heat + heat_rate() * STEP, 0.0, 100.0)
	if not heat_warning and heat >= profile.heat_warning_enter:
		heat_warning = true
		record("HIGH HEAT — enable cooling or pause drive charging.")
	elif heat_warning and heat <= profile.heat_warning_clear:
		heat_warning = false
		record("Heat warning cleared. Cooling is recovering margin.")
	if not drive_cooling_down and heat >= profile.drive_cutoff:
		drive_cooling_down = true
		drive_powered = false
		record("Drive cutoff: charge retained; %d-unit demand released. Cool down, then reassign power." % profile.drive_demand)
	elif drive_cooling_down and heat < profile.drive_restart:
		drive_cooling_down = false
		record("Drive available again. Reassign its power deliberately to resume charging.")
	if not critical and heat >= profile.critical_enter:
		critical = true
		critical_elapsed = 0.0
		record("CRITICAL HEAT — cooling required before grace expires.")
	if critical:
		if heat < profile.critical_clear:
			critical = false
			critical_elapsed = 0.0
			record("Critical heat cleared. Grace countdown reset.")
		else:
			critical_elapsed += STEP
	# Terminal resource conditions win over charge completion in the same tick.
	if air <= 0:
		stop_simulation("AIR DEPLETED")
	elif critical_elapsed + 0.000000001 >= profile.critical_grace_seconds:
		stop_simulation("CRITICAL HEAT")
	if not failure.is_empty(): return
	if was_charging:
		charge = minf(charge + profile.charge_rate * STEP, 100.0)
		if charge >= 100:
			drive_powered = false
			record("RETURN TO BRIDGE — JUMP READY. Full charge retained; drive power released.")

func stop_simulation(cause: String) -> void:
	if not failure.is_empty(): return
	failure = cause
	drive_powered = false
	record("SIMULATION STOPPED: %s. Restart from pause. M3 adds the full ending." % cause)

func snapshot() -> Dictionary:
	return {"seconds": snappedf(active_seconds, 0.01), "air": air, "heat": heat, "charge": charge,
		"air_rate": air_rate(), "heat_rate": heat_rate(), "power": used_power(),
		"life_support": life_support_powered, "cooling": cooling_powered, "drive": drive_powered,
		"armed": drive_armed, "cooldown": drive_cooling_down, "critical_seconds": critical_elapsed,
		"pump_repaired": repaired, "repair_seconds": repair_elapsed, "motor": motor,
		"reserve_used": reserve_used, "failure": failure}

func record(message: String) -> void:
	var entry := snapshot()
	entry["event"] = message
	events.append(entry)
	event_occurred.emit(message)
	changed.emit()
