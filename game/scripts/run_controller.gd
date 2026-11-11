extends "res://scripts/ship_simulation.gd"
## Opening, transition, emergency and outcomes share the simulation's fixed clock.
const Scenario = preload("res://scripts/scenario_controller.gd")
enum Stage { OPENING, TRANSITION, EMERGENCY, WON, LOST }
const ANNOUNCEMENTS := [
	"COOLING VERIFIED — CHECKLIST COMPLETE\nBridge: preparing the scheduled jump.",
	"JUMP FAILED — POWER SURGE\nCoolant motor offline. Service section isolated.",
	"CREW EVACUATION COMPLETE\nYour maintenance pod failed its launch check.",
	"ONE LIFE SIGN REMAINING\nThe ship is your way home.\nRestore cooling, then charge the jump drive."
]
var stage := Stage.OPENING
var scenario: RefCounted
var opening_seconds := 0.0
var connector_elapsed := 0.0
var connector_ready := false
var opening_power_off := false
var power_practiced := false
var transition_seconds := 0.0
var announcement_index := 0
var leak_active := false
var leak_patched := false
var patch_elapsed := 0.0
var work_target := "pump"
var jump_requested := false

func _init(config: Resource = DEFAULT_PROFILE, with_opening := true) -> void:
	super(config)
	scenario = Scenario.new(config)
	if with_opening:
		repaired = true
		repair_elapsed = profile.repair_seconds
		record("Pre-jump check. Take Engineering's east service shortcut to Cargo.")
	else:
		begin_emergency()

func command_blocked() -> String:
	var blocked := super.command_blocked()
	if not blocked.is_empty(): return blocked
	if stage == Stage.TRANSITION: return "Stand by — ship status report in progress."
	return ""

func emergency_command() -> bool:
	return stage == Stage.EMERGENCY and command_blocked().is_empty()

func salvage() -> bool:
	return super.salvage() if emergency_command() else false

func arm_drive() -> String:
	return super.arm_drive() if stage == Stage.EMERGENCY else "Complete the maintenance checklist first."

func use_reserve() -> String:
	return super.use_reserve() if stage == Stage.EMERGENCY else "Emergency reserve sealed during routine work."

func set_power(consumer: String, enabled: bool) -> String:
	if not command_blocked().is_empty(): return command_blocked()
	if stage == Stage.OPENING:
		if not connector_ready: return "Reseat the Cargo service connector before the power check."
		if consumer != "cooling": return "Routine check: switch cooling OFF, then ON. No resource danger during the checklist."
	var result := super.set_power(consumer, enabled)
	if result.is_empty() and stage == Stage.OPENING:
		if not enabled: opening_power_off = true
		elif opening_power_off:
			power_practiced = true
			stage = Stage.TRANSITION
			record(ANNOUNCEMENTS[0])
	return result

func air_rate() -> float:
	if stage != Stage.EMERGENCY or terminal(): return 0.0
	return super.air_rate() - (profile.leak_drain if leak_active else 0.0)

func heat_rate() -> float:
	return super.heat_rate() if stage == Stage.EMERGENCY else 0.0

func pump_status() -> String:
	return "ONLINE / ROUTINE" if stage == Stage.OPENING and cooling_powered else super.pump_status()

func step(working: bool, in_range: bool) -> void:
	if stage == Stage.OPENING:
		opening_seconds += STEP
		if working and in_range and work_target == "connector" and not connector_ready:
			connector_elapsed = minf(profile.connector_seconds, connector_elapsed + STEP)
			if connector_elapsed + 0.000000001 >= profile.connector_seconds:
				connector_elapsed = profile.connector_seconds
				connector_ready = true
				record("CONNECTOR SEATED — return to Engineering. Cycle cooling OFF then ON to finish the pre-jump check.")
		return
	if stage == Stage.TRANSITION:
		if awaiting_report_dismissal(): return
		transition_seconds += STEP
		var index := mini(ANNOUNCEMENTS.size() - 1, int((transition_seconds + 0.000000001) / profile.transition_message_seconds))
		if index != announcement_index:
			announcement_index = index
			if index == 1: fail_coolant()
			record(ANNOUNCEMENTS[index])
		return
	if stage != Stage.EMERGENCY: return
	if working and in_range and work_target == "leak" and leak_active:
		patch_elapsed = minf(profile.patch_seconds, patch_elapsed + STEP)
		if patch_elapsed + 0.000000001 >= profile.patch_seconds:
			patch_elapsed = profile.patch_seconds
			leak_active = false
			leak_patched = true
			record("HULL SEALED — extra air loss stopped. This patch is permanent.")
	super.step(working and work_target == "pump", in_range)
	if terminal():
		jump_requested = false
		return
	scenario.advance(STEP, self)
	# Bridge input is queued. Survival resolves first, including the request tick.
	if jump_requested:
		jump_requested = false
		if escape_ready():
			escaped = true
			stage = Stage.WON
			drive_powered = false
			record("SHIFT COMPLETE — jump successful. You brought the ship home.")

func awaiting_report_dismissal() -> bool:
	return stage == Stage.TRANSITION and announcement_index == ANNOUNCEMENTS.size() - 1

func dismiss_report() -> bool:
	if not awaiting_report_dismissal() or is_paused: return false
	begin_emergency()
	return true

func fail_coolant() -> void:
	if scenario.coolant_fired: return
	scenario.coolant_fired = true
	repaired = false
	repair_elapsed = 0.0

func begin_emergency() -> void:
	if stage == Stage.EMERGENCY or terminal(): return
	fail_coolant()
	stage = Stage.EMERGENCY
	# Routine resources never depleted; start the response clock only now.
	record("GET HOME. Coolant pump failed. Salvage the Cargo motor; restore cooling, then charge the drive.")

func request_jump() -> String:
	if not emergency_command(): return "Jump unavailable."
	if not escape_ready(): return "Charge the drive fully before initiating jump."
	jump_requested = true
	return "Jump requested — checking ship conditions."

func stop_simulation(cause: String) -> void:
	if terminal(): return
	stage = Stage.LOST
	jump_requested = false
	super.stop_simulation(cause)

func recovery_advice() -> String:
	if escaped: return "Your repairs held. The ship is home."
	if failure == "CRITICAL HEAT":
		if not repaired: return "Restore the coolant pump earlier so cooling can lower heat."
		if not cooling_powered: return "Keep repaired cooling powered during recovery; stop drive charging to free power."
		return "Cooling was running. Stop charging sooner to leave enough time for heat to fall."
	if leak_active: return "The Cargo leak was still open. Patch it to stop the extra air loss."
	if not life_support_powered: return "Life support was off. Restore its power when charging pauses to slow air loss."
	if not reserve_used: return "The emergency reserve was unused. It can buy time on the next attempt."
	return "Life support was on and the reserve was spent. Reduce delays and head to the bridge at full charge."

func snapshot() -> Dictionary:
	var result := super.snapshot()
	result.merge({"stage": Stage.keys()[stage], "opening_seconds": opening_seconds,
		"connector_seconds": connector_elapsed, "connector_ready": connector_ready, "power_practiced": power_practiced,
		"transition_seconds": transition_seconds, "leak_active": leak_active, "leak_patched": leak_patched,
		"patch_seconds": patch_elapsed, "jump_requested": jump_requested,
		"scenario": scenario.snapshot() if scenario != null else {}})
	return result
