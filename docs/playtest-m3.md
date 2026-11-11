# M3 hands-on test

Version **0.3.0**, profile **m3-candidate-01**. The ordinary opening now leads into a complete emergency, a one-shot Cargo leak, a final bridge jump and results. Repairs remain permanent. Powered charging remains approximately **120 seconds**, with the same underlying air/heat rates as 0.2.1. These are candidate values for playtesting.

## Launch

Windows player: extract `LastShift-M3-Windows-x86_64.zip` into a writable folder and double-click `LastShift.exe`. No editor is required. `build-info.json` records the source commit, dirty flag, engine identity and executable SHA-512. The development export is unsigned. Export and headless checks do not establish native Windows graphical behavior.

Linux/cloud development, from the repository root:

```sh
python3 scripts/dev.py setup
python3 scripts/dev.py run
```

The setup command was tested in the selected Linux environment. For graphical cloud play, use a Terminal in the shared Desktop after `cd /workspace/lastshift`; the agent shell may lack display/session variables. Windows development uses PowerShell:

```powershell
py -3 scripts/dev.py setup
py -3 scripts/dev.py run
```

## Controls and time

| Action | Key |
| --- | --- |
| Move | WASD or arrows |
| Interact with local equipment / final bridge jump | E |
| Connector, pump or hull work | Hold E; T changes to toggle work |
| Drop the carried motor | Q |
| Show map | M; emergency time keeps running |
| Close equipment / cancel salvage | Escape |
| Pause / resume | Escape when no equipment/dialog is open |
| Menu navigation / activate | Tab / Shift+Tab, Enter or Space; mouse works too |
| Retry / replay opening | Results screen or pause menu |

Power and reserve panels freeze movement but **emergency time keeps running**. Close the panel and press Escape again to pause. Salvage confirmation pauses time while you review its permanent cost. Pause freezes resources, work, the evacuation report, scenario timers and critical grace. Work progress survives releasing E, leaving range and pausing. Work mode and volume are session preferences retained across retry; there is no mid-run save. Focus loss does not automatically pause.

## Full shift walkthrough

1. **Safe checklist.** Start in Engineering with a functioning pump. Air and heat do not change, even if you take a long time. Use M to find Cargo; the northern service shortcut is open. At the small SERVICE connector near Cargo's northwest corner, hold E for four accumulated seconds. Release halfway and return to confirm retained progress. Return to the Engineering power console and switch cooling OFF, then ON. Other consumers and emergency equipment are unavailable during this lesson.
2. **Failed jump.** The eight-second evacuation report announces jump failure, crew evacuation, pod failure and one life sign. Resources are held until control returns; Escape pauses the report too. The coolant pump then fails once and the objective becomes GET HOME. The opening is player-paced: there is no forced minimum wait to make it last 45–60 seconds.
3. **Permanent coolant repair.** Find the Cargo donor motor. Cancel salvage once to inspect the cost, then accept: the shortcut closes and its light goes out. The southern permanent corridor remains open. Drop/recover the motor, then return to the Engineering pump. Hold E for six accumulated seconds; interrupt it once and verify retained progress. The motor installs once and cooling immediately works when powered. The pump stays repaired for the rest of this run.
4. **Arm and charge.** Walk to the Jump Chamber's lever and press E. Confirm the handle pulls down, its indicator lights, and ARMED stays visible after leaving. Return to Engineering. Capacity is six units; life support and cooling cost two each, drive charging four. Explicitly turn one survival consumer off before enabling drive. Cooling plus drive charges with little heat gain but faster air loss. Life support plus drive conserves air but needs cooling breaks. Charge survives interruption and cutoff. Full charge releases the drive allocation automatically.
5. **The authored leak.** After pump repair has held for at least 40 active seconds, charge is at least 30%, and heat is below warning, Cargo seal strain warns of a leak. A six-second lead-in gives notice; onset waits if heat becomes unsafe. The leak adds 0.35 air loss per second and gets a map `!`, a visible crack and a local prompt. Decide whether to patch it or spend air while continuing to charge. The built-in repair tool takes eight accumulated seconds: no second component is needed. Interrupt and resume; sealing removes only the extra drain, permanently. It does not refill air or undo any other repair.
6. **Final push.** At 70% charge, a one-time message and quiet placeholder musical tone mark the approach to completion. No new fault is added. The emergency reserve in Life Support can add up to 25 air once, capped at 100. At full charge, restore survival power if needed, go to the Bridge helm and press E. Full charge alone does not escape: air and heat continue until the local bridge action succeeds.
7. **Outcome and retry.** Successful jump shows SHIFT COMPLETE and freezes the run. Air depletion or an expired critical-heat grace shows its specific cause and a state-aware recovery suggestion. Results include active/emergency duration, air, heat, charge, repair/reserve state and profile. Retry starts directly at the emergency with a broken pump, fresh motor/resources and open shortcut. Replay the opening starts with a functioning ship and the safe checklist. Repeat each and check that no patch, charge, event, menu or motor state leaks into the next run.

## Compare approaches and failures

Use a fresh run and the same profile for each comparison. Record reading/travel time, charge downtime, air/heat at outcome, reserve use, mistakes and confusing prompts.

- **Patch and take cooling breaks:** keep life support on while charging without cooling. Stop charging before excessive heat, power cooling and allow recovery. Patch the leak during a break, then return to resume charging. The scripted reference breaks at heat 64 and resumes at 38.
- **Endure and charge continuously:** leave cooling on and life support off while charging. Accept the leak's ongoing air cost; use the reserve if needed, and restore life support at full charge. This is a choice to test, not a recommendation for every player.
- **Failure/retry:** air zero loses immediately. Heat warns at 68, drive cuts off at 86, and critical heat at 92 starts a 30-second grace that clears below 88. Because repaired cooling and cutoff provide protection, the critical outcome is more practical to inspect with automated fixtures than to force in a normal run. Both causes must show distinct results and permit retry.

Developer/editor builds offer F5 (fresh emergency), F6 (prepared repaired pump and armed drive at the power console), F7 (prepared leak beat at Cargo), F8 (profile/rates overlay), and F10 (local `user://m3-events.json`). F6/F7 are targeted test setups, not completed runs. These keys are disabled in release exports. Helper log data is under `.tools/data/godot/app_userdata/Last Shift/` on Linux and `.tools/data/Godot/app_userdata/Last Shift/` on Windows. Record source commit and dirty status with source-run logs; packaged builds contain `build-info.json`.

## Local evidence still needed

Record Windows version, GPU/driver, resolution/scaling and build identity. Check launch, 1280×720 and 1920×1080 readability, keyboard/mouse focus, audible cues/mix, close/relaunch and repeated outcomes. Play full shifts without developer shortcuts, including an imperfect run that recovers. Report whether the leak choice, permanent relief and loss explanation make sense. Native Windows graphical behavior, human recovery, enjoyment and difficulty balance remain unverified. The original 8–12 minute target is a hypothesis; do not prolong the approved shorter charge merely to meet it.
