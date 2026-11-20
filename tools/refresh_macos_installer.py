"""Repackage the verified v0.3.7 Mac payload with current installer files."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import urllib.request
import zipfile
from pathlib import Path

BASE_NAME = 'MonsterRoadtripChinese-v0.3.7-macos-experimental-installer2-macOS.zip'
BASE_URL = ('https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/download/'
            'v0.3.7-macos-installer2/' + BASE_NAME)
BASE_SHA256 = '128055c3eae37a7928143b6d1cd10d98808e35e01d90c90dcb42a1133c0be01a'
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
    info['status'] = 'user reports Mac installer update works; other configurations unverified'
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
    notes = f'''Monster Prom 3 - Monster Roadtrip 非官方简体中文 Mod，Mac v0.3.7 一键安装包。

## 版本说明

当前 Mac 最新安装包，包内版本标记为 v0.3.7，包含安装器更新 2。安装器重新打包时保留 33 个载荷文件原样不变。

## 安装与升级

安装前退出游戏，并复制备份现有的 UserData。从 Assets 下载 `{archive.name}`，完整解压后运行 `install.command`，按提示选择游戏 .app 或其所在目录。

若系统拦截脚本，请确认来源后到“系统设置 → 隐私与安全性”选择“仍要打开”（Open Anyway），或使用终端的 `/bin/bash` 运行脚本。

安装器校验加载器后，可能询问是否放行。核对路径和用途后，输入大写 `YES` 可仅移除该加载器的下载隔离标记；直接回车跳过。相同完整版本可重复运行此安装器，无需卸载或修改已有 Steam 启动选项。

安装完成后，把终端输出的整行命令复制到 Steam → 游戏属性 → 通用 → 启动选项，再通过 Steam 启动游戏。

## 备份存档

退出游戏，复制游戏 .app 内及外层实际存在的 UserData。安装器还会自动备份到 `~/Library/Application Support/MonsterRoadtripChinese/backups`，仅复制文件，不覆盖现有存档或自动恢复旧进度。

## 卸载

退出游戏，运行同包的 `uninstall.command`，然后移除本汉化的 Steam 启动命令，保留原有其他设置。存档、配置和备份保留；其他 Mod 共用的加载器也会保留。

## 适用范围

用户已反馈 Mac 安装测试正常，其他配置与完整游玩仍待更多验证。仅支持 x86_64 Mono 游戏；Apple Silicon 需要 Rosetta。本包未签名和公证，首次运行仍可能出现系统提示，无需全局关闭 Gatekeeper 或 SIP。

## 校验与说明

[完整中文安装、备份和卸载说明](https://github.com/stellabunny0v0/monster-roadtrip-cn/blob/main/docs/MACOS.md)

SHA256: `{digest}`
'''
    (out / 'release-notes.md').write_text(notes, encoding='utf-8')
    print(json.dumps({'archive': str(archive), 'sha256': digest, 'source_commit': commit}))


if __name__ == '__main__':
    main()
