# Monster Prom 3 - Monster Roadtrip 简体中文 Mod

为 **Monster Prom 3 - Monster Roadtrip** 提供非官方简体中文翻译。请使用正版 Steam 游戏。

| 平台 | 下载 | 适用范围 |
| --- | --- | --- |
| Windows | [一键安装包](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/tag/v0.3.6-mono-layout-1) | Windows 10／11，Intel／AMD；已在 Windows 11 验证 |
| macOS | [实验版安装包](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/tag/v0.3.7-macos-experimental) | x86_64 Mono 游戏；Apple Silicon 需 Rosetta，**尚未在 Mac 真机验证** |

## 安装

**安装前请退出游戏，并先[备份存档](#备份存档)。** 从 Release 的 **Assets** 下载对应平台 ZIP，完整解压后再运行；`Source code` 不是安装包。无需另装 BepInEx、Python 或 dotnet。

### Windows

1. 双击 `install.bat`。
2. 按提示确认游戏目录；找不到时，选择 `MonsterRoadtrip.exe` 所在文件夹。
3. 显示安装完成后，通过 Steam 正常启动游戏。

当前加载器在中文游戏安装路径下存在问题；如收到提示，请通过 Steam 将游戏移至英文路径。安装包解压位置可以含中文。

### macOS（实验版）

1. 双击 `install.command`，按提示选择游戏 `.app` 或其所在目录。
2. 安装完成后，将终端显示的**整行启动选项**复制到 Steam → 游戏“属性”→“通用”→“启动选项”。
3. 通过 Steam 启动游戏。Apple Silicon 需要先安装 Rosetta；纯 arm64 游戏程序暂不支持。

若系统阻止打开脚本，或需要从终端安装，请参阅 [Mac 安装说明](docs/MACOS.md)。这是供测试的独立安装包，中文显示、存档读写及退出流程仍待 Mac 实机确认。

## 备份存档

1. 退出游戏，在 Steam 中右键游戏 →“管理”→“浏览本地文件”。
2. **Windows：**把游戏目录中的整个 `UserData` 文件夹复制到其他位置，并注明日期。
3. **Mac：**右键游戏 `.app` →“显示包内容”，复制其中的 `UserData`；游戏外层目录如也有 `UserData`，一并备份。找不到时不要新建或替换存档，详见 [Mac 说明](docs/MACOS.md#存档备份)。

安装器还会自动复制备份，并显示实际路径：

- Windows：`%LOCALAPPDATA%\MonsterRoadtripChinese\backups`
- Mac：`~/Library/Application Support/MonsterRoadtripChinese/backups`

备份只复制文件，不删除或覆盖现有存档，也不会自动恢复旧进度。

## 卸载

退出游戏，运行安装时所用包中的 `uninstall.bat`（Windows）或 `uninstall.command`（Mac）。**Mac 还需删除 Steam 中本汉化的启动选项。**

卸载保留存档、配置和备份；有其他 Mod 或原先已有 BepInEx 时，保留共享加载器。文件被修改时会停止，避免误删。升级前请先用旧包卸载。

手动安装的旧版，可只删除 `BepInEx/plugins/MonsterRoadtripChinese`。不要删除 `UserData`；不确定加载器用途时，请保留 BepInEx。

## 问题反馈

请附上系统、游戏与 Mod 版本、复现步骤，以及游戏目录中的 `BepInEx/LogOutput.log`。翻译问题请附截图或英文原句。

## 开发与许可

源码在 `src`，译文在 `translation`，工具在 `tools`。参阅 [构建说明](docs/DEVELOPMENT.md)、[翻译规范](docs/STYLE_GUIDE_ZH.md)和[平台验证范围](docs/INSTALLER_PLATFORMS.md)。发行包所含第三方组件及许可见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。
