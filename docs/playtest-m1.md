# M1 hands-on test

This is a walkable repair prototype, not the complete survival scenario. No lethal timer, heat/air/power simulation, charge, leak, jump win/loss or opening sequence exists yet. The pump's circulation animation and hum demonstrate lasting repair feedback; actual heat reduction begins in M2.

## Launch

Windows player: extract `LastShift-M1-Windows-x86_64.zip` into a writable folder and double-click `LastShift.exe`. No Godot editor is needed. The build is unsigned. `build-info.json` identifies its source and engine; do not count export success as native launch verification.

Linux/cloud development, from repository root:

```sh
python3 scripts/dev.py setup
python3 scripts/dev.py run
```

Run from a terminal in the shared Desktop for graphical cloud play. A headless agent shell may lack its display/session variables. Start the Desktop, open its Terminal, `cd /workspace/lastshift`, then run the command. No display authentication changes are needed.

Windows development, from PowerShell in the repository:

```powershell
py -3 scripts/dev.py setup
py -3 scripts/dev.py run
```

## Controls

| Action | Key |
| --- | --- |
| Move | WASD or arrows |
| Interact / work | E; hold to repair by default |
| Toggle hold/toggle work mode | T, or checkbox in pause menu |
| Drop motor | Q |
| Show labeled ship map | M (does not pause) |
| Pause / resume; cancel salvage | Escape |
| Navigate/activate menu buttons | Tab / Shift+Tab, Enter or Space |
| Developer reset | F5, editor/debug build only |
| Save local event log | F10, editor/debug build only |

In toggle mode, E starts/stops work. Walking out of range, dropping, or pausing stops it and retains progress. Hold mode resumes while E is held. Debug controls are disabled by `OS.is_debug_build()` in the release player; relaunch the executable to start another M1 run. F10 writes `user://m1-events.json`, shown in the HUD; repository helper user data lives under `.tools/data/godot/app_userdata/Last Shift/` on Linux and `.tools/data/Godot/app_userdata/Last Shift/` on Windows. M1 settings are session-only.

## Traversal and repair pass

1. Start in Engineering (room 1). Inspect the broken pump and objective. Press M: identify Cargo (2), Bridge (3), Life Support (4), Jump Chamber (5) and the permanent corridor.
2. Walk east through the short service passage to Cargo. Approach the mint motor; only one target should highlight. Read the cost before pressing E. Cancel once: the donor and shortcut must remain unchanged.
3. Press E again and explicitly accept salvage. The motor is visible on the character and HUD, the donor is empty, and the map marks the closed shortcut. Approach the closed gate: it must block only that passage. Its work light must be off.
4. Press Q and walk away. The motor stays on the map and deck. Return and press E to recover it. At a wall, a rejected drop must keep the motor in hand. Dropping in a doorway must never block movement.
5. Take Cargo's south doorway to the lit permanent corridor; head west, then north into Engineering. Every other room must remain accessible. Crates and machinery are non-solid floor placeholders in M1.
6. At the coolant pump, hold E for about two seconds, then release. Expect roughly 33%, with the motor still carried. Leave range, drop/pick up, and pause. Progress must stay. Resume using either hold or toggle work until six seconds of total work completes.
7. Expect READY, a turning pump, an installed motor, a completion message and a confirmation tone followed by spatial machinery hum. Wait, leave and return: completion must remain. E/Q cannot duplicate or remove the installed motor. No heat value is simulated yet.
8. In a debug build, press F10, then F5. The donor, open gate, broken pump, empty hands, zero progress, controls and audio return to their initial state. Repeat once while paused and once during a repair.

Record Windows version, GPU/driver, resolution and display scaling, build identity, navigation confusion, input problems, whether the audio was audible, and whether the cost and recovery were understood without coaching. Check 1280×720 and 1920×1080, mouse and keyboard menus, focus loss, and window close/relaunch. Enjoyment, difficulty, sound mix and native Windows behavior remain local playtest questions.
