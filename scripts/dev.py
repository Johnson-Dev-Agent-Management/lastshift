#!/usr/bin/env python3
"""Repository-owned Godot setup, validation, launch and export. Python 3.10+."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import struct
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PIN = json.loads((ROOT / 'scripts/toolchain.json').read_text())
TOOLS = ROOT / '.tools'
BUILD = ROOT / 'builds'
GAME = ROOT / 'game'
WINDOWS = sys.platform == 'win32'
ENGINE_NAME = f"Godot_v{PIN['version']}-stable_" + ('win64.exe' if WINDOWS else 'linux.x86_64')
ENGINE = TOOLS / 'engine' / ENGINE_NAME
ENV = dict(os.environ)
# Isolated caches/templates; never replace a developer's installed Godot version.
if WINDOWS:
    ENV['APPDATA'] = str(TOOLS / 'data')
else:
    for kind in ('DATA', 'CACHE', 'CONFIG'):
        ENV[f'XDG_{kind}_HOME'] = str(TOOLS / kind.lower())


def digest(path):
    with path.open('rb') as stream:
        h = hashlib.sha512()
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def download(name):
    target = TOOLS / 'downloads' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        partial = target.with_suffix(target.suffix + '.tmp')
        subprocess.run(['curl', '--fail', '--location', '--silent', '--show-error',
                        '--retry', '2', '--max-time', '900',
                        f"{PIN['base_url']}/{name}", '-o', str(partial)], check=True)
        if digest(partial) != PIN['sha512'][name]:
            partial.unlink()
            raise RuntimeError(f'Checksum mismatch: {name}')
        partial.replace(target)
    if digest(target) != PIN['sha512'][name]:
        raise RuntimeError(f'Cached archive checksum mismatch: {target}; remove it and rerun setup')
    print(f'SHA-512 verified: {name}', flush=True)
    return target


def setup():
    if platform.machine().lower() not in ('x86_64', 'amd64') or sys.platform not in ('linux', 'win32'):
        raise RuntimeError('This pinned setup supports Linux and Windows x86_64 only')
    for folder in ('engine', 'data', 'cache', 'config'):
        (TOOLS / folder).mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(download(ENGINE_NAME + '.zip')) as archive:
        # Extract only known engine names from a checksum-verified official archive.
        for name in (ENGINE_NAME, ENGINE_NAME.replace('.exe', '_console.exe')):
            if name in archive.namelist():
                (TOOLS / 'engine' / name).write_bytes(archive.read(name))
    ENGINE.chmod(0o755)
    with zipfile.ZipFile(download(f"Godot_v{PIN['version']}-stable_export_templates.tpz")) as archive:
        if archive.read('templates/version.txt').decode().strip() != PIN['template_version']:
            raise RuntimeError('Template version mismatch')
        target = TOOLS / 'data' / ('Godot' if WINDOWS else 'godot') / 'export_templates' / PIN['template_version']
        target.mkdir(parents=True, exist_ok=True)
        for name in ('version.txt', 'windows_debug_x86_64.exe', 'windows_release_x86_64.exe',
                     'linux_debug.x86_64', 'linux_release.x86_64'):
            (target / name).write_bytes(archive.read('templates/' + name))
            (target / name).chmod(0o755)
    version()


def engine_command():
    # Console executable captures diagnostics reliably on native Windows.
    return str(ENGINE.with_name(ENGINE_NAME.replace('.exe', '_console.exe')) if WINDOWS else ENGINE)


def version():
    output = subprocess.check_output([engine_command(), '--headless', '--version'], env=ENV, text=True).strip()
    if output != PIN['engine_version']:
        raise RuntimeError(f"Expected {PIN['engine_version']}, got {output}")
    print(output, flush=True)


def checked(label, args, marker=None):
    BUILD.mkdir(exist_ok=True)
    result = subprocess.run(args, env=ENV, cwd=ROOT, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", timeout=180)
    (BUILD / f'{label}.log').write_text(result.stdout, encoding='utf-8')
    errors = re.search(r'SCRIPT ERROR:|\bERROR:|Parse Error|Failed to load|Assertion failed', result.stdout)
    if result.returncode or errors or (marker and marker not in result.stdout):
        print(result.stdout)
        raise RuntimeError(f'{label} failed; see builds/{label}.log')
    print(f'PASS {label}', flush=True)


def godot(*args):
    return [engine_command(), '--headless', '--path', str(GAME), *args]


def check(clean=False):
    version()
    if clean and (GAME / '.godot').exists():
        shutil.rmtree(GAME / '.godot')
    checked('import', godot('--import'))
    checked('startup', godot('--quit-after', '120', '--', '--smoke-test'), 'LAST_SHIFT_STARTUP_PASS')
    checked('m1-tests', godot('--fixed-fps', '60', '--script', 'res://tests/m1_test.gd'), 'LAST_SHIFT_M1_PASS')
    checked('m2-tests', godot('--fixed-fps', '60', '--script', 'res://tests/m2_test.gd'), 'LAST_SHIFT_M2_PASS')
    checked('m3-tests', godot('--fixed-fps', '60', '--script', 'res://tests/m3_test.gd'), 'LAST_SHIFT_M3_PASS')
    checked('m4-tests', godot('--fixed-fps', '60', '--script', 'res://tests/m4_test.gd'), 'LAST_SHIFT_M4_PASS')


def export_windows():
    version()
    checked('export-import', godot('--import'))
    target = BUILD / 'windows' / 'LastShift.exe'
    target.parent.mkdir(parents=True, exist_ok=True)
    checked('windows-export', godot('--export-release', 'Windows Desktop', str(target)))
    data = target.read_bytes()
    pe = struct.unpack_from('<I', data, 0x3c)[0]
    if data[:2] != b'MZ' or data[pe:pe + 4] != b'PE\0\0' or struct.unpack_from('<H', data, pe + 4)[0] != 0x8664:
        raise RuntimeError('Export is not a Windows x86_64 PE executable')
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    dirty = bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).strip())
    metadata = {'engine': PIN['engine_version'], 'source_commit': revision, 'source_dirty': dirty,
                'executable_sha512': digest(target), 'milestones': 'M0/M1/M2/M3/M4-candidate', 'native_windows_tested': False}
    (target.parent / 'build-info.json').write_text(json.dumps(metadata, indent=2) + '\n')
    for source, dest in [('docs/playtest-m4.md', 'PLAYTEST.md'), ('docs/credits.md', 'CREDITS.md'),
                         ('docs/GODOT-LICENSE.txt', 'GODOT-LICENSE.txt'),
                         ('docs/GODOT-COPYRIGHT.txt', 'GODOT-COPYRIGHT.txt')]:
        if (ROOT / source).exists():
            shutil.copyfile(ROOT / source, target.parent / dest)
    shutil.make_archive(str(BUILD / 'LastShift-M4-Windows-x86_64'), 'zip', target.parent)
    print(f'Windows package: {BUILD / "LastShift-M4-Windows-x86_64.zip"}', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('setup', 'version', 'check', 'run', 'editor', 'export-windows'))
    parser.add_argument('--clean', action='store_true', help='Delete only generated game/.godot before checks')
    args, extra = parser.parse_known_args()
    if extra and args.command not in ('run', 'editor'):
        parser.error(f'Unexpected arguments: {extra}')
    if args.command == 'setup':
        setup()
        return
    if not ENGINE.exists():
        raise RuntimeError('Run python scripts/dev.py setup first')
    if args.command == 'version':
        version()
    elif args.command == 'check':
        check(args.clean)
    elif args.command == 'export-windows':
        export_windows()
    else:
        version()
        subprocess.run([engine_command(), '--path', str(GAME)] +
                       (['--editor'] if args.command == 'editor' else []) + extra, env=ENV, check=True)


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, subprocess.SubprocessError, OSError) as error:
        print(f'FAIL: {error}', file=sys.stderr)
        sys.exit(1)
