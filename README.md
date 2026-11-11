# Last Shift

An aging cargo ship is your only way home. Godot 4.6.3, GDScript, Compatibility renderer. The [design baseline](docs/last-shift-game-plan.md) defines the first playable; **M0–M3** are implemented. Finish a safe maintenance checklist, survive the failed jump, salvage a motor, restore cooling, and manage air, heat and power while charging. An authored Cargo leak introduces a repair-or-endure decision. Repairs and charge persist. At full charge, return to the bridge and jump home.

Version **0.3.2** is a complete authored-run prototype with victory, cause-specific failure results, emergency retry and optional opening replay. Opening directions favor the Cargo service shortcut. Floor lights mark only the main corridor; the slower pre-jump report waits for dismissal on its final page. Cargo's door hydraulics explain the salvage cost. Powered charging still takes about **120 seconds**; M3 preserves the approved shorter charge and existing air/heat rates. Candidate tuning is not validated difficulty. Next is M4: human playtesting and recovery tuning.

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

On Windows substitute `py -3` for `python3`. Checks cover engine identity, clean import, startup, M1/M2 regressions and M3 scenario/outcome/retry behavior. Logs and scripted-run measurements go to `builds/`. `--clean` deletes only Godot's generated `game/.godot/` cache. The Windows ZIP is `builds/LastShift-M3-Windows-x86_64.zip`; extract it and run `LastShift.exe` without the editor. Exports are unsigned. Builds and tool downloads stay out of Git.

[M3 hands-on controls and test route](docs/playtest-m3.md) · [M3 candidate and validation](docs/m3-validation.md) · [historical M2 evidence](docs/m2-validation.md) · [historical M0/M1 evidence](docs/m0-m1-validation.md) · [credits](docs/credits.md)
