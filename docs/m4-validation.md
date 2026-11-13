# M4 difficulty and recovery: candidate evidence

Version **0.4.1**, profile **m4-candidate-02**, branch `feat/m4-difficulty-recovery`, from merged M3 `0ef5569539419dd2b576a93785f5fc9d30b95c21`. Godot and matching official templates remain 4.6.3. Current evidence collected November 13, 2026 UTC; candidate 01 observations below date from November 11.

**Status:** the supplied human report supports increasing pressure. It does not close M4's fresh-player gate: explain a loss, choose an adjustment and test it. Automated or agent-operated success cannot establish comprehension, enjoyment or difficulty balance. Another human run on candidate 02 is needed.

## Supplied player evidence

The user reported that air and heat made the game too easy and supplied `run-2026-11-13T02-55-55-604641.json` (0.4.0 / `m4-candidate-01`). The report records **169.22 emergency seconds**, **64.14 air**, **43.86 heat**, hull sealed, reserve unused, and no developer setup. Heat never reached 44 in its samples/events. There are 44 samples without truncation. The safe opening took 31.72 seconds, separately from emergency time.

The player salvaged at 15.50s, armed while carrying at 23.70s, finished the pump at 42.88s, and charged with cooling / life support off from 48.78s. The leak began at 90.78s; patching from 98.18s to 106.17s removed it while charge continued. Full charge arrived at 168.80s, followed promptly by the Bridge jump. This efficient route was missing from the original physical-policy tests.

The packaged metadata names commit `b753fa98cf200c149e6a3394f49469d0afc91601` with `source_dirty: true`. Its exact recorded tuning matches candidate 01; it is not evidence of a clean checkout's binary identity. The report alone does not establish platform, audio, display/focus behavior or fresh-player comprehension. The raw attachment stays local; only gameplay observations are summarized here.

## Tuning and response windows

| Setting | Candidate 01 | Candidate 02 |
| --- | --- | --- |
| Air drain with life support | 0.08/s | **0.14/s** |
| Air drain without life support | 0.22/s | **0.50/s** |
| Charging heat added | +0.35/s | **+0.65/s** |
| Net charging heat with repaired cooling | +0.03/s | **+0.33/s** |
| Net charging heat without cooling | +0.45/s | **+0.75/s** |
| LOW AIR threshold | 25 | **36** |
| HIGH HEAT enter / clear | 68 / 62 | **64 / 58** |

Keep **120 powered seconds of charge**, starting air/heat 100/38, idle heat +0.10/s, cooling −0.42/s, leak drain +0.35/s, reserve +25, cutoff 86/restart below 64, critical 92/clear below 88, critical grace 65 seconds, repairs 6/8 seconds, capacity 6 and power costs 2/2/4. Authored leak gates (40 seconds / 30% charge / safe heat) and player-paced opening remain unchanged. Repairs and charge remain permanent. Cooling without charging still recovers at −0.32/s.

At the fastest air loss, **36 / 0.85 = 42.35 seconds** remain at the warning. The measured power-to-leak route plus work is **12.83 + 8 = 20.83 seconds**, or 41.66 doubled. A reserve buys 29.41 seconds at that worst rate, or 51.02 seconds with life support and the leak active. HIGH HEAT at 64 leaves **(86 − 64) / 0.75 = 29.33 seconds** before cutoff without cooling, just over twice the measured 13.63-second distant return plus a one-second console action. These are arithmetic response allowances, not proof a player will notice and act in time.

The earlier M4 critical-grace adjustment remains: **30 → 65 seconds**. The direct Jump Chamber → Engineering response plus cooling below 88 took **30.42 seconds**, or **36.97 seconds** with five seconds of recognition delay. The old 30-second fixture expires with heat about 90.24; 65 exceeds twice the direct response. No automatic allocation or refill was added. Full-charge LOW AIR continues to prioritize Bridge escape; critical countdown has higher priority. Opt-in local reports remain available from pause/results.

## Automatic checks

Commands used:

```sh
python3 scripts/dev.py check --clean
python3 scripts/dev.py export-windows
```

Clean import, initialized scene startup and M1–M4 suites pass. The M4 suite moves the actual CharacterBody2D through collision geometry, invokes range-checked equipment and performs the Bridge request. Its six full emergency policies do not teleport, refill, pre-repair or accelerate simulation time; `--fixed-fps 60` runs fixed steps without real-time waits. Decisions and waypoints are scripted.

| Physical policy, candidate 02 | Emergency duration | Final air | Final heat | Outcome / reserve / hull |
| --- | --- | --- | --- | --- |
| Careful: life support + drive, cooling breaks, patch during a break | 385.98 s | 38.67 | 53.96 | Escape / unused / sealed |
| Aggressive: cooling + drive, endure leak, prompt escape | 179.62 s | 2.17 | 69.59 | Escape / unused / leaking |
| Aggressive with a physical reserve detour at LOW AIR | 179.62 s | 27.17 | 69.59 | Escape / used / leaking |
| Imperfect: wrong turn, interrupted pump, cooling off while arming, delayed cutoff response, reserve detour, interrupted patch | 480.23 s | 45.83 | 38.83 | Escape / used / sealed |
| Efficient: arm while carrying, cooling + drive, patch while charging, head straight to Bridge | 154.78 s | 27.82 | 80.53 | Escape / unused / sealed |
| Neglect: aggressive route, then delay ten seconds before restoring survival power / heading to Bridge | 179.55 s | 0.00 | 69.61 | AIR DEPLETED / unused / leaking |

The no-reserve aggressive route is now a narrow race; using the reserve buys a meaningful margin without extending charge. The imperfect policy waits for the actual heat-gated leak before patching, which now occurs later after the overheated start. It demonstrates retained work/charge and recovery, not that players will discover those decisions. The older M3 timing simulation now includes a ten-second travel allowance each way to use the reserve when enduring the leak; it is distinct from these physical walks.

A separate command-timing replay uses rounded action times from the supplied report. First it reproduces candidate 01 at **64.13 air / 43.85 heat**, within 0.1 of the recorded outcome; applying candidate 02 predicts **27.35 air / 79.85 heat** at the same escape time, with the hull sealed and reserve unused. This replay has no movement claims; the physical efficient policy above supplies route coverage. Neither is a new human playtest.

Separate critical fixtures set repaired cooling, critical heat and a Jump Chamber position. They compare the old countdown, candidate with a five-second notice delay, and direct response. `builds/m4-physical-runs.json` identifies physical policies, fixtures and timing replays separately. Report tests cover active-time sampling, pause, JSON save/read, tuning, event history, fresh retry and developer-setup identification. Warning tests cover full-charge Bridge guidance, pre-completion Cargo guidance and critical priority. Existing M3 tests cover both terminal failures, deterministic ordering and repeated retry.

For comparison, candidate 01's physical careful/aggressive/imperfect routes escaped at **301.13 / 179.62 / 342.63 seconds**, with **68.62 / 39.35 / 65.02 air** and **45.11 / 33.59 / 46.85 heat**. Those historical results are not measurements of candidate 02.

The Windows package is `builds/LastShift-M4-Windows-x86_64.zip`; CI validates setup/check/export on Ubuntu 24.04 and Windows Server 2022. The PR records exact commit, export and CI identities. An export or headless Windows pass is not a native Windows graphical playtest.

## Actually operated and rendered

**Current candidate, November 13 UTC:** the agent played a full Linux emergency retry on **0.4.1 / m4-candidate-02**, using real keyboard/mouse input. Salvaged, armed while carrying, repaired the pump, charged with cooling, patched Cargo and escaped directly from Bridge at **176.83 seconds**, **28.55 air**, **75.69 heat**, reserve unused. No F6/F7 setup was used. The rendered HUD showed −0.50 air/s and +0.33 heat/s during cooled charging, the sealed hull persisted, and LOW AIR was visible before escape. Results showed the correct candidate profile. Saving the report worked; its JSON has 38 samples, developer setup false, and no truncation. Local evidence: `builds/m4-live-efficient-candidate02.json`. Pauses and tool latency affect this run; waiting at the console before charging also cooled the ship more than in the reported human route. This was an operational check, not a new human balance result.

**Historical checks from candidate 01 (November 11 UTC):**

The agent operated the Linux Compatibility build using real keyboard/mouse input in an 1180×812 window with a letterboxed view. No F6/F7 prepared state was used for full runs. Tool latency and pauses to inspect evidence make these operational checks, not representative human timings.

- **Baseline aggressive, 0.3.2 / m3-candidate-01:** emergency retry, physical motor trip/repair/arming, cooling + drive, leak endured, survival power restored, Bridge jump. Escape at **278.63 seconds**, **4.06 air**, **14.15 heat**, reserve unused. Charge finished at 216.18 seconds with 38.52 air; inspection delays left another 62.45 seconds before escape. The full-charge LOW AIR patch prompt was visibly contradictory and motivated the focused warning fix. A missed repair approach also cost time before the player moved closer.
- **Candidate imperfect, 0.4.0 / m4-candidate-01:** deliberately walked toward the closed shutter, interrupted the pump at 50%, left cooling off during arming, delayed response through cutoff at 79.9% charge, enabled cooling, detoured for the reserve, interrupted the patch at 38%, resumed/sealed, then deliberately reassigned drive power and escaped. Result: **422.38 seconds**, **37.75 air**, **66.10 heat**, reserve used and hull sealed. The reserve gave +25; sealing visibly changed air loss from 0.43/s to 0.08/s. The saved report contains 87 samples and 32 events, with developer setup false. This run did not enter critical heat; the grace change is tested by the separate fixture.
- **Candidate careful, 0.4.0 / m4-candidate-01:** complete emergency start with prompt pump repair, life support + drive, one deliberate cooling/patch trip, resumed charge, survival power restored and Bridge escape. The result showed **328.0 seconds**, **49.0 air**, **53.6 heat**, hull sealed and reserve unused. The patch/return trip visibly lowered heat while preserving 74.2% charge. Tool delays affected response times, but no cutoff or developer setup was used.

The pause and results Save playtest report buttons were both operated. The final dialog wrapped the absolute path cleanly and the saved JSON was read back to verify events, samples, profile and outcome. Local source evidence is retained as `builds/m4-live-baseline-aggressive.json`, `builds/m4-live-imperfect.json` and `builds/m4-live-careful.json`; generated files remain outside source control. The Windows package report-metadata path still needs native Windows exercise.

Fresh render fixtures cover pause/results report actions, low-air full-charge guidance and the critical countdown at **1280×720 and 1920×1080**. These fixture times are not playtest durations. Reproduce from a graphical Desktop terminal:

```sh
python3 scripts/dev.py run --script res://tests/capture.gd
```

Images go to `builds/screenshots-m4/`. The cloud uses software rendering and has no usable ALSA device, so audio falls back to a dummy driver. Audible relief was not heard. The previously documented active-loop WAV/playback shutdown warning remains; no native audio/GPU conclusion follows from it.

## Open acceptance and next milestone

Use [the M4 playtest guide](playtest-m4.md) and save each attempt before retrying. Obtain an uncoached Windows run and a loss/retry explanation; compare careful, aggressive and imperfect approaches on the same profile. Watch whether continuous cooling + drive dominates in practice, whether the reserve is found in time, and whether waiting between heat cycles feels useful or empty. The original 8–12 minute first-run target is still unvalidated and must not be enforced by extending the approved charge time.

**Next: M5 cohesion and readability**, after reviewing the M4 human evidence. That includes the requested satisfying blue full-charge drive treatment, accessibility options, sound/alert coherence and broader visual polish. No new incident, random failure, repair regression or later-milestone mechanic is part of this candidate.
