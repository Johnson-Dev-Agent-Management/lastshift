# Pinned development toolchain

Godot **4.6.3.stable.official.7d41c59c4**, standard GDScript, x86_64, Compatibility (`gl_compatibility`). Matching export template version: **4.6.3.stable**. This selects a verified stable release, not a floating latest release. No Android, XR, .NET or QuestOS dependencies.

The exact Linux editor, Windows editor and export template archive SHA-512 values and official download URLs are committed in `scripts/toolchain.json`. They were checked against the official [4.6.3-stable SHA512-SUMS.txt](https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/SHA512-SUMS.txt). Setup verifies every archive, including cached downloads, before extracting only known filenames. Rerunning restores those files and validates the full engine version. Checksums protect reproducibility and corruption detection; they are not an independent signature verification.

Implementation consulted the [Godot 4.6 command-line reference](https://github.com/godotengine/godot-docs/blob/4.6/tutorials/editor/command_line_tutorial.rst): `--import` waits for imports; `--quit-after` counts frames, not seconds; exports use an editor binary and an existing output directory. Checks scan logs for script/import failures as well as exit codes.

Dependencies: Python 3.10+, Git, curl with trusted HTTPS certificates; Linux desktop additionally needs OpenGL 3.3 support and standard X11/audio libraries. Windows 10/11 x64 provides curl; install Python if absent. Setup uses repository-local `.tools/` and does not require administrator privileges. The official full template archive is downloaded for checksum verification, but only Linux/Windows x64 templates are installed. CI repeats setup, checks and export on Linux and Windows. CI results are distinct from native graphical playtesting.

Windows exports embed the PCK and disable optional resource modification and signing. This avoids rcedit/Wine; the test build is unsigned and uses the engine's executable metadata. Distribution signing, a Windows icon and release polish are deferred.
