# M4 difficulty and recovery playtest

Version **0.4.0**, profile **m4-candidate-01**. This is the same authored shift with one tuning change: critical-heat grace is **65 seconds**, previously 30. The measured return from the Jump Chamber plus actual cooling took longer than the old countdown. Charging still requires 120 powered seconds. Air drains, leak timing, reserve amount, repairs and travel speed are unchanged. This candidate has not passed the fresh-player difficulty gate.

## Launch and controls

Extract the entire `LastShift-M4-Windows-x86_64.zip` into a writable folder, then run **LastShift.exe**. Keep `build-info.json` alongside it; saved reports include that exact build identity. No editor is required. The unsigned executable has not been graphically tested on native Windows 10/11 in this cloud task.

From a prepared source checkout:

```sh
python3 scripts/dev.py run
```

On native Windows use `py -3 scripts/dev.py run`. See the repository README for setup.

| Action | Control |
| --- | --- |
| Move | WASD / arrows |
| Interact / work | E; hold for repairs |
| Toggle work mode | T, or pause-menu checkbox |
| Drop motor | Q |
| Map | M |
| Close equipment; pause when no panel is open | Escape |
| Menus | Mouse, or Tab / Shift+Tab and Enter / Space |
| Dismiss final report page | E / Enter / Begin emergency button |
| Save this attempt | Save playtest report in pause or results |

Equipment and map screens keep emergency time running. Pause stops all gameplay clocks. The opening checklist and report consume no emergency resources. The first three report pages last six seconds each; the final page waits for you. Progress survives interrupted work, and full charge releases drive power. Retry starts at the emergency; replay opening restores the safe checklist.

## Run the passes

For a fresh-player pass, read only launch/controls, then play without the route below. Save the report before retrying or quitting. Record confusion as it happens; do not use developer shortcuts. The next three passes intentionally provide more guidance and should be recorded separately.

1. **Careful:** take the east shortcut for the safe Cargo connector check, return and cycle cooling OFF/ON. After the report, salvage the door-pump motor and return through the permanent corridor. Repair cooling, arm the local drive, then manage power at Engineering. Try life support + drive with cooling breaks; patch the Cargo leak during a break. Return to Bridge at full charge. Was there useful breathing room after each repair?
2. **Aggressive:** retry from the emergency, repair and arm promptly, then use cooling + drive with life support off. Endure the leak and race the remaining air to the Bridge. Does that faster win feel like spending a resource? Was air loss visible enough to judge the risk? Do not increase charge time to create activity.
3. **Imperfect:** take a wrong turn toward the shutter after salvage, interrupt the pump repair once, and react late to one warning. Recover by reallocating power, finishing retained repairs and/or using the one-time reserve. Record the exact mistake rather than simply calling the run hard. Deliberately waiting through every warning is a separate stress test, not the expected player mistake.
4. **Loss and retry:** if you lose, explain the cause and the next adjustment before reading a walkthrough. Confirm that the result names the actual cause and never blames a repair you completed. Retry and attempt that adjustment. A successful run alone does not demonstrate this comprehension gate.

At critical heat, the countdown keeps running while the ship cools; it resets only below 88 heat. At the Engineering console, enable repaired cooling and stop charging if necessary. Cutoff retains charge and releases drive demand. Once heat is below 64, explicitly reassign drive power. The longer grace is time to travel and recover, not an automatic rescue or refill.

## Save evidence

Choose **Save playtest report** in pause or results. A dialog gives the absolute JSON path. Saving again updates the same attempt; retry creates a different filename. Save before retry/quit: reports are opt-in, not autosaved. You can also save an unfinished attempt from pause.

- Windows packaged build: `%APPDATA%\Godot\app_userdata\Last Shift\playtests\`.
- Linux via helper: `.tools/data/godot/app_userdata/Last Shift/playtests/` in the repository.
- Windows via helper: `.tools/data/Godot/app_userdata/Last Shift/playtests/`.

Reports contain version/engine, packaged source and executable identity, exact tuning, active-time resource/location samples every five seconds, events, reserve use and the final snapshot. Automatic samples use active-play time; pausing or reading the ship report does not advance that clock. Saving also records the current state. Source/editor launches explicitly report an unrecorded source commit; include `git rev-parse HEAD` and `git status --short` with those notes. F6/F7 developer setups are marked; they do not count as full runs. Samples are capped at 3,600 (about five hours) and explicitly flag truncation. Files stay local until you share them.

Alongside each report, record:

| Field | Your observation |
| --- | --- |
| Pass / previous experience | Fresh, careful, aggressive, imperfect, or stress; prior runs |
| Platform | Windows version, display resolution/scaling, input, audio heard |
| Confusing moment | What you expected; what you saw; what you tried |
| Mistake and recovery | Wrong turn / interrupted work / late warning; how you recovered |
| Relief | Which repair or allocation visibly helped? |
| Outcome | Why you won/lost; what you would change next time |
| Pacing | Any idle stretch; useful decision or empty waiting? |

Native Windows focus/input, 720p/1080p layout, sound, an unaided fresh-player run, and loss comprehension remain required. Do not infer enjoyment or fair difficulty from automated runs.

## Developer reproduction

```sh
python3 scripts/dev.py check --clean
python3 scripts/dev.py export-windows
```

`builds/m4-physical-runs.json` distinguishes full physical scripted routes from explicit critical-heat fixtures. Those scripts use deterministic decisions; they do not stand in for a human playtest. Debug builds retain F5 emergency reset, F6 repaired setup, F7 leak setup, F8 overlay and F10 report saving. Player builds disable these shortcuts.
