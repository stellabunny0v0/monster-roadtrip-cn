"""Verify a Windows installer ZIP against its manifest and current build."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path, PurePosixPath


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, default=Path('.cache/windows-release-integrity.json'))
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    version = re.search(r'PluginVersion = "([^"]+)"', (repo / 'src/Plugin.cs').read_text(encoding='utf-8'))[1]
    path = repo / f'dist/MonsterRoadtripChinese-v{version}-Windows.zip'
    files = {}
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError('Corrupt archive')
        for entry in archive.infolist():
            name = entry.filename
            relative = PurePosixPath(name)
            if entry.is_dir() or relative.is_absolute() or '..' in relative.parts or '\\' in name or name in files:
                raise ValueError(f'Invalid/duplicate archive path: {name}')
            if any(part in {'UserData', 'save-backups', 'config', '.git'} for part in relative.parts) or name.endswith(('.cfg', '.exe')):
                raise ValueError(f'Local data or game executable in release: {name}')
            files[name] = archive.read(entry)
    manifest = json.loads(files['package-manifest.json'])
    if manifest['version'] != version:
        raise ValueError('Manifest version mismatch')
    payload = set()
    for item in manifest['files']:
        name = 'payload/' + item['path']
        if name in payload or digest(files[name]) != item['sha256'].lower():
            raise ValueError(f'Payload mismatch: {name}')
        payload.add(name)
    if payload != {name for name in files if name.startswith('payload/')}:
        raise ValueError('Payload differs from manifest')
    actual_script = files['installer/Manage-Mod.ps1']
    if not actual_script.startswith(b'\xef\xbb\xbf') or actual_script.decode('utf-8-sig').replace('\r\n', '\n') != (repo / 'installer/windows/Manage-Mod.ps1').read_text(encoding='utf-8-sig'):
        raise ValueError('PowerShell 5.1 script encoding/content mismatch')
    for name in ('install.bat', 'uninstall.bat'):
        source = (repo / 'installer/windows' / name).read_text(encoding='utf-8').replace('\r\n', '\n').replace('\n', '\r\n').encode('ascii')
        if files[name] != source:
            raise ValueError(f'Entry point mismatch: {name}')
    prefix = 'payload/BepInEx/plugins/MonsterRoadtripChinese/'
    plugin_files = {name for name in files if name.startswith(prefix)}
    if len(plugin_files) != 14:
        raise ValueError('Expected DLL plus 13 translation/adaptation files')
    for name in plugin_files:
        source = repo / 'build/package/BepInEx/plugins/MonsterRoadtripChinese' / name.removeprefix(prefix)
        if files[name] != source.read_bytes():
            raise ValueError(f'Stale plugin or translation: {name}')
    dll = 'MonsterRoadtripChinese.dll'
    if files[prefix + dll] != (repo / 'src/bin/Release' / dll).read_bytes():
        raise ValueError('Release DLL differs from compiled plugin')
    sha = digest(path.read_bytes())
    checksum = Path(str(path) + '.sha256').read_text(encoding='ascii').strip()
    if checksum.lower() != (sha + '  ' + path.name).lower():
        raise ValueError('Checksum sidecar mismatch')
    report = {'version': version, 'platform': 'Windows', 'archive': path.name,
              'bytes': path.stat().st_size, 'sha256': sha, 'payload_files': len(payload),
              'plugin_files': len(plugin_files), 'plugin_sha256': digest(files[prefix + dll]),
              'contains_saves_or_local_config': False}
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
