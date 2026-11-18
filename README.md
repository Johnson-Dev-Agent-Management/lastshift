# Last Shift

An aging cargo ship is your only way home. Godot 4.6.3, GDScript, Compatibility renderer. The [design baseline](docs/last-shift-game-plan.md) defines the first playable; **M0–M5** are implemented. Finish a safe maintenance checklist, survive the failed jump, salvage a motor, restore cooling, and manage air, heat and power while charging. An authored Cargo leak introduces a repair-or-endure decision. Repairs and charge persist. At full charge, return to the bridge and jump home.

Version **0.5.0** adds an optional final approach at the Bridge. From 70% charge, hold **E** at the helm while the drive is charging to advance ship time at **4×** and jump on completion. Release E to resume normal speed. At full charge you can also jump with one press. A blue core, checkmark and completion chime mark full charge. The pause menu includes repair controls, reduced flashing and shake, and individual audio levels. The balance profile is `m4-candidate-02`.

## Development

From the repository root on Linux/cloud (Python 3.10+, Git and curl):

```sh
python3 scripts/dev.py setup
python3 scripts/dev.py run
```

The setup command above was run successfully in the selected Linux cloud environment. It pins and verifies official engine/template archives; no global engine installation is required. Use `python3 scripts/dev.py editor` to open the editor.

Native Windows 10/11 x64, from PowerShell with Python 3.10+, Git and curl available:

```powershell
py -3 scripts/dev.py setup
py -3 scripts/dev.py run
py -3 scripts/dev.py editor
```

Windows setup uses the same helper and pinned manifest, with Windows engine filenames and template paths. Setup, headless checks and export passed CI on Windows Server 2022. Windows 10/11 graphical launch and play still need local validation. See [toolchain provenance and requirements](docs/toolchain.md).

## Validate and export

```sh
python3 scripts/dev.py check --clean
python3 scripts/dev.py export-windows
```

On Windows substitute `py -3` for `python3`. Checks cover engine identity, clean import, startup, M1/M2 regressions and M3 scenario/outcome/retry behavior, and M4 physical routes, critical recovery, report persistence and a replay of the supplied playtest's timing. M5 checks the helm clock, interruptions, outcomes and accessibility controls. Logs and scripted-run measurements go to `builds/`. `--clean` deletes only Godot's generated `game/.godot/` cache. The Windows ZIP is `builds/LastShift-M5-Windows-x86_64.zip`; extract it and run `LastShift.exe` without the editor. Exports are unsigned. Builds and tool downloads stay out of Git.

[M5 hands-on test and evidence](docs/playtest-m5.md) · [historical M4 hands-on test](docs/playtest-m4.md) · [M4 measurements and open gate](docs/m4-validation.md) · [historical M3 evidence](docs/m3-validation.md) · [historical M2 evidence](docs/m2-validation.md) · [historical M0/M1 evidence](docs/m0-m1-validation.md) · [credits](docs/credits.md)
