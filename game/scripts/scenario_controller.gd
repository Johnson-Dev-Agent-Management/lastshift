extends RefCounted
## Deterministic one-shot authored events. Resources stay in the run simulation.
var profile: Resource
var coolant_fired := false
var repair_seen := false
var repair_age := 0.0
var leak_warned := false
var warning_age := 0.0
var leak_fired := false
var final_push := false

func _init(config: Resource) -> void:
	profile = config

func advance(delta: float, run) -> void:
	if run.repaired:
		if repair_seen: repair_age += delta
		else: repair_seen = true
	var eligible: bool = run.repaired and repair_age + 0.000000001 >= profile.recovery_seconds and run.charge >= profile.leak_charge_gate and run.heat < profile.heat_warning_enter and not run.heat_warning
	if leak_warned and not leak_fired:
		warning_age += delta
		# Recheck prerequisites at onset too; heat trouble never creates a backlog.
		if eligible and warning_age + 0.000000001 >= profile.leak_warning_seconds:
			leak_fired = true
			run.leak_active = true
			run.record("HULL LEAK — Cargo. Patch with your repair tool to stop the extra air loss.")
	elif not leak_warned and eligible:
		leak_warned = true
		run.record("CARGO SEAL STRAIN — a leak is developing. Your built-in repair tool can patch it.")
	if not final_push and run.charge >= profile.final_push_charge:
		final_push = true
		run.record("FINAL PUSH — charge nearing ready. Keep a route back to the bridge.")

func snapshot() -> Dictionary:
	return {"coolant_fired": coolant_fired, "repair_age": repair_age, "leak_warned": leak_warned,
		"warning_age": warning_age, "leak_fired": leak_fired, "final_push": final_push}
