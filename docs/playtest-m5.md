# Last Shift 0.5.0 playtest

Extract the entire `LastShift-M5-Windows-x86_64.zip` into a folder, then run `LastShift.exe`. Keep `build-info.json` alongside it to identify the build in saved reports. From a prepared checkout run `python3 scripts/dev.py run` (Windows PowerShell: `py -3 scripts/dev.py run`).

Use WASD or arrows to move, E to interact, Q to drop the motor, M for the map, and Esc to pause or close a panel. Hold E for repairs, or press T to switch to toggle-to-work. Pause → **Controls, effects and audio** offers reduced flashing, reduced camera shake and six volume sliders. Tab and Shift+Tab move focus, arrows adjust a slider, and Enter or Space activates a button. These settings apply across retries in the current session.

## Try the helm

1. Finish the safe Cargo connector and Engineering power checklist. Read the failure report and begin the emergency. Salvage the motor, repair the coolant pump, arm the drive and allocate four units to charge it. Use the map and resource trends to choose how to handle the leak and reserve.
2. Reach the Bridge helm during the final push (70% or higher, drive charging). Hold **E** briefly. The helm and HUD show **ship time ×4**. Air, heat, incidents and charge advance together. Release E and watch charging continue at normal speed. Leaving range, opening the map, pausing or losing window focus releases the helm.
3. Hold E again through completion to jump. The heat cutoff interrupts the hold and retains charge. Air depletion or critical-heat expiry ends the run even on the completion tick. You can also let the drive finish normally and press E at the ready helm.
4. On a separate pass, see the orange charge ring complete at the Jump Chamber. Look for the blue center, checkmark and READY label, then return to the Bridge. Try with audio muted and with effects reduced. Check that hazard text agrees with what you see and hear.
5. Save the playtest report from pause or results before retrying. The dialog shows the file location. Results show build **0.5.0** and tuning **m4-candidate-02**. Reports use simulated ship seconds and record helm engagement and release. Note how the final approach felt and whether you could anticipate a cutoff.

## Development evidence

Run `python3 scripts/dev.py check --clean`, then `python3 scripts/dev.py export-windows`. From a graphical terminal run `python3 scripts/dev.py run --script res://tests/capture.gd` for PNGs in `builds/screenshots-m5/`.

- **Automated.** Import, startup and M1–M5 suites exercise both failure causes, repairs, physical routes and local reports. M5 compares one second held with four seconds of ordinary simulation including an open leak. Separate fixtures exercise release, lost range, map, pause, focus, cutoff on completion, loss on completion, ordinary full-charge activation and options. At 88.25% charge a successful hold takes 212 physics frames (3.53 real seconds at 60 Hz).
- **Rendered and operated on Linux.** The prepared Bridge approach used the returning player’s sampled 88.25% charge, 54.5 air and 77.5 heat. A keyboard hold and release showed normal speed at 91.8%. A second hold reached SHIFT COMPLETE with 47.4 air and 82.2 heat. This was a prepared final segment. Render fixtures covered the ship map, settings, helm states, ready drive, warnings and outcome at 1280×720 and 1920×1080.
- **Still to playtest.** Native Windows input, display scaling, audible alert priority, pause-menu mix levels and how the final approach feels in a complete human run. Cloud rendering used the dummy audio driver. Fresh-player loss comprehension also remains open. M6 covers release packaging and a fresh-player launch-through-retry pass.
