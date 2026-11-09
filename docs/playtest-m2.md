# M2 hands-on test

Version 0.2.0 implements the walkable ship and working power, air, heat and charge systems. The pump starts broken and the emergency is already underway. This is not yet the complete authored scenario: the ordinary opening, leak, final jump and results arrive in M3. Reaching full charge and interacting at the bridge is the current checkpoint; survival resources continue until you pause or restart.

## Launch

Windows player: extract `LastShift-M2-Windows-x86_64.zip` into a writable folder and double-click `LastShift.exe`. No editor is required. `build-info.json` records the source commit, dirty flag, engine identity and executable SHA-512. The development build is unsigned. Export and headless checks do not establish Windows graphical behavior.

Linux/cloud development, from the repository root:

```sh
python3 scripts/dev.py setup
python3 scripts/dev.py run
```

For graphical cloud play, run those commands in a Terminal in the shared Desktop, after `cd /workspace/lastshift`. The agent shell may lack display/session variables; no display authentication changes are needed. The setup command has been tested on Linux. Windows development uses PowerShell:

```powershell
py -3 scripts/dev.py setup
py -3 scripts/dev.py run
```

## Controls

| Action | Key |
| --- | --- |
| Move | WASD or arrows |
| Interact / open local equipment | E |
| Repair pump | Hold E by default; T switches hold/toggle mode |
| Drop carried motor | Q |
| Show ship map | M; time keeps running |
| Close equipment / cancel salvage | Escape |
| Pause / resume | Escape when no equipment/dialog is open |
| Menu navigation / activate | Tab / Shift+Tab, Enter or Space; mouse also works |
| Restart, including after resource failure | Escape → Restart M2 simulation |

Power and reserve panels freeze movement but **time keeps running**. Close with Escape, then press Escape again to pause. The salvage confirmation pauses resource drain and work while you review the permanent cost. The pause menu freezes resources, repair, animation and critical grace. Preferences are session-only; restart retains the chosen work mode and volume. There is no mid-run save.

Debug/editor builds also support F5 (fresh run), F6 (fresh run with pump repaired and drive armed, positioned at the Engineering console), F8 (profile/rates/threshold overlay), and F10 (local event log). F6 is a test shortcut, not a normal completed run. These controls are disabled in the exported release player. F10 writes `user://m2-events.json`; helper data is under `.tools/data/godot/app_userdata/Last Shift/` on Linux and `.tools/data/Godot/app_userdata/Last Shift/` on Windows. Record the Git commit and dirty status alongside source-run logs; packaged builds have `build-info.json`.

## Repair and equipment pass

1. Start in Engineering. Check movement and M for the five labeled rooms. Air falls slowly and heat rises while the pump is broken. Walk to Cargo through the optional service shortcut.
2. Review the donor motor's salvage cost. Cancel once and check that the shortcut remains open. Accept: the shortcut closes, its light goes out, and the permanent corridor stays lit/open. Drop and recover the motor; it must never block a doorway. Return south to the permanent corridor, west, then north to Engineering.
3. Repair the pump for two seconds, release, walk away, and pause. Progress must remain. Drop directly on the pump and recover the motor with E. Complete six accumulated seconds of work: the motor installs once, the pump turns/hums when powered, and heat starts falling. Switching cooling off later must preserve the repair and show `OFF / REPAIRED`.
4. Open Engineering's power console. Drive activation must explain the missing local arming step (or repair interlock if attempted earlier), without changing other allocations. Close the panel and follow the permanent corridor to the Jump Chamber. Approach the small ARM PANEL east of the drive and press E. Arming must not allocate power remotely.
5. Return to Engineering. Attempt to enable drive while life support and cooling are both on: `4 + 4 > 6` must be rejected. Switch one consumer off explicitly, then enable drive. Check that the HUD, live panel, pump animation and heat/air trends agree with the selected allocation. Close/pause, wait, and verify no value changes. Resume and verify continued charging.
6. Visit the emergency reserve in Life Support. Its live preview is `min(25, 100 − air)`. Activating it adds that amount once and marks EMPTY; a second activation is disabled. At full air, it cannot be wasted. Because time runs while the panel is open, the preview can increase slightly before you click.
7. At 100% charge, drive power releases automatically. Restore life support/cooling at Engineering if needed, then go to the bridge and press E. Expect `M2 COMPLETE: escape-ready at the bridge`. This is not the final jump or victory sequence. Pause or restart to end the test.

## Compare two approaches

Use the same candidate profile and fresh run for each. Record active time, remaining air/heat, reserve use and confusing moments; do not treat the scripted timings as a player's expected performance.

- **Continuous charging:** repair and arm promptly, turn life support off and leave cooling on, then charge continuously. Air falls at 0.22/s; heat rises at 0.03/s. Full charge takes about 312.5 seconds of powered charging. Restore both survival consumers for the bridge trip. Use the reserve if delays require it.
- **Cooling breaks:** leave life support on, turn cooling off and charge. Heat rises at 0.45/s. Stop charging before cutoff, turn cooling on and let heat recover; charge is retained. Switch cooling off and deliberately resume the drive. The automated candidate policy takes breaks at heat 64 and resumes at 38.

For cutoff testing, leave life support and drive on without cooling: warning enters at 68, cutoff at 86. Cutoff must retain charge, release the drive's four units and show COOLING DOWN. Turn cooling on. Availability returns only below 64; the drive stays off until you deliberately reassign power. Critical heat enters at 92 with a visible 30-second grace and clears below 88. Air 0 or expired grace stops the simulation; restart must restore all run state. Use automated threshold fixtures for these cases if reaching them manually is slow.

## Record local results

Record Windows version, GPU/driver, resolution/display scaling, build source identity, profile `m2-candidate-01`, navigation/input issues, and whether the power cost and lasting recovery were understood. Check 1280×720 and 1920×1080, keyboard and mouse menus, focus loss, audio, window close/relaunch, and restart after either failure. Pause before switching away: focus loss does not automatically pause.

Native Windows 10/11 graphical behavior, audible mix, a complete human M2 run, imperfect-play recovery, enjoyment and difficulty remain open playtest questions. The current candidate has no leak or opening, so it cannot establish the final 8–12 minute target or demonstrate that every allocation has a worthwhile role.
