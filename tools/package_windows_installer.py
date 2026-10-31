"""Build the offline Windows installer from validated local artifacts, never saves."""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import zipfile
from pathlib import Path


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--game-dir', type=Path, required=True)
    parser.add_argument('--version', default='0.3.6-mono-layout-1')
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    if any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-' for c in args.version):
        raise SystemExit('Invalid package version')
    out = repo / 'dist' / f'MonsterRoadtripChinese-v{args.version}-Windows'
    if out.exists():
        raise SystemExit(f'Output already exists: {out}. Choose a new version/directory; no files removed.')
    plugin = repo / 'build/package/BepInEx/plugins/MonsterRoadtripChinese'
    plugin_files = sorted(p for p in plugin.rglob('*') if p.is_file())
    if len(plugin_files) != 14:
        raise SystemExit('Expected the plugin DLL and 13 translation/adaptation files.')
    loader = repo / '.tools/bepinex-x86'
    compat = repo / 'build/mono-compat'
    compatibility = json.loads((compat / 'compatibility-manifest.json').read_text(encoding='utf-8-sig'))
    if sha(compat / 'MonoMod.Utils.dll') != compatibility['patchedSha256'] or sha(compat / 'MonsterRoadtripMonoCompat.dll') != compatibility['helperSha256']:
        raise SystemExit('Compatibility build hash mismatch')
    game_files = []
    for relative in ('MonsterRoadtrip.exe', 'UnityPlayer.dll',
                     'MonoBleedingEdge/EmbedRuntime/mono-2.0-bdwgc.dll',
                     'MonsterRoadtrip_Data/Managed/Assembly-CSharp.dll'):
        path = args.game_dir / relative
        game_files.append({'path': relative, 'sha256': sha(path)})
    payload: dict[str, tuple[Path, str, list[str]]] = {}
    for name in ('.doorstop_version', 'changelog.txt', 'doorstop_config.ini', 'winhttp.dll'):
        payload[name] = (loader / name, 'loader', [])
    for path in sorted((loader / 'BepInEx/core').glob('*.dll')):
        relative = 'BepInEx/core/' + path.name
        payload[relative] = (path, 'loader', [])
    payload['BepInEx/core/MonoMod.Utils.dll'] = (compat / 'MonoMod.Utils.dll', 'loader', [compatibility['originalSha256']])
    payload['BepInEx/core/MonsterRoadtripMonoCompat.dll'] = (compat / 'MonsterRoadtripMonoCompat.dll', 'loader', [])
    payload['BepInEx/core/MonsterRoadtripMonoCompat.LICENSE.txt'] = (repo / 'compat/LICENSE-MonoMod.txt', 'loader', [])
    for path in plugin_files:
        relative = 'BepInEx/plugins/MonsterRoadtripChinese/' + path.relative_to(plugin).as_posix()
        payload[relative] = (path, 'plugin', [])
    out.mkdir(parents=True)
    files = []
    for relative, (source, kind, allowed) in sorted(payload.items()):
        destination = out / 'payload' / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        files.append({'path': relative, 'kind': kind, 'sha256': sha(destination), 'allowedExistingSha256': allowed})
    for name in ('install.bat', 'uninstall.bat'):
        text = (repo / 'installer/windows' / name).read_text(encoding='utf-8')
        (out / name).write_bytes(text.replace('\r\n', '\n').replace('\n', '\r\n').encode('ascii'))
    installer = out / 'installer'
    installer.mkdir()
    # Windows PowerShell 5.1 requires a BOM to recognize Chinese script text.
    text = (repo / 'installer/windows/Manage-Mod.ps1').read_text(encoding='utf-8-sig')
    (installer / 'Manage-Mod.ps1').write_text(text, encoding='utf-8-sig')
    shutil.copy2(repo / 'THIRD-PARTY-NOTICES.md', out / 'THIRD-PARTY-NOTICES.md')
    licenses = out / 'licenses'
    licenses.mkdir()
    for path in (repo / 'compat').glob('LICENSE*.txt'):
        shutil.copy2(path, licenses / path.name)
    (out / 'package-manifest.json').write_text(json.dumps({'format': 1, 'version': args.version, 'gameFiles': game_files, 'files': files}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (out / '安装说明.txt').write_text(
        f'Monster Prom 3 - Monster Roadtrip 简体中文 Mod {args.version}\n\n'
        '适用：Windows 10 / 11，Intel / AMD 电脑，已测试游戏版本的 Windows x86 游戏程序。\n'
        'Windows 11 本机验证；Windows 10 尚待实机验证。Windows ARM、旧版 Windows、Mac 不包含在此包的验证范围。\n\n'
        '安装：\n1. 将整个压缩包解压到一个文件夹，不要直接在压缩包里运行。\n'
        '2. 正常退出游戏，双击 install.bat。自动检测不到时，选择 MonsterRoadtrip.exe 所在的游戏文件夹。\n'
        '3. 等待显示“安装完成”，之后通过 Steam 正常启动。无需另装 Python、dotnet SDK 或 BepInEx。\n\n'
        '保护措施：先校验游戏和安装包，再复制备份 UserData 与即将覆盖的旧文件；不删除、不覆盖存档。\n'
        '默认备份位置：%LOCALAPPDATA%\\MonsterRoadtripChinese\\backups\\<日期>。安装器会显示实际路径。\n'
        '仍建议自己提前复制一份游戏根目录下的 UserData 文件夹到安全位置。\n\n'
        '卸载：退出游戏，双击 uninstall.bat。只删除本安装包记录且未被修改的汉化文件，保留 UserData 与备份。\n'
        '安装前已有 BepInEx 或后来安装其他 Mod 时，会保留共享加载器和退出兼容补丁。\n'
        '本安装器首次安装的加载器，在没有其他 Mod 时会连同本包创建的文件一起移除。\n\n'
        '限制：不同游戏版本、未知加载器、游戏运行中、文件校验不符时停止安装；不自动申请管理员权限。\n'
        '游戏安装路径含中文时，当前 Unity 有已知问题，请使用 Steam 移动到英文路径；安装包解压路径可以含中文。\n'
        '重复安装同一完整版本不会改文件；升级到另一版安装包时，请先用旧包卸载。\n'
        '此包没有数字签名。只从本项目下载；文件哈希用于检查损坏，不能代替来源可信性。\n'
        'Mac 后续需独立安装包、匹配的加载器和实机验证，不能运行此 Windows 安装包。\n', encoding='utf-8-sig')
    # Do not use with_suffix for versioned directories containing dots.
    archive = Path(str(out) + '.zip')
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for path in sorted(out.rglob('*')):
            if path.is_file():
                z.write(path, path.relative_to(out).as_posix())
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None:
            raise SystemExit('Archive integrity check failed')
        if any('UserData' in name or 'save-backups' in name or 'cn.monsterroadtrip.localization.cfg' in name for name in z.namelist()):
            raise SystemExit('Unexpected local save/config file in archive')
    Path(str(archive) + '.sha256').write_text(f'{sha(archive)}  {archive.name}\n', encoding='ascii')
    print(json.dumps({'archive': str(archive), 'sha256': sha(archive), 'payload_files': len(files), 'contains_saves': False}, ensure_ascii=False))


if __name__ == '__main__':
    main()
