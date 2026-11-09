# M0 / M1 implementation evidence

Validated November 8, 2026 (America/Los_Angeles), in the selected Linux cloud development environment. Baseline repository was clean at `7ed2773` with only the game plan; no AGENTS.md, contribution instructions, or review policy files were present. The baseline was moved unchanged to `docs/last-shift-game-plan.md`. Working branch: `feat/m0-m1-walkable-ship`. No later milestone systems were added.

## Automated checks actually run

- `python3 scripts/dev.py setup` passed, including a rerun with cached archives. Engine identity: `4.6.3.stable.official.7d41c59c4`. Linux editor and matching `4.6.3.stable` template archives verified against pinned official SHA-512 values. Windows editor archive was also downloaded, hash-checked, and inspected for GUI/console executable filenames; it was not executed in this Linux environment.
- `python3 scripts/dev.py check --clean` passed: fresh cache import, imported SVG dimensions, live ship/player/HUD/collision nodes and physics frames, then behavior checks. Diagnostics are checked in addition to process exit status. Logs: `builds/import.log`, `startup.log`, `m1-tests.log`.
- Behavior checks cover partial work at 30/60/120 Hz; release/range/pause preservation; exactly-once salvage, pickup and installation; unsafe-drop rejection; no repair without the motor; permanent completion; every floor cell reachable before and after closure; every accepted grid-sampled drop reachable; real CharacterBody2D traversal and collision through the open/closed gate; real permanent-route traversal; toggle work, pause, drop/pickup and reset through the scene; repaired machinery playback state.
- `python3 scripts/dev.py export-windows` passed using official matching templates, embedded PCK, release mode, x86_64. The helper verifies the Windows PE signature and x86_64 machine type, writes source identity and executable SHA-512 to `builds/windows/build-info.json`, and packages the executable, guide, credits and Godot notices. Build output remains ignored by Git.
- Python helper compilation and `git diff --check` passed. The baseline file was verified byte-for-byte against the initial commit.
- Remote [CI run 42555359091](https://github.com/Johnson-Dev-Agent-Management/lastshift/actions/runs/42555359091) passed on **Ubuntu 24.04 and Windows Server 2022**, testing implementation commit `71d8ad098f59053ca717535b9ff21e897a759136`. Both runners completed fresh setup, clean import/startup/behavior checks, Windows export and artifact upload. This establishes native Windows headless engine/helper execution on that runner, not Windows 10/11 graphical player behavior.

During development, the checks caught GDScript type inference errors and an export launched before template setup finished. These were corrected and setup/import/behavior/export were rerun successfully. The final workflow runs dependent steps sequentially.

## Rendered and interacted with

The agent operated the actual Linux Godot Compatibility build on the shared desktop using keyboard input. Observed: all five room landmarks and routes; donor targeting; the cost dialog; cancellation preserving the shortcut; keyboard confirmation; carried motor and safe drop/pickup; the physical closed gate; return through the lit permanent corridor; repair interrupted at 33%; pause; resumed work using toggle mode; READY at 100%, installed motor and rotating pump; F10 local log; F5 reset after completion and while paused. This is an agent-operated check, not a fresh-player study.

The live desktop window was 1180×812 with a letterboxed 16:9 game view. `game/tests/capture.gd` separately rendered the same scene/HUD into exact 1280×720 and 1920×1080 viewports. The corrected map and repaired-state captures were visually inspected; the map, HUD, status text and controls fit. Captures are generated into `builds/screenshots/` with:

```sh
# In a graphical desktop terminal, from the repository root:
python3 scripts/dev.py run --script res://tests/capture.gd
```

The initial large map extended into the HUD; its scale/position were corrected. A work-stop message overwrote the completion message; completion now retains the recovery message. The pause checkbox now follows the T-key setting. Render captures and subsequent desktop inspection verified those corrections.

Audio stream generation, playback state and reset were checked in code. Audible quality, spatial mix and output-device behavior were **not** heard or validated. Rendered/headless/export results do not prove native Windows behavior, enjoyment, or difficulty balance.

## Timing foundation, not validated balance

All M1 tunables live in `game/m1_profile.tres`: walk speed **180 px/s**, work duration **6 s**, target range **100 px**. Carrying uses the same walk speed. Diagonal movement is normalized. Salvage is immediate after explicit cost acceptance; thinking/confirmation time is player-dependent. Pause and the salvage dialog freeze active clocks; the map does not.

| Route/action | Measurement | Method |
| --- | --- | --- |
| Pump approach → Cargo, open service shortcut | **8.70 s / 522 ticks** | Actual CharacterBody2D at fixed 60 Hz |
| Cargo approach → pump, permanent route after salvage | **13.17 s / 790 ticks** | Actual CharacterBody2D at fixed 60 Hz |
| Pump installation | **6.00 s accumulated work** | State checks at 30/60/120 Hz; on-screen hold/toggle interruption check |

Scripted route endpoints are `(340,400)` and `(1840,400)`. Shortcut waypoints: `(700,400)`, `(700,340)`, `(1720,340)`, then Cargo. Permanent return: `(1720,400)`, `(1720,840)`, `(480,840)`, `(480,400)`, then pump. Each waypoint accepts a 4 px arrival tolerance; route times include fixed-step rounding. They are reproducible traversal measurements, not human response times. Reading, orientation, wrong turns and decisions must be measured before lethal rates are chosen. The optional shortcut is intentionally faster than the plan's initial 10–20 second destination hypothesis.

## Implementation boundaries and review notes

- `repair_state.gd` owns the single motor lifecycle, repair time and completion, with signals; it is independently testable. Consumption happens only on completion. Partial work lasts for the current run; there is no mid-run save.
- `layout.gd` defines the five rooms and floor connections. The same geometry generates visible walls, physics walls and reachability checks. Closure affects one dedicated gate only. No component exists before salvage closes the gate, and the donor is far outside the gate's closing volume.
- Drops use the player's current position after a floor-clearance check, never a forward throw. Motors are non-solid and cannot obstruct a path. Targets require range and clear line of sight. Machinery/crates are readable non-solid placeholders, deliberately not physical obstacles.
- `ship.gd` owns M1 input, target selection, menus, collision assembly and placeholder drawing. `player.gd`, `hud.gd` and `feedback.gd` separate movement/presentation. There is one main scene; extracting reusable equipment scenes can follow the actual M2 responsibilities.
- F5 reset and F10 local logging are debug-only. No scenario-jump control, resource overlay, music, incidents or telemetry were added because M1 has no corresponding simulation.

## PR review follow-up

The independent “Review PR #1” chat reproduced two gaps in the original checks: horizontal arrow bindings used Right/Page Up instead of Left/Right, and a motor dropped exactly at the pump's position lost every target-selection tie to the pump. The bindings are corrected, and a dropped motor now takes priority on equal distance while retaining range and line-of-sight checks.

New regression cases first failed against the reviewed implementation, then passed after the fixes. They inject physical key events through Godot's Input Map for all WASD/arrow keys, verify key release and Page Up inactivity, and use Q/E to drop and recover a motor coincident with the pump from the center and all four sides. Each overlap case verifies retained partial work and successful repair completion. Clean import, startup and the expanded M1 suite passed locally. These follow-up checks are automated; they do not add a new native Windows graphical playtest claim. The PR's CI checks track the updated branch separately from the original run linked above.

## Remaining local work and next milestone

Local Windows 10/11 setup and graphical launch/play, Windows display scaling/input/audio, audible feedback, and fresh-player navigation/tradeoff comprehension still need testing using `docs/playtest-m1.md`. The unsigned M1 executable is a development test build. Release icons/signing, settings persistence and broader accessibility polish are deferred.

**Next: M2 Working systems** — authoritative power, heat, finite air, charge, drive arming, reserve, pause and a centralized survival balance profile. Start from these route/work measurements. Authored opening/incidents/outcomes remain M3; fairness and difficulty validation remain M4. No random failures or repair regression should be introduced.
