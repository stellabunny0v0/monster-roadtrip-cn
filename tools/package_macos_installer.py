"""Build a separate, offline macOS x86_64 experimental package (no game files)."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', default='0.3.7-macos-experimental')
    args = parser.parse_args()
    if not re.fullmatch(r'[a-zA-Z0-9.-]+', args.version):
        raise SystemExit('Invalid version')
    repo = Path(__file__).resolve().parent.parent
    out = repo / 'dist' / f'MonsterRoadtripChinese-v{args.version}-macOS'
    archive = Path(str(out) + '.zip')
    if out.exists() or archive.exists():
        raise SystemExit(f'Output exists; choose a new version: {out}')
    loader = repo / '.tools/bepinex-macos'
    compat = repo / 'build/mono-compat'
    plugin = repo / 'build/package/BepInEx/plugins/MonsterRoadtripChinese'
    compiled_dll = repo / 'src/bin/Release/MonsterRoadtripChinese.dll'
    if not compiled_dll.is_file():
        raise SystemExit('Build the plugin first')
    version = re.search(r'PluginVersion = "([^"]+)"', (repo / 'src/Plugin.cs').read_text(encoding='utf-8'))[1]
    if not args.version.startswith(version + '-'):
        raise SystemExit('Package version must match the plugin source version')
    if compiled_dll.stat().st_mtime < max(p.stat().st_mtime for p in (repo / 'src').glob('*.cs')):
        raise SystemExit('Plugin DLL is older than source; rebuild first')
    compatibility = json.loads((compat / 'compatibility-manifest.json').read_text(encoding='utf-8-sig'))
    for name, key in [('MonoMod.Utils.dll', 'patchedSha256'), ('MonsterRoadtripMonoCompat.dll', 'helperSha256')]:
        if sha(compat / name) != compatibility[key].lower():
            raise SystemExit('Compatibility file hash mismatch')
    if sha(loader / 'BepInEx/core/MonoMod.Utils.dll') != compatibility['originalSha256'].lower():
        raise SystemExit('The Mac dependency does not match the reviewed backport')
    plugin_files = sorted(p for p in plugin.rglob('*') if p.is_file())
    if len(plugin_files) != 14 or any(p.is_symlink() for p in plugin_files):
        raise SystemExit('Expected DLL plus 13 translation/adaptation files, without symlinks')
    payload: dict[str, tuple[Path | bytes, str, str]] = {}
    for name in ('.doorstop_version', 'changelog.txt', 'libdoorstop.dylib'):
        payload[name] = loader / name, 'loader', '-'
    for path in sorted((loader / 'BepInEx/core').glob('*.dll')):
        payload['BepInEx/core/' + path.name] = path, 'loader', '-'
    payload['BepInEx/core/MonoMod.Utils.dll'] = compat / 'MonoMod.Utils.dll', 'loader', compatibility['originalSha256'].lower()
    payload['BepInEx/core/MonsterRoadtripMonoCompat.dll'] = compat / 'MonsterRoadtripMonoCompat.dll', 'loader', '-'
    payload['BepInEx/core/MonsterRoadtripMonoCompat.LICENSE.txt'] = repo / 'compat/LICENSE-MonoMod.txt', 'loader', '-'
    run_script = (loader / 'run_bepinex.sh').read_text(encoding='utf-8')
    replacements = {
        'export ARCHPREFERENCE="arm64,x86_64"': 'export ARCHPREFERENCE="x86_64"',
        'exec arch -e DYLD_INSERT_LIBRARIES=': 'exec arch -x86_64 -e DYLD_INSERT_LIBRARIES=',
        'doorstop_name="libdoorstop.${lib_extension}"': 'doorstop_name="${doorstop_directory}libdoorstop.${lib_extension}"',
    }
    for old, new in replacements.items():
        if run_script.count(old) != 1:
            raise SystemExit('Unexpected upstream launch script; review required')
        run_script = run_script.replace(old, new)
    payload['run_bepinex.sh'] = run_script.encode('utf-8'), 'loader', sha(loader / 'run_bepinex.sh')
    payload['monster_roadtrip_cn.sh'] = repo / 'installer/macos/monster_roadtrip_cn.sh', 'launcher', '-'
    for path in plugin_files:
        source = compiled_dll if path.name == 'MonsterRoadtripChinese.dll' else path
        payload['BepInEx/plugins/MonsterRoadtripChinese/' + path.relative_to(plugin).as_posix()] = source, 'plugin', '-'
    out.mkdir(parents=True)
    rows = []
    for relative, (source, kind, baseline) in sorted(payload.items()):
        destination = out / 'payload' / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(source, bytes):
            destination.write_bytes(source)
        elif source.suffix in ('.sh', '.command'):
            destination.write_bytes(source.read_text(encoding='utf-8').encode('utf-8'))
        else:
            shutil.copyfile(source, destination)
        rows.append(f'{sha(destination)}\t{kind}\t{relative}\t{baseline}')
    for name in ('install.command', 'uninstall.command'):
        (out / name).write_bytes((repo / 'installer/macos' / name).read_text(encoding='utf-8').encode('utf-8'))
    (out / 'installer').mkdir()
    (out / 'installer/manage-macos.sh').write_bytes((repo / 'installer/macos/manage-macos.sh').read_text(encoding='utf-8').encode('utf-8'))
    (out / 'package-files.tsv').write_bytes(('\n'.join(rows) + '\n').encode('utf-8'))
    (out / 'package-version.txt').write_bytes((args.version + '\n').encode('ascii'))
    shutil.copyfile(repo / 'THIRD-PARTY-NOTICES.md', out / 'THIRD-PARTY-NOTICES.md')
    (out / 'licenses').mkdir()
    for path in (repo / 'compat').glob('LICENSE*.txt'):
        shutil.copyfile(path, out / 'licenses' / path.name)
    shutil.copyfile(repo / 'docs/MACOS.md', out / '安装说明.md')
    (out / 'build-info.json').write_text(json.dumps({
        'platform': 'macOS', 'status': 'experimental, no native macOS validation',
        'game_process': 'x86_64 Mono only; Apple Silicon requires Rosetta',
        'plugin_version': version, 'loader': 'BepInEx 5.4.23.5 macos universal',
        'loader_archive_sha256': sha(repo / '.tools/downloads/BepInEx_macos_universal_5.4.23.5.zip'),
        'launch_script_changes': replacements, 'compatibility': compatibility,
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    # Explicit Unix permissions also work when built on Windows.
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for path in sorted(out.rglob('*')):
            if not path.is_file():
                continue
            relative = path.relative_to(out).as_posix()
            info = zipfile.ZipInfo(relative)
            info.create_system = 3
            mode = 0o100755 if path.suffix in ('.sh', '.command') else 0o100644
            info.external_attr = mode << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, path.read_bytes())
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None:
            raise SystemExit('ZIP integrity failed')
        for info in z.infolist():
            name = info.filename
            if any(x in name for x in ('UserData', 'save-backups', '.cfg', '.exe', 'winhttp.dll', '.bat')):
                raise SystemExit(f'Unexpected platform/local file: {name}')
            if name.endswith(('.sh', '.command')) and (b'\r' in z.read(name) or not info.external_attr >> 16 & 0o100):
                raise SystemExit(f'Broken script encoding/permission: {name}')
    Path(str(archive) + '.sha256').write_text(f'{sha(archive)}  {archive.name}\n', encoding='ascii')
    print(json.dumps({'archive': str(archive), 'sha256': sha(archive), 'payload_files': len(rows)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
