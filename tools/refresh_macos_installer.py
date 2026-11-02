"""Repackage the verified v0.3.7 Mac payload with current installer files."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import urllib.request
import zipfile
from pathlib import Path

BASE_NAME = 'MonsterRoadtripChinese-v0.3.7-macos-experimental-macOS.zip'
BASE_URL = ('https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/download/'
            'v0.3.7-macos-experimental/' + BASE_NAME)
BASE_SHA256 = '320c734f9004efb419240b071feb52a94637f3987e22ad6395b4758ae2fc4795'
NAME = 'MonsterRoadtripChinese-v0.3.7-macos-experimental-installer2-macOS'


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-zip', type=Path)
    parser.add_argument('--output-dir', type=Path, default=Path('dist'))
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    out = args.output_dir.resolve()
    archive = out / (NAME + '.zip')
    extracted = out / NAME
    if archive.exists() or extracted.exists():
        raise SystemExit('Output already exists; refusing to overwrite')
    if args.base_zip:
        data = args.base_zip.read_bytes()
    else:
        with urllib.request.urlopen(BASE_URL, timeout=60) as response:
            data = response.read()
    if sha(data) != BASE_SHA256:
        raise SystemExit('Original Mac release SHA256 mismatch')
    import io
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        if z.testzip() is not None:
            raise SystemExit('Original ZIP is corrupt')
        files = {}
        for item in z.infolist():
            path = Path(item.filename)
            if path.is_absolute() or '..' in path.parts or item.is_dir() or item.filename in files:
                raise SystemExit('Unexpected ZIP entry')
            files[item.filename] = z.read(item)
    original = dict(files)
    for name in ('install.command', 'uninstall.command'):
        files[name] = (repo / 'installer/macos' / name).read_bytes()
    files['installer/manage-macos.sh'] = (repo / 'installer/macos/manage-macos.sh').read_bytes()
    files['\u5b89\u88c5\u8bf4\u660e.md'] = (repo / 'docs/MACOS.md').read_bytes()
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
    info = json.loads(files['build-info.json'].decode('utf-8-sig'))
    info['status'] = 'experimental; user reports Mac installer update works; other configurations unverified'
    info['installer_revision'] = 2
    info['installer_update'] = {
        'base_archive_sha256': BASE_SHA256,
        'source_commit': commit,
        'manage_macos_sha256': sha(files['installer/manage-macos.sh']),
        'payload_unchanged': True,
        'consent': 'Explicit YES only; default skip; libdoorstop.dylib quarantine only',
    }
    files['build-info.json'] = (json.dumps(info, ensure_ascii=False, indent=2) + '\n').encode()
    for line in files['package-files.tsv'].decode().splitlines():
        digest, kind, rel, baseline = line.split('\t')
        if sha(files['payload/' + rel]) != digest:
            raise SystemExit('Payload hash mismatch: ' + rel)
    for name, content in original.items():
        if name.startswith('payload/') or name in ('package-files.tsv', 'package-version.txt'):
            if files[name] != content:
                raise SystemExit('Installer update must preserve payload identity: ' + name)
    out.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for name, content in sorted(files.items()):
            item = zipfile.ZipInfo(name)
            item.create_system = 3
            item.external_attr = (0o100755 if name.endswith(('.sh', '.command')) else 0o100644) << 16
            item.compress_type = zipfile.ZIP_DEFLATED
            if name.endswith(('.sh', '.command')) and b'\r' in content:
                raise SystemExit('Script must use LF: ' + name)
            z.writestr(item, content)
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None:
            raise SystemExit('Output ZIP is corrupt')
        z.extractall(extracted)
    digest = sha(archive.read_bytes())
    Path(str(archive) + '.sha256').write_text(f'{digest}  {archive.name}\n', encoding='ascii')
    notes = f'''Mac installer update 2 (experimental).

Only the Mac installer and instructions changed. The plugin, translations and all 33 payload files are identical to v0.3.7-macos-experimental. Windows is unchanged.

Download `{archive.name}` from Assets and fully extract it. Run `install.command`. If macOS blocks the script, use System Settings > Privacy & Security > Open Anyway, or run it with `/bin/bash` in Terminal.

After the installer verifies the loader, type uppercase `YES` to remove only its download-quarantine attribute. Press Enter to skip. Existing identical v0.3.7 Mac installations can rerun this installer without uninstalling or changing Steam launch options.

The user reported successful Mac testing. Other hardware/OS configurations and full gameplay coverage remain unverified. Apple Silicon requires Rosetta; only x86_64 Mono games are supported. This package is unsigned and not notarized; first-run security prompts remain possible.

Validation: 19 loader-trust checks (including native macOS xattr fixtures) and 17 installer integration fixtures. See the release workflow run for results.

[Chinese installation instructions](https://github.com/stellabunny0v0/monster-roadtrip-cn/blob/main/docs/MACOS.md)

SHA256: `{digest}`
'''
    (out / 'release-notes.md').write_text(notes, encoding='utf-8')
    print(json.dumps({'archive': str(archive), 'sha256': digest, 'source_commit': commit}))


if __name__ == '__main__':
    main()
