# M4 difficulty and recovery: candidate evidence

Version **0.4.0**, profile **m4-candidate-01**, branch `feat/m4-difficulty-recovery`, from merged M3 `0ef5569539419dd2b576a93785f5fc9d30b95c21`. Godot and matching official templates remain 4.6.3. Evidence collected November 11, 2026 UTC.

**Status:** recovery implementation and reproducible checks are ready for player review. M4's human gate remains open: a fresh player must explain a loss, choose an adjustment and test it. Automated or agent-operated success cannot establish comprehension, enjoyment or difficulty balance.

## Observed issues and changes

| Observation | Change | Limits |
| --- | --- | --- |
| A distant critical warning cannot be recovered from within 30 seconds after five seconds of recognition, 13.63 seconds of physical travel, then cooling below the clear threshold | Critical grace **30 → 65 seconds**; no other tuning changes | Explicit threshold fixture, not a claim that ordinary play often reaches critical heat |
| In a live aggressive run, full charge and low air simultaneously said return to Bridge and patch Cargo | At full charge, LOW AIR directs the player to Bridge; critical countdown still takes priority | Does not calculate a guaranteed safe escape or change resource consequences |
| Release players lacked a convenient way to share the state behind a confusing outcome | Opt-in Save playtest report in pause/results, with exact profile settings, packaged build identity, periodic resource/location samples and events | No autosave or upload; source/editor reports need a separately recorded commit |

The direct critical response is **30.42 seconds**: 13.63 seconds of travel plus actual cooling from the heat accumulated during travel. With five seconds of delayed reaction it is **36.97 seconds**. The former 30-second window expires with heat still about 90.24; the candidate clears critical below 88 with about 28 seconds remaining. **65 > 2 × 30.42**, satisfying the plan's initial direct-response allowance for this measured route. Cooling must still be repaired and deliberately powered. Longer delays can still lose; no hidden refill, automatic allocation or new protection was added.

All other settings remain M3's: 120 powered seconds of charge, capacity 6 and costs 2/2/4, starting air/heat 100/38, air drains 0.08/0.22 plus leak 0.35, reserve +25, heat rates +0.10 idle / +0.35 charging / −0.42 cooling, warning 68/clear 62, cutoff 86/restart below 64, critical 92/clear below 88, repairs 6/8 seconds, and leak gates 40 seconds / 30% charge / safe heat. The opening remains player-paced with no survival clocks.

At the fastest air loss, the low-air threshold of 25 provides **43.86 seconds** until depletion if nothing changes. The unchanged measured power-to-leak route is 12.83 seconds plus eight seconds of work: **20.83 seconds**, or 41.66 doubled. A full reserve also buys 43.86 seconds at that worst rate, or 58.14 seconds with life support and the leak active. These are arithmetic response margins, not evidence that a player notices or understands the warning in time. No additional air, travel or reserve tuning was justified by the available evidence.

## Automatic checks

Commands used:

```sh
python3 scripts/dev.py check --clean
python3 scripts/dev.py export-windows
```

Clean import, initialized scene startup, M1/M2/M3 regression suites and the new M4 suite pass. The M4 suite moves the actual CharacterBody2D through collision geometry, invokes range-checked local equipment and completes an actual Bridge request. It does not teleport, refill, pre-repair or accelerate the simulation clock within the three full emergency policies; `--fixed-fps 60` runs the same fixed steps without real-time waits. Policy decisions and exact waypoints are scripted.

| Physical policy | Emergency duration | Air at escape | Heat | Reserve / hull |
| --- | --- | --- | --- | --- |
| Careful: life support + drive, cooling breaks, patch during a break | 301.13 s | 68.62 | 45.11 | Unused / sealed |
| Aggressive: cooling + drive, endure leak | 179.62 s | 39.35 | 33.59 | Unused / leaking |
| Imperfect: wrong turn, interrupted pump, cooling off during arming trip, delayed heat response through cutoff, reserve detour, interrupted patch | 342.63 s | 65.02 | 46.85 | Used / sealed |

The same three routes produced these results under the M3 baseline: none reached critical heat, so changing critical grace does not make their ordinary resource budget easier. The imperfect route specifically demonstrates retained work, retained charge after cutoff, one reserve use, permanent patch relief and eventual escape. Its comfortable final air does not prove that uncoached players will discover that sequence.

Separate critical fixtures explicitly set repaired cooling, the critical threshold and a Jump Chamber starting position. They compare the old window, the candidate with five seconds of recognition delay, and the direct candidate route. They are clearly separated from the full runs in `builds/m4-physical-runs.json`.

Report tests cover periodic active-time sampling, pause, JSON save/read, exact tuning, event history, a clean report on retry and developer-setup identification. Warning tests verify Bridge guidance at full charge, Cargo guidance before completion and critical-countdown priority. Existing M3 tests still cover both terminal failures, deterministic outcome order and repeated retry.

The Windows package is `builds/LastShift-M4-Windows-x86_64.zip`; CI validates setup/check/export on Ubuntu 24.04 and Windows Server 2022. The PR records exact commit, export and CI identities. An export or headless Windows pass is not a native Windows graphical playtest.

## Actually operated and rendered

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
