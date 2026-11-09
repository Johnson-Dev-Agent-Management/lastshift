# Last Shift

An aging cargo ship is your only way home. Godot 4.6.3, GDScript, Compatibility renderer. The [design baseline](docs/last-shift-game-plan.md) defines the first playable; **M0–M2** are implemented. Salvage a motor, repair cooling, arm the drive locally, and trade limited power between air, cooling and charging. Repairs and charge persist.

This is a systems prototype. M3 adds the ordinary opening, authored incidents, final jump and results. The current bridge interaction verifies escape readiness; air depletion or sustained critical heat stops the simulation. Candidate rates are not validated difficulty.

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

On Windows substitute `py -3` for `python3`. Checks cover engine identity, clean import, startup, M1 regressions and M2 simulation/local controls. Logs and scripted-run measurements go to `builds/`. `--clean` deletes only Godot's generated `game/.godot/` cache. The Windows ZIP is `builds/LastShift-M2-Windows-x86_64.zip`; extract it and run `LastShift.exe` without the editor. Exports are unsigned. Builds and tool downloads stay out of Git.

[M2 hands-on controls and test route](docs/playtest-m2.md) · [candidate tuning and validation](docs/m2-validation.md) · [historical M0/M1 evidence](docs/m0-m1-validation.md) · [credits](docs/credits.md)
