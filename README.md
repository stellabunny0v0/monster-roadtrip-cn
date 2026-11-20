# Monster Prom 3 - Monster Roadtrip 简体中文 Mod

非官方简体中文汉化，适用于正版 Steam 游戏。译文风格与常见角色译名延续前几作的官方中文翻译。

## 下载

| 平台 | 最新安装包 | 适用范围 |
| --- | --- | --- |
| Windows | [v0.3.8 一键安装版](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/tag/v0.3.8) | Windows 10／11，Intel／AMD；已在 Windows 11 验证 |
| Mac | [v0.3.7 一键安装版](https://github.com/stellabunny0v0/monster-roadtrip-cn/releases/tag/v0.3.7-macos-installer2) | x86_64 Mono 游戏；Intel Mac 或通过 Rosetta 运行的 Apple Silicon Mac |

在发布页面的 **Assets** 中下载对应平台 ZIP，**完整解压**后再运行。`Source code` 是源码，不是安装包；无需另装 BepInEx、Python 或 .NET。

## 安装

> [!IMPORTANT]
> 安装前请退出游戏，先[备份存档](#备份存档)，并保留安装包以便卸载。跨版本升级时，先用旧包卸载，再安装新版。

### Windows

1. 双击 `install.bat`。
2. 按提示确认游戏目录；找不到时，选择 `MonsterRoadtrip.exe` 所在文件夹。
3. 显示安装完成后，通过 Steam 正常启动游戏。

当前加载器在中文游戏安装路径下存在问题；如收到提示，请通过 Steam 将游戏移至英文路径。安装包解压位置可以含中文。

### Mac

1. 双击 `install.command`，按提示选择游戏 `.app` 或其所在目录。
2. 若系统阻止打开，确认来源后，在“系统设置 → 隐私与安全性”选择“仍要打开”（Open Anyway）。也可在终端输入 `/bin/bash `（末尾有空格），拖入 `install.command` 后按回车。
3. 如安装器询问是否允许加载器运行，核对路径和用途后输入大写 `YES`；这只会移除本包 `libdoorstop.dylib` 的下载隔离标记，直接回车可跳过。
4. 安装完成后，将终端显示的**整行启动命令**复制到 Steam → 游戏“属性”→“通用”→“启动选项”，保留引号、路径和 `%command%`，再通过 Steam 启动游戏。已有其他启动选项时，请先核对，避免覆盖。

Apple Silicon 需要 Rosetta；纯 arm64 游戏程序暂不支持。本包未签名和公证，无需全局关闭 Gatekeeper 或 SIP。已有用户反馈安装测试正常，其他机型与系统仍待更多验证。详细步骤见 [Mac 安装说明](docs/MACOS.md)。

已安装相同 v0.3.7 且文件清单一致时，可重新运行 `install.command` 核对文件并选择加载器放行，无需卸载或更改已有启动选项。

## 备份存档

退出游戏，在 Steam 中右键游戏 →“管理”→“浏览本地文件”，将以下**已有目录完整复制**到其他位置，并注明日期：

| 平台 | 手动备份位置 | 安装器自动备份位置 |
| --- | --- | --- |
| Windows | 游戏目录中的 `UserData` 文件夹 | `%LOCALAPPDATA%\MonsterRoadtripChinese\backups` |
| Mac | 右键游戏 `.app` →“显示包内容”，备份其中的 `UserData`；外层目录如也有，一并备份 | `~/Library/Application Support/MonsterRoadtripChinese/backups` |

找不到存档时，不要新建空目录或替换现有文件；Mac 的其他存档布局见[详细说明](docs/MACOS.md#存档备份)。自动备份只复制文件，不覆盖现有存档，也不会自动恢复旧进度。

## 卸载

退出游戏，使用安装时所用的安装包：

| 平台 | 卸载步骤 |
| --- | --- |
| Windows | 双击 `uninstall.bat`，选择原游戏目录 |
| Mac | 双击 `uninstall.command`，选择原游戏目录；完成后，移除 Steam 中本汉化的启动命令，保留其他设置 |

卸载保留存档、配置和备份；原先已有加载器或其他 Mod 时，会保留共享加载器。文件被修改时会停止，避免误删。手动安装的旧版可只删除 `BepInEx/plugins/MonsterRoadtripChinese`；不要删除 `UserData`。

## 问题反馈

请在 [Issues](https://github.com/stellabunny0v0/monster-roadtrip-cn/issues) 提供系统、游戏与 Mod 版本、复现步骤及游戏目录中的 `BepInEx/LogOutput.log`。翻译问题请附截图或英文原句。

## 开发

源码位于 `src`，译文位于 `translation`，工具位于 `tools`。参阅[构建说明](docs/DEVELOPMENT.md)、[翻译规范](docs/STYLE_GUIDE_ZH.md)、[平台验证范围](docs/INSTALLER_PLATFORMS.md)及[第三方组件说明](THIRD-PARTY-NOTICES.md)。
