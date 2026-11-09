# M2 working systems: candidate and evidence

Implemented on `feat/m2-working-systems` from merged M0/M1 baseline `f6711af`. Existing in-progress changes were preserved and completed. The original design plan remains unchanged. Engine/templates remain pinned to Godot `4.6.3.stable.official.7d41c59c4` / `4.6.3.stable`; see `toolchain.md` for official download checksums and repeatable setup. No Android/XR tooling or later scenario systems were added.

## Candidate profile

`game/balance_profile.tres` replaces the M1-only resource and centralizes all current tunables. Profile ID: **m2-candidate-01**. Values are normalized units per active second, unless stated otherwise.

| Setting | Value |
| --- | --- |
| Walk speed / interaction range / accumulated pump work | 180 px/s / 100 px / 6 s |
| Capacity; life support / cooling / drive demand | 6; 2 / 2 / 4 |
| Starting air / heat / charge | 100 / 38 / 0 |
| Air drain, life support on / off | 0.08 / 0.22 per second |
| Low-air warning / one-shot reserve | 25 / up to +25, capped at 100 |
| Idle heat / extra charging heat / repaired cooling | +0.10 / +0.35 / −0.42 per second |
| Charge rate | +0.32% per second while powered, repaired and armed |
| Heat warning enter / clear | ≥68 / ≤62 |
| Drive cutoff / availability restored | ≥86 / strictly below 64 |
| Critical enter / clear / grace | ≥92 / strictly below 88 / 30 s |

Initial allocation is life support + cooling (4/6). Broken cooling still occupies its allocation; the pump status and heat trend expose that it has no cooling effect. Repair makes the allocated cooling useful immediately and permanently. Charging with cooling yields +0.03 heat/s; charging without cooling yields +0.45; repaired cooling without charging yields −0.32. Life support always consumes finite air. Full charge takes about 312.5 seconds of actual charging and releases only drive demand.

The first candidate iteration used 0.10/s powered air drain; the slower cooling-break policy then consumed more air than uninterrupted charging. This candidate uses 0.08 to give that longer policy an air-margin benefit. Warning thresholds moved from 72/66 to 68/62 to provide 40 seconds from warning to cutoff at maximum charging heat: `(86 − 68) / 0.45`. The measured drive-to-power route is 13.60 seconds, leaving a nominal 6.40 seconds for noticing and operating within a 20-second response budget, doubled to 40. This is a design allowance, **not measured human response or demonstrated fairness**. A full reserve buys roughly 114 seconds with support off or 313 with support on, absent later incidents.

## State and boundaries

`ship_simulation.gd` extends the single-motor/repair state and owns authoritative resource values, allocations, arming, reserve, threshold flags and clocks. It has no scene references. A 1/60-second accumulator produces matching results across caller cadences and retains fractional time across pause. Resource values clamp to 0–100. Terminal resource conditions resolve before charge completion in the same tick. Failure is a one-shot simulation stop; M3 will add full outcomes and final bridge ordering.

Equipment panels render that same state. Range and line of sight are rechecked before local commands; allocations are validated without silently switching other consumers. Cutoff and full charge release drive demand only. Cooldown clears below its lower threshold, but never reassigns power automatically. Partial repair, completed repair and stored charge never regress. Reserve preview updates with ongoing drain, rejects zero gain, and consumes once.

Power/reserve panels and the map keep simulation time running. Pause and salvage confirmation freeze it. Restart replaces run state and resets components, gate, resources, menus, movement and machinery audio; work-mode and volume preferences remain. The debug overlay and F6 prepared-state shortcut are excluded from release use. F10 logs active times, changes and snapshots locally with application/engine version and profile; record source commit/dirty status alongside source-run logs. Release packages include source and executable identity in `build-info.json`.

## Automated validation

On November 9, 2026 UTC, the Linux cloud environment ran:

```sh
python3 scripts/dev.py check --clean
python3 scripts/dev.py export-windows
```

The checks include engine identity, clean import, a startup marker after actual scene/physics initialization, the existing M1 regression suite, and the new M2 suite. Logs are scanned for script/import errors as well as exit codes and expected markers. `m2-tests.log` and `m2-scripted-runs.json` contain reproducible measurements.

M2 checks cover allocation/interlock rejection without side effects; retained repair and charge; meaningful powered cooling; 30/60/120/144 Hz and irregular integration; invalid-delta rejection; pause including fractional time and critical grace; capped one-shot reserve; warning/cutoff/restart hysteresis; manual drive reassignment; full-charge power release; terminal precedence and one-shot failure; local E/Escape controls; live panels; physical traversal between power and drive; and restart after failure. M1 checks retain arrow-input, overlapping dropped-motor pickup, reachability, gate collision and partial-work regressions.

| Route | Actual CharacterBody2D at 60 Hz |
| --- | --- |
| Pump approach → Cargo, open shortcut (M1 regression) | 8.70 s |
| Cargo → pump, permanent route (M1 regression) | 13.17 s |
| Power console → drive panel, permanent route | 13.62 s |
| Drive panel → power console | 13.60 s |

Waypoints and four-pixel arrival tolerance are in `game/tests/m1_test.gd` and `m2_test.gd`. These are traversal measurements, not reading or decision time.

The scripted runs include 8.70 seconds outbound, 10 seconds of decision allowance, 13.17 seconds return, six seconds repair, two conservative 16-second drive-panel journeys, and a 12-second bridge-return allowance. Resource simulation uses those allowances; these full policy runs do not physically walk every route. Neither uses the reserve. Both end alive, fully charged and eligible for the M2 bridge checkpoint:

| Policy | Total active time | Air at checkpoint | Heat | Charge | Cooling breaks |
| --- | --- | --- | --- | --- | --- |
| Careful: life support stays on; charge to heat 64, cool to 38 | 800.75 s (13.35 min) | 35.94 | 38.28 | 100% | 5 |
| Aggressive: cooling stays on, life support off while charging | 394.37 s (6.57 min) | 24.70 | 37.07 | 100% | 0 |

These demonstrate viable resource paths and a time/air tradeoff under one candidate. They do not prove balance, enjoyment, an imperfect-play recovery route, or final victory. Their durations bracket the eventual 8–12 minute target even before the opening and leak exist. Continuous charging may still dominate in practice; test that before adding mechanics or tuning to a win percentage.

The Windows export uses the matching official release template with embedded resources. The helper checks PE/x86_64 identity and packages the playtest guide, credits and notices in `builds/LastShift-M2-Windows-x86_64.zip`. CI runs the same setup/check/export sequence on Ubuntu 24.04 and Windows Server 2022, uploads logs plus scripted measurements, and records current results on the PR. Windows CI is headless validation, not a Windows graphical playtest.

## Rendered and interacted with

The actual Linux Compatibility game was operated on the shared desktop. Observed: resource trends at startup; F6 prepared state; local E power panel; mouse-driven over-capacity rejection; explicit life-support-off/drive-on allocation and rising charge; Escape panel close and pause; unchanged values while paused; keyboard Tab/Enter restart; and the F8 profile/rates overlay. The live window was 1180×812 with a letterboxed 16:9 view. This was a targeted control check using the developer shortcut, not a complete human M2 run.

`game/tests/capture.gd` rendered map, capacity rejection, charging, cooldown, reserve preview, critical grace and escape-ready fixtures at exact 1280×720 and 1920×1080. Map, equipment panels, warning text and escape-ready layouts were visually inspected. The first panel layout partly covered the warning banner; moving the panel and tightening spacing fixed that, and new captures verified the warning remains visible. Reproduce in a graphical desktop terminal:

```sh
python3 scripts/dev.py run --script res://tests/capture.gd
```

Images go to `builds/screenshots-m2/`. Threshold and ready captures use scripted state setup; they are not manually achieved gameplay outcomes. Audio generation/playback state is checked in code; audible output/mix was not heard or validated.

## Remaining work and next milestone

Use `playtest-m2.md` for native Windows graphical launch, display scaling, input/focus, audio, complete human runs, and tradeoff comprehension. Candidate tuning needs human evidence, especially whether the longer careful policy feels worthwhile and whether imperfect play can recover. The minimal terminal stop/bridge checkpoint intentionally lack the full opening, leak, final jump and results.

**Next: M3 Complete authored run** — ordinary opening, emergency transition, prerequisite-gated coolant/leak sequence, final bridge jump, cause-specific outcomes and repeatable retry. Preserve repaired benefits and deterministic ordering. Fairness tuning remains M4; do not add random faults or repair regression.
