# M3 complete authored run: candidate and evidence

Implemented on `feat/m3-authored-run` from merged M2 baseline `c076173`. Application **0.3.2**, profile **m3-candidate-01**. The design plan now records the requested satisfying full-charge visual/audio treatment under M5; its scope and mechanics remain unchanged. Godot and official export templates remain pinned to `4.6.3.stable.official.7d41c59c4` / `4.6.3.stable`; see [toolchain provenance](toolchain.md). This milestone completes the authored scenario and its outcomes. M4 difficulty/recovery tuning and M5 presentation work remain separate.

## Authored sequence and tuning

| Beat / setting | Candidate behavior |
| --- | --- |
| Ordinary opening | Functioning pump; air/heat held; four accumulated seconds reseating Cargo's SERVICE connector, then Engineering cooling OFF → ON |
| Emergency transition | Scheduled jump, surge/isolation and evacuation/pod failure pages last six seconds each; the final way-home page waits for E/Enter/click; resources held; Escape pauses the report |
| Coolant fault | Fires once at the surge report, visibly stopping the pump; response clock starts when emergency control returns |
| Existing repair / charging | Six accumulated seconds for pump; 120 seconds of actual powered charging; approved M2 rates retained |
| Leak eligibility | Repaired pump for at least 40 active seconds, charge ≥30%, heat below 68 and heat-warning flag clear |
| Leak warning / onset | Six-second lead-in; eligibility rechecked at onset, so unsafe heat delays it |
| Leak cost | Extra 0.35 air/s until patched |
| Patch | Eight accumulated seconds using the built-in tool; removes only extra drain permanently |
| Final push | One-time message and quiet synthesized Music layer at 70% charge; no new fault |
| Escape | Full charge plus local E at the Bridge; resources continue until the request succeeds |
| Retry | Fresh emergency by default; separate option replays the safe opening |

The opening is player-paced rather than enforcing the plan's hypothetical 45–60 seconds with a wait. No lethal clocks run during learning or the report. Its first three pages last six seconds each (18 seconds to the final page); the final page holds indefinitely until the player chooses Begin emergency. This preserves reading time without consuming emergency response time. A practiced player can finish the checklist faster. The leak adds a decision during the shortened charge; it does not lengthen the charge requirement. There are no random faults, patch inventory, repeated incidents or repair regression. The transition starts with a calm confirmation, then uses dim/amber presentation for the failure; camera shake and broader presentation/accessibility polish remain for M5.

All existing M2 resource values remain unchanged: capacity 6, consumer costs 2/2/4; starting air/heat 100/38; air drain 0.08/s with life support and 0.22/s without; idle heat +0.10/s, charging +0.35/s, repaired cooling −0.42/s; reserve up to +25 once; warning 68/clear 62; cutoff 86/restart below 64; critical 92/clear below 88/grace 30s. With an open leak the air rates are 0.43/s and 0.57/s. Patching restores the ordinary rates without adding air. A full reserve buys about 58 or 44 seconds with the leak open; those are arithmetic margins, not measured player response.

## State, ordering and reset

`run_controller.gd` extends the existing authoritative simulation with OPENING, TRANSITION, EMERGENCY, WON and LOST phases. `scenario_controller.gd` owns one-shot eligibility/timers only; resource accounting remains in the simulation. All clocks share its 1/60-second accumulator. Opening and emergency active time are recorded separately; results' active-play total excludes transition and pause time.

Work completes before that tick's resource update, so finishing a patch removes its extra drain immediately, as completing the pump immediately enables allocated cooling. Resource failure then resolves before any queued bridge request: air zero or expired critical grace defeats a same-tick jump. Successful jump and either failure freeze all resource/scenario clocks, close panels, stop looping audio and open results. Movement freezes in the terminal tick. Results identify the cause and offer advice based on actual repairs, allocation and reserve use.

Pause freezes the report, leak lead-in, repair work and survival clocks. Map/power/reserve panels retain their M2 emergency-time behavior. Retrying replaces run/scenario state and resets the motor, shortcut gate, resources, charge, patch, alerts, menus, animation and audio. Opening replay also resets the checklist and restores the initially working pump. Work-mode and volume preferences survive; run progress does not. No mid-run save was added.

## Automatically checked

On November 11, 2026 UTC, the selected Linux environment passed:

```sh
python3 scripts/dev.py check --clean
python3 -m py_compile scripts/dev.py
git diff --check
```

The check command verifies engine identity, clean import and an actual initialized scene/physics startup marker, then runs M1, M2 and M3 suites. Exit codes, required success markers and script/import errors are checked. Existing regressions cover component safety, reachability, physical arrow input, overlapping dropped-motor pickup, retained pump repair, allocation/cadence/threshold accounting and local equipment controls.

M3 checks cover a 600-second safe opening; interrupted connector and patch work; ordered announcements and paused transition; one-shot coolant/leak/final-push events; repair/time/charge/heat gates including heat changing during lead-in; patch persistence without component consumption/refill; same-tick loss-before-jump ordering for both causes; frozen outcomes; state-aware loss advice; matching scenario/resource snapshots at 30/60/120/144 Hz; actual scene input, local bridge range, audio-loop stop and repeated outcome/retry/opening cycles. The critical-heat result is exercised with explicit threshold fixtures.

The actual CharacterBody2D travels from the Engineering power approach to the Cargo leak approach by the permanent route in **12.83 seconds** at 180 px/s and 60 Hz. Eight seconds of patch work makes that a minimum 20.83-second response from the console before reading/decision time. The scripted policies allow 14 seconds each way. Existing measured routes remain 8.70 seconds to the donor through the open shortcut, 13.17 seconds back to the pump through the permanent route, and approximately 13.6 seconds between power and drive. Route tolerances/waypoints are in the test scripts.

Two complete emergency-start simulations use those travel allowances, ten seconds of initial decision allowance, six-second pump repair, two 16-second drive-panel trips and a 12-second final bridge allowance. Neither uses the reserve:

| Scripted policy | Emergency duration | Air at escape | Heat | Hull |
| --- | --- | --- | --- | --- |
| Life support + drive, cooling breaks, patch during a break | 319.18 s (5.32 min) | 66.77 | 44.17 | Sealed |
| Cooling + drive, life support off, endure the leak | 201.90 s (3.37 min) | 35.53 | 31.29 | Leaking |

Both resolve an actual successful bridge request. `builds/m3-scripted-runs.json` and the test logs retain reproducible data. These are simulation policies with route allowances, not full physical traversal for every journey or evidence of human fairness. Continuous charging may still dominate for practiced players; the patch's air benefit must be weighed against travel burden in M4. The original 8–12 minute target remains unvalidated.

The Windows export command is `python3 scripts/dev.py export-windows`. It uses the official matching release template, verifies PE/x86_64 identity and packages `LastShift.exe`, the M3 playtest guide, source/executable identity, credits and license notices as `builds/LastShift-M3-Windows-x86_64.zip`. CI runs setup, clean checks and export on Ubuntu 24.04 and Windows Server 2022, uploading logs and both policy measurements. Exact build/CI results are recorded on the PR; headless Windows CI is not native Windows graphical playtesting.

## Actually rendered and operated

The Linux Compatibility build was operated with actual keyboard/mouse input on the shared desktop, in an 1180×812 window with a letterboxed 16:9 view. The agent walked from Engineering through the shortcut to the connector, stopped at 45%, resumed to completion, returned and cycled cooling. The failed-jump report appeared and returned control to the broken-pump emergency with resources held during the report.

A separate targeted pass used F7's prepared leak state. The agent held work to 30%, paused, resumed and sealed the hull; air drain visibly returned from 0.43/s to 0.08/s. It then walked the permanent route back to Engineering, explicitly switched life support off and drive on, waited for charge completion, restored life support, walked to the Bridge and pressed E. SHIFT COMPLETE appeared with frozen resources. Keyboard Enter retried directly into a fresh emergency; the pause menu's opening replay restored the safe checklist. This used a developer setup and includes tool/inspection delays: it is not an unaided full-shift or balance playtest.

`game/tests/capture.gd` rendered opening/map/connector/power, the report, emergency, leak warning/active/partial/sealed, ready bridge, victory, air-loss and heat-loss fixtures at exact **1280×720 and 1920×1080**. Transition, leak and outcome layouts were visually inspected. A decorative crate overlapped the hull marker; it was removed and fresh renders confirmed separation. Reproduce in a graphical Desktop terminal:

```sh
python3 scripts/dev.py run --script res://tests/capture.gd
```

Images go to `builds/screenshots-m3/`. Capture fixtures directly prepare states; their outcome times are not playtest measurements. Audio playback state and stopping are checked automatically, but the cloud desktop had no usable ALSA output device and fell back to a dummy driver. Audible cues/mix were not heard. A Godot shutdown warning reports one `AudioStreamWAV`/`AudioStreamPlaybackWAV` reference pair when quitting with a loop active, including the opening startup smoke run; gameplay suites pass without that warning. Explicit stop-on-exit is included, but does not clear that engine shutdown diagnostic in this environment. VSync is also unsupported by the cloud's software renderer. These do not establish behavior on a native audio/GPU driver.

### 0.3.1 player-feedback pass

In 0.3.1, room-to-corridor fixtures started beside the Engineering spawn and continued through all five rooms' permanent exits, with exit chevrons and brighter corridor strips. They remained independent of consumer power and salvage. The Cargo motor belongs to a labeled hydraulic door pump; that revision also drew a line to the shutter. Prompts and the confirmation explain pressure loss, shutter closure and work-light isolation before committing. Cargo's SERVICE label sits beneath its connector, clear of the room title; door-pump and Bridge helm labels are centered using their actual text width in both states.

The pre-jump checklist now leads through four distinct report pages. The scheduled jump precedes the surge; the pump stops at that surge while response time remains held. Tests check that phase boundary, pause, report order and one-shot failure, then exercise the existing emergency/retry regressions. Scripted emergency outcomes and physical traversal measurements are unchanged. The plan records the requested satisfying blue completed-drive fill, READY label and completion cue for M5; that visual is not implemented in this pass.

Actual Linux keyboard/mouse checks completed the connector/power checklist, observed the scheduled-jump and evacuation pages and returned to emergency control, then reviewed and accepted the hydraulic-motor salvage. That revision's fixtures covered every room's lights, each report page, the salvage panel, door pump before/after removal, shutter closure and both helm labels at both target resolutions. Visual inspection prompted moving lower-room fixtures below the room-title band. Native Windows graphics/audio and human evaluation of the revised guidance remain local checks; export and CI results are recorded on the PR.

### 0.3.2 guidance and report-pacing pass

Room floor strips and exit chevrons are removed; only the main corridor retains floor lights. Opening directions now favor Engineering's east service shortcut to Cargo. The decorative line between the donor motor and shutter is removed, while its hydraulic explanation, salvage warning and permanent route remain intact.

The first three report pages last six seconds each, up from four. The last page waits for **Begin emergency**, activated by fresh E, Enter or a mouse click. Resources and scenario clocks stay held until dismissal. Automated checks cover a 600-second final-page hold, rejection of early/paused/repeated dismissal, holding E through the sequence, pause/resume focus, E closing only the report, and Enter activation. The full M1/M2/M3 regression suites and scripted emergency policies still pass.

Actual Linux keyboard/mouse operation traversed the shortcut, completed the connector/power checklist, observed the report waiting at 100 air / 38 heat, paused and resumed it, then clicked Begin emergency to restore control and start resource drain. Fresh fixtures at both target resolutions cover the uncluttered rooms, door pump without its floor line, and the waiting report. Visual inspection caught a button/footer overlap; the final button position leaves a clear gap. This was targeted interaction and rendering, not a new full-run balance playtest. Native Windows graphics/audio remain local checks; the updated export and CI identities are recorded on the PR.

## Next milestone and open evidence

**M4 Difficulty and recovery:** play careful, aggressive and imperfect full shifts without developer shortcuts. Measure warning comprehension, travel cost, patch value, reserve use and whether a player can recover from a mistake and explain a loss. Tune only from that evidence; keep completed repairs permanent and preserve the shorter charge unless playtesting motivates a change.

Native Windows 10/11 launch, GPU/display scaling, audible output, input/focus behavior, a complete unaided human run, enjoyment and difficulty remain local playtest work. Use [the M3 test guide](playtest-m3.md). Presentation is still readable placeholder art and synthesized audio; richer endings, alert hierarchy and accessibility polish remain M5.
