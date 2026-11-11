extends Resource
## Candidate tuning, not validated difficulty. Rates are normalized units/second.
@export var profile_id := "m2-candidate-02"
@export var walk_speed := 180.0
@export var repair_seconds := 6.0
@export var interaction_range := 100.0
@export var capacity := 6
@export var life_support_demand := 2
@export var cooling_demand := 2
@export var drive_demand := 4
@export var starting_air := 100.0
@export var starting_heat := 38.0
@export var powered_air_drain := 0.08
@export var unpowered_air_drain := 0.22
@export var air_warning := 25.0
@export var reserve_amount := 25.0
@export var idle_heat_rate := 0.10
@export var charging_heat_rate := 0.35
@export var cooling_rate := 0.42
@export var charge_rate := 100.0 / 120.0
@export var heat_warning_enter := 68.0
@export var heat_warning_clear := 62.0
@export var drive_cutoff := 86.0
@export var drive_restart := 64.0
@export var critical_enter := 92.0
@export var critical_clear := 88.0
@export var critical_grace_seconds := 30.0
